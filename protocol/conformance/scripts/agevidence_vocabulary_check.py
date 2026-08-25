#!/usr/bin/env python3
"""Validate stable AgEvidence vocabulary families."""

from __future__ import annotations

import argparse
from pathlib import Path
from typing import Any

import yaml


REPO_ROOT = Path(__file__).resolve().parents[1]
VOCAB_ROOT = REPO_ROOT / "specs" / "agevidence" / "vocabulary"
ADAPTER_ROOT = REPO_ROOT / "specs" / "agevidence" / "country_adapters"

EXPECTED_FILES = {
    "species": "species.yml",
    "production": "production_systems.yml",
    "intervention": "interventions.yml",
    "evidence": "evidence_types.yml",
    "authority": "authority_roles.yml",
    "institution": "institutions.yml",
    "decision": "decisions.yml",
}


def load_yaml(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        value = yaml.safe_load(handle) or {}
    if not isinstance(value, dict):
        raise ValueError(f"{path} must contain a YAML object")
    return value


def identifiers_for_family(path: Path, family: str) -> set[str]:
    data = load_yaml(path)
    ids: set[str] = set()
    for value in data.values():
        if isinstance(value, dict):
            ids.update(key for key in value if isinstance(key, str) and key.startswith(f"{family}."))
        elif isinstance(value, list):
            ids.update(item for item in value if isinstance(item, str) and item.startswith(f"{family}."))
    return ids


def collect_manifest_references() -> dict[str, set[str]]:
    refs = {family: set() for family in EXPECTED_FILES}
    for path in sorted(ADAPTER_ROOT.glob("*/adapter.yml")):
        manifest = load_yaml(path)
        contexts = manifest.get("applicability", {})
        for context in (contexts.get("required_context", {}), contexts.get("excluded_context", {})):
            for values in context.values():
                for value in values or []:
                    if isinstance(value, str) and "." in value:
                        refs.setdefault(value.split(".", 1)[0], set()).add(value)
        for value in manifest.get("required_evidence", []):
            if isinstance(value, str) and "." in value:
                refs.setdefault(value.split(".", 1)[0], set()).add(value)
    return refs


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=VOCAB_ROOT)
    args = parser.parse_args()

    errors: list[str] = []
    declared: dict[str, set[str]] = {}
    for family, filename in EXPECTED_FILES.items():
        path = args.root / filename
        if not path.exists():
            errors.append(f"missing vocabulary file: {path.relative_to(REPO_ROOT)}")
            declared[family] = set()
            continue
        ids = identifiers_for_family(path, family)
        declared[family] = ids
        if not ids:
            errors.append(f"{path.relative_to(REPO_ROOT)} declares no {family}.* identifiers")

    refs = collect_manifest_references()
    for family in ("species", "production", "intervention", "evidence"):
        missing = sorted(refs.get(family, set()) - declared.get(family, set()))
        for identifier in missing:
            errors.append(f"manifest references undeclared vocabulary identifier: {identifier}")

    if errors:
        for error in errors:
            print(error)
        return 1

    for family in EXPECTED_FILES:
        print(f"{family}: {len(declared[family])} identifiers")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

