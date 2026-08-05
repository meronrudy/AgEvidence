"""Typed campaign response models."""

from __future__ import annotations

from typing import Any

from pydantic import Field

from ..models import AgEvidenceModel


class CampaignContactRef(AgEvidenceModel):
    contact_id: str
    display_name: str | None = None
    role_category: str | None = None
    email_domain: str | None = None
    salesforce_contact_id: str | None = None
    apollo_person_id: str | None = None
    technical_authority: bool = False
    commercial_authority: bool = False
    scientific_authority: bool = False
    contactability_status: str | None = None


class ActivationPath(AgEvidenceModel):
    activation_id: str
    account_id: str | None = None
    path_type: str
    status: str
    repository_sha: str | None = None
    guide_path: str | None = None
    sdk_version: str | None = None
    cli_version: str | None = None
    developer_project_external_id: str | None = None
    support_minutes: int = 0
    authority_boundary: str | None = None


class TechnicalQualification(AgEvidenceModel):
    qualification_id: str
    account_id: str
    developer_project_id: int | str | None = None
    status: str
    qualification_level: str
    authoritative_system_confirmed: bool = False
    supported_event_count: int = 0
    required_event_count: int = 0
    evidence_gap_count: int = 0
    unreviewed_candidate_count: int = 0
    country_code: str | None = None
    country_adapter_identifier: str | None = None
    named_obligation_code: str | None = None
    named_relying_party_type: str | None = None
    qualification_reason: str | None = None
    snapshot: dict[str, Any] = Field(default_factory=dict)
    authority_boundary: str | None = None


class CommercialHandoff(AgEvidenceModel):
    handoff_id: str
    account_id: str
    qualification_id: str
    product_code: str
    status: str
    scope_digest: str
    planning_value_cents: int = 0
    contracted_value_cents: int = 0
    cash_collected_cents: int = 0
    currency: str = "USD"
    salesforce_opportunity_id: str | None = None
    salesforce_proposal_id: str | None = None
    proposal_reference: str | None = None
    proposal_terms_digest: str | None = None
    contract_reference: str | None = None
    contract_terms_digest: str | None = None
    invoice_reference: str | None = None
    cash_collection_reference: str | None = None
    revenue_system: str | None = None
    last_revenue_signal_at: str | None = None
    authority_boundary: str | None = None


class CampaignAccount(AgEvidenceModel):
    account_id: str
    name: str
    domain: str | None = None
    country_code: str
    subsector: str | None = None
    funding_stage: str | None = None
    capital_raised_cents: int = 0
    status: str
    qualification_level: str
    priority_score: int = 0
    authoritative_system: str | None = None
    evidence_obligation_code: str | None = None
    evidence_obligation_summary: str | None = None
    salesforce_account_id: str | None = None
    apollo_account_id: str | None = None
    developer_account_id: int | str | None = None
    contacts: list[CampaignContactRef] = Field(default_factory=list)
    activations: list[ActivationPath] = Field(default_factory=list)
    qualifications: list[TechnicalQualification] = Field(default_factory=list)
    handoffs: list[CommercialHandoff] = Field(default_factory=list)
    authority_boundary: str | None = None


class CampaignDashboard(AgEvidenceModel):
    counts: dict[str, int] = Field(default_factory=dict)
    phase10: dict[str, Any] = Field(default_factory=dict)
    recent_accounts: list[CampaignAccount] = Field(default_factory=list)
    recent_activations: list[ActivationPath] = Field(default_factory=list)
    recent_qualifications: list[TechnicalQualification] = Field(default_factory=list)
    recent_handoffs: list[CommercialHandoff] = Field(default_factory=list)
    authority_boundary: str | None = None
