"""Country adapter manifest models."""

from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field


ManifestStatus = Literal["active", "pilot", "scaffold", "research", "superseded", "retired"]


class ManifestAdapter(BaseModel):
    model_config = ConfigDict(extra="forbid")

    id: str
    version: str
    status: ManifestStatus
    country_code: str


class ManifestGlobalContract(BaseModel):
    model_config = ConfigDict(extra="forbid")

    receipt_envelope: Literal["ink.receipt.v2"]
    agricultural_vocabulary: Literal["athian.agevidence.v1"]
    verifier_contract: Literal["ink.verify.v1"]


class ManifestMethod(BaseModel):
    model_config = ConfigDict(extra="forbid")

    id: str
    version: str
    authority: str


class ManifestProfileRef(BaseModel):
    model_config = ConfigDict(extra="allow")

    profile: str


class CountryAdapterManifest(BaseModel):
    """Typed view of `athian.country_adapter_manifest.v1`."""

    model_config = ConfigDict(extra="forbid")

    adapter: ManifestAdapter
    global_contract: ManifestGlobalContract
    method: ManifestMethod
    applicability: dict[str, Any]
    required_evidence: list[str]
    claim_policy: ManifestProfileRef
    verification_profile: ManifestProfileRef
    data_policy: ManifestProfileRef
    artifact_profiles: list[str] = Field(min_length=1)
    limitations: list[str] = Field(min_length=1)

    @property
    def classification(self) -> str:
        if self.adapter.status in {"active", "pilot", "scaffold", "research"}:
            return self.adapter.status
        return "research"

