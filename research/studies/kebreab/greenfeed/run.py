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
    model_run,
    object_commitment,
    observation,
    operational_event,
    research_bundle,
    source_record,
    stable_id,
    statement,
    write_bundle,
)

OUTPUT_PATH = Path(__file__).resolve().parent / "output" / "greenfeed_provenance.agevidence.json"


def build_bundle() -> dict[str, Any]:
    source = source_record(
        record_id="doi:10.3168/jds.2024-25419:methods",
        source_system="Journal of Dairy Science",
        observed_at="2025-03-01",
        controlled_uri="https://doi.org/10.3168/jds.2024-25419",
        commitment=object_commitment({"doi": "10.3168/jds.2024-25419", "section": "methods"}),
        metadata={"public_data_status": "published_methods_no_public_row_level_data"},
    )
    source_ids = [source["id"]]
    calibration = calibration_record(
        instrument="greenfeed:large-animal-system",
        calibrated_at="published_protocol:daily",
        source_ids=source_ids,
        procedure="daily standard calibration plus period CO2 recovery calibration",
        standard="CH4/CO2 calibration gas and zero-air N2 standard",
        metadata={"co2_recovery": "approximately 97% +/- 2%", "source": "published methods"},
        limitations=["Protocol-level reconstruction only; no instrument log rows are public in this case study."],
    )
    visit = operational_event(
        machine="greenfeed:large-animal-system",
        operation="valid_visit",
        started_at="published_protocol:visit:start",
        completed_at="published_protocol:visit:end",
        source_ids=source_ids,
        metadata={"rfid": "cow RFID", "valid_visit_minutes": "approximately 2 to 3", "mean_visits_per_day": "2.41 +/- 0.83"},
        limitations=["Represents method requirements, not a measured animal visit row."],
    )
    spot = observation(
        subject="cow_period:example",
        observable="ch4_spot_sample",
        value="published_protocol_placeholder",
        unit="g_per_day",
        observed_at="published_protocol:greenfeed_spot",
        source_ids=source_ids,
        instrument={"id": "greenfeed:large-animal-system", "calibration_record": calibration["id"], "visit_record": visit["id"]},
        method="GreenFeed spot sampling",
        metadata={"minimum_spot_samples_per_cow_treatment": ">20"},
        limitations=["No row-level spot-sample value is asserted."],
    )
    run = model_run(
        model_id="research.examples.greenfeed.visit_to_treatment_mean",
        model_version="0.1.0",
        input_commitments=[source["commitment"], calibration["id"], visit["id"], spot["id"]],
        outputs=[
            {
                "observable": "greenfeed_provenance_chain",
                "value": ["instrument", "calibration", "rfid_visit", "gas_spot", "cow_period_aggregation", "treatment_mean"],
                "unit": "provenance_steps",
            }
        ],
        metadata={"case_study_id": stable_id("case", "greenfeed", "provenance")},
        limitations=["Schema mapping only; does not reconstruct private GreenFeed exports."],
    )
    statements = [
        statement(
            text="Published GreenFeed methods can be represented with SourceRecord, CalibrationRecord, OperationalEvent, Observation, and ModelRun records.",
            statement_type="schema_mapping",
            source="research example",
            basis=[source["id"], calibration["id"], visit["id"], spot["id"], run["id"]],
        )
    ]
    return research_bundle(
        study={
            "id": "greenfeed-provenance-protocol",
            "title": "GreenFeed instrument provenance mapping from published livestock methane methods",
            "public_data_status": "published_methods_no_public_row_level_data",
        },
        sources=[source],
        observations=[spot],
        operational_events=[visit],
        calibration_records=[calibration],
        model_runs=[run],
        statements=statements,
    )


def main() -> None:
    bundle = build_bundle()
    output = write_bundle(bundle, OUTPUT_PATH)
    print("AgEvidence GreenFeed Provenance Case Study")
    print(f"Sources registered:           {len(bundle['sources'])}")
    print(f"Calibration records:          {len(bundle['calibration_records'])}")
    print(f"Operational events:           {len(bundle['operational_events'])}")
    print(f"Observations:                 {len(bundle['observations'])}")
    print(f"Evidence bundle: ./{output.relative_to(Path(__file__).resolve().parent)}")


if __name__ == "__main__":
    main()

