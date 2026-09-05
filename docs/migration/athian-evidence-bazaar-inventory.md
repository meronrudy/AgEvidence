# athian-evidence-bazaar Migration Inventory

`/Users/mini/BAINK copy 2` is migration/reference material only. AgEvidence is
the canonical forward repository.

| Area | Classification | Notes |
| --- | --- | --- |
| `docs/internal/ENGINEERING_ARCHITECTURE_ORIENTATION.md` | MIGRATE/REFERENCE | Preserve trust-boundary doctrine and validation-state separation. |
| `docs/internal/TRUST_BOUNDARY_ORIENTATION.md` | MIGRATE/REFERENCE | Preserve Rails -> facade -> Rust direction and receipt/event signature distinction. |
| `docs/implementation/GLOBAL_THIN_WAIST_ARCHITECTURE.md` | MIGRATE/REFERENCE | Preserve global receipt types and country adapter boundary. |
| `docs/implementation/MODEL_AUTHORITY_BOUNDARY.md` | MIGRATE/REFERENCE | Preserve model non-authority language. |
| `athian_ink_rails_bootstrap/gems/ink_receipts` facade names | MIGRATE CONCEPTS | Reuse ergonomic names only when they fit AgEvidence Ruby SDK boundaries. |
| `ink_receipts` demo receipt issuance and Ruby hashing | DELETE AFTER REPLACEMENT | Must not survive as trust behavior. |
| `ink_receipts` CLI-unavailable demo fallback | DELETE | Verifier unavailable must be explicit error or indeterminate. |
| `crates/baink-*` Rust workspace | REWRITE/DELETE | Same scaffold lineage as AgEvidence; do not migrate as authoritative code. |
| `specs/agevidence/country_adapters` | MIGRATE SELECTIVELY | Use only missing country/profile content after protocol review. |
| product-market bundle catalog | MIGRATE SELECTIVELY | Move durable bundle concepts into protocol bundle profiles, not trust code. |
| Rails workflows | REFERENCE/ARCHIVE | Useful workflow reference, not trust semantics. |

After AgEvidence reaches parity, add a deprecation banner to the legacy
repository README, point developers to `meronrudy/AgEvidence`, freeze
trust-related implementation, and preserve historical tags.
