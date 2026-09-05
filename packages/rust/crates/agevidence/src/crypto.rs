use crate::error::{AgEvidenceError, Result};
use base64::engine::general_purpose::URL_SAFE_NO_PAD;
use base64::Engine as _;
use p256::ecdsa::signature::Verifier as P256Verifier;
use p256::pkcs8::DecodePublicKey;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

/// Parsed digest components.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DigestParts {
    /// Optional typed digest domain. Legacy `sha256:<hex>` has no domain.
    pub domain: Option<String>,
    /// Digest algorithm.
    pub algorithm: String,
    /// Lowercase hex digest value.
    pub value: String,
}

/// Public key material available to the verifier.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PublicKey {
    /// Key identifier referenced by signatures and trust policies.
    pub key_id: String,
    /// Signing algorithm associated with this key.
    pub algorithm: String,
    /// Unpadded base64url public key bytes.
    #[serde(default)]
    pub public_key: Option<String>,
    /// Alias for `public_key`.
    #[serde(default)]
    pub public_key_base64url: Option<String>,
    /// PEM public key, used primarily for P-256.
    #[serde(default)]
    pub public_key_pem: Option<String>,
}

/// Lowercase SHA-256 hex digest.
pub fn sha256_hex(bytes: &[u8]) -> String {
    let mut hasher = Sha256::new();
    hasher.update(bytes);
    hex::encode(hasher.finalize())
}

/// Typed SHA-256 digest.
pub fn sha256_typed(domain: &str, bytes: &[u8]) -> String {
    format!("{domain}:sha256:{}", sha256_hex(bytes))
}

/// Legacy SHA-256 digest.
pub fn sha256_legacy(bytes: &[u8]) -> String {
    format!("sha256:{}", sha256_hex(bytes))
}

/// Parse `sha256:<hex>` or `<domain>:sha256:<hex>`.
pub fn parse_digest(value: &str) -> Option<DigestParts> {
    let parts = value.split(':').collect::<Vec<_>>();
    match parts.as_slice() {
        ["sha256", digest] if is_hex_sha256(digest) => Some(DigestParts {
            domain: None,
            algorithm: "sha256".to_owned(),
            value: digest.to_ascii_lowercase(),
        }),
        [domain, "sha256", digest] if is_hex_sha256(digest) => Some(DigestParts {
            domain: Some((*domain).to_owned()),
            algorithm: "sha256".to_owned(),
            value: digest.to_ascii_lowercase(),
        }),
        [digest] if is_hex_sha256(digest) => Some(DigestParts {
            domain: None,
            algorithm: "sha256".to_owned(),
            value: digest.to_ascii_lowercase(),
        }),
        _ => None,
    }
}

/// Compare a declared digest with bytes.
pub fn digest_matches(declared: &str, domain: &str, bytes: &[u8], allow_legacy: bool) -> bool {
    let Some(parsed) = parse_digest(declared) else {
        return false;
    };
    if parsed.algorithm != "sha256" {
        return false;
    }
    match parsed.domain.as_deref() {
        Some(found) if found == domain => parsed.value == sha256_hex(bytes),
        None if allow_legacy => parsed.value == sha256_hex(bytes),
        _ => false,
    }
}

/// Verify an Ed25519 or P-256/ES256 signature.
pub fn verify_signature(
    algorithm: &str,
    key: &PublicKey,
    message: &[u8],
    signature_value: &str,
) -> Result<()> {
    let signature = decode_base64url(signature_value)?;
    match normalize_algorithm(algorithm).as_str() {
        "ed25519" => verify_ed25519(key, message, &signature),
        "es256" => verify_es256(key, message, &signature),
        other => Err(AgEvidenceError::UnsupportedProtocol(format!(
            "unsupported signature algorithm: {other}"
        ))),
    }
}

/// Normalize supported signature algorithm labels.
pub fn normalize_algorithm(algorithm: &str) -> String {
    match algorithm.to_ascii_lowercase().as_str() {
        "ed25519" | "eddsa" | "eddsa-ed25519" => "ed25519".to_owned(),
        "es256" | "p-256" | "p256" | "ecdsa-p256-sha256" => "es256".to_owned(),
        other => other.to_owned(),
    }
}

/// Decode unpadded base64url bytes.
pub fn decode_base64url(value: &str) -> Result<Vec<u8>> {
    URL_SAFE_NO_PAD
        .decode(value)
        .map_err(|error| AgEvidenceError::Crypto(format!("invalid base64url: {error}")))
}

/// Encode unpadded base64url bytes.
pub fn encode_base64url(bytes: &[u8]) -> String {
    URL_SAFE_NO_PAD.encode(bytes)
}

fn verify_ed25519(key: &PublicKey, message: &[u8], signature: &[u8]) -> Result<()> {
    let key_bytes = public_key_bytes(key)?;
    let key_bytes: [u8; 32] = key_bytes
        .as_slice()
        .try_into()
        .map_err(|_| AgEvidenceError::Crypto("ed25519 public key must be 32 bytes".to_owned()))?;
    let signature_bytes: [u8; 64] = signature
        .try_into()
        .map_err(|_| AgEvidenceError::Crypto("ed25519 signature must be 64 bytes".to_owned()))?;
    let verifying_key = ed25519_dalek::VerifyingKey::from_bytes(&key_bytes)
        .map_err(|error| AgEvidenceError::Crypto(error.to_string()))?;
    let signature = ed25519_dalek::Signature::from_bytes(&signature_bytes);
    P256Verifier::verify(&verifying_key, message, &signature)
        .map_err(|error| AgEvidenceError::Crypto(error.to_string()))
}

fn verify_es256(key: &PublicKey, message: &[u8], signature: &[u8]) -> Result<()> {
    let verifying_key = if let Some(pem) = &key.public_key_pem {
        p256::ecdsa::VerifyingKey::from_public_key_pem(pem)
            .map_err(|error| AgEvidenceError::Crypto(error.to_string()))?
    } else {
        let key_bytes = public_key_bytes(key)?;
        p256::ecdsa::VerifyingKey::from_sec1_bytes(&key_bytes)
            .map_err(|error| AgEvidenceError::Crypto(error.to_string()))?
    };
    let signature = p256::ecdsa::Signature::from_slice(signature)
        .map_err(|error| AgEvidenceError::Crypto(error.to_string()))?;
    verifying_key
        .verify(message, &signature)
        .map_err(|error| AgEvidenceError::Crypto(error.to_string()))
}

fn public_key_bytes(key: &PublicKey) -> Result<Vec<u8>> {
    let encoded = key
        .public_key
        .as_deref()
        .or(key.public_key_base64url.as_deref())
        .ok_or_else(|| AgEvidenceError::Crypto("missing public key bytes".to_owned()))?;
    decode_base64url(encoded)
}

fn is_hex_sha256(value: &str) -> bool {
    value.len() == 64 && value.bytes().all(|byte| byte.is_ascii_hexdigit())
}
