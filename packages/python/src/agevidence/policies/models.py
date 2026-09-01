"""Policy composition models."""

from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


ResolutionCode = Literal[
    "compatible",
    "extension_applied",
    "requirement_added",
    "requirement_overridden",
    "unresolved_conflict",
    "superseded_policy",
    "institution_specific_requirement",
]


class PolicyStackEntry(BaseModel):
    """One layer in a resolved policy stack."""

    model_config = ConfigDict(extra="forbid")

    layer: Literal["global", "country", "subnational", "member_state", "institution"]
    profile_type: str
    profile_id: str
    version: str
    authority: str | None = None
    requirements: list[str] = Field(default_factory=list)
    limitations: list[str] = Field(default_factory=list)


class PolicyResolutionResult(BaseModel):
    """A policy resolution observation."""

    model_config = ConfigDict(extra="forbid")

    code: ResolutionCode
    message: str
    requirement: str | None = None
    source_profile: str | None = None


class PolicyResolution(BaseModel):
    """Resolved policy stack and requirement set."""

    model_config = ConfigDict(extra="forbid")

    stack: list[PolicyStackEntry] = Field(default_factory=list)
    requirements: list[str] = Field(default_factory=list)
    results: list[PolicyResolutionResult] = Field(default_factory=list)
    unresolved_conflicts: list[str] = Field(default_factory=list)

