#!/usr/bin/env python3
"""Validate canonical Rails API paths in the OpenAPI document."""

from __future__ import annotations

from pathlib import Path

import yaml


REPO_ROOT = Path(__file__).resolve().parents[3]
OPENAPI_PATH = REPO_ROOT / "protocol" / "openapi" / "agevidence-v1.yaml"
REQUIRED_PATHS = {
    "/projects/{project_code}/source-records",
    "/projects/{project_code}/source-records/{record_code}",
    "/artifacts/{artifact_code}",
    "/artifacts/{artifact_code}/verify",
    "/artifacts/{artifact_code}/reliance-events",
    "/schemas/{contract_version}",
}


def main() -> int:
    document = yaml.safe_load(OPENAPI_PATH.read_text(encoding="utf-8"))
    paths = set((document or {}).get("paths", {}))
    missing = sorted(REQUIRED_PATHS - paths)
    if missing:
        for path in missing:
            print(f"missing canonical OpenAPI path: {path}")
        return 1
    print("AgEvidence canonical OpenAPI paths passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
