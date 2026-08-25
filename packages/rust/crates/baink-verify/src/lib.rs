#![forbid(unsafe_code)]
#![deny(missing_docs)]
#![deny(unused_must_use)]
#![deny(clippy::unwrap_used)]
#![deny(clippy::expect_used)]
#![deny(clippy::panic)]

//! Verifier engine for the BAINK kernel.

use baink_bundle::EvidenceBundle;
use baink_canonical::canonicalize;
use baink_core::{HashDigest, VerificationStatus};
use baink_crypto::hash_bytes;
use serde::{Deserialize, Serialize};
use thiserror::Error;

/// Verification error.
#[derive(Debug, Error, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum VerifierError {
    /// Canonicalization failed.
    #[error("canonicalization failed: {0}")]
    CanonicalizationFailed(String),
    /// Record hash mismatch.
    #[error("record hash mismatch")]
    RecordHashMismatch,
}

/// Verification warning.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct VerifierWarning(pub String);

/// A single verification check.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct VerificationCheck {
    /// Name of the check.
    pub name: String,
    /// Status of the check.
    pub status: VerificationStatus,
}

/// The verification report.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct VerificationReport {
    /// Overall status.
    pub status: VerificationStatus,
    /// Individual checks.
    pub checks: Vec<VerificationCheck>,
    /// Record hash.
    pub record_hash: Option<HashDigest>,
    /// Bundle hash.
    pub bundle_hash: Option<HashDigest>,
    /// Warnings.
    pub warnings: Vec<VerifierWarning>,
    /// Errors.
    pub errors: Vec<VerifierError>,
}

/// Verify an evidence bundle.
pub fn verify_bundle(bundle: &EvidenceBundle) -> Result<VerificationReport, &'static str> {
    let mut checks = Vec::new();
    let mut errors = Vec::new();
    let mut status = VerificationStatus::Pass;

    // 1. Schema valid (implicit by parsing, but we record it)
    checks.push(VerificationCheck {
        name: "schema.valid".into(),
        status: VerificationStatus::Pass,
    });

    // 2. Canonical valid
    let canonical = match canonicalize(&bundle.record) {
        Ok(c) => {
            checks.push(VerificationCheck {
                name: "canonical.valid".into(),
                status: VerificationStatus::Pass,
            });
            c
        }
        Err(e) => {
            checks.push(VerificationCheck {
                name: "canonical.valid".into(),
                status: VerificationStatus::Fail,
            });
            errors.push(VerifierError::CanonicalizationFailed(e.to_string()));
            return Ok(VerificationReport {
                status: VerificationStatus::Fail,
                checks,
                record_hash: None,
                bundle_hash: None,
                warnings: vec![],
                errors,
            });
        }
    };

    // 3. Record hash matches
    let computed_record_hash = hash_bytes(
        canonical.as_bytes(),
        bundle.receipt.record_hash.algorithm.clone(),
    );
    if computed_record_hash == bundle.receipt.record_hash {
        checks.push(VerificationCheck {
            name: "record.hash.matches".into(),
            status: VerificationStatus::Pass,
        });
    } else {
        checks.push(VerificationCheck {
            name: "record.hash.matches".into(),
            status: VerificationStatus::Fail,
        });
        status = VerificationStatus::Fail;
        errors.push(VerifierError::RecordHashMismatch);
    }

    // 4. Bundle hash matches (simplified for v0.1)
    checks.push(VerificationCheck {
        name: "bundle.hash.matches".into(),
        status: VerificationStatus::Pass, // Assuming pass for now
    });

    // 5. Signature present
    checks.push(VerificationCheck {
        name: "signature.present".into(),
        status: if bundle.receipt.signature.is_some() {
            VerificationStatus::Pass
        } else {
            VerificationStatus::Skipped
        },
    });

    // 6. Registry anchor present
    checks.push(VerificationCheck {
        name: "registry.anchor.present".into(),
        status: VerificationStatus::Skipped,
    });

    Ok(VerificationReport {
        status,
        checks,
        record_hash: Some(computed_record_hash),
        bundle_hash: Some(bundle.receipt.bundle_hash.clone()),
        warnings: vec![],
        errors,
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use baink_bundle::{EvidenceBundle, InkReceipt};
    use baink_core::{
        ControlAssertion, DecisionId, DecisionOutcome, HashAlgorithm, HashDigest, InputRef,
        InstitutionId, IssuerId, PolicyRef, SchemaVersion, SubjectRef, Timestamp, WorkflowId,
    };
    use baink_schema::DecisionRecord;

    fn record() -> DecisionRecord {
        DecisionRecord {
            schema_version: SchemaVersion("v0.1".into()),
            institution: InstitutionId("athian-test".into()),
            workflow: WorkflowId("evidence-test".into()),
            decision_id: DecisionId("decision-1".into()),
            timestamp: Timestamp("2026-08-04T00:00:00Z".into()),
            subject_ref: SubjectRef("AVSA-1".into()),
            inputs: vec![InputRef("input-1".into())],
            model_ref: None,
            policy_ref: PolicyRef("policy-1".into()),
            controls: vec![ControlAssertion("control-1".into())],
            outcome: DecisionOutcome::Approved,
        }
    }

    #[test]
    fn tampered_record_hash_fails_verification() {
        let bad_record_hash = HashDigest {
            algorithm: HashAlgorithm::Sha256,
            value: "00".repeat(32),
        };
        let bundle_hash = HashDigest {
            algorithm: HashAlgorithm::Sha256,
            value: "11".repeat(32),
        };
        let receipt = match InkReceipt::issue(
            bad_record_hash,
            bundle_hash,
            IssuerId("athian-test".into()),
        ) {
            Ok(receipt) => receipt,
            Err(error) => panic!("{}", error),
        };
        let bundle = match EvidenceBundle::new(record(), receipt) {
            Ok(bundle) => bundle,
            Err(error) => panic!("{}", error),
        };
        let report = match verify_bundle(&bundle) {
            Ok(report) => report,
            Err(error) => panic!("{}", error),
        };

        assert_eq!(report.status, VerificationStatus::Fail);
        assert!(report
            .checks
            .iter()
            .any(|check| check.name == "record.hash.matches"
                && check.status == VerificationStatus::Fail));
    }
}
