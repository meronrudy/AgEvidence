#![forbid(unsafe_code)]
#![deny(missing_docs)]
#![deny(unused_must_use)]
#![deny(clippy::unwrap_used)]
#![deny(clippy::expect_used)]
#![deny(clippy::panic)]

//! Receipt bundle structure for the BAINK kernel.

use baink_core::{HashDigest, IssuerId, SchemaVersion, Timestamp};
use baink_schema::DecisionRecord;
use serde::{Deserialize, Serialize};

/// Signature block (placeholder for v0.1).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SignatureBlock {
    /// The signature value.
    pub value: String,
}

/// The evidence object.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct InkReceipt {
    /// Receipt schema version.
    pub receipt_version: SchemaVersion,
    /// Hash of the canonical record.
    pub record_hash: HashDigest,
    /// Hash of the bundle (excluding the receipt itself, or computed carefully).
    /// For v0.1, we might just hash the record and attachments.
    pub bundle_hash: HashDigest,
    /// Time of issuance.
    pub issued_at: Timestamp,
    /// Issuer identifier.
    pub issuer: IssuerId,
    /// Optional signature.
    pub signature: Option<SignatureBlock>,
}

impl InkReceipt {
    /// Issue a new receipt.
    pub fn issue(
        record_hash: HashDigest,
        bundle_hash: HashDigest,
        issuer: IssuerId,
    ) -> Result<Self, &'static str> {
        Ok(Self {
            receipt_version: SchemaVersion("v0.1".into()),
            record_hash,
            bundle_hash,
            issued_at: Timestamp("".into()), // Real app: current time
            issuer,
            signature: None,
        })
    }
}

/// The evidence bundle.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct EvidenceBundle {
    /// Bundle version.
    pub bundle_version: SchemaVersion,
    /// The decision record.
    pub record: DecisionRecord,
    /// The receipt.
    pub receipt: InkReceipt,
    /// Profile identifier.
    pub profile: String,
}

impl EvidenceBundle {
    /// Create a new evidence bundle.
    pub fn new(record: DecisionRecord, receipt: InkReceipt) -> Result<Self, &'static str> {
        Ok(Self {
            bundle_version: SchemaVersion("baink.bundle.v0.1".into()),
            record,
            receipt,
            profile: "default".into(),
        })
    }
}
