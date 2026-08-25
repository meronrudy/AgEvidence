"""Base country adapter interface."""

from __future__ import annotations

from abc import ABC, abstractmethod
from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field

from agevidence.adapters.findings import Finding, finding
from agevidence.identifiers.models import IdentifierNormalizationResult
from agevidence.policies.models import PolicyStackEntry
from agevidence.sources.external_checks import ExternalCheckResult
from agevidence.sources.models import SourceNormalizationResult, SourceRecordInput


AdapterStatus = Literal["active", "pilot", "scaffold", "research", "superseded", "retired"]
DeterminationStatus = Literal[
    "eligible",
    "eligible_with_conditions",
    "outside_current_method",
    "method_extension_required",
    "insufficient_evidence",
    "unassigned",
]


class AdapterMetadata(BaseModel):
    """Executable adapter metadata."""

    model_config = ConfigDict(extra="forbid")

    id: str
    country_code: str
    version: str
    status: AdapterStatus
    domain: str
    description: str
    capabilities: list[str] = Field(default_factory=list)
    limitations: list[str] = Field(default_factory=list)


class AdapterEvaluationResult(BaseModel):
    """Country adapter evaluation result before Rails receipt issuance."""

    model_config = ConfigDict(extra="forbid")

    contract: str = "athian.country_determination.v1"
    project_id: str
    country_code: str
    adapter_id: str
    adapter_version: str
    method_id: str
    method_version: str
    status: DeterminationStatus
    evidence_graph_root: str | None = None
    matched_context: dict[str, Any] = Field(default_factory=dict)
    excluded_contexts: list[dict[str, Any]] = Field(default_factory=list)
    required_evidence: list[str] = Field(default_factory=list)
    missing_evidence: list[str] = Field(default_factory=list)
    unresolved_conflicts: list[str] = Field(default_factory=list)
    authority: str
    determination_role: str = "Athian compatibility assessment only"
    policy_stack: list[PolicyStackEntry] = Field(default_factory=list)
    institution_profile: dict[str, Any] | None = None
    identifier_bindings: list[dict[str, Any]] = Field(default_factory=list)
    external_checks: list[dict[str, Any]] = Field(default_factory=list)
    source_profile_versions: dict[str, str] = Field(default_factory=dict)
    supersedes: str | None = None
    limitations: list[str] = Field(default_factory=list)
    findings: list[Finding] = Field(default_factory=list)
    evaluated_at: str


class CountryAdapter(ABC):
    """Executable country adapter interface."""

    metadata: AdapterMetadata
    method_id: str
    method_version: str
    authority: str

    @abstractmethod
    def normalize_identifier(self, identifier_system: str, value: str, **context: Any) -> IdentifierNormalizationResult:
        """Normalize and optionally bind a local identifier."""

    @abstractmethod
    def normalize_source_record(self, source_profile: str, record: dict[str, Any], **context: Any) -> SourceNormalizationResult:
        """Translate a local source record into a global evidence type."""

    @abstractmethod
    def validate_local_context(self, country_context: dict[str, Any]) -> list[Finding]:
        """Validate country context without producing authority decisions."""

    @abstractmethod
    def evidence_requirements(self, country_context: dict[str, Any] | None = None) -> list[str]:
        """Return global evidence requirements for the supplied context."""

    @abstractmethod
    def external_checks(self, check_id: str, reference: dict[str, Any]) -> ExternalCheckResult:
        """Run or describe an external check."""

    @abstractmethod
    def policy_stack(self, institution_profile: dict[str, Any] | None = None) -> list[PolicyStackEntry]:
        """Return the policy stack used by this adapter."""

    def limitations(self) -> list[str]:
        """Return adapter limitations."""

        return list(self.metadata.limitations)

    def evaluate(
        self,
        *,
        project_id: str,
        evidence_graph_root: str | None,
        source_records: list[SourceRecordInput],
        country_context: dict[str, Any] | None = None,
        institution_profile: dict[str, Any] | None = None,
        supersedes: str | None = None,
    ) -> AdapterEvaluationResult:
        """Evaluate a source graph against this adapter."""

        from datetime import datetime, timezone

        context = country_context or {}
        normalized = [
            self.normalize_source_record(record.source_profile, record.record, commitment=record.commitment, source_system=record.source_system)
            for record in source_records
        ]
        available = sorted(
            {
                item.normalized.global_evidence_type
                for item in normalized
                if item.normalized is not None
            }
        )
        required = self.evidence_requirements(context)
        missing = [item for item in required if item not in available]
        findings = self.validate_local_context(context)
        for item in normalized:
            findings.extend(item.findings)
        status = "eligible" if not missing else "eligible_with_conditions"
        if not available:
            status = "insufficient_evidence"

        bindings = [
            binding.model_dump(mode="json", exclude_none=True)
            for item in normalized
            if item.normalized is not None
            for binding in item.normalized.identifier_bindings
        ]
        return AdapterEvaluationResult(
            project_id=project_id,
            country_code=self.metadata.country_code,
            adapter_id=self.metadata.id,
            adapter_version=self.metadata.version,
            method_id=self.method_id,
            method_version=self.method_version,
            status=status,
            evidence_graph_root=evidence_graph_root,
            matched_context={key: value for key, value in context.items() if value},
            required_evidence=required,
            missing_evidence=missing,
            unresolved_conflicts=[],
            authority=self.authority,
            policy_stack=self.policy_stack(institution_profile),
            institution_profile=institution_profile,
            identifier_bindings=bindings,
            external_checks=[],
            source_profile_versions={record.source_profile: self.metadata.version for record in source_records},
            supersedes=supersedes,
            limitations=self.limitations(),
            findings=findings or [finding("review_required", "Adapter output requires Rails review before reliance.")],
            evaluated_at=datetime.now(timezone.utc).isoformat(),
        )
