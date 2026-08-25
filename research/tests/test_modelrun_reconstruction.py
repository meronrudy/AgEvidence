from __future__ import annotations

from utils import load_example


def test_methane_database_sem_to_sd_and_exclusions():
    module = load_example("examples/researchers/02_methane_database_2024/run.py")
    bundle = module.build_bundle()

    assert bundle["bundle_type"] == "agevidence.research_bundle.v0"
    assert bundle["study"]["dataset_doi"] == "10.5281/zenodo.10832823"
    assert bundle["study"]["reported_study_count"] == 150
    assert bundle["study"]["reported_report_count"] == 177
    assert bundle["metadata"]["workbook_rows"] >= 177
    assert bundle["transformations"][0]["implementation"] == "SD = SEM * sqrt(n)"
    assert len(bundle["derived_observations"]) > 0
    assert len(bundle["exclusion_decisions"]) == bundle["metadata"]["workbook_rows"]
    assert any(decision["decision"] == "excluded" for decision in bundle["exclusion_decisions"])
    assert any(decision["decision"] == "included" for decision in bundle["exclusion_decisions"])

    output = bundle["model_runs"][0]["outputs"][0]["value"]
    assert output["included_rows"] > 0
    assert output["excluded_rows"] > 0
    assert output["n_per_group"] >= 1
    assert bundle["model_runs"][0]["verification"]["normalized_output_digest"].startswith("sha256:")
    assert all(bundle["verification"].values())

