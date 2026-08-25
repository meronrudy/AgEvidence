from __future__ import annotations

import json
from pathlib import Path

import pytest

from agevidence.events import canonical_event_payload, sign_hmac_event
from agevidence.errors import AgEvidenceError
from agevidence.verification import Verifier


def event_payload():
    return {
        "event_id": "evt_demo_1",
        "event_type": "project.registered",
        "schema_version": "1.0.0",
        "source": "demo",
        "occurred_at": "2026-08-04T18:00:00Z",
        "subject": {"type": "project", "external_id": "project-1"},
        "correlation": {"project_id": "project-1"},
        "data": {"project_id": "project-1"},
        "integrity": {
            "payload_digest": "sha256:scaffold-demo",
            "signature_algorithm": "hmac-sha256",
            "signature": "v1=scaffold",
        },
    }


def test_canonical_event_payload_excludes_signature_and_digest():
    canonical = canonical_event_payload(event_payload(), source="demo")

    assert "payload_digest" not in canonical
    assert "v1=scaffold" not in canonical
    assert json.loads(canonical)["integrity"]["signature_algorithm"] == "hmac-sha256"


def test_sign_hmac_event_sets_digest_and_signature():
    signed = sign_hmac_event(event_payload(), source="source-a", secret="secret")

    assert signed["source"] == "source-a"
    assert signed["integrity"]["payload_digest"].startswith("sha256:")
    assert signed["integrity"]["signature"].startswith("v1=")


def test_verifier_missing_command_fails_clearly(monkeypatch):
    monkeypatch.delenv("AGEVIDENCE_VERIFIER_COMMAND", raising=False)

    with pytest.raises(AgEvidenceError, match="VERIFIER_COMMAND_MISSING"):
        Verifier(command=None).verify_bundle(Path("bundle.zip"))


def test_verifier_missing_binary_fails_clearly():
    with pytest.raises(AgEvidenceError, match="VERIFIER_COMMAND_NOT_FOUND"):
        Verifier(command="/definitely/missing/agevidence-verifier").verify_bundle(Path("bundle.zip"))
