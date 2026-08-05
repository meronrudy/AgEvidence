"""Integration event helpers.

These helpers sign upstream integration events only. They do not sign receipts
or produce receipt commitments.
"""

from __future__ import annotations

import copy
import hashlib
import hmac
import json
from pathlib import Path
from typing import Any, Iterable


def canonical_value(value: Any) -> Any:
    if isinstance(value, dict):
        return {key: canonical_value(value[key]) for key in sorted(value)}
    if isinstance(value, list):
        return [canonical_value(item) for item in value]
    return value


def canonical_json(value: Any) -> str:
    return json.dumps(canonical_value(value), separators=(",", ":"), ensure_ascii=False)


def canonical_event_payload(event: dict[str, Any], source: str | None = None) -> str:
    payload = canonical_value(copy.deepcopy(event))
    if source:
        payload["source"] = source
    payload.setdefault("integrity", {})
    payload["integrity"].pop("payload_digest", None)
    payload["integrity"].pop("signature", None)
    payload["integrity"].setdefault("signature_algorithm", "hmac-sha256")
    return canonical_json(payload)


def sign_hmac_event(event: dict[str, Any], *, source: str, secret: str, timestamp: str | None = None) -> dict[str, Any]:
    signed = copy.deepcopy(event)
    signed["source"] = source
    signed.setdefault("integrity", {})
    signed["integrity"]["signature_algorithm"] = "hmac-sha256"
    occurred_at = timestamp or signed["occurred_at"]
    canonical = canonical_event_payload(signed, source=source)
    digest = hashlib.sha256(canonical.encode("utf-8")).hexdigest()
    signature = hmac.new(secret.encode("utf-8"), f"{occurred_at}\n{canonical}".encode("utf-8"), hashlib.sha256).hexdigest()
    signed["integrity"]["payload_digest"] = f"sha256:{digest}"
    signed["integrity"]["signature"] = f"v1={signature}"
    return signed


def load_event(path: str | Path) -> dict[str, Any]:
    return json.loads(Path(path).read_text(encoding="utf-8"))


def project_4030_event_files(root: str | Path | None = None) -> list[Path]:
    base = Path(root) if root else Path(__file__).resolve().parents[4] / "examples" / "integrations" / "project_4030_beef"
    return sorted(base.glob("[0-9][0-9]-*.json"))


def load_project_4030_events(root: str | Path | None = None) -> Iterable[dict[str, Any]]:
    for path in project_4030_event_files(root):
        yield load_event(path)
