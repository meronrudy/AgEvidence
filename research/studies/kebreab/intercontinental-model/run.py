from __future__ import annotations

import sys
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[3]
SHARED = REPO_ROOT / "examples" / "researchers" / "_shared"
if str(SHARED) not in sys.path:
    sys.path.insert(0, str(SHARED))

from research_bundle import model_run, object_commitment, research_bundle, source_record, statement, transformation, write_bundle  # noqa: E402

OUTPUT_PATH = Path(__file__).resolve().parent / "output" / "intercontinental_prediction.agevidence.json"


def build_bundle() -> dict[str, Any]:
    source = source_record(
        record_id="doi:10.1111/gcb.14094",
        source_system="Global Change Biology",
        observed_at="2018-02-16",
        controlled_uri="https://doi.org/10.1111/gcb.14094",
        commitment=object_commitment({"doi": "10.1111/gcb.14094", "model": "intercontinental methane prediction"}),
        metadata={"public_data_status": "study_architecture_described_raw_consolidated_database_not_located"},
    )
    harmonization = transformation(
        name="intercontinental_methane_harmonization",
        version="published-study-architecture",
        implementation="harmonize regional individual-cow methane observations and diet/production covariates",
        parameters={"regions": ["Europe", "United States", "Australia"], "targets": ["CH4 production", "CH4 yield", "CH4 intensity"]},
    )
    run = model_run(
        model_id="niu-kebreab-2018-intercontinental-prediction",
        model_version="published-2018",
        input_commitments=[source["commitment"], harmonization["id"]],
        outputs=[
            {
                "observable": "prediction_model_lineage",
                "value": {
                    "response_variables": ["CH4 production", "CH4 yield", "CH4 intensity"],
                    "inputs": ["DMI", "dietary NDF", "milk yield", "milk composition", "available animal and diet covariates"],
                    "model_families": ["regional models", "global model"],
                    "validation": "cross-validation across intercontinental data",
                    "published_conclusion": "DMI is required for good prediction; NDF can improve prediction.",
                },
                "unit": "model_architecture",
            }
        ],
        limitations=["Architecture-level reconstruction only; row-level consolidated database is not included."],
    )
    statements = [
        statement(
            text="The Niu et al. study demonstrates multi-source evidence graph requirements for methane prediction model provenance.",
            statement_type="model_provenance_case_study",
            source="research example",
            basis=[source["id"], harmonization["id"], run["id"]],
        )
    ]
    return research_bundle(
        study={
            "id": "niu-kebreab-2018-intercontinental-methane-model",
            "title": "Prediction of enteric methane production, yield, and intensity in dairy cattle using an intercontinental database",
            "publication_doi": "10.1111/gcb.14094",
            "public_data_status": "study_architecture_described_raw_consolidated_database_not_located",
        },
        sources=[source],
        transformations=[harmonization],
        model_runs=[run],
        statements=statements,
    )


def main() -> None:
    bundle = build_bundle()
    output = write_bundle(bundle, OUTPUT_PATH)
    print("AgEvidence Intercontinental Prediction Case Study")
    print(f"Transformations:              {len(bundle['transformations'])}")
    print(f"Model runs:                   {len(bundle['model_runs'])}")
    print(f"Evidence bundle: ./{output.relative_to(Path(__file__).resolve().parent)}")


if __name__ == "__main__":
    main()

