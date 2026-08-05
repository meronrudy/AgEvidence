"""Typed response models for the current AgEvidence /v1 scaffold."""

from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field


class AgEvidenceModel(BaseModel):
    """Base model that tolerates additive scaffold fields."""

    model_config = ConfigDict(extra="allow")


class ApiErrorPayload(AgEvidenceModel):
    code: str | None = None
    message: str | None = None
    event_id: str | None = None


class DeveloperProject(AgEvidenceModel):
    id: int | str
    name: str
    developer_account: str | None = None
    target_claim: str | None = None
    project_type: str | None = None
    protocol_status: str | None = None
    integration_status: str | None = None
    evidence_graph_root: str | None = None
    source_records_url: str | None = None
    model_runs_url: str | None = None
    artifacts_url: str | None = None
    authority_boundary: str | None = None


class SourceRecord(AgEvidenceModel):
    id: int | str
    document_id: str
    evidence_type: str
    evidence_class: str | None = None
    source_system: str | None = None
    controlled_uri: str
    commitment: str
    disclosure_status: str | None = None
    status: str | None = None
    source_event_id: str | None = None
    event_id: str | None = None
    operation_id: str | None = None
    created_at: str | None = None


class EvidenceGap(AgEvidenceModel):
    id: int | str
    gap_type: str
    requirement: str
    description: str
    severity: str
    resolution_status: str | None = None


class ReviewDecision(AgEvidenceModel):
    id: int | str
    reviewer_role: str | None = None
    decision: str
    reason: str | None = None
    policy_version: str | None = None
    receipt_id: int | str | None = None
    decided_at: str | None = None


class EvidenceCandidate(AgEvidenceModel):
    id: int | str
    model_run_id: int | str | None = None
    candidate_type: str | None = None
    claim_text: str | None = None
    source_references: list[dict[str, Any]] = Field(default_factory=list)
    model_confidence: float | None = None
    review_status: str | None = None
    review_notes: str | None = None
    reviewed_by: str | None = None
    reviewed_at: str | None = None
    authority_boundary: str | None = None
    review_decisions: list[ReviewDecision] = Field(default_factory=list)
    latest_decision: ReviewDecision | None = None


class ModelRun(AgEvidenceModel):
    id: int | str
    project_id: int | str | None = None
    adapter_id: str
    base_model_id: str | None = None
    task: str | None = None
    status: str
    prompt_digest: str | None = None
    retrieval_digest: str | None = None
    output_digest: str | None = None
    limitations: list[str] = Field(default_factory=list)
    candidates: list[EvidenceCandidate] = Field(default_factory=list)
    gaps: list[EvidenceGap] = Field(default_factory=list)
    completed_at: str | None = None


class PricingQuote(AgEvidenceModel):
    quote_id: str
    product_code: str
    currency: str = "USD"
    amount: int
    pricing_version: str | None = None
    breakdown: list[dict[str, Any]] | dict[str, Any] | None = None
    status: str | None = None
    expires_at: str | None = None
    accepted_at: str | None = None
    notice: str | None = None


class Product(AgEvidenceModel):
    code: str
    name: str | None = None
    billing_type: str | None = None
    base_planning_price_cents: int | None = None
    currency: str = "USD"
    description: str | None = None
    notice: str | None = None


class ProductCatalog(AgEvidenceModel):
    notice: str | None = None
    pricing_factors: list[str] | dict[str, Any] | None = None
    products: list[Product] = Field(default_factory=list)


class ArtifactMetadata(AgEvidenceModel):
    artifact_id: str | None = None
    bundle_id: int | str | None = None
    status: str | None = None
    verification_status: str | None = None
    receipt_root: str | None = None
    download_url: str | None = None
    verification_command: str | None = None
    limitations: list[str] | dict[str, Any] | None = None


class ArtifactOrder(AgEvidenceModel):
    order_id: str
    quote_id: str | None = None
    project_id: int | str | None = None
    product_code: str | None = None
    status: str
    currency: str | None = None
    amount: int | None = None
    checkout_url: str | None = None
    checkout_completed_at: str | None = None
    assembled_at: str | None = None
    artifact: ArtifactMetadata | None = None
    notice: str | None = None
    next_step: str | None = None


class ArtifactDownloadMetadata(AgEvidenceModel):
    artifact_id: str | None = None
    download_url: str | None = None
    verification_command: str | None = None
    note: str | None = None


class Operation(AgEvidenceModel):
    operation_id: str
    event_id: str | None = None
    status: str
    operation_type: str | None = None
    started_at: str | None = None
    completed_at: str | None = None
    result: dict[str, Any] | None = None
    error: dict[str, Any] | None = None

    @property
    def terminal(self) -> bool:
        return self.status in {"succeeded", "completed", "failed", "dead_letter", "dead_lettered"}


class EventSubmission(AgEvidenceModel):
    event_id: str
    status: str
    duplicate: bool = False
    operation_id: str | None = None


class IntegrationEventStatus(AgEvidenceModel):
    event_id: str
    event_type: str | None = None
    schema_version: str | None = None
    source: str | None = None
    signature_status: str | None = None
    schema_status: str | None = None
    processing_status: str | None = None
    payload_digest: str | None = None
    operation_id: str | None = None
    occurred_at: str | None = None
    received_at: str | None = None
    error: dict[str, Any] | None = None


class WebhookEndpoint(AgEvidenceModel):
    id: int | str
    url: str
    status: str
    subscribed_event_types: list[str] = Field(default_factory=list)
    last_success_at: str | None = None
    last_failure_at: str | None = None


class VerifyResult(AgEvidenceModel):
    status: Literal["delegated", "failed"]
    command: list[str]
    returncode: int | None = None
    stdout: str = ""
    stderr: str = ""
