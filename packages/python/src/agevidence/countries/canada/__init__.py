"""Canada federated adapter starting from the federal beef manifest."""

from __future__ import annotations

from agevidence.adapters.base import AdapterMetadata
from agevidence.countries.base import DeclarativeCountryAdapter
from agevidence.manifest_resources import country_manifest_snapshot
from agevidence.policies.models import PolicyStackEntry


_MANIFEST = country_manifest_snapshot("athian-country-ca-beef-v1")


class CanadaAdapter(DeclarativeCountryAdapter):
    metadata = AdapterMetadata(
        id=_MANIFEST["adapter"]["id"],
        country_code=_MANIFEST["adapter"]["country_code"],
        version=_MANIFEST["adapter"]["version"],
        status=_MANIFEST["adapter"]["status"],
        domain="livestock",
        description="Canada federal beef adapter with provincial extension support.",
        capabilities=["identifier_normalization", "source_normalization", "federal_profile", "provincial_extension"],
        limitations=_MANIFEST["limitations"],
    )
    method_id = _MANIFEST["method"]["id"]
    method_version = _MANIFEST["method"]["version"]
    authority = _MANIFEST["method"]["authority"]
    identifier_patterns = {
        "ca_pid": (r"[A-Z0-9-]{3,32}", "Canadian premises authority"),
        "ca_ccia": (r"[A-Z0-9]{8,32}", "Canadian Cattle Identification Agency"),
        "ca_clts": (r"[A-Z0-9]{8,32}", "Canadian Livestock Tracking System"),
        "ca_pigtrace": (r"[A-Z0-9-]{4,32}", "PigTRACE Canada"),
    }
    source_profiles = {
        "premises": "evidence.land_registry",
        "livestock_identity": "evidence.animal_cohort",
        "movement": "evidence.animal_cohort",
        "feed": "evidence.feed_record",
        "intervention_delivery": "evidence.intervention_delivery",
        "measurement": "evidence.weight_record",
        "baseline_ration": "evidence.baseline_ration",
        "baseline_performance": "evidence.baseline_performance",
        "animal_cohort": "evidence.animal_cohort",
    }
    requirements = _MANIFEST["required_evidence"]
    stack_entries = [
        PolicyStackEntry(layer="global", profile_type="global_contract", profile_id="athian.agevidence.v1", version="v1"),
        PolicyStackEntry(
            layer="country",
            profile_type="methodology",
            profile_id=_MANIFEST["claim_policy"]["profile"],
            version="v1",
            authority=authority,
            requirements=requirements,
            limitations=metadata.limitations,
        ),
    ]
