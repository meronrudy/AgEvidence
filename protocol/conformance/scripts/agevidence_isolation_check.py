#!/usr/bin/env python3
"""Static isolation checks for the global country adapter architecture."""

from __future__ import annotations

import re
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
GENERIC_RUST_CRATES = {
    "baink-core",
    "baink-schema",
    "baink-canonical",
    "baink-crypto",
    "baink-bundle",
    "baink-verify",
}
METHOD_PATTERNS = [
    "AU-GOV-IND-LIVESTOCK-PILOT",
    "CA-FED-REME-BC",
    "J-Credit",
    "canada_federal",
    "brazil_car",
    "eu_crcf",
]
COUNTRY_BRANCH_RE = re.compile(r"\b(if|match)\b[^\n]*(country_code|jurisdiction|country)[^\n]*(AU|CA|NZ|GB|UK|EU|BR|JP)\b", re.I)
MODEL_IMPORT_RE = re.compile(r"\bfrom\s+agevidence\.(plugins|countries|adapters)\b|\bimport\s+agevidence\.(plugins|countries|adapters)\b")
DETERMINATION_MUTATION_RE = re.compile(r"(CountryDetermination|country_determinations)\S*\.(update|update!|destroy|destroy!)")


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore")


def scan_generic_rust() -> list[str]:
    errors: list[str] = []
    for crate in GENERIC_RUST_CRATES:
        for path in (REPO_ROOT / "crates" / crate / "src").glob("**/*.rs"):
            source = read(path)
            if COUNTRY_BRANCH_RE.search(source):
                errors.append(f"country-code branch in generic Rust crate: {path.relative_to(REPO_ROOT)}")
            if "country_adapter" in source or "country_determination" in source:
                errors.append(f"country adapter dependency in generic Rust crate: {path.relative_to(REPO_ROOT)}")
    return errors


def scan_receipt_envelope() -> list[str]:
    path = REPO_ROOT / "specs" / "agevidence" / "schemas" / "ink.receipt_envelope.v2.json"
    source = read(path)
    forbidden = ["country_code", "adapter_id", "method_id", "jurisdiction", "institution_profile"]
    return [f"global receipt envelope contains country-specific property: {value}" for value in forbidden if value in source]


def scan_rails_controllers() -> list[str]:
    errors: list[str] = []
    for path in (REPO_ROOT / "athian_ink_rails_bootstrap" / "app" / "controllers").glob("**/*.rb"):
        source = read(path)
        for pattern in METHOD_PATTERNS:
            if pattern.lower() in source.lower():
                errors.append(f"method-specific country logic in Rails controller: {path.relative_to(REPO_ROOT)} matches {pattern}")
    return errors


def scan_model_service() -> list[str]:
    errors: list[str] = []
    for path in (REPO_ROOT / "services" / "agevidence-model" / "src").glob("**/*.py"):
        if MODEL_IMPORT_RE.search(read(path)):
            errors.append(f"model service imports country plugin layer: {path.relative_to(REPO_ROOT)}")
    return errors


def scan_determination_mutation() -> list[str]:
    errors: list[str] = []
    app_root = REPO_ROOT / "athian_ink_rails_bootstrap" / "app"
    for path in app_root.glob("**/*.rb"):
        if path.name == "country_determination.rb":
            continue
        source = read(path)
        if DETERMINATION_MUTATION_RE.search(source):
            errors.append(f"country determination mutation outside appender/model: {path.relative_to(REPO_ROOT)}")
    return errors


def main() -> int:
    errors = [
        *scan_generic_rust(),
        *scan_receipt_envelope(),
        *scan_rails_controllers(),
        *scan_model_service(),
        *scan_determination_mutation(),
    ]
    if errors:
        for error in errors:
            print(error)
        return 1
    print("AgEvidence isolation checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

