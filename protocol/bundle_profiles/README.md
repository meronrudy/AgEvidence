# AgEvidence Bundle Profiles

This directory defines premium artifact bundle profiles. Fractional developers should add one versioned YAML file per profile and keep profile names aligned with AgEvidence product configuration in `apps/console`.

Initial profile responsibilities:

- declare the intended relying party;
- list included receipt classes;
- declare selective-disclosure expectations;
- declare the local verification command;
- reference the trust policy file used by the bundle.

Country-specific artifact profiles live with their adapter packs under
`protocol/country_adapters/<country>/artifact_profiles`. The global bundle
profile contract stays stable while local profiles declare required receipts,
required documents, verification behavior, and limitations.
