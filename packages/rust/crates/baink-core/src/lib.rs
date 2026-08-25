#![forbid(unsafe_code)]
#![deny(missing_docs)]
#![deny(unused_must_use)]
#![deny(clippy::unwrap_used)]
#![deny(clippy::expect_used)]
#![deny(clippy::panic)]

//! Core types and traits for the BAINK kernel.

use serde::{Deserialize, Serialize};

/// Schema version identifier.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SchemaVersion(pub String);

/// Institution identifier.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct InstitutionId(pub String);

/// Workflow identifier.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct WorkflowId(pub String);

/// Decision identifier.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct DecisionId(pub String);

/// Issuer identifier.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct IssuerId(pub String);

/// Timestamp string.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Timestamp(pub String);

/// Subject reference.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SubjectRef(pub String);

/// Input reference.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct InputRef(pub String);

/// Model reference.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ModelRef(pub String);

/// Policy reference.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PolicyRef(pub String);

/// Control assertion.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ControlAssertion(pub String);

/// Decision outcome.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum DecisionOutcome {
    /// Approved outcome.
    Approved,
    /// Denied outcome.
    Denied,
    /// Manual review required.
    ManualReview,
}

/// Hash digest.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct HashDigest {
    /// The algorithm used.
    pub algorithm: HashAlgorithm,
    /// The hex-encoded hash value.
    pub value: String,
}

/// Hash algorithm.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum HashAlgorithm {
    /// SHA-256
    Sha256,
    /// BLAKE3
    Blake3,
}

/// Verification status.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "UPPERCASE")]
pub enum VerificationStatus {
    /// Record is structurally valid and cryptographically consistent.
    Pass,
    /// Record is valid but has policy or completeness concerns.
    Warning,
    /// Record is invalid, corrupted, mismatched, or unverifiable.
    Fail,
    /// Check was not applicable or not configured.
    Skipped,
}
