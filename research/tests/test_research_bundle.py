from __future__ import annotations

from utils import bundle_ids, load_example


def test_case_study_bundles_have_resolvable_statement_basis():
    examples = [
        "research/studies/kebreab/roque-2021/run.py",
        "research/studies/kebreab/methane-database-2024/run.py",
        "research/studies/kebreab/greenfeed/run.py",
        "research/studies/kebreab/grape-pomace-2025/run.py",
        "research/studies/kebreab/intercontinental-model/run.py",
        "research/studies/kebreab/rationsmart/run.py",
    ]

    for relative in examples:
        bundle = load_example(relative).build_bundle()
        ids = bundle_ids(bundle)
        assert bundle["bundle_type"] == "agevidence.research_bundle.v0"
        assert bundle["statements"]
        assert all(set(statement["basis"]).issubset(ids) for statement in bundle["statements"])
        assert bundle["verification"]["statement_reconstruction"] is True


def test_case_studies_mark_non_public_row_level_boundaries():
    grape = load_example("research/studies/kebreab/grape-pomace-2025/run.py").build_bundle()
    intercontinental = load_example("research/studies/kebreab/intercontinental-model/run.py").build_bundle()
    rationsmart = load_example("research/studies/kebreab/rationsmart/run.py").build_bundle()

    assert grape["study"]["public_data_status"] == "published_methods_and_tables_no_public_row_level_data"
    assert intercontinental["study"]["public_data_status"] == "study_architecture_described_raw_consolidated_database_not_located"
    assert rationsmart["study"]["public_data_status"] == "project_architecture_public_feed_library_rows_not_included"
