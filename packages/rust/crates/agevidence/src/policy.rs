use serde::{Deserialize, Serialize};

/// Trust policy consumed by the verifier.
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct TrustPolicy {
    /// Stable policy identifier.
    #[serde(default)]
    pub policy_id: Option<String>,
    /// Accepted signer key identifiers.
    #[serde(default)]
    pub accepted_signers: Vec<String>,
    /// Permitted schema identifiers.
    #[serde(default)]
    pub permitted_schema_ids: Vec<String>,
    /// Permitted receipt versions.
    #[serde(default)]
    pub permitted_receipt_versions: Vec<String>,
    /// Permitted signature algorithms.
    #[serde(default)]
    pub allowed_algorithms: Vec<String>,
    /// Revoked key identifiers embedded in the policy.
    #[serde(default)]
    pub revoked_key_ids: Vec<String>,
    /// Whether signatures are required for policy pass.
    #[serde(default = "default_require_signature")]
    pub require_signature: bool,
}

/// Revocation data bundled for offline verification.
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct RevocationSnapshot {
    /// Revoked key identifiers.
    #[serde(default)]
    pub revoked_key_ids: Vec<String>,
    /// Legacy alias from older scaffold bundles.
    #[serde(default)]
    pub revoked_keys: Vec<String>,
}

impl RevocationSnapshot {
    /// Return true when a key is revoked.
    pub fn contains(&self, key_id: &str) -> bool {
        self.revoked_key_ids.iter().any(|value| value == key_id)
            || self.revoked_keys.iter().any(|value| value == key_id)
    }
}

fn default_require_signature() -> bool {
    true
}
