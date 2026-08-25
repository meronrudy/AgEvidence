from __future__ import annotations

import json

import httpx
from typer.testing import CliRunner

from agevidence import Client
from agevidence.cli import app


runner = CliRunner()


def transport_for(handler):
    return httpx.MockTransport(handler)


def json_response(payload, status_code=200):
    return httpx.Response(status_code, json=payload)


def test_campaign_client_constructs_core_requests_and_headers():
    seen = []

    def handler(request: httpx.Request) -> httpx.Response:
        seen.append((request.method, request.url.path, dict(request.headers), json.loads(request.content or b"{}")))
        if request.url.path == "/v1/campaign/accounts":
            if request.method == "POST":
                return json_response({"account_id": "camp_1", "name": "Target", "country_code": "AU", "status": "identified", "qualification_level": "unqualified"}, 201)
            return json_response({"accounts": [{"account_id": "camp_1", "name": "Target", "country_code": "AU", "status": "identified", "qualification_level": "unqualified"}]})
        if request.url.path == "/v1/campaign/accounts/camp_1/activations":
            return json_response({"activation_id": "act_1", "account_id": "camp_1", "path_type": "python_sdk", "status": "started"}, 201)
        if request.url.path == "/v1/campaign/accounts/camp_1/qualifications":
            return json_response({"qualification_id": "tq_1", "account_id": "camp_1", "status": "qualified", "qualification_level": "developer_activated"})
        if request.url.path == "/v1/campaign/accounts/camp_1/handoffs":
            return json_response(
                {
                    "handoff_id": "handoff_1",
                    "account_id": "camp_1",
                    "qualification_id": "tq_1",
                    "product_code": "evidence_architecture_sprint",
                    "status": "ready",
                    "scope_digest": "sha256:" + "a" * 64,
                    "salesforce_proposal_id": "sf_prop_1",
                    "proposal_reference": "proposal-1",
                    "proposal_terms_digest": "sha256:" + "b" * 64,
                    "contract_reference": "contract-1",
                    "contract_terms_digest": "sha256:" + "c" * 64,
                    "invoice_reference": "invoice-1",
                    "cash_collection_reference": "cash-1",
                    "revenue_system": "salesforce",
                    "last_revenue_signal_at": "2026-08-05T12:00:00Z",
                },
                201,
            )
        if request.url.path == "/v1/campaign/dashboard":
            return json_response({"counts": {"accounts": 1}, "phase10": {"enabled": False}, "recent_accounts": []})
        raise AssertionError(request.url.path)

    client = Client(
        base_url="http://testserver",
        transport=transport_for(handler),
        campaign_account_id="camp_1",
        activation_id="act_1",
        repository_sha="f4ec679",
    )

    account = client.campaign.create_account(name="Target", country_code="AU")
    accounts = client.campaign.list_accounts()
    activation = client.campaign.start_activation("camp_1", path_type="python_sdk")
    qualification = client.campaign.evaluate_qualification("camp_1", developer_project_id="42")
    handoff = client.campaign.create_handoff("camp_1", qualification_id="tq_1", product_code="evidence_architecture_sprint", planning_value_cents=1, scope={})
    dashboard = client.campaign.get_dashboard()

    assert account.account_id == "camp_1"
    assert accounts[0].account_id == "camp_1"
    assert activation.path_type == "python_sdk"
    assert qualification.qualification_level == "developer_activated"
    assert handoff.product_code == "evidence_architecture_sprint"
    assert handoff.salesforce_proposal_id == "sf_prop_1"
    assert handoff.cash_collection_reference == "cash-1"
    assert dashboard.counts["accounts"] == 1
    assert dashboard.phase10["enabled"] is False
    assert seen[0][2]["x-agevidence-campaign-account"] == "camp_1"
    assert seen[0][2]["x-agevidence-activation"] == "act_1"
    assert seen[0][2]["x-agevidence-repository-sha"] == "f4ec679"
    assert "x-agevidence-sdk-version" in seen[0][2]


def test_campaign_headers_do_not_mutate_event_payload():
    seen_payload = {}

    def handler(request: httpx.Request) -> httpx.Response:
        seen_payload.update(json.loads(request.content))
        return json_response({"event_id": "evt_1", "status": "accepted", "duplicate": False}, 202)

    client = Client(base_url="http://testserver", transport=transport_for(handler), campaign_account_id="camp_1", activation_id="act_1")
    event = {
        "event_id": "evt_1",
        "event_type": "project.registered",
        "data": {"project_id": "project-1"},
    }
    client.submit_event(event, source="source", timestamp="2026-08-04T18:00:00Z", signature="v1=sig")

    assert seen_payload == event
    assert "campaign_account_id" not in seen_payload
    assert "activation_id" not in seen_payload


def test_campaign_cli_account_create_and_yaml(monkeypatch):
    class FakeCampaign:
        def create_account(self, **kwargs):
            assert kwargs["name"] == "Target"
            return {"account_id": "camp_1", "name": kwargs["name"], "country_code": kwargs["country_code"]}

    class FakeClient:
        campaign = FakeCampaign()

    monkeypatch.setattr("agevidence.cli._client", lambda **_kwargs: FakeClient())

    result = runner.invoke(app, ["campaign", "account", "create", "--name", "Target", "--country-code", "AU", "--format", "yaml"])

    assert result.exit_code == 0
    assert "account_id: camp_1" in result.stdout


def test_campaign_cli_dashboard_json_includes_phase10_gate(monkeypatch):
    class FakeCampaign:
        def get_dashboard(self):
            return {"counts": {"accounts": 1}, "phase10": {"enabled": True, "proof_handoff_id": "handoff_1"}}

    class FakeClient:
        campaign = FakeCampaign()

    monkeypatch.setattr("agevidence.cli._client", lambda **_kwargs: FakeClient())

    result = runner.invoke(app, ["campaign", "dashboard"])

    assert result.exit_code == 0
    assert '"phase10"' in result.stdout
    assert '"proof_handoff_id": "handoff_1"' in result.stdout


def test_project_4030_replay_completes_campaign_activation(tmp_path, monkeypatch):
    fixture = tmp_path / "01-project.registered.json"
    fixture.write_text(
        json.dumps(
            {
                "event_id": "evt_1",
                "event_type": "project.registered",
                "schema_version": "1.0.0",
                "source": "source",
                "occurred_at": "2026-08-04T18:00:00Z",
                "subject": {"type": "project", "external_id": "project-1"},
                "data": {},
                "integrity": {"payload_digest": "pending", "signature_algorithm": "hmac-sha256", "signature": "pending"},
            }
        )
    )

    class Submission:
        def model_dump(self, **_kwargs):
            return {"event_id": "evt_1", "status": "accepted", "duplicate": False}

    class Activation:
        def model_dump(self, **_kwargs):
            return {"activation_id": "act_1", "status": "completed"}

    class FakeCampaign:
        def complete_activation(self, account_id, activation_id):
            assert account_id == "camp_1"
            assert activation_id == "act_1"
            return Activation()

    class FakeClient:
        campaign = FakeCampaign()

        def submit_event(self, *_args, **_kwargs):
            return Submission()

    monkeypatch.setattr("agevidence.cli._client", lambda **kwargs: FakeClient())

    result = runner.invoke(
        app,
        [
            "replay",
            "project-4030",
            "--fixture-root",
            str(tmp_path),
            "--campaign-account-id",
            "camp_1",
            "--activation-id",
            "act_1",
        ],
    )

    assert result.exit_code == 0
    assert '"campaign_activation"' in result.stdout
    assert '"status": "completed"' in result.stdout
