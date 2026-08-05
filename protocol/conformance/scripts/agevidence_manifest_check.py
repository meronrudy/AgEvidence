#!/usr/bin/env python3
"""Validate AgEvidence country adapter manifests.

This is a local CI gate. It intentionally treats implementation status as a
validator result, not as a side effect of syntactically valid YAML.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_ROOT / "sdks" / "python" / "src"))

from agevidence.adapters.manifest_validation import validate_manifest_root  # noqa: E402

DEFAULT_ROOT = REPO_ROOT / "specs" / "agevidence" / "country_adapters"
DEFAULT_SCHEMA = REPO_ROOT / "specs" / "agevidence" / "schemas" / "athian.country_adapter_manifest.v1.json"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=DEFAULT_ROOT)
    parser.add_argument("--schema", type=Path, default=DEFAULT_SCHEMA)
    parser.add_argument("--json", action="store_true", help="Emit machine-readable output.")
    args = parser.parse_args()

    reports = validate_manifest_root(args.root, args.schema, report_root=REPO_ROOT)
    failed = [report for report in reports if report["classification"] == "invalid"]

    if args.json:
        print(json.dumps({"manifests": reports}, indent=2, sort_keys=True))
    else:
        for report in reports:
            print(f"{report['classification']:8} {report['country_code'] or '-':6} {report['adapter_id'] or '-'} {report['path']}")
            for error in report["errors"]:
                print(f"  - {error}")

    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
