from __future__ import annotations

from collections import Counter
from pathlib import Path
from typing import Any

import pandas as pd

REPO_ROOT = Path(__file__).resolve().parents[4]

from agevidence.research.datasets import ensure_download, load_excel, normalize_columns
from agevidence.research.bundles import (
    clean_text,
    intervention_event,
    model_run,
    number,
    observation,
    operational_event,
    research_bundle,
    sha256_file,
    source_record,
    statement,
    write_bundle,
)

DATA_URL = "https://journals.plos.org/plosone/article/file?id=10.1371/journal.pone.0247820.s001&type=supplementary"
DATA_SHA256 = "sha256:f8c90ca7b106d95abc2df4c316ac520b482a47350ab2ea0f3647a1442181b409"
DATA_PATH = REPO_ROOT / "research" / ".data" / "kebreab" / "roque-2021" / "pone.0247820.s001.xlsx"
OUTPUT_PATH = Path(__file__).resolve().parent / "output" / "roque_2021.agevidence.json"
PUBLISHED_AT = "2021-03-17"
STUDY_ID = "roque-2021-asparagopsis-beef-steers"


def build_bundle(download: bool = True) -> dict[str, Any]:
    if download:
        ensure_download(url=DATA_URL, path=DATA_PATH, sha256=DATA_SHA256)
    sheets = {name: normalize_columns(frame) for name, frame in load_excel(DATA_PATH).items()}
    source = _source()
    source_ids = [source["id"]]

    observations = []
    observations.extend(_production_observations(sheets["ProductionData"], source_ids))
    observations.extend(_gas_observations(sheets["GasData"], source_ids))
    observations.extend(_carcass_observations(sheets["CarcassData"], source_ids))
    observations.extend(_taste_panel_observations(sheets["TastePanelData"], source_ids))

    interventions = _interventions(sheets["ProductionData"], source_ids)
    operations = _tmr_operations(sheets["ProductionData"], source_ids)
    run = _model_run(sheets, source)
    statements = _statements(source, run, observations, interventions, operations)

    return research_bundle(
        study={
            "id": STUDY_ID,
            "title": "Red seaweed (Asparagopsis taxiformis) supplementation reduces enteric methane by over 80 percent in beef steers",
            "authors": ["Breanna M. Roque", "Ermias Kebreab", "collaborators"],
            "publication_doi": "10.1371/journal.pone.0247820",
            "dataset_doi": "10.1371/journal.pone.0247820.s001",
            "public_data_status": "public_original_xlsx",
            "reconstruction_scope": "Workbook rows are reconstructed into example evidence objects; this is not a new statistical publication.",
        },
        sources=[source],
        observations=observations,
        intervention_events=interventions,
        operational_events=operations,
        model_runs=[run],
        statements=statements,
        metadata={
            "workbook_sheets": {name: {"rows": int(len(frame)), "columns": list(frame.columns)} for name, frame in sheets.items()},
            "animal_count": len(_animal_ids(sheets["ProductionData"])),
            "treatment_groups": sorted(_treatment_counts(sheets["ProductionData"]).keys()),
        },
    )


def _source() -> dict[str, Any]:
    return source_record(
        record_id="doi:10.1371/journal.pone.0247820.s001",
        source_system="PLOS ONE supporting information",
        observed_at=PUBLISHED_AT,
        controlled_uri=DATA_URL,
        commitment=sha256_file(DATA_PATH),
        metadata={
            "publication_doi": "10.1371/journal.pone.0247820",
            "dataset_title": "S1 Table. Original data.",
            "license": "CC BY",
            "local_path": str(DATA_PATH.relative_to(REPO_ROOT)),
        },
    )


def _production_observations(frame: pd.DataFrame, source_ids: list[str]) -> list[dict[str, Any]]:
    columns = {
        "Dry Matter Intake (kg)": ("dry_matter_intake", "kg_per_day"),
        "Initial Body Weight (kg)": ("initial_body_weight", "kg"),
        "Final Body Weight (kg)": ("final_body_weight", "kg"),
        "Total Gain (kg)": ("total_gain", "kg"),
        "Average Daily Gain (kg)": ("average_daily_gain", "kg_per_day"),
        "Feed Conversion Efficiency (ADG/DMI)": ("feed_conversion_efficiency", "kg_adg_per_kg_dmi"),
        "Cost Per Gain (ADG/Cost Per Day)": ("cost_per_gain", "usd_per_kg_gain"),
    }
    observations = []
    for _, row in frame.iterrows():
        animal_id = _animal_id(row)
        diet = clean_text(row["Diet"])
        treatment = _treatment(row["Treatment"])
        for column, (observable, unit) in columns.items():
            value = number(row.get(column))
            if value is None:
                continue
            observations.append(
                observation(
                    subject=f"animal:{animal_id}",
                    observable=observable,
                    value=value,
                    unit=unit,
                    observed_at=f"{STUDY_ID}:diet:{_slug(diet)}",
                    source_ids=source_ids,
                    method="published_workbook_row",
                    metadata={"sheet": "ProductionData", "diet": diet, "treatment": treatment, "original_column": column},
                )
            )
    return observations


def _gas_observations(frame: pd.DataFrame, source_ids: list[str]) -> list[dict[str, Any]]:
    columns = {
        "CO2 Production (g/day)": ("co2_production", "g_per_day"),
        "CO2 Yield            (g CO2/kg DMI)": ("co2_yield", "g_co2_per_kg_dmi"),
        "CH4 Production (g/day)": ("ch4_production", "g_per_day"),
        "CH4 Yield        (g CH4/g DMI)": ("ch4_yield", "g_ch4_per_kg_dmi"),
        "H2 Production (g/day)": ("h2_production", "g_per_day"),
        "H2 Yield           (g H2/kg DMI)": ("h2_yield", "g_h2_per_kg_dmi"),
    }
    observations = []
    for _, row in frame.iterrows():
        animal_id = _animal_id(row)
        diet = clean_text(row["Diet"])
        treatment = _treatment(row["Treatment"])
        week = int(number(row["Experimental Week"]) or 0)
        for column, (observable, unit) in columns.items():
            value = number(row.get(column))
            if value is None:
                continue
            observations.append(
                observation(
                    subject=f"animal:{animal_id}",
                    observable=observable,
                    value=value,
                    unit=unit,
                    observed_at=f"{STUDY_ID}:week:{week:02d}",
                    source_ids=source_ids,
                    method="published_workbook_row",
                    instrument={"type": "enteric_gas_measurement", "source": "published workbook"},
                    metadata={"sheet": "GasData", "diet": diet, "treatment": treatment, "experimental_week": week, "original_column": column},
                )
            )
    return observations


def _carcass_observations(frame: pd.DataFrame, source_ids: list[str]) -> list[dict[str, Any]]:
    columns = {
        "Moisture": ("strip_loin_moisture", "percent"),
        "Protein": ("strip_loin_protein", "percent"),
        "Fat": ("strip_loin_fat", "percent"),
        "Ash": ("strip_loin_ash", "percent"),
        "Carbohydrates": ("strip_loin_carbohydrates", "percent"),
        "Calories": ("strip_loin_calories", "kcal"),
        "Iodine (PPM)": ("iodine", "ppm"),
        "Slice Shear Force (kgf)": ("slice_shear_force", "kgf"),
        "Warner- Bratzler (kgf)": ("warner_bratzler_shear_force", "kgf"),
        "Hot Carcass Weight (kg)": ("hot_carcass_weight", "kg"),
        "Rib Eye Area (inches)": ("rib_eye_area", "square_inches"),
    }
    observations = []
    for _, row in frame.iterrows():
        animal_id = _animal_id(row)
        treatment = _treatment(row["Treatment"])
        for column, (observable, unit) in columns.items():
            value = number(row.get(column))
            if value is None:
                continue
            observations.append(
                observation(
                    subject=f"animal:{animal_id}",
                    observable=observable,
                    value=value,
                    unit=unit,
                    observed_at=f"{STUDY_ID}:carcass",
                    source_ids=source_ids,
                    method="published_workbook_row",
                    metadata={"sheet": "CarcassData", "treatment": treatment, "original_column": column},
                )
            )
    return observations


def _taste_panel_observations(frame: pd.DataFrame, source_ids: list[str]) -> list[dict[str, Any]]:
    observations = []
    sample_offsets = [0, 6, 12]
    response_columns = [("Tenderness", "tenderness_score"), ("Flavor", "flavor_score"), ("Juciness", "juiciness_score"), ("Overall", "overall_acceptability")]
    for _, row in frame.iterrows():
        participant = clean_text(row["Participant ID"])
        session = clean_text(row["Session"])
        values = list(row)
        for offset in sample_offsets:
            if offset + 7 >= len(values):
                continue
            sample_id = clean_text(values[offset + 2])
            treatment = _treatment(values[offset + 3])
            if not sample_id or sample_id.lower() == "nan":
                continue
            for response_index, (_, observable) in enumerate(response_columns, start=4):
                value = number(values[offset + response_index])
                if value is None:
                    continue
                observations.append(
                    observation(
                        subject=f"taste_panel_sample:{sample_id}",
                        observable=observable,
                        value=value,
                        unit="panel_score",
                        observed_at=f"{STUDY_ID}:taste-panel:session:{session}",
                        source_ids=source_ids,
                        method="consumer_taste_panel",
                        metadata={"sheet": "TastePanelData", "participant_id": participant, "session": session, "treatment": treatment},
                    )
                )
    return observations


def _interventions(frame: pd.DataFrame, source_ids: list[str]) -> list[dict[str, Any]]:
    events = []
    assignments = sorted({(_animal_id(row), _treatment(row["Treatment"]), clean_text(row["Treatment"])) for _, row in frame.iterrows()})
    for animal_id, treatment, raw_treatment in assignments:
        quantity = _dose(treatment)
        events.append(
            intervention_event(
                target=f"animal:{animal_id}",
                intervention="asparagopsis_taxiformis_inclusion",
                quantity=quantity,
                unit="percent_organic_matter",
                occurred_at=f"{STUDY_ID}:treatment-assignment",
                source_ids=source_ids,
                batch=None,
                metadata={"treatment": treatment, "raw_treatment": raw_treatment},
                limitations=["The workbook records treatment assignment but not exact calendar assignment timestamps."],
            )
        )
    return events


def _tmr_operations(frame: pd.DataFrame, source_ids: list[str]) -> list[dict[str, Any]]:
    events = []
    seen = set()
    for _, row in frame.iterrows():
        animal_id = _animal_id(row)
        diet = clean_text(row["Diet"])
        key = (animal_id, diet)
        if key in seen:
            continue
        seen.add(key)
        events.append(
            operational_event(
                machine="feedlot_tmr_regime",
                operation="diet_regime",
                started_at=f"{STUDY_ID}:diet:{_slug(diet)}:start",
                completed_at=f"{STUDY_ID}:diet:{_slug(diet)}:end",
                source_ids=source_ids,
                metadata={"animal_id": animal_id, "diet": diet, "diet_sequence": ["High Forage", "Medium Forage", "Low Forage"]},
                limitations=["The workbook identifies diet regime but not exact calendar boundaries."],
            )
        )
    return events


def _model_run(sheets: dict[str, pd.DataFrame], source: dict[str, Any]) -> dict[str, Any]:
    gas = sheets["GasData"].copy()
    gas["treatment_normalized"] = gas["Treatment"].map(_treatment)
    grouped = []
    for treatment, group in gas.groupby("treatment_normalized"):
        ch4 = pd.to_numeric(group["CH4 Production (g/day)"], errors="coerce")
        yield_values = pd.to_numeric(group["CH4 Yield        (g CH4/g DMI)"], errors="coerce")
        grouped.append(
            {
                "treatment": treatment,
                "n_gas_rows": int(ch4.count()),
                "mean_ch4_production_g_per_day": round(float(ch4.mean()), 6),
                "mean_ch4_yield_g_per_kg_dmi": round(float(yield_values.mean()), 6),
            }
        )
    production = sheets["ProductionData"].copy()
    production["treatment_normalized"] = production["Treatment"].map(_treatment)
    animal_counts = {treatment: int(group["Animal ID"].nunique()) for treatment, group in production.groupby("treatment_normalized")}
    return model_run(
        model_id="research.examples.roque_2021.treatment_summary",
        model_version="0.1.0",
        implementation_digest=sha256_file(Path(__file__)),
        input_commitments=[source["commitment"]],
        parameters={"group_by": ["treatment"], "response": ["CH4 Production (g/day)", "CH4 Yield        (g CH4/g DMI)"]},
        execution_environment={"runtime": "python", "library": "pandas"},
        outputs=[{"observable": "treatment_ch4_summary", "value": grouped, "unit": "published_workbook_units"}],
        metadata={"animal_counts": animal_counts},
        limitations=["This model run summarizes workbook rows; it does not reproduce the paper's full inferential model."],
    )


def _statements(
    source: dict[str, Any],
    run: dict[str, Any],
    observations: list[dict[str, Any]],
    interventions: list[dict[str, Any]],
    operations: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    ch4_basis = [obs["id"] for obs in observations if obs["observable"] == "ch4_production"][:12]
    return [
        statement(
            text="The public Roque et al. 2021 S1 workbook was reconstructed into animal, treatment, diet, gas, production, carcass, and sensory evidence records.",
            statement_type="reconstruction",
            source="research example",
            basis=[source["id"], run["id"], *[event["id"] for event in interventions[:3]], *[event["id"] for event in operations[:3]]],
        ),
        statement(
            text="The reconstructed gas table preserves treatment-level CH4 production and CH4 yield measurements from the published workbook.",
            statement_type="data_lineage",
            source="research example",
            basis=[source["id"], run["id"], *ch4_basis],
            limitations=["This statement describes reconstruction lineage and does not make an independent causal claim."],
        ),
    ]


def _treatment(raw: object) -> str:
    value = clean_text(raw).lower()
    if "control" in value:
        return "Control"
    if "low" in value or "0.25" in value:
        return "0.25% OM Asparagopsis taxiformis"
    if "high" in value or "0.50" in value or "0.5" in value:
        return "0.50% OM Asparagopsis taxiformis"
    return clean_text(raw)


def _dose(treatment: str) -> float:
    if treatment.startswith("0.25"):
        return 0.25
    if treatment.startswith("0.50"):
        return 0.5
    return 0.0


def _animal_id(row: Any) -> str:
    return str(int(number(row["Animal ID"]) or 0))


def _animal_ids(frame: pd.DataFrame) -> set[str]:
    return {_animal_id(row) for _, row in frame.iterrows()}


def _treatment_counts(frame: pd.DataFrame) -> Counter[str]:
    return Counter(_treatment(row["Treatment"]) for _, row in frame.iterrows())


def _slug(value: str) -> str:
    return "-".join(value.lower().replace("/", " ").split())


def main() -> None:
    bundle = build_bundle()
    output = write_bundle(bundle, OUTPUT_PATH)
    treatment_groups = bundle["metadata"]["treatment_groups"]

    print("AgEvidence Research Reconstruction")
    print("Study:")
    print("Roque et al. 2021")
    print("Red seaweed supplementation reduces enteric methane by over 80 percent in beef steers")
    print(f"Sources registered:           {len(bundle['sources'])}")
    print(f"Animals represented:         {bundle['metadata']['animal_count']}")
    print(f"Treatment groups:             {len(treatment_groups)}")
    print(f"Observations:               {len(bundle['observations'])}")
    print(f"Intervention events:          {len(bundle['intervention_events'])}")
    print(f"Operational events:          {len(bundle['operational_events'])}")
    print(f"Model runs:                   {len(bundle['model_runs'])}")
    print(f"Scientific statements:        {len(bundle['statements'])}")
    print("Evidence bundle:")
    print(f"./{output.relative_to(Path(__file__).resolve().parent)}")
    print("Verification:")
    for key, value in bundle["verification"].items():
        print(f"[{'ok' if value else 'fail'}] {key.replace('_', ' ')}")


if __name__ == "__main__":
    main()
