#!/usr/bin/env python3
"""Run a lightweight cross-country adapter conformance check."""

from __future__ import annotations

import os
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SDK_SRC = REPO_ROOT / "sdks" / "python" / "src"
sys.path.insert(0, str(SDK_SRC))

from agevidence.adapters.registry import default_registry  # noqa: E402
from agevidence.sources.models import SourceRecordInput  # noqa: E402


def main() -> int:
    registry = default_registry(load_entry_points=False)
    evidence_root = "sha256:synthetic-root"
    source_records = [
        SourceRecordInput(
            source_system="synthetic",
            source_profile="animal_cohort",
            record={"document_id": "source-1", "commitment": "sha256:source-1"},
            commitment="sha256:source-1",
        ),
        SourceRecordInput(
            source_system="synthetic",
            source_profile="intervention_delivery",
            record={"document_id": "source-2", "commitment": "sha256:source-2"},
            commitment="sha256:source-2",
        ),
    ]
    adapters = [registry.resolve(value) for value in ["AU", "NZ", "CA", "UK", "EU"]]
    determinations = []
    for adapter in adapters:
        result = adapter.evaluate(
            project_id="project-synthetic",
            evidence_graph_root=evidence_root,
            source_records=source_records,
            country_context={"species": "species.beef_cattle"},
        )
        determinations.append(result)
        if result.evidence_graph_root != evidence_root:
            print(f"{adapter.metadata.id}: evidence root changed")
            return 1

    adapter_ids = {result.adapter_id for result in determinations}
    policy_stacks = {tuple(item.profile_id for item in result.policy_stack) for result in determinations}
    if len(adapter_ids) != len(determinations):
        print("adapter commitments are not distinct")
        return 1
    if len(policy_stacks) != len(determinations):
        print("policy stacks are not distinct")
        return 1

    print("AgEvidence cross-country conformance passed")
    return 0


if __name__ == "__main__":
    os.environ.setdefault("AGEVIDENCE_OFFLINE", "1")
    raise SystemExit(main())

