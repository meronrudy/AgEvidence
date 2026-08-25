from __future__ import annotations

from pathlib import Path

import pytest
import yaml
from pydantic import ValidationError

from agevidence.adapters.base import AdapterEvaluationResult, AdapterMetadata
from agevidence.adapters.registry import AdapterRegistry, default_registry
from agevidence.countries.australia import AustraliaAdapter
from agevidence.countries.base import DeclarativeCountryAdapter
from agevidence.manifest_resources import country_manifest_snapshots
from agevidence.policies.models import PolicyStackEntry
from agevidence.sources.models import SourceRecordInput


def test_default_registry_resolves_country_code_and_adapter_id():
    registry = default_registry(load_entry_points=False)

    au_by_code = registry.resolve("AU")
    au_by_id = registry.resolve("athian-country-au-livestock-v1")

    assert au_by_code is au_by_id
    assert au_by_code.metadata.status == "active"


def test_identifier_normalization_produces_binding_without_approval():
    adapter = default_registry(load_entry_points=False).resolve("AU")

    result = adapter.normalize_identifier("au_pic", "abc123", source_commitment="sha256:source")

    assert result.valid_format
    assert result.binding is not None
    assert result.binding.identifier_system == "au_pic"
    assert "not authority approval" in result.authority_boundary


def test_unknown_identifier_system_requires_review_without_binding():
    adapter = default_registry(load_entry_points=False).resolve("AU")

    result = adapter.normalize_identifier("au_unknown", "ABC123")

    assert not result.valid_format
    assert result.binding is None
    assert {finding.code for finding in result.findings} == {"invalid_format", "review_required"}


def test_source_normalization_maps_local_profiles_to_global_evidence():
    adapter = default_registry(load_entry_points=False).resolve("AU")

    result = adapter.normalize_source_record(
        "au_envd",
        {"document_id": "envd-1", "identifiers": [{"system": "au_pic", "value": "ABC123"}]},
        commitment="sha256:envd-1",
    )

    assert result.normalized is not None
    assert result.normalized.global_evidence_type == "evidence.feed_record"
    assert result.normalized.source_commitment == "sha256:envd-1"
    assert result.normalized.identifier_bindings[0].jurisdiction == "AU"


def test_adapter_statuses_cannot_claim_approval_or_certification():
    with pytest.raises(ValidationError):
        AdapterMetadata(
            id="bad",
            country_code="AU",
            version="v1",
            status="approved",
            domain="livestock",
            description="Invalid approval status.",
        )

    with pytest.raises(ValidationError):
        AdapterEvaluationResult(
            project_id="project-1",
            country_code="AU",
            adapter_id="bad",
            adapter_version="v1",
            method_id="method",
            method_version="v1",
            status="certified",
            authority="none",
            evaluated_at="2026-08-05T00:00:00Z",
        )


def test_policy_stack_entries_are_deep_copied():
    adapter = AustraliaAdapter()

    stack = adapter.policy_stack()
    stack[0].requirements.append("mutated")

    assert "mutated" not in adapter.policy_stack()[0].requirements


def test_entry_point_adapter_discovery_loads_synthetic_adapter(monkeypatch):
    class SyntheticAdapter(DeclarativeCountryAdapter):
        metadata = AdapterMetadata(
            id="synthetic-country-adapter-v1",
            country_code="ZZ",
            version="v1",
            status="research",
            domain="test",
            description="Synthetic adapter for entry-point discovery.",
        )
        method_id = "ZZ-SYNTHETIC"
        method_version = "v1"
        authority = "Synthetic"
        source_profiles = {"animal_cohort": "evidence.animal_cohort"}
        requirements = ["evidence.animal_cohort"]
        stack_entries = [PolicyStackEntry(layer="country", profile_type="methodology", profile_id="synthetic", version="v1")]

    class FakeEntryPoint:
        def load(self):
            return SyntheticAdapter

    class FakeEntryPoints:
        def select(self, *, group):
            assert group == "agevidence.country_adapters"
            return [FakeEntryPoint()]

    monkeypatch.setattr("agevidence.adapters.loader.metadata.entry_points", lambda: FakeEntryPoints())

    registry = AdapterRegistry()
    loaded = registry.load_entry_points()

    assert loaded[0].metadata.id == "synthetic-country-adapter-v1"
    assert registry.resolve("ZZ").metadata.id == "synthetic-country-adapter-v1"


def test_external_check_unavailable_is_not_receipt_failure_or_approval():
    adapter = default_registry(load_entry_points=False).resolve("AU")

    result = adapter.external_checks("au_nlis", {"nlis": "982000000000001"})

    assert result.status == "external_check_unavailable"
    assert "not approval" in result.authority_boundary


def test_cross_country_evaluation_keeps_evidence_root_stable():
    registry = default_registry(load_entry_points=False)
    source_records = [
        SourceRecordInput(
            source_system="test",
            source_profile="animal_cohort",
            record={"document_id": "source-1", "commitment": "sha256:source-1"},
            commitment="sha256:source-1",
        )
    ]

    results = [
        registry.resolve(country).evaluate(
            project_id="project-1",
            evidence_graph_root="sha256:root",
            source_records=source_records,
            country_context={"species": "species.beef_cattle"},
        )
        for country in ["AU", "NZ", "CA", "UK", "EU"]
    ]

    assert {result.evidence_graph_root for result in results} == {"sha256:root"}
    assert len({result.adapter_id for result in results}) == 5
    assert len({tuple(entry.profile_id for entry in result.policy_stack) for result in results}) == 5


def test_packaged_manifest_snapshot_matches_repo_specs():
    repo_root = Path(__file__).resolve().parents[3]
    country_dirs = {
        "AU": "australia",
        "CA": "canada",
        "NZ": "new_zealand",
        "UK": "uk",
        "EU": "eu",
    }

    for snapshot in country_manifest_snapshots():
        country_code = snapshot["adapter"]["country_code"]
        path = repo_root / "specs" / "agevidence" / "country_adapters" / country_dirs[country_code] / "adapter.yml"
        manifest = yaml.safe_load(path.read_text(encoding="utf-8"))

        for key in ["adapter", "global_contract", "method", "required_evidence", "claim_policy", "limitations"]:
            assert snapshot[key] == manifest[key]
