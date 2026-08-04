# AgEvidence Bundle Profiles

This directory defines premium artifact bundle profiles. Fractional developers should add one versioned YAML file per profile and keep profile names aligned with `athian_ink_rails_bootstrap/config/agevidence/products.yml`.

Initial profile responsibilities:

- declare the intended relying party;
- list included receipt classes;
- declare selective-disclosure expectations;
- declare the local verification command;
- reference the trust policy file used by the bundle.

Country-specific artifact profiles live with their adapter packs under `specs/agevidence/country_adapters/<country>/artifact_profiles`. The global bundle profile contract stays stable while local profiles declare required receipts, required documents, verification behavior, and limitations.
