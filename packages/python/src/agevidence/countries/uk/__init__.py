"""United Kingdom common and devolved adapter scaffold."""

from __future__ import annotations

from agevidence.adapters.base import AdapterMetadata
from agevidence.countries.base import DeclarativeCountryAdapter
from agevidence.manifest_resources import country_manifest_snapshot
from agevidence.policies.models import PolicyStackEntry


_MANIFEST = country_manifest_snapshot("athian-country-uk-common-v1")


class UnitedKingdomAdapter(DeclarativeCountryAdapter):
    metadata = AdapterMetadata(
        id=_MANIFEST["adapter"]["id"],
        country_code=_MANIFEST["adapter"]["country_code"],
        version=_MANIFEST["adapter"]["version"],
        status=_MANIFEST["adapter"]["status"],
        domain="livestock",
        description="United Kingdom common/devolved adapter architecture scaffold.",
        capabilities=["identifier_normalization", "source_normalization", "devolved_profile_resolution"],
        limitations=_MANIFEST["limitations"],
    )
    method_id = _MANIFEST["method"]["id"]
    method_version = _MANIFEST["method"]["version"]
    authority = _MANIFEST["method"]["authority"]
    identifier_patterns = {
        "uk_cph": (r"[0-9/]{6,16}", "UK county parish holding authority"),
        "uk_lis": (r"[A-Z0-9-]{4,32}", "UK livestock information service"),
    }
    source_profiles = {
        "statutory_movement": "evidence.animal_cohort",
        "animal_health": "evidence.verification_readiness_report",
        "environmental_incentive": "evidence.intervention_delivery",
        "private_assurance": "evidence.verification_readiness_report",
        "animal_cohort": "evidence.animal_cohort",
    }
    requirements = _MANIFEST["required_evidence"]
    stack_entries = [
        PolicyStackEntry(layer="global", profile_type="global_contract", profile_id="athian.agevidence.v1", version="v1"),
        PolicyStackEntry(
            layer="country",
            profile_type="government",
            profile_id=_MANIFEST["claim_policy"]["profile"],
            version=method_version,
            authority=authority,
            requirements=requirements,
            limitations=metadata.limitations,
        ),
    ]
