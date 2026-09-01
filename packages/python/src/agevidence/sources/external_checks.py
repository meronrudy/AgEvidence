"""External check result models."""

from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

from agevidence.adapters.findings import Finding


ExternalCheckStatus = Literal[
    "request_accepted",
    "queued",
    "processed",
    "rejected",
    "rate_limited",
    "service_unavailable",
    "source_found",
    "source_not_found",
    "external_check_unavailable",
    "institutionally_accepted",
]


class ExternalCheckResult(BaseModel):
    """A transport/source observation from an external system."""

    model_config = ConfigDict(extra="forbid")

    adapter_id: str
    country_code: str
    check_id: str
    status: ExternalCheckStatus
    reference: dict[str, object] = Field(default_factory=dict)
    source_commitment: str | None = None
    checked_at: str | None = None
    findings: list[Finding] = Field(default_factory=list)
    authority_boundary: str = "External check status is not approval, certification, or receipt validity."

