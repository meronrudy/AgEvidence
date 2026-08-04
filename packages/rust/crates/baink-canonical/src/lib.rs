#![forbid(unsafe_code)]
#![deny(missing_docs)]
#![deny(unused_must_use)]
#![deny(clippy::unwrap_used)]
#![deny(clippy::expect_used)]
#![deny(clippy::panic)]

//! Deterministic JSON canonicalization for the BAINK kernel.

use serde::Serialize;
use thiserror::Error;

/// Error during canonicalization.
#[derive(Debug, Error)]
pub enum CanonicalError {
    /// Serialization error.
    #[error("serialization error: {0}")]
    Serialization(#[from] serde_json::Error),
}

/// Canonical JSON representation.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CanonicalJson {
    bytes: Vec<u8>,
}

impl CanonicalJson {
    /// Get the canonical bytes.
    pub fn as_bytes(&self) -> &[u8] {
        &self.bytes
    }

    /// Get the canonical string.
    pub fn as_str(&self) -> Result<&str, std::str::Utf8Error> {
        std::str::from_utf8(&self.bytes)
    }
}

/// Canonicalize a serializable value.
///
/// For v0.1, we use `serde_json::to_vec` which is deterministic enough for simple structs
/// if we don't use maps with arbitrary key ordering (or if we use BTreeMap).
/// A true canonical JSON implementation (like RFC 8785) would be better for production.
pub fn canonicalize<T: Serialize>(value: &T) -> Result<CanonicalJson, CanonicalError> {
    // In a real implementation, this should strictly follow RFC 8785 (JCS).
    // For now, serde_json::to_vec is deterministic for structs.
    let bytes = serde_json::to_vec(value)?;
    Ok(CanonicalJson { bytes })
}
