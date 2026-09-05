#!/usr/bin/env python3
"""Validate protocol canonicalization vector checksums."""

from __future__ import annotations

import hashlib
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
VECTOR_ROOT = REPO_ROOT / "protocol" / "conformance" / "canonicalization" / "vectors"


def metadata_has_expected_error(path: Path) -> bool:
    metadata = path.read_text(encoding="utf-8")
    return any(line.strip().startswith("expected_error:") for line in metadata.splitlines())


def main() -> int:
    failures: list[str] = []
    for vector in sorted(path for path in VECTOR_ROOT.iterdir() if path.is_dir()):
        metadata = vector / "metadata.yaml"
        expected = vector / "expected.json"
        digest = vector / "expected.sha256"
        if metadata.exists() and metadata_has_expected_error(metadata):
            if expected.exists() or digest.exists():
                failures.append(f"{vector.name}: error vector must not include expected output")
            continue
        if not expected.exists():
            failures.append(f"{vector.name}: missing expected.json")
            continue
        if not digest.exists():
            failures.append(f"{vector.name}: missing expected.sha256")
            continue
        expected_bytes = expected.read_bytes().removesuffix(b"\n")
        computed = hashlib.sha256(expected_bytes).hexdigest()
        recorded = digest.read_text(encoding="utf-8").strip()
        if computed != recorded:
            failures.append(f"{vector.name}: checksum mismatch {computed} != {recorded}")
    if failures:
        print("\n".join(failures))
        return 1
    print("AgEvidence canonicalization vectors passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
