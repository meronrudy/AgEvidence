from __future__ import annotations

from pathlib import Path

import pytest

from agevidence.research.bundles import sha256_file, verify_checksum
from utils import load_example


def test_checksum_enforcement_rejects_mismatch(tmp_path):
    path = tmp_path / "source.xlsx"
    path.write_bytes(b"not the workbook")

    with pytest.raises(ValueError, match="SHA-256 mismatch"):
        verify_checksum(path, sha256="sha256:" + "0" * 64)

    verify_checksum(path, sha256=sha256_file(path))


def test_roque_reconstruction_counts_and_lineage():
    module = load_example("research/studies/kebreab/roque-2021/run.py")
    bundle = module.build_bundle()

    assert bundle["bundle_type"] == "agevidence.research_bundle.v0"
    assert bundle["metadata"]["animal_count"] == 20
    assert bundle["metadata"]["treatment_groups"] == [
        "0.25% OM Asparagopsis taxiformis",
        "0.50% OM Asparagopsis taxiformis",
        "Control",
    ]
    assert len(bundle["sources"]) == 1
    assert len(bundle["intervention_events"]) == 20
    assert len(bundle["model_runs"]) == 1
    assert len([obs for obs in bundle["observations"] if obs["observable"] == "ch4_production"]) > 0
    assert all(bundle["verification"].values())

    source_ids = {source["id"] for source in bundle["sources"]}
    assert all(set(obs["source_records"]).issubset(source_ids) for obs in bundle["observations"])

    data_path = Path(module.DATA_PATH)
    assert data_path.exists()
    assert sha256_file(data_path) == module.DATA_SHA256
