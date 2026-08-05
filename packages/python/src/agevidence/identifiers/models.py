"""Identifier normalization models."""

from __future__ import annotations

from pydantic import BaseModel, ConfigDict, Field

from agevidence.adapters.findings import Finding


class IdentifierBinding(BaseModel):
    """Binding from a local identifier to a global AgEvidence subject."""

    model_config = ConfigDict(extra="forbid")

    identifier_system: str
    issuing_authority: str
    local_value: str
    global_subject: str
    source_commitment: str | None = None
    valid_from: str | None = None
    valid_until: str | None = None
    jurisdiction: str
    limitations: list[str] = Field(default_factory=list)


class IdentifierNormalizationResult(BaseModel):
    """Result of local identifier normalization."""

    model_config = ConfigDict(extra="forbid")

    adapter_id: str
    country_code: str
    identifier_system: str
    original_value: str
    normalized_value: str | None = None
    valid_format: bool
    binding: IdentifierBinding | None = None
    findings: list[Finding] = Field(default_factory=list)
    authority_boundary: str = "Identifier normalization is not authority approval or certification."

