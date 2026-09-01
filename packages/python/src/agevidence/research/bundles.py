"""Evidence object builders for research examples."""

from __future__ import annotations

import hashlib
import json
import math
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

from agevidence.events import canonical_json, canonical_value


def now_utc() -> str:
    return datetime.now(UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return f"sha256:{digest.hexdigest()}"


def md5_file(path: Path) -> str:
    digest = hashlib.md5()  # noqa: S324 - provenance check, not security.
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return f"md5:{digest.hexdigest()}"


def verify_checksum(path: Path, *, sha256: str, md5: str | None = None) -> None:
    actual_sha256 = sha256_file(path)
    if actual_sha256 != sha256:
        raise ValueError(f"SHA-256 mismatch for {path}: expected {sha256}, got {actual_sha256}")
    if md5 is not None:
        actual_md5 = md5_file(path)
        if actual_md5 != md5:
            raise ValueError(f"MD5 mismatch for {path}: expected {md5}, got {actual_md5}")


def object_commitment(value: dict[str, Any]) -> str:
    digest = hashlib.sha256(canonical_json(value).encode("utf-8")).hexdigest()
    return f"sha256:{digest}"


def stable_id(prefix: str, *parts: object) -> str:
    material = "|".join(str(part) for part in parts)
    digest = hashlib.sha256(material.encode("utf-8")).hexdigest()[:16]
    return f"{prefix}:{digest}"


def clean_text(value: object) -> str:
    return str(value).strip()


def number(value: object) -> float | None:
    if value is None:
        return None
    if isinstance(value, str) and not value.strip():
        return None
    try:
        result = float(value)
    except (TypeError, ValueError):
        return None
    if math.isnan(result):
        return None
    return result


def integer(value: object) -> int | None:
    result = number(value)
    if result is None:
        return None
    return int(result)


def source_record(
    *,
    record_id: str,
    source_system: str,
    observed_at: str,
    controlled_uri: str,
    commitment: str,
    metadata: dict[str, Any] | None = None,
    limitations: list[str] | None = None,
) -> dict[str, Any]:
    return {
        "schema_id": "athian.agevidence.source_record.v1",
        "primitive_type": "SourceRecord",
        "id": stable_id("source", source_system, record_id),
        "source_system": source_system,
        "record_id": record_id,
        "observed_at": observed_at,
        "controlled_uri": controlled_uri,
        "commitment": commitment,
        "metadata": metadata or {},
        "limitations": limitations or [],
    }


def observation(
    *,
    subject: str,
    observable: str,
    value: Any,
    unit: str,
    observed_at: str,
    source_ids: list[str],
    method: str | None = None,
    instrument: dict[str, Any] | None = None,
    metadata: dict[str, Any] | None = None,
    limitations: list[str] | None = None,
) -> dict[str, Any]:
    obj = {
        "schema_id": "athian.agevidence.observation.v1",
        "primitive_type": "Observation",
        "subject": subject,
        "observable": observable,
        "value": value,
        "unit": unit,
        "observed_at": observed_at,
        "source_records": source_ids,
        "metadata": metadata or {},
        "limitations": limitations or [],
    }
    if method:
        obj["method"] = method
    if instrument:
        obj["instrument"] = instrument
    obj["id"] = stable_id("obs", subject, observable, observed_at, value, unit, source_ids)
    return obj


def intervention_event(
    *,
    target: str,
    intervention: str,
    quantity: Any,
    unit: str,
    occurred_at: str,
    source_ids: list[str],
    batch: str | None = None,
    metadata: dict[str, Any] | None = None,
    limitations: list[str] | None = None,
) -> dict[str, Any]:
    obj = {
        "schema_id": "athian.agevidence.intervention_event.v1",
        "primitive_type": "InterventionEvent",
        "target": target,
        "intervention": intervention,
        "quantity": quantity,
        "unit": unit,
        "occurred_at": occurred_at,
        "source_records": source_ids,
        "metadata": metadata or {},
        "limitations": limitations or [],
    }
    if batch:
        obj["batch"] = batch
    obj["id"] = stable_id("intervention", target, intervention, quantity, unit, occurred_at, source_ids)
    return obj


def operational_event(
    *,
    machine: str,
    operation: str,
    started_at: str,
    completed_at: str,
    source_ids: list[str],
    location: dict[str, Any] | None = None,
    metadata: dict[str, Any] | None = None,
    limitations: list[str] | None = None,
) -> dict[str, Any]:
    obj = {
        "schema_id": "athian.agevidence.operational_event.v1",
        "primitive_type": "OperationalEvent",
        "machine": machine,
        "operation": operation,
        "started_at": started_at,
        "completed_at": completed_at,
        "source_records": source_ids,
        "metadata": metadata or {},
        "limitations": limitations or [],
    }
    if location:
        obj["location"] = location
    obj["id"] = stable_id("operation", machine, operation, started_at, completed_at, source_ids)
    return obj


def transformation(
    *,
    name: str,
    version: str,
    implementation: str | None = None,
    parameters: dict[str, Any] | None = None,
    metadata: dict[str, Any] | None = None,
    limitations: list[str] | None = None,
) -> dict[str, Any]:
    obj = {
        "schema_id": "athian.agevidence.transformation.v1",
        "primitive_type": "Transformation",
        "name": name,
        "version": version,
        "implementation": implementation,
        "parameters": parameters or {},
        "metadata": metadata or {},
        "limitations": limitations or [],
    }
    obj["id"] = stable_id("transformation", name, version, implementation, parameters)
    return obj


def derived_observation(
    *,
    subject: str,
    observable: str,
    value: Any,
    unit: str,
    observed_at: str,
    inputs: list[str | dict[str, Any]],
    transformation_ref: str | dict[str, Any],
    source_ids: list[str],
    derived_at: str | None = None,
    metadata: dict[str, Any] | None = None,
    limitations: list[str] | None = None,
) -> dict[str, Any]:
    obj = {
        "schema_id": "athian.agevidence.derived_observation.v1",
        "primitive_type": "DerivedObservation",
        "subject": subject,
        "observable": observable,
        "value": value,
        "unit": unit,
        "observed_at": observed_at,
        "inputs": inputs,
        "transformation": transformation_ref,
        "derived_at": derived_at or now_utc(),
        "source_records": source_ids,
        "metadata": metadata or {},
        "limitations": limitations or [],
    }
    obj["id"] = stable_id("derived", subject, observable, observed_at, value, unit, inputs, transformation_ref)
    return obj


def calibration_record(
    *,
    instrument: str,
    calibrated_at: str,
    source_ids: list[str],
    valid_until: str | None = None,
    procedure: str | None = None,
    standard: str | None = None,
    certificate_hash: str | None = None,
    metadata: dict[str, Any] | None = None,
    limitations: list[str] | None = None,
) -> dict[str, Any]:
    obj = {
        "schema_id": "athian.agevidence.calibration_record.v1",
        "primitive_type": "CalibrationRecord",
        "instrument": instrument,
        "calibrated_at": calibrated_at,
        "valid_until": valid_until,
        "procedure": procedure,
        "standard": standard,
        "certificate_hash": certificate_hash,
        "source_records": source_ids,
        "metadata": metadata or {},
        "limitations": limitations or [],
    }
    obj["id"] = stable_id("calibration", instrument, calibrated_at, procedure, standard, source_ids)
    return {key: value for key, value in obj.items() if value is not None}


def model_run(
    *,
    model_id: str,
    model_version: str,
    input_commitments: list[str],
    outputs: list[dict[str, Any]],
    parameters: dict[str, Any] | None = None,
    execution_environment: dict[str, Any] | None = None,
    implementation_digest: str | None = None,
    started_at: str | None = None,
    completed_at: str | None = None,
    metadata: dict[str, Any] | None = None,
    limitations: list[str] | None = None,
) -> dict[str, Any]:
    obj = {
        "schema_id": "athian.agevidence.model_run.v1",
        "primitive_type": "ModelRun",
        "model_id": model_id,
        "model_version": model_version,
        "implementation_digest": implementation_digest,
        "input_commitments": input_commitments,
        "parameters": parameters or {},
        "execution_environment": execution_environment or {"runtime": "python"},
        "started_at": started_at,
        "completed_at": completed_at,
        "outputs": outputs,
        "metadata": metadata or {},
        "limitations": limitations or [],
        "verification": {"normalized_output_digest": object_commitment({"outputs": outputs})},
    }
    obj["id"] = stable_id("model_run", model_id, model_version, input_commitments, outputs)
    return {key: value for key, value in obj.items() if value is not None}


def statement(
    *,
    text: str,
    basis: list[str],
    statement_type: str,
    source: str,
    limitations: list[str] | None = None,
    metadata: dict[str, Any] | None = None,
) -> dict[str, Any]:
    obj = {
        "record_type": "ScientificStatement",
        "statement_type": statement_type,
        "text": text,
        "basis": basis,
        "source": source,
        "metadata": metadata or {},
        "limitations": limitations or [],
    }
    obj["id"] = stable_id("statement", text, basis, source)
    obj["commitment"] = object_commitment(obj)
    return obj


def research_bundle(
    *,
    study: dict[str, Any],
    sources: list[dict[str, Any]],
    observations: list[dict[str, Any]] | None = None,
    intervention_events: list[dict[str, Any]] | None = None,
    operational_events: list[dict[str, Any]] | None = None,
    calibration_records: list[dict[str, Any]] | None = None,
    transformations: list[dict[str, Any]] | None = None,
    derived_observations: list[dict[str, Any]] | None = None,
    exclusion_decisions: list[dict[str, Any]] | None = None,
    model_runs: list[dict[str, Any]] | None = None,
    statements: list[dict[str, Any]] | None = None,
    metadata: dict[str, Any] | None = None,
) -> dict[str, Any]:
    bundle = {
        "bundle_type": "agevidence.research_bundle.v0",
        "bundle_version": "0.0.1",
        "study": study,
        "sources": sources,
        "observations": observations or [],
        "intervention_events": intervention_events or [],
        "operational_events": operational_events or [],
        "calibration_records": calibration_records or [],
        "transformations": transformations or [],
        "derived_observations": derived_observations or [],
        "exclusion_decisions": exclusion_decisions or [],
        "model_runs": model_runs or [],
        "statements": statements or [],
        "metadata": metadata or {},
    }
    bundle["verification"] = verification_summary(bundle)
    bundle["bundle_commitment"] = object_commitment(bundle)
    return canonical_value(bundle)


def verification_summary(bundle: dict[str, Any]) -> dict[str, Any]:
    source_ids = {item["id"] for item in bundle.get("sources", [])}
    evidence_ids = object_ids(bundle)
    observations = bundle.get("observations", []) + bundle.get("derived_observations", [])
    interventions = bundle.get("intervention_events", [])
    models = bundle.get("model_runs", [])
    statements = bundle.get("statements", [])
    return {
        "source_integrity": all(source.get("commitment", "").startswith("sha256:") for source in bundle.get("sources", [])),
        "observation_lineage": all(set(obs.get("source_records", [])).issubset(source_ids) for obs in observations),
        "intervention_lineage": all(set(event.get("source_records", [])).issubset(source_ids) for event in interventions),
        "model_provenance": all(run.get("model_id") and run.get("model_version") and run.get("input_commitments") for run in models),
        "statement_reconstruction": all(set(stmt.get("basis", [])).issubset(evidence_ids) for stmt in statements),
    }


def object_ids(bundle: dict[str, Any]) -> set[str]:
    ids: set[str] = set()
    for key in (
        "sources",
        "observations",
        "intervention_events",
        "operational_events",
        "calibration_records",
        "transformations",
        "derived_observations",
        "exclusion_decisions",
        "model_runs",
        "statements",
    ):
        ids.update(item["id"] for item in bundle.get(key, []) if "id" in item)
    return ids


def write_bundle(bundle: dict[str, Any], path: Path) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(bundle, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return path
