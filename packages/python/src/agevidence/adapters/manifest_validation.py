"""Reusable country adapter manifest validation."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import jsonschema
import yaml


IMPLEMENTATION_STATUSES = {"active", "pilot", "scaffold", "research"}


def load_yaml(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        value = yaml.safe_load(handle) or {}
    if not isinstance(value, dict):
        raise ValueError("manifest must be a YAML object")
    return value


def load_json_schema(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError("manifest schema must be a JSON object")
    return value


def classify_manifest(manifest: dict[str, Any], errors: list[str]) -> str:
    if errors:
        return "invalid"
    status = manifest.get("adapter", {}).get("status")
    if status in IMPLEMENTATION_STATUSES:
        return str(status)
    if status in {"superseded", "retired"}:
        return "research"
    return "invalid"


def validate_manifest_data(manifest: dict[str, Any], schema: dict[str, Any]) -> dict[str, Any]:
    errors = [
        error.message
        for error in sorted(
            jsonschema.Draft202012Validator(schema).iter_errors(manifest),
            key=lambda item: list(item.path),
        )
    ]
    adapter = manifest.get("adapter", {}) if isinstance(manifest, dict) else {}
    return {
        "adapter_id": adapter.get("id"),
        "country_code": adapter.get("country_code"),
        "declared_status": adapter.get("status"),
        "classification": classify_manifest(manifest, errors),
        "errors": errors,
    }


def validate_manifest_path(path: Path, schema: dict[str, Any], *, root: Path | None = None) -> dict[str, Any]:
    errors: list[str] = []
    manifest: dict[str, Any] = {}
    try:
        manifest = load_yaml(path)
        report = validate_manifest_data(manifest, schema)
        errors = report["errors"]
    except Exception as exc:  # noqa: BLE001 - validators report all file errors.
        report = {
            "adapter_id": None,
            "country_code": None,
            "declared_status": None,
            "classification": "invalid",
            "errors": [str(exc)],
        }
        errors = report["errors"]

    adapter = manifest.get("adapter", {}) if isinstance(manifest, dict) else {}
    report.update(
        {
            "path": str(path.relative_to(root)) if root else str(path),
            "adapter_id": adapter.get("id") or report.get("adapter_id"),
            "country_code": adapter.get("country_code") or report.get("country_code"),
            "declared_status": adapter.get("status") or report.get("declared_status"),
            "classification": classify_manifest(manifest, errors),
            "errors": errors,
        }
    )
    return report


def validate_manifest_root(root: Path, schema_path: Path, *, report_root: Path | None = None) -> list[dict[str, Any]]:
    schema = load_json_schema(schema_path)
    return [validate_manifest_path(path, schema, root=report_root) for path in sorted(root.glob("*/adapter.yml"))]
