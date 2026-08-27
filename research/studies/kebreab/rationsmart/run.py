from __future__ import annotations

from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[4]

from agevidence.research.bundles import model_run, object_commitment, observation, operational_event, research_bundle, source_record, statement, transformation, write_bundle  # noqa: E402

OUTPUT_PATH = Path(__file__).resolve().parent / "output" / "rationsmart_feed_to_methane.agevidence.json"


def build_bundle() -> dict[str, Any]:
    source = source_record(
        record_id="uc-davis-rationsmart-feed-libraries",
        source_system="UC Davis CAES",
        observed_at="2025-10-16",
        controlled_uri="https://caes.ucdavis.edu/news/new-mobile-app-seeks-reduce-dairy-methane-emissions-africa-asia",
        commitment=object_commitment({"source": "UC Davis CAES", "project": "RationSmart", "date": "2025-10-16"}),
        metadata={"reported_feed_library_country_count": 20, "public_data_status": "project_architecture_public_feed_library_rows_not_included"},
    )
    sample = observation(
        subject="feed_resource:local_example",
        observable="nutrient_composition",
        value={"pathways": ["wet_lab", "NIRS"], "fields": ["DM", "CP", "NDF", "energy"]},
        unit="feed_database_record",
        observed_at="project_architecture:feed_sampling",
        source_ids=[source["id"]],
        method="national feed database sampling architecture",
        limitations=["Architecture-level example; no national feed-library row is asserted."],
    )
    ration = operational_event(
        machine="rationsmart:ration_formulation_tool",
        operation="formulate_local_dairy_ration",
        started_at="project_architecture:ration:start",
        completed_at="project_architecture:ration:end",
        source_ids=[source["id"]],
        metadata={"inputs": ["feed library", "farmer context", "animal context"], "outputs": ["recommended ration", "predicted production", "predicted methane intensity"]},
    )
    transform = transformation(
        name="feed_sample_to_methane_prediction",
        version="architecture-v0",
        implementation="feed sample -> feed library -> ration model -> animal context -> methane intensity estimate",
        parameters={"decision_context": "smallholder dairy ration formulation"},
    )
    run = model_run(
        model_id="research.examples.rationsmart.feed_to_methane",
        model_version="architecture-v0",
        input_commitments=[source["commitment"], sample["id"], ration["id"], transform["id"]],
        outputs=[
            {
                "observable": "feed_to_methane_lineage",
                "value": ["SampleRecord", "wet lab or NIRS", "national feed database", "ration formulation", "predicted production", "predicted methane intensity"],
                "unit": "architecture_steps",
            }
        ],
        limitations=["Not a deployed RationSmart model artifact and not a country-specific feed database export."],
    )
    statements = [
        statement(
            text="RationSmart-style feed infrastructure can be mapped as evidence from physical feed samples through model-based methane estimates.",
            statement_type="field_decision_architecture",
            source="research example",
            basis=[source["id"], sample["id"], ration["id"], transform["id"], run["id"]],
        )
    ]
    return research_bundle(
        study={
            "id": "rationsmart-feed-to-methane-architecture",
            "title": "RationSmart national feed database to methane accounting architecture",
            "public_data_status": "project_architecture_public_feed_library_rows_not_included",
        },
        sources=[source],
        observations=[sample],
        operational_events=[ration],
        transformations=[transform],
        model_runs=[run],
        statements=statements,
    )


def main() -> None:
    bundle = build_bundle()
    output = write_bundle(bundle, OUTPUT_PATH)
    print("AgEvidence RationSmart Feed-to-Methane Case Study")
    print(f"Observations:                 {len(bundle['observations'])}")
    print(f"Operational events:           {len(bundle['operational_events'])}")
    print(f"Model runs:                   {len(bundle['model_runs'])}")
    print(f"Evidence bundle: ./{output.relative_to(Path(__file__).resolve().parent)}")


if __name__ == "__main__":
    main()
