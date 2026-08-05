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
