from __future__ import annotations

import math
import sys
from collections import Counter
from pathlib import Path
from typing import Any

import pandas as pd

REPO_ROOT = Path(__file__).resolve().parents[3]
SHARED = REPO_ROOT / "examples" / "researchers" / "_shared"
if str(SHARED) not in sys.path:
    sys.path.insert(0, str(SHARED))

from data_sources import ensure_download, load_excel, normalize_columns  # noqa: E402
from research_bundle import (  # noqa: E402
    clean_text,
    derived_observation,
    model_run,
    number,
    object_commitment,
    observation,
    research_bundle,
    sha256_file,
    source_record,
    stable_id,
    statement,
    transformation,
    write_bundle,
)

DATA_URL = "https://zenodo.org/records/10832823/files/Enteric%20CH4%20yield%20and%20its%20variability%20in%20dairy%20cows.xlsx?download=1"
DATA_SHA256 = "sha256:b5a5064306bbaedb778a4177d4de31a4a6d0742440e0e013a92b36edf9017b2e"
DATA_MD5 = "md5:2c98c4b5042606fb80606793e7ddd4f0"
DATA_PATH = REPO_ROOT / "fixtures" / "researchers" / "methane_database_2024" / "Enteric CH4 yield and its variability in dairy cows.xlsx"
OUTPUT_PATH = Path(__file__).resolve().parent / "output" / "methane_database_2024.agevidence.json"
PUBLISHED_AT = "2024-03-21"
STUDY_ID = "ramirez-agudelo-kebreab-2024-methane-database"
EXCLUSION_SD_THRESHOLD = 4.8


def build_bundle(download: bool = True) -> dict[str, Any]:
    if download:
        ensure_download(url=DATA_URL, path=DATA_PATH, sha256=DATA_SHA256, md5=DATA_MD5)

    sheets = {name: normalize_columns(frame) for name, frame in load_excel(DATA_PATH).items()}
    frame = sheets["Sheet1"].dropna(subset=["DOI"]).reset_index(drop=True)
    source = _source()
    source_ids = [source["id"]]
    sem_to_sd = transformation(
        name="reported_sem_to_sd",
        version="0.1.0",
        implementation="SD = SEM * sqrt(n)",
        parameters={"n_column": "n", "sem_column": "SEM"},
        metadata={"source": "Ramirez-Agudelo and Kebreab 2024 workflow"},
    )

    observations, sem_inputs, reported_sds = _observations(frame, source_ids)
    derived, decisions = _derived_sds_and_decisions(frame, source_ids, sem_to_sd, sem_inputs, reported_sds)
    run = _sample_size_model_run(frame, source, derived, decisions)
    statements = _statements(source, sem_to_sd, derived, decisions, run)

    return research_bundle(
        study={
            "id": STUDY_ID,
            "title": "Systematic review for optimizing sample size in dairy cow methane emission studies in temperate regions",
            "authors": ["John Fredy Ramirez-Agudelo", "Ermias Kebreab"],
            "dataset_doi": "10.5281/zenodo.10832823",
            "dataset_concept_doi": "10.5281/zenodo.10356505",
            "publication_doi": "10.3168/jds.2023-24529",
            "public_data_status": "public_zenodo_xlsx_v2",
            "reported_study_count": 150,
            "reported_report_count": 177,
        },
        sources=[source],
        observations=observations,
        transformations=[sem_to_sd],
        derived_observations=derived,
        exclusion_decisions=decisions,
        model_runs=[run],
        statements=statements,
        metadata={
            "workbook_rows": int(len(frame)),
            "method_counts": dict(Counter(clean_text(value) or "unknown" for value in frame["Method"])),
            "design_type_counts": dict(Counter(clean_text(value) or "unknown" for value in frame["Design_type"])),
            "exclusion_rule": f"SD > {EXCLUSION_SD_THRESHOLD}",
        },
    )


def _source() -> dict[str, Any]:
    return source_record(
        record_id="doi:10.5281/zenodo.10832823",
        source_system="Zenodo",
        observed_at=PUBLISHED_AT,
        controlled_uri=DATA_URL,
        commitment=sha256_file(DATA_PATH),
        metadata={
            "concept_doi": "10.5281/zenodo.10356505",
            "file_md5": DATA_MD5,
            "file_name": DATA_PATH.name,
            "license": "cc-by-4.0",
            "local_path": str(DATA_PATH.relative_to(REPO_ROOT)),
        },
    )


def _observations(frame: pd.DataFrame, source_ids: list[str]) -> tuple[list[dict[str, Any]], dict[int, str], dict[int, str]]:
    observations = []
    sem_inputs: dict[int, str] = {}
    reported_sds: dict[int, str] = {}
    numeric_columns = {
        "OM": ("organic_matter", "percent_dm"),
        "CP": ("crude_protein", "percent_dm"),
        "EE": ("ether_extract", "percent_dm"),
        "NDF": ("neutral_detergent_fiber", "percent_dm"),
        "DMI": ("dry_matter_intake", "kg_per_day"),
        "CH4 prod": ("ch4_production", "g_per_day"),
        "CH4 yield": ("ch4_yield", "g_ch4_per_kg_dmi"),
        "Highest CH4 yield": ("highest_ch4_yield", "g_ch4_per_kg_dmi"),
        "SEM": ("reported_sem", "g_ch4_per_kg_dmi"),
        "SD": ("reported_sd", "g_ch4_per_kg_dmi"),
    }
    for index, row in frame.iterrows():
        subject = _subject(index)
        metadata = _row_metadata(row, index)
        for column, (observable, unit) in numeric_columns.items():
            value = number(row.get(column))
            if value is None:
                continue
            obs = observation(
                subject=subject,
                observable=observable,
                value=value,
                unit=unit,
                observed_at=PUBLISHED_AT,
                source_ids=source_ids,
                method="literature_extraction",
                metadata={**metadata, "original_column": column},
            )
            observations.append(obs)
            if observable == "reported_sem":
                sem_inputs[index] = obs["id"]
            if observable == "reported_sd":
                reported_sds[index] = obs["id"]
    return observations, sem_inputs, reported_sds


def _derived_sds_and_decisions(
    frame: pd.DataFrame,
    source_ids: list[str],
    sem_to_sd: dict[str, Any],
    sem_inputs: dict[int, str],
    reported_sds: dict[int, str],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    derived = []
    decisions = []
    for index, row in frame.iterrows():
        subject = _subject(index)
        sem = number(row.get("SEM"))
        n = number(row.get("n"))
        reported_sd = number(row.get("SD"))
        basis: list[str | dict[str, Any]]
        value: float | None = None
        basis_id: str | None = None
        source_kind = "missing_variability"
        if sem is not None and n is not None and n > 0:
            value = round(sem * math.sqrt(n), 6)
            basis = [sem_inputs[index]]
            derived_obs = derived_observation(
                subject=subject,
                observable="derived_sd_from_sem",
                value=value,
                unit="g_ch4_per_kg_dmi",
                observed_at=PUBLISHED_AT,
                inputs=basis,
                transformation_ref=sem_to_sd["id"],
                source_ids=source_ids,
                metadata={**_row_metadata(row, index), "reported_sd": reported_sd, "formula": "SD = SEM * sqrt(n)"},
            )
            derived.append(derived_obs)
            basis_id = derived_obs["id"]
            source_kind = "derived_from_sem"
        elif reported_sd is not None:
            value = reported_sd
            basis_id = reported_sds.get(index)
            source_kind = "reported_sd"

        excluded = bool(value is not None and value > EXCLUSION_SD_THRESHOLD)
        decision = {
            "record_type": "ExclusionDecision",
            "id": stable_id("exclusion", subject, value, EXCLUSION_SD_THRESHOLD),
            "subject": subject,
            "rule": f"SD > {EXCLUSION_SD_THRESHOLD}",
            "decision": "excluded" if excluded else "included",
            "basis": [basis_id] if basis_id else [],
            "metadata": {**_row_metadata(row, index), "sd_value_used": value, "source_kind": source_kind},
            "limitations": [] if value is not None else ["No SEM-derived or reported SD was available for this row."],
        }
        decision["commitment"] = object_commitment(decision)
        decisions.append(decision)
    return derived, decisions


def _sample_size_model_run(
    frame: pd.DataFrame,
    source: dict[str, Any],
    derived: list[dict[str, Any]],
    decisions: list[dict[str, Any]],
) -> dict[str, Any]:
    included_subjects = {decision["subject"] for decision in decisions if decision["decision"] == "included"}
    accepted_sds = [float(item["value"]) for item in derived if item["subject"] in included_subjects and number(item["value"]) is not None]
    pooled_sd = math.sqrt(sum(value * value for value in accepted_sds) / len(accepted_sds)) if accepted_sds else 0.0
    minimum_detectable_difference = 5.0
    z_alpha_two_sided = 1.96
    z_power_80 = 0.84
    n_per_group = math.ceil(2 * ((z_alpha_two_sided + z_power_80) * pooled_sd / minimum_detectable_difference) ** 2) if pooled_sd else 0

    outputs = [
        {
            "observable": "sample_size_estimate",
            "value": {
                "workbook_rows": int(len(frame)),
                "included_rows": len(included_subjects),
                "excluded_rows": sum(1 for decision in decisions if decision["decision"] == "excluded"),
                "pooled_sd_g_ch4_per_kg_dmi": round(pooled_sd, 6),
                "minimum_detectable_difference_g_ch4_per_kg_dmi": minimum_detectable_difference,
                "alpha": 0.05,
                "power": 0.8,
                "n_per_group": n_per_group,
            },
            "unit": "animals_per_group",
        }
    ]
    return model_run(
        model_id="research.examples.kebreab_methane_database.sample_size",
        model_version="0.1.0",
        implementation_digest=sha256_file(Path(__file__)),
        input_commitments=[source["commitment"], *[decision["commitment"] for decision in decisions]],
        parameters={
            "sd_rule": f"exclude if SD > {EXCLUSION_SD_THRESHOLD}",
            "minimum_detectable_difference_g_ch4_per_kg_dmi": minimum_detectable_difference,
            "alpha": 0.05,
            "power": 0.8,
        },
        execution_environment={"runtime": "python", "library": "math"},
        outputs=outputs,
        limitations=["This is a compact tutorial calculation, not a replacement for the full JDS analysis."],
    )


def _statements(
    source: dict[str, Any],
    sem_to_sd: dict[str, Any],
    derived: list[dict[str, Any]],
    decisions: list[dict[str, Any]],
    run: dict[str, Any],
) -> list[dict[str, Any]]:
    sample_basis = [item["id"] for item in derived[:8]] + [item["id"] for item in decisions[:8]]
    return [
        statement(
            text="The Zenodo v2 methane-yield workbook was registered with DOI, SHA-256, MD5, and license metadata before reconstruction.",
            statement_type="source_provenance",
            source="research example",
            basis=[source["id"]],
        ),
        statement(
            text="The reconstruction records SEM-to-SD transformations and SD-based exclusion decisions before the sample-size model run.",
            statement_type="analysis_lineage",
            source="research example",
            basis=[sem_to_sd["id"], run["id"], *sample_basis],
            limitations=["The branch demonstrates lineage structure and does not assert that the tutorial formula is the paper's full workflow."],
        ),
    ]


def _row_metadata(row: pd.Series, index: int) -> dict[str, Any]:
    return {
        "row_number": int(index + 2),
        "literature_doi": clean_text(row.get("DOI")),
        "title": clean_text(row.get("Title")),
        "authors": clean_text(row.get("Authors")),
        "country": clean_text(row.get("Country")),
        "breed": clean_text(row.get("Breed")),
        "lactating": clean_text(row.get("Lactating")),
        "method": clean_text(row.get("Method")),
        "design": clean_text(row.get("Design")),
        "design_type": clean_text(row.get("Design_type")),
        "treatments": number(row.get("Treatments")),
        "periods": number(row.get("Periods")),
        "animals": number(row.get("Animals")),
        "n": number(row.get("n")),
        "sem_type": clean_text(row.get("SEM_type")),
    }


def _subject(index: int) -> str:
    return f"literature_report:{index + 1:03d}"


def main() -> None:
    bundle = build_bundle()
    output = write_bundle(bundle, OUTPUT_PATH)
    sample_size = bundle["model_runs"][0]["outputs"][0]["value"]

    print("AgEvidence Literature Evidence Reconstruction")
    print("Study:")
    print("Ramirez-Agudelo and Kebreab 2024")
    print("Systematic review for optimizing sample size in dairy cow methane emission studies")
    print(f"Sources registered:           {len(bundle['sources'])}")
    print(f"Workbook rows represented:   {bundle['metadata']['workbook_rows']}")
    print(f"Reported studies:            {bundle['study']['reported_study_count']}")
    print(f"Reported reports:            {bundle['study']['reported_report_count']}")
    print(f"Observations:               {len(bundle['observations'])}")
    print(f"Derived observations:       {len(bundle['derived_observations'])}")
    print(f"Exclusion decisions:        {len(bundle['exclusion_decisions'])}")
    print(f"Excluded rows:              {sample_size['excluded_rows']}")
    print(f"Model runs:                   {len(bundle['model_runs'])}")
    print(f"Scientific statements:        {len(bundle['statements'])}")
    print("Evidence bundle:")
    print(f"./{output.relative_to(Path(__file__).resolve().parent)}")
    print("Verification:")
    for key, value in bundle["verification"].items():
        print(f"[{'ok' if value else 'fail'}] {key.replace('_', ' ')}")


if __name__ == "__main__":
    main()
