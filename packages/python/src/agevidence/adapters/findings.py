"""Standard country adapter findings."""

from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


FindingCode = Literal[
    "normalized",
    "valid_format",
    "invalid_format",
    "source_found",
    "source_not_found",
    "external_check_unavailable",
    "review_required",
    "conflict",
    "superseded",
]


class Finding(BaseModel):
    """A non-authoritative adapter observation."""

    model_config = ConfigDict(extra="forbid")

    code: FindingCode
    message: str
    field: str | None = None
    severity: Literal["info", "warning", "error"] = "info"
    source: str | None = None
    details: dict[str, object] = Field(default_factory=dict)


def finding(code: FindingCode, message: str, **kwargs: object) -> Finding:
    """Build a standard finding."""

    return Finding(code=code, message=message, **kwargs)

