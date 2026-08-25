#!/usr/bin/env python3
"""Validate country adapter paths in the OpenAPI document."""

from __future__ import annotations

from pathlib import Path

import yaml


REPO_ROOT = Path(__file__).resolve().parents[1]
OPENAPI_PATH = REPO_ROOT / "docs" / "openapi" / "agevidence.v1.yaml"
REQUIRED_PATHS = {
    "/v1/country_adapters",
    "/v1/country_adapters/{adapter_id}",
    "/v1/country_adapters/{adapter_id}/validate",
    "/v1/developer/projects/{project_id}/country_determinations",
}


def main() -> int:
    document = yaml.safe_load(OPENAPI_PATH.read_text(encoding="utf-8"))
    paths = set((document or {}).get("paths", {}))
    missing = sorted(REQUIRED_PATHS - paths)
    if missing:
        for path in missing:
            print(f"missing OpenAPI country path: {path}")
        return 1
    print("AgEvidence OpenAPI country paths passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

