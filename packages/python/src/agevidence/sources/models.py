"""Source normalization models."""

from __future__ import annotations

from typing import Any

from pydantic import BaseModel, ConfigDict, Field

from agevidence.adapters.findings import Finding
from agevidence.identifiers.models import IdentifierBinding


class SourceRecordInput(BaseModel):
    """Local source record input supplied to an adapter."""

    model_config = ConfigDict(extra="allow")

    source_system: str
    source_profile: str
    record: dict[str, Any] = Field(default_factory=dict)
    commitment: str | None = None


class NormalizedSourceRecord(BaseModel):
    """Country source translated into global AgEvidence evidence."""

    model_config = ConfigDict(extra="forbid")

    source_system: str
    source_profile: str
    global_evidence_type: str
    source_commitment: str | None = None
    controlled_uri: str | None = None
    normalized_payload: dict[str, Any] = Field(default_factory=dict)
    identifier_bindings: list[IdentifierBinding] = Field(default_factory=list)
    limitations: list[str] = Field(default_factory=list)


class SourceNormalizationResult(BaseModel):
    """Result of source record normalization."""

    model_config = ConfigDict(extra="forbid")

    adapter_id: str
    country_code: str
    original_profile: str
    normalized: NormalizedSourceRecord | None = None
    findings: list[Finding] = Field(default_factory=list)
    authority_boundary: str = "Source translation preserves provenance and does not approve evidence."

