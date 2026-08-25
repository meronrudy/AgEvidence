"""New Zealand difference adapter scaffold with executable contracts."""

from __future__ import annotations

from agevidence.adapters.base import AdapterMetadata
from agevidence.countries.base import DeclarativeCountryAdapter
from agevidence.manifest_resources import country_manifest_snapshot
from agevidence.policies.models import PolicyStackEntry


_MANIFEST = country_manifest_snapshot("athian-country-nz-processor-v1")


class NewZealandAdapter(DeclarativeCountryAdapter):
    metadata = AdapterMetadata(
        id=_MANIFEST["adapter"]["id"],
        country_code=_MANIFEST["adapter"]["country_code"],
        version=_MANIFEST["adapter"]["version"],
        status=_MANIFEST["adapter"]["status"],
        domain="livestock",
        description="New Zealand processor-program difference adapter scaffold.",
        capabilities=["identifier_normalization", "source_normalization", "rights_governance_findings"],
        limitations=_MANIFEST["limitations"],
    )
    method_id = _MANIFEST["method"]["id"]
    method_version = _MANIFEST["method"]["version"]
    authority = _MANIFEST["method"]["authority"]
    identifier_patterns = {
        "nz_nait": (r"[A-Z0-9-]{4,32}", "NAIT"),
        "nz_mpi": (r"[A-Z0-9-]{4,32}", "Ministry for Primary Industries"),
        "nz_ets": (r"[A-Z0-9-]{4,40}", "New Zealand Emissions Trading Scheme"),
    }
    source_profiles = {
        "nait_cattle_movement": "evidence.animal_cohort",
        "deer_movement": "evidence.animal_cohort",
        "pasture_intervention": "evidence.intervention_delivery",
        "organic_certificate": "evidence.product_authorization",
        "processor_reliance": "evidence.verification_readiness_report",
        "maori_governance": "evidence.rights_receipt",
        "animal_cohort": "evidence.animal_cohort",
        "intervention_delivery": "evidence.intervention_delivery",
    }
    requirements = _MANIFEST["required_evidence"]
    stack_entries = [
        PolicyStackEntry(layer="global", profile_type="global_contract", profile_id="athian.agevidence.v1", version="v1"),
        PolicyStackEntry(
            layer="country",
            profile_type="processor",
            profile_id=_MANIFEST["claim_policy"]["profile"],
            version=method_version,
            authority=authority,
            requirements=requirements,
            limitations=metadata.limitations,
        ),
    ]
