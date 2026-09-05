use thiserror::Error;

/// AgEvidence verifier result type.
pub type Result<T> = std::result::Result<T, AgEvidenceError>;

/// Errors returned by the verifier kernel.
#[derive(Debug, Error)]
pub enum AgEvidenceError {
    /// Filesystem or stream error.
    #[error("I/O error: {0}")]
    Io(#[from] std::io::Error),
    /// JSON parse or serialization error.
    #[error("JSON error: {0}")]
    Json(#[from] serde_json::Error),
    /// ZIP parse error.
    #[error("ZIP error: {0}")]
    Zip(#[from] zip::result::ZipError),
    /// Canonicalization failed.
    #[error("canonicalization failed: {0}")]
    Canonical(String),
    /// Input is malformed.
    #[error("malformed input: {0}")]
    Malformed(String),
    /// Protocol version or algorithm is unsupported.
    #[error("unsupported protocol: {0}")]
    UnsupportedProtocol(String),
    /// Cryptographic material is malformed or invalid.
    #[error("cryptographic error: {0}")]
    Crypto(String),
}
