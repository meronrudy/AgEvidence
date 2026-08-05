"""Strict request models for the public SDK surface."""

from __future__ import annotations

from typing import Any

from pydantic import BaseModel, ConfigDict, Field


class AgEvidenceRequest(BaseModel):
    """Base model for SDK-authored request payloads."""

    model_config = ConfigDict(extra="forbid")


class ProjectCreateRequest(AgEvidenceRequest):
    account_name: str
    project_name: str
    target_claim: str
    funding_stage: str = "sandbox"
    project_type: str = "intervention"
    external_project_id: str | None = None
    country_context: dict[str, Any] | None = None

    def api_payload(self) -> dict[str, Any]:
        project: dict[str, Any] = {
            "name": self.project_name,
            "project_type": self.project_type,
            "target_claim": self.target_claim,
        }
        if self.external_project_id:
            project["external_project_id"] = self.external_project_id
        if self.country_context:
            project["country_context"] = self.country_context
        return {"developer_account": {"name": self.account_name, "funding_stage": self.funding_stage}, "project": project}


class SourceRecordCreateRequest(AgEvidenceRequest):
    document_id: str
    evidence_type: str
    controlled_uri: str
    commitment: str
    source_system: str = "python_sdk"
    evidence_class: str | None = None
    metadata: dict[str, Any] | None = None

    def api_payload(self) -> dict[str, Any]:
        record: dict[str, Any] = {
            "document_id": self.document_id,
            "evidence_type": self.evidence_type,
            "controlled_uri": self.controlled_uri,
            "commitment": self.commitment,
            "source_system": self.source_system,
        }
        if self.evidence_class:
            record["evidence_class"] = self.evidence_class
        if self.metadata:
            record["metadata_json"] = self.metadata
        return {"source_record": record}


class ModelRunCreateRequest(AgEvidenceRequest):
    adapter_id: str = "qwen3.5-4b-reference"


class ReviewCandidateRequest(AgEvidenceRequest):
    decision: str
    reason: str
    reviewer_role: str = "scientific_reviewer_sandbox"
    policy_version: str | None = None

    def api_payload(self) -> dict[str, Any]:
        review = self.model_dump(mode="json", exclude_none=True)
        return {"review_decision": review}


class CountryDeterminationCreateRequest(AgEvidenceRequest):
    adapter: str
    institution_profile: dict[str, Any] | None = None


class QuoteCreateRequest(AgEvidenceRequest):
    project_id: str
    product_code: str
    scope: dict[str, Any] = Field(default_factory=dict)

    def api_payload(self) -> dict[str, Any]:
        return {"quote": self.model_dump(mode="json")}


class OrderCreateRequest(AgEvidenceRequest):
    quote_id: str
    artifact_scope: dict[str, Any] = Field(default_factory=dict)

    def api_payload(self) -> dict[str, Any]:
        return {"artifact_order": self.model_dump(mode="json")}


class ArtifactBuildRequest(AgEvidenceRequest):
    order_id: str | None = None
    quote_id: str | None = None
    product_code: str | None = None
    sandbox_checkout: bool = False
    scope: dict[str, Any] | None = None


class EventReplayRequest(AgEvidenceRequest):
    reason: str = "python_sdk_replay"


class WebhookEndpointCreateRequest(AgEvidenceRequest):
    url: str
    signing_secret: str
    subscribed_event_types: list[str] | None = None


class CampaignAccountCreateRequest(AgEvidenceRequest):
    name: str
    country_code: str
    external_id: str | None = None
    domain: str | None = None
    subsector: str | None = None
    funding_stage: str | None = None
    priority_score: int = 0
    evidence_obligation_code: str | None = None
    evidence_obligation_summary: str | None = None


class CampaignAccountUpdateRequest(AgEvidenceRequest):
    name: str | None = None
    country_code: str | None = None
    domain: str | None = None
    subsector: str | None = None
    funding_stage: str | None = None
    priority_score: int | None = None
    evidence_obligation_code: str | None = None
    evidence_obligation_summary: str | None = None


class CampaignActivationStartRequest(AgEvidenceRequest):
    path_type: str
    status: str = "started"
    external_id: str | None = None
    repository_sha: str | None = None
    guide_path: str | None = None
    developer_project_external_id: str | None = None


class CampaignActivationFailRequest(AgEvidenceRequest):
    failure_code: str = "activation_failed"


class CampaignQualificationRequest(AgEvidenceRequest):
    developer_project_id: str | None = None
    named_obligation_code: str | None = None
    named_relying_party_type: str | None = None
    reusable_mapping_identified: bool = False
    product_code: str | None = None
    scope_estimate: str | None = None
    accountable_buyer_or_sponsor: str | None = None
    timing_window: str | None = None
    permitted_commercial_handoff: bool = False


class CampaignHandoffCreateRequest(AgEvidenceRequest):
    qualification_id: str
    product_code: str
    planning_value_cents: int = 0
    currency: str = "USD"
    scope: dict[str, Any] = Field(default_factory=dict)
