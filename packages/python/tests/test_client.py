from __future__ import annotations

import json
import time

import httpx
import pytest

from agevidence import Client
from agevidence.errors import AgEvidenceError


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
