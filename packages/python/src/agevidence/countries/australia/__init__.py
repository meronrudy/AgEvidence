"""Australia executable reference adapter."""

from __future__ import annotations

from agevidence.adapters.base import AdapterMetadata
from agevidence.countries.base import DeclarativeCountryAdapter
from agevidence.manifest_resources import country_manifest_snapshot
from agevidence.policies.models import PolicyStackEntry


_MANIFEST = country_manifest_snapshot("athian-country-au-livestock-v1")


class AustraliaAdapter(DeclarativeCountryAdapter):
    metadata = AdapterMetadata(
        id=_MANIFEST["adapter"]["id"],
        country_code=_MANIFEST["adapter"]["country_code"],
        version=_MANIFEST["adapter"]["version"],
        status=_MANIFEST["adapter"]["status"],
        domain="livestock",
        description="Australia livestock country adapter v1.",
        capabilities=["identifier_normalization", "source_normalization", "external_check_descriptions", "policy_evaluation"],
        limitations=_MANIFEST["limitations"],
    )
    method_id = _MANIFEST["method"]["id"]
    method_version = _MANIFEST["method"]["version"]
    authority = _MANIFEST["method"]["authority"]
    identifier_patterns = {
        "au_pic": (r"[A-Z0-9]{3,12}", "Australian state or territory PIC authority"),
        "au_nlis": (r"[A-Z0-9]{8,32}", "National Livestock Identification System"),
        "nlis": (r"[A-Z0-9]{8,32}", "National Livestock Identification System"),
        "au_envd": (r"[A-Z0-9-]{6,32}", "Electronic National Vendor Declaration"),
        "au_lpa": (r"[A-Z0-9-]{4,32}", "Livestock Production Assurance"),
        "au_nfas": (r"[A-Z0-9-]{4,32}", "National Feedlot Accreditation Scheme"),
        "au_abn": (r"\d{11}", "Australian Business Register"),
        "au_acn": (r"\d{9}", "Australian Securities and Investments Commission"),
        "au_cer": (r"[A-Z0-9-]{4,40}", "Clean Energy Regulator"),
    }
    source_profiles = {
        "au_pic": "evidence.land_registry",
        "au_nlis": "evidence.animal_cohort",
        "au_envd": "evidence.feed_record",
        "au_lpa": "evidence.verification_readiness_report",
        "au_nfas": "evidence.verification_readiness_report",
        "au_abn": "evidence.land_registry",
        "au_cer": "evidence.verification_readiness_report",
        "au_satellite": "evidence.remote_sensing",
        "property_records": "evidence.land_registry",
        "livestock_identity": "evidence.animal_cohort",
        "movement_records": "evidence.animal_cohort",
        "vendor_declarations": "evidence.feed_record",
        "feed_and_intervention_delivery": "evidence.intervention_delivery",
        "product_authorization": "evidence.product_authorization",
        "measurement": "evidence.weight_record",
        "model_calculation": "evidence.calculation_report",
        "verification": "evidence.verification_readiness_report",
        "claim_allocation": "evidence.calculation_report",
        "producer_payment": "evidence.payment_record",
        "animal_cohort": "evidence.animal_cohort",
        "intervention_delivery": "evidence.intervention_delivery",
    }
    requirements = _MANIFEST["required_evidence"]
    stack_entries = [
        PolicyStackEntry(
            layer="global",
            profile_type="global_contract",
            profile_id="athian.agevidence.v1",
            version="v1",
            requirements=["ink.receipt.v2", "ink.verify.v1"],
        ),
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
