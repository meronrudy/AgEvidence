"""Packaged country manifest resources used by the SDK runtime."""

from __future__ import annotations

import json
from importlib import resources
from typing import Any


def country_manifest_snapshots() -> list[dict[str, Any]]:
    payload = resources.files("agevidence.resources").joinpath("country_adapters.json").read_text(encoding="utf-8")
    value = json.loads(payload)
    manifests = value.get("manifests", [])
    if not isinstance(manifests, list):
        raise ValueError("country_adapters.json must contain a manifests array")
    return manifests


def country_manifest_snapshot(adapter_id: str) -> dict[str, Any]:
    for manifest in country_manifest_snapshots():
        adapter = manifest.get("adapter", {})
        if adapter.get("id") == adapter_id:
            return manifest
    raise KeyError(adapter_id)


def country_manifest_snapshot_by_code(country_code: str) -> dict[str, Any]:
    normalized = country_code.upper().replace("-", "_")
    matches = [
        manifest
        for manifest in country_manifest_snapshots()
        if str(manifest.get("adapter", {}).get("country_code", "")).upper().replace("-", "_") == normalized
    ]
    active = [manifest for manifest in matches if manifest.get("adapter", {}).get("status") == "active"]
    selected = active or matches
    if len(selected) != 1:
        raise KeyError(country_code)
    return selected[0]
