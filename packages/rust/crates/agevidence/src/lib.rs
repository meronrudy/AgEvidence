#![forbid(unsafe_code)]
#![deny(unused_must_use)]

//! Portable AgEvidence trust and verifier kernel.

pub mod bundle;
pub mod canonical;
pub mod crypto;
pub mod error;
pub mod policy;
pub mod receipt;
pub mod schema;
pub mod verify;

pub use bundle::{bundle_commitment_for_json_value, load_bundle, LoadedBundle};
pub use canonical::{canonicalize, canonicalize_value, CanonicalJson};
pub use crypto::{sha256_hex, sha256_typed, DigestParts, PublicKey};
pub use error::{AgEvidenceError, Result};
pub use policy::{RevocationSnapshot, TrustPolicy};
pub use verify::{verify_bundle, verify_path, CheckStatus, VerificationCheck, VerificationReport};
