"""Shared built-in adapter implementation helpers."""

from __future__ import annotations

from typing import Any

from agevidence.adapters.base import AdapterMetadata, CountryAdapter
from agevidence.adapters.findings import Finding, finding
from agevidence.identifiers.binding import build_binding
from agevidence.identifiers.models import IdentifierNormalizationResult
from agevidence.identifiers.validation import matches
from agevidence.policies.models import PolicyStackEntry
from agevidence.sources.external_checks import ExternalCheckResult
from agevidence.sources.models import NormalizedSourceRecord, SourceNormalizationResult
from agevidence.sources.normalization import compact_record


class DeclarativeCountryAdapter(CountryAdapter):
    """Country adapter backed by declarative maps and conservative behavior."""

    metadata: AdapterMetadata
    method_id: str
    method_version: str
    authority: str
    identifier_patterns: dict[str, tuple[str, str]] = {}
    source_profiles: dict[str, str] = {}
    requirements: list[str] = []
    stack_entries: list[PolicyStackEntry] = []

    def normalize_identifier(self, identifier_system: str, value: str, **context: Any) -> IdentifierNormalizationResult:
        key = identifier_system.lower()
        normalized = value.strip().upper()
        if key not in self.identifier_patterns:
            return IdentifierNormalizationResult(
                adapter_id=self.metadata.id,
                country_code=self.metadata.country_code,
                identifier_system=identifier_system,
                original_value=value,
                normalized_value=None,
                valid_format=False,
                findings=[
                    finding("invalid_format", f"Unknown identifier system: {identifier_system}.", field=identifier_system, severity="warning"),
                    finding("review_required", "Unknown identifier systems require an explicit binding record.", severity="warning"),
                ],
            )

        pattern, authority = self.identifier_patterns[key]
        valid = matches(pattern, normalized)
        findings = [
            finding("valid_format" if valid else "invalid_format", f"{identifier_system} format {'valid' if valid else 'invalid'}.", field=identifier_system)
        ]
        binding = None
        if valid:
            binding = build_binding(
                identifier_system=identifier_system,
                issuing_authority=authority,
                local_value=value,
                global_subject=context.get("global_subject") or f"subject:{self.metadata.country_code}:{identifier_system}:{normalized}",
                source_commitment=context.get("source_commitment"),
                jurisdiction=self.metadata.country_code,
                limitations=self.limitations(),
            )
            findings.append(finding("normalized", f"{identifier_system} normalized."))
        return IdentifierNormalizationResult(
            adapter_id=self.metadata.id,
            country_code=self.metadata.country_code,
            identifier_system=identifier_system,
            original_value=value,
            normalized_value=normalized if valid else None,
            valid_format=valid,
            binding=binding,
            findings=findings,
        )

    def normalize_source_record(self, source_profile: str, record: dict[str, Any], **context: Any) -> SourceNormalizationResult:
        key = source_profile.lower()
        global_type = self.source_profiles.get(key)
        if global_type is None:
            return SourceNormalizationResult(
                adapter_id=self.metadata.id,
                country_code=self.metadata.country_code,
                original_profile=source_profile,
                findings=[finding("source_not_found", f"No source profile mapping for {source_profile}.", severity="warning")],
            )
        bindings = []
        for identifier in record.get("identifiers", []) or []:
            if isinstance(identifier, dict) and identifier.get("system") and identifier.get("value"):
                result = self.normalize_identifier(
                    str(identifier["system"]),
                    str(identifier["value"]),
                    source_commitment=context.get("commitment"),
                    global_subject=identifier.get("global_subject"),
                )
                if result.binding:
                    bindings.append(result.binding)
        normalized = NormalizedSourceRecord(
            source_system=context.get("source_system", record.get("source_system", "unknown")),
            source_profile=source_profile,
            global_evidence_type=global_type,
            source_commitment=context.get("commitment") or record.get("commitment"),
            controlled_uri=record.get("controlled_uri"),
            normalized_payload=compact_record(record),
            identifier_bindings=bindings,
            limitations=self.limitations(),
        )
        return SourceNormalizationResult(
            adapter_id=self.metadata.id,
            country_code=self.metadata.country_code,
            original_profile=source_profile,
            normalized=normalized,
            findings=[finding("source_found", f"{source_profile} mapped to {global_type}."), finding("normalized", "Source record normalized.")],
        )

    def validate_local_context(self, country_context: dict[str, Any]) -> list[Finding]:
        if not country_context:
            return [finding("review_required", "Country context is missing or incomplete.", severity="warning")]
        return [finding("normalized", "Country context accepted for adapter evaluation.")]

    def evidence_requirements(self, country_context: dict[str, Any] | None = None) -> list[str]:
        return list(self.requirements)

    def external_checks(self, check_id: str, reference: dict[str, Any]) -> ExternalCheckResult:
        return ExternalCheckResult(
            adapter_id=self.metadata.id,
            country_code=self.metadata.country_code,
            check_id=check_id,
            status="external_check_unavailable",
            reference=reference,
            findings=[finding("external_check_unavailable", f"{check_id} is not configured for live lookup.", severity="warning")],
        )

    def policy_stack(self, institution_profile: dict[str, Any] | None = None) -> list[PolicyStackEntry]:
        stack = [entry.model_copy(deep=True) for entry in self.stack_entries]
        if institution_profile:
            stack.append(
                PolicyStackEntry(
                    layer="institution",
                    profile_type=str(institution_profile.get("profile_type", "institution")),
                    profile_id=str(institution_profile.get("profile_id", "ad-hoc-institution-profile")),
                    version=str(institution_profile.get("version", "v1")),
                    authority=institution_profile.get("authority"),
                    requirements=list(institution_profile.get("requirements", [])),
                    limitations=list(institution_profile.get("limitations", [])),
                )
            )
        return stack
