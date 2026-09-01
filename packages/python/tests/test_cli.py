from __future__ import annotations

import json
from pathlib import Path

import httpx
from typer.testing import CliRunner

from agevidence.cli import app


runner = CliRunner()


def test_login_writes_config_without_printing_token(tmp_path, monkeypatch):
    config_path = tmp_path / "config.json"
    monkeypatch.setenv("AGEVIDENCE_CONFIG_PATH", str(config_path))

    result = runner.invoke(app, ["login", "--base-url", "http://localhost:3000", "--api-token", "secret-token"])

    assert result.exit_code == 0
    assert "secret-token" not in result.stdout
    assert json.loads(config_path.read_text())["api_token"] == "secret-token"


def test_project_create_command_uses_sdk(monkeypatch):
    class FakeClient:
        def create_project(self, **kwargs):
            assert kwargs["account_name"] == "Startup"
            return {"id": 1, "name": kwargs["project_name"]}

    monkeypatch.setattr("agevidence.cli._client", lambda: FakeClient())

    result = runner.invoke(
        app,
        [
            "project",
            "create",
            "--account-name",
            "Startup",
            "--name",
            "Pilot",
            "--target-claim",
            "Methane reduction",
        ],
    )

    assert result.exit_code == 0
    assert '"name": "Pilot"' in result.stdout


def test_event_submit_accepts_explicit_signature(tmp_path, monkeypatch):
    event_path = tmp_path / "event.json"
    event_path.write_text('{"event_id":"evt_1","occurred_at":"2026-08-04T18:00:00Z"}')

    class FakeClient:
        def submit_event(self, event, **kwargs):
            assert event["event_id"] == "evt_1"
            assert kwargs["signature"] == "v1=sig"
            return {"event_id": "evt_1", "status": "accepted", "duplicate": False}

    monkeypatch.setattr("agevidence.cli._client", lambda: FakeClient())

    result = runner.invoke(
        app,
        [
            "event",
            "submit",
            "--file",
            str(event_path),
            "--source",
            "source",
            "--timestamp",
            "2026-08-04T18:00:00Z",
            "--signature",
            "v1=sig",
        ],
    )

    assert result.exit_code == 0
    assert '"event_id": "evt_1"' in result.stdout


def test_pricing_products_table_output(monkeypatch):
    class FakeClient:
        def list_products(self):
            return {"products": [{"code": "verification_readiness_cycle"}]}

    monkeypatch.setattr("agevidence.cli._client", lambda: FakeClient())

    result = runner.invoke(app, ["pricing", "products", "--format", "table"])

    assert result.exit_code == 0
    assert "products" in result.stdout


def test_adapters_list_uses_local_runtime():
    result = runner.invoke(app, ["adapters", "list"])

    assert result.exit_code == 0
    assert "athian-country-au-livestock-v1" in result.stdout
    assert "athian-country-eu-common-v1" in result.stdout


def test_identifier_normalize_command():
    result = runner.invoke(app, ["identifiers", "normalize", "AU", "au_pic", "ABC123"])

    assert result.exit_code == 0
    assert '"valid_format": true' in result.stdout
    assert '"identifier_system": "au_pic"' in result.stdout


def test_source_normalize_command(tmp_path):
    record = tmp_path / "record.json"
    record.write_text(json.dumps({"document_id": "envd-1", "commitment": "sha256:envd-1"}))

    result = runner.invoke(app, ["sources", "normalize", "AU", "au_envd", str(record)])

    assert result.exit_code == 0
    assert '"global_evidence_type": "evidence.feed_record"' in result.stdout


def test_country_evaluate_uses_sdk(monkeypatch):
    class FakeClient:
        def create_country_determination(self, **kwargs):
            assert kwargs["project_id"] == "project-1"
            assert kwargs["adapter"] == "AU"
            return {"adapter_id": "athian-country-au-livestock-v1", "country_code": "AU", "status": "eligible"}

    monkeypatch.setattr("agevidence.country_cli._client", lambda: FakeClient())

    result = runner.invoke(app, ["country", "evaluate", "project-1", "--adapter", "AU"])

    assert result.exit_code == 0
    assert '"country_code": "AU"' in result.stdout
