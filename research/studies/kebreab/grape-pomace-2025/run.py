from __future__ import annotations

import sys
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[3]
SHARED = REPO_ROOT / "examples" / "researchers" / "_shared"
if str(SHARED) not in sys.path:
    sys.path.insert(0, str(SHARED))

from research_bundle import (  # noqa: E402
    calibration_record,
    intervention_event,
    model_run,
    object_commitment,
    observation,
    operational_event,
    research_bundle,
    source_record,
    statement,
    write_bundle,
)

OUTPUT_PATH = Path(__file__).resolve().parent / "output" / "grape_pomace_latin_square.agevidence.json"


def build_bundle() -> dict[str, Any]:
    source = source_record(
        record_id="doi:10.3168/jds.2024-25419",
        source_system="Journal of Dairy Science",
        observed_at="2025-03-01",
        controlled_uri="https://doi.org/10.3168/jds.2024-25419",
        commitment=object_commitment({"doi": "10.3168/jds.2024-25419", "title": "Grape pomace supplementation"}),
        metadata={"public_data_status": "published_methods_and_tables_no_public_row_level_data"},
    )
    source_ids = [source["id"]]
    treatments = [
        ("control", 0),
        ("10_percent_grape_pomace", 10),
        ("15_percent_grape_pomace", 15),
    ]
    interventions = [
        intervention_event(
            target="cow_group:latin_square_period",
            intervention="fresh_grape_pomace_inclusion",
            quantity=dose,
            unit="percent_dm",
            occurred_at="published_design:period_assignment",
            source_ids=source_ids,
            metadata={"treatment": treatment, "design": "3 x 3 Latin square", "periods": 3, "period_length_weeks": 4},
            limitations=["Published design mapping only; no cow-period assignment table is public."],
        )
        for treatment, dose in treatments
    ]
    calibration = calibration_record(
        instrument="greenfeed:large-animal-system",
        calibrated_at="published_protocol:daily_and_periodic",
        source_ids=source_ids,
        procedure="standard calibration daily and CO2 recovery calibration before each period",
        standard="CH4/CO2 calibration gas and zero-air N2 standard",
        metadata={"reported_co2_recovery": "approximately 97% +/- 2%"},
    )
    milk = observation(
        subject="cow_group:latin_square",
        observable="milk_yield_and_components",
        value={"milk_yield": "morning_and_evening", "components": ["fat", "protein", "lactose", "SNF", "MUN", "SCC", "fatty_acid_profile"]},
        unit="published_measurement_schedule",
        observed_at="published_design:three_periods",
        source_ids=source_ids,
        method="published JDS methods",
    )
    gas = observation(
        subject="cow_group:latin_square",
        observable="greenfeed_gases",
        value=["CH4", "CO2", "H2"],
        unit="published_measurement_streams",
        observed_at="published_design:three_periods",
        source_ids=source_ids,
        instrument={"id": "greenfeed:large-animal-system", "calibration_record": calibration["id"]},
        method="GreenFeed",
    )
    feeding = operational_event(
        machine="feeding_protocol",
        operation="twice_daily_ration_delivery",
        started_at="published_design:period:start",
        completed_at="published_design:period:end",
        source_ids=source_ids,
        metadata={"base_ration": ["alfalfa hay", "wheat hay", "almond hulls", "cottonseed", "grain mix"]},
    )
    run = model_run(
        model_id="research.examples.grape_pomace.proc_glimmix_lineage",
        model_version="0.1.0",
        input_commitments=[source["commitment"], calibration["id"], feeding["id"], *[event["id"] for event in interventions]],
        outputs=[
            {
                "observable": "statistical_lineage",
                "value": {
                    "software": "SAS 9.4",
                    "procedure": "PROC GLIMMIX",
                    "design": "3 x 3 Latin square",
                    "fixed_effects": ["treatment", "period"],
                    "random_effects": ["cow"],
                    "preprocessing": ["cow x treatment aggregation", "log transform selected CH4 ratio variables"],
                    "outputs": ["least-square means", "SE", "P-values"],
                },
                "unit": "model_specification",
            }
        ],
        limitations=["Preserves reported statistical lineage, not private SAS output tables."],
    )
    statements = [
        statement(
            text="The grape-pomace study is represented as a schema and provenance case study because public row-level cow data were not located.",
            statement_type="public_data_boundary",
            source="research example",
            basis=[source["id"], run["id"], calibration["id"], gas["id"], milk["id"]],
        )
    ]
    return research_bundle(
        study={
            "id": "akter-kebreab-2025-grape-pomace",
            "title": "Grape pomace supplementation reduced methane emissions and improved milk quality in lactating dairy cows",
            "publication_doi": "10.3168/jds.2024-25419",
            "public_data_status": "published_methods_and_tables_no_public_row_level_data",
        },
        sources=[source],
        observations=[milk, gas],
        intervention_events=interventions,
        operational_events=[feeding],
        calibration_records=[calibration],
        model_runs=[run],
        statements=statements,
    )


def main() -> None:
    bundle = build_bundle()
    output = write_bundle(bundle, OUTPUT_PATH)
    print("AgEvidence Grape Pomace Latin-Square Case Study")
    print(f"Intervention events:          {len(bundle['intervention_events'])}")
    print(f"Calibration records:          {len(bundle['calibration_records'])}")
    print(f"Model runs:                   {len(bundle['model_runs'])}")
    print(f"Evidence bundle: ./{output.relative_to(Path(__file__).resolve().parent)}")


if __name__ == "__main__":
    main()

