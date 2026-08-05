"""European Union common and member-state adapter scaffold."""

from __future__ import annotations

from agevidence.adapters.base import AdapterMetadata
from agevidence.countries.base import DeclarativeCountryAdapter
from agevidence.manifest_resources import country_manifest_snapshot
from agevidence.policies.models import PolicyStackEntry


_MANIFEST = country_manifest_snapshot("athian-country-eu-common-v1")


class EuropeanUnionAdapter(DeclarativeCountryAdapter):
    metadata = AdapterMetadata(
        id=_MANIFEST["adapter"]["id"],
        country_code=_MANIFEST["adapter"]["country_code"],
        version=_MANIFEST["adapter"]["version"],
        status=_MANIFEST["adapter"]["status"],
        domain="spatial",
        description="European Union common/member-state adapter architecture scaffold.",
        capabilities=["source_normalization", "shared_spatial_evidence", "member_state_extension"],
        limitations=_MANIFEST["limitations"],
    )
    method_id = _MANIFEST["method"]["id"]
    method_version = _MANIFEST["method"]["version"]
    authority = _MANIFEST["method"]["authority"]
    identifier_patterns = {
        "eu_nuts": (r"[A-Z]{2}[A-Z0-9]{0,3}", "Eurostat NUTS"),
        "eu_inspire": (r"[A-Z0-9:._/-]{4,80}", "INSPIRE"),
    }
    source_profiles = {
        "eu_cap": "evidence.land_registry",
        "eu_lucas": "evidence.remote_sensing",
        "eu_copernicus": "evidence.remote_sensing",
        "eu_inspire": "evidence.land_registry",
        "eu_iacs": "evidence.land_registry",
        "eu_lpis": "evidence.land_registry",
        "animal_cohort": "evidence.animal_cohort",
    }
    requirements = _MANIFEST["required_evidence"]
    stack_entries = [
        PolicyStackEntry(layer="global", profile_type="global_contract", profile_id="athian.agevidence.v1", version="v1"),
        PolicyStackEntry(
            layer="country",
            profile_type="supranational",
            profile_id=_MANIFEST["claim_policy"]["profile"],
            version=method_version,
            authority=authority,
            requirements=requirements,
            limitations=metadata.limitations,
        ),
    ]
