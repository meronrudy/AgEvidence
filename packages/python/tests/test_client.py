from __future__ import annotations

import asyncio
import json
import shutil
import subprocess
import sys
import time

import httpx
import pytest

from agevidence import AsyncClient, Client
from agevidence.errors import AgEvidenceError
from agevidence.transport import RetryPolicy


def transport_for(handler):
    return httpx.MockTransport(handler)


def json_response(payload, status_code=200):
    return httpx.Response(status_code, json=payload)


def test_client_constructs_full_developer_flow_requests():
    seen = []

    def handler(request: httpx.Request) -> httpx.Response:
        seen.append((request.method, request.url.path, json.loads(request.content or b"{}")))
        if request.url.path == "/v1/developer/projects":
            return json_response({"id": 42, "name": "Pilot"}, 201)
        if request.url.path == "/v1/developer/projects/42/source_records":
            return json_response({"id": 1, "document_id": "trial", "evidence_type": "evidence.trial_report", "controlled_uri": "evidence://trial", "commitment": "sha256:demo"})
        if request.url.path == "/v1/developer/projects/42/model_runs":
            return json_response({"id": 2, "adapter_id": "qwen3.5-4b-reference", "status": "completed", "candidates": [], "gaps": []})
        if request.url.path == "/v1/developer/candidates/7":
            return json_response({"id": 7, "review_status": "accepted", "latest_decision": {"id": 8, "decision": "accepted"}})
        if request.url.path == "/v1/pricing/quotes":
            return json_response({"quote_id": "quote_1", "product_code": "verification_readiness_cycle", "amount": 6000000, "status": "quoted"})
        if request.url.path == "/v1/artifact-orders":
            return json_response({"order_id": "order_1", "quote_id": "quote_1", "status": "quoted"}, 201)
        if request.url.path == "/v1/artifact-orders/order_1/checkout":
            return json_response({"order_id": "order_1", "quote_id": "quote_1", "status": "paid"})
        if request.url.path == "/v1/developer/projects/42/artifacts":
            return json_response({"order_id": "order_1", "quote_id": "quote_1", "status": "fulfilled", "artifact": {"artifact_id": "artifact_1", "verification_command": "verify-bundle demo.zip"}}, 201)
        raise AssertionError(request.url.path)

    client = Client(base_url="http://testserver", transport=transport_for(handler))

    project = client.create_project(account_name="Startup", project_name="Pilot", target_claim="Methane reduction")
    source = client.submit_source_record(project_id=project.id, document_id="trial", evidence_type="evidence.trial_report", controlled_uri="evidence://trial", commitment="sha256:demo")
    run = client.run_model(project_id=project.id)
    candidate = client.review_candidate(candidate_id=7, decision="accepted", reason="source linked")
    quote = client.create_quote(project_id=project.id, product_code="verification_readiness_cycle")
    order = client.create_order(quote_id=quote.quote_id)
    paid = client.checkout_order(order_id=order.order_id)
    artifact = client.build_artifact(project_id=project.id, order_id=paid.order_id)

    assert source.document_id == "trial"
    assert run.status == "completed"
    assert candidate.review_status == "accepted"
    assert artifact.artifact.verification_command == "verify-bundle demo.zip"
    assert ("POST", "/v1/developer/projects/42/artifacts", {"order_id": "order_1", "sandbox_checkout": False}) in seen


def test_error_shape_maps_to_agevidence_error():
    def handler(_request: httpx.Request) -> httpx.Response:
        return json_response({"error": {"code": "PROJECT_NOT_FOUND", "message": "Project was not found."}}, 404)

    client = Client(base_url="http://testserver", transport=transport_for(handler))

    with pytest.raises(AgEvidenceError) as exc:
        client.get_project("missing")

    assert exc.value.status_code == 404
    assert exc.value.code == "PROJECT_NOT_FOUND"
    assert "Project was not found" in str(exc.value)


def test_wait_for_operation_returns_terminal_state():
    calls = {"count": 0}

    def handler(_request: httpx.Request) -> httpx.Response:
        calls["count"] += 1
        status = "succeeded" if calls["count"] > 1 else "pending"
        return json_response({"operation_id": "op_1", "status": status})

    client = Client(base_url="http://testserver", transport=transport_for(handler))

    operation = client.wait_for_operation("op_1", timeout=1, interval=0.01)

    assert operation.status == "succeeded"


def test_wait_for_operation_times_out():
    def handler(_request: httpx.Request) -> httpx.Response:
        return json_response({"operation_id": "op_1", "status": "pending"})

    client = Client(base_url="http://testserver", transport=transport_for(handler))

    with pytest.raises(AgEvidenceError, match="OPERATION_TIMEOUT"):
        client.wait_for_operation("op_1", timeout=0.01, interval=0.01)


def test_get_retries_transient_http_error():
    calls = {"count": 0}

    def handler(request: httpx.Request) -> httpx.Response:
        calls["count"] += 1
        if calls["count"] == 1:
            raise httpx.ConnectError("temporary", request=request)
        return json_response({"operation_id": "op_1", "status": "succeeded"})

    client = Client(base_url="http://testserver", transport=transport_for(handler), retries=1)

    assert client.get_operation("op_1").status == "succeeded"
    assert calls["count"] == 2


def test_resource_namespaces_accept_paginated_envelopes_and_auth_headers():
    seen = []

    def handler(request: httpx.Request) -> httpx.Response:
        seen.append((request.url.path, dict(request.headers)))
        if request.url.path == "/v1/country_adapters":
            return json_response(
                {
                    "adapters": [
                        {
                            "adapter_id": "athian-country-au-livestock-v1",
                            "country_code": "AU",
                            "version": "v1",
                            "status": "active",
                        }
                    ],
                    "next_cursor": None,
                }
            )
        raise AssertionError(request.url.path)

    client = Client(base_url="http://testserver", api_token="token", transport=transport_for(handler))

    adapters = client.country.list_adapters()

    assert adapters[0].adapter_id == "athian-country-au-livestock-v1"
    assert seen[0][1]["authorization"] == "Bearer token"


def test_mutating_request_retries_only_with_idempotency_key():
    calls = {"count": 0}

    def handler(request: httpx.Request) -> httpx.Response:
        calls["count"] += 1
        if calls["count"] == 1:
            return json_response({"error": {"code": "TEMPORARY", "message": "retry later"}}, 503)
        assert request.headers["idempotency-key"] == "idem-1"
        return json_response({"quote_id": "quote_1", "product_code": "verification_readiness_cycle", "amount": 1, "status": "quoted"})

    client = Client(
        base_url="http://testserver",
        transport=transport_for(handler),
        retry_policy=RetryPolicy(max_attempts=2, backoff_seconds=0),
    )

    quote = client.pricing.create_quote(
        project_id="42",
        product_code="verification_readiness_cycle",
        idempotency_key="idem-1",
    )

    assert quote.quote_id == "quote_1"
    assert calls["count"] == 2


def test_mutating_request_without_idempotency_key_does_not_retry_status():
    calls = {"count": 0}

    def handler(_request: httpx.Request) -> httpx.Response:
        calls["count"] += 1
        return json_response({"error": {"code": "TEMPORARY", "message": "retry later"}}, 503)

    client = Client(
        base_url="http://testserver",
        transport=transport_for(handler),
        retry_policy=RetryPolicy(max_attempts=2, backoff_seconds=0),
    )

    with pytest.raises(AgEvidenceError) as exc:
        client.pricing.create_quote(project_id="42", product_code="verification_readiness_cycle")

    assert exc.value.status_code == 503
    assert calls["count"] == 1


def test_async_client_mirrors_resource_namespace_and_headers():
    seen = []

    async def handler(request: httpx.Request) -> httpx.Response:
        seen.append((request.url.path, dict(request.headers)))
        return json_response(
            {
                "adapters": [
                    {
                        "adapter_id": "athian-country-au-livestock-v1",
                        "country_code": "AU",
                        "version": "v1",
                        "status": "active",
                    }
                ]
            }
        )

    async def run() -> None:
        async with AsyncClient(base_url="http://testserver", api_token="token", transport=httpx.MockTransport(handler)) as client:
            adapters = await client.country.list_adapters()
            assert adapters[0].country_code == "AU"

    asyncio.run(run())

    assert seen[0][0] == "/v1/country_adapters"
    assert seen[0][1]["authorization"] == "Bearer token"


def test_package_build_install_and_cli_help_smoke(tmp_path):
    pytest.importorskip("build")
    repo_root = __import__("pathlib").Path(__file__).resolve().parents[3]
    sdk_root = repo_root / "sdks" / "python"
    dist_dir = tmp_path / "dist"
    result = subprocess.run(
        [sys.executable, "-m", "build", "--sdist", "--wheel", "--outdir", str(dist_dir)],
        cwd=sdk_root,
        capture_output=True,
        text=True,
        check=False,
    )
    assert result.returncode == 0, result.stderr

    venv_dir = tmp_path / "venv"
    subprocess.run([sys.executable, "-m", "venv", str(venv_dir)], check=True)
    python = venv_dir / ("Scripts/python.exe" if sys.platform == "win32" else "bin/python")
    wheel = next(dist_dir.glob("*.whl"))
    install = subprocess.run([str(python), "-m", "pip", "install", str(wheel)], capture_output=True, text=True, check=False)
    assert install.returncode == 0, install.stderr
    imported = subprocess.run(
        [str(python), "-c", "import agevidence; print(agevidence.__version__)"],
        capture_output=True,
        text=True,
        check=False,
    )
    assert imported.returncode == 0, imported.stderr
    help_result = subprocess.run([str(python), "-m", "agevidence", "--help"], capture_output=True, text=True, check=False)
    assert help_result.returncode == 0, help_result.stderr
    shutil.rmtree(sdk_root / "build", ignore_errors=True)
    shutil.rmtree(sdk_root / "src" / "agevidence.egg-info", ignore_errors=True)
