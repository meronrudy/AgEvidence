#!/usr/bin/env python3
"""Count net-new AgEvidence implementation LOC since a baseline commit."""

from __future__ import annotations

import argparse
import subprocess
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
DEFAULT_BASELINE = "pre-monorepo-2026-08-25"
PLOC = {".py", ".rb", ".rs", ".ts", ".js", ".sql", ".sh"}
CLOC = {".yml", ".yaml", ".json"}
DLOC = {".md", ".txt"}
EXCLUDED = {"package-lock.json", "Gemfile.lock", "Cargo.lock"}
ACTIVE_PREFIXES = (
    "apps/console/",
    "docs/adr/",
    "docs/comparison/",
    "docs/country/",
    "docs/self-service/COUNTRY_ADAPTER_GUIDE.md",
    "docs/self-service/GOVERNMENT_DATA_CONNECTOR_GUIDE.md",
    "docs/self-service/PYTHON_PLUGIN_GUIDE.md",
    "examples/countries/",
    "examples/python_plugins/",
    "papers/",
    "protocol/conformance/scripts/agevidence_",
    "packages/python/src/agevidence/adapters/",
    "packages/python/src/agevidence/countries/",
    "packages/python/src/agevidence/country_cli.py",
    "packages/python/src/agevidence/identifiers/",
    "packages/python/src/agevidence/policies/",
    "packages/python/src/agevidence/sources/",
    "packages/python/tests/test_adapters_runtime.py",
    "protocol/",
)
CAMPAIGN_MARKERS = (
    "/campaign/",
    "campaign/",
    "Campaign",
    "CAMPAIGN",
    "packages/python/src/agevidence/campaign/",
    "packages/python/tests/test_campaign.py",
    "specs/campaign/",
)


def category(path: str) -> str | None:
    name = Path(path).name
    if name in EXCLUDED or "__pycache__" in path:
        return None
    suffix = Path(path).suffix
    if path.startswith("docs/") or path.startswith("papers/"):
        return "DLOC" if suffix in DLOC else None
    if suffix in PLOC:
        return "PLOC"
    if suffix in CLOC:
        return "CLOC"
    if suffix in DLOC:
        return "DLOC"
    return None


def include_path(path: str, *, include_all: bool = False) -> bool:
    if include_all:
        return True
    if any(marker in path for marker in CAMPAIGN_MARKERS):
        return False
    return path.startswith(ACTIVE_PREFIXES)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", default=DEFAULT_BASELINE)
    parser.add_argument("--all", action="store_true", help="Count every changed path instead of the country-adapter program subset.")
    args = parser.parse_args()

    result = subprocess.run(
        ["git", "diff", "--numstat", args.baseline, "--"],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        print(result.stderr)
        return result.returncode

    totals = {"PLOC": 0, "CLOC": 0, "TLOC": 0, "DLOC": 0}
    for line in result.stdout.splitlines():
        added, _deleted, path = line.split("\t", 2)
        if added == "-":
            continue
        if not include_path(path, include_all=args.all):
            continue
        loc_category = category(path)
        if loc_category is None:
            continue
        if "/test" in path or "/tests" in path or path.startswith("examples/") or "fixtures" in path:
            loc_category = "TLOC" if loc_category != "DLOC" else "DLOC"
        totals[loc_category] += int(added)

    untracked = subprocess.run(
        ["git", "ls-files", "--others", "--exclude-standard"],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    if untracked.returncode != 0:
        print(untracked.stderr)
        return untracked.returncode

    for path in untracked.stdout.splitlines():
        if not include_path(path, include_all=args.all):
            continue
        loc_category = category(path)
        if loc_category is None:
            continue
        if "/test" in path or "/tests" in path or path.startswith("examples/") or "fixtures" in path:
            loc_category = "TLOC" if loc_category != "DLOC" else "DLOC"
        try:
            added = sum(1 for _line in (REPO_ROOT / path).open("r", encoding="utf-8", errors="ignore"))
        except OSError:
            continue
        totals[loc_category] += added

    implementation = totals["PLOC"] + totals["CLOC"] + totals["TLOC"]
    for name in ("PLOC", "CLOC", "TLOC", "DLOC"):
        print(f"{name}: {totals[name]}")
    print(f"Implementation LOC: {implementation}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
