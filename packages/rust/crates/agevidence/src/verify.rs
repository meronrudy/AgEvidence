use crate::bundle::{load_bundle, BundleFormat, LoadedBundle};
use crate::crypto::{normalize_algorithm, parse_digest, verify_signature};
use crate::error::{AgEvidenceError, Result};
use crate::policy::TrustPolicy;
use crate::receipt::{
    body_digest_matches, legacy_record_hash_matches, receipt_commitment,
    receipt_commitment_matches, receipt_metadata, receipt_signing_bytes, SignatureInfo,
};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::path::Path;

/// Verifier protocol version emitted in machine-readable reports.
pub const PROTOCOL_VERSION: &str = "agevidence.trust.v1";

/// Status vocabulary for verification checks and reports.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum CheckStatus {
    /// Check passed.
    Pass,
    /// Check failed.
    Fail,
    /// Check could not be completed from available local material.
    Indeterminate,
    /// Check was not applicable.
    Skipped,
    /// Check passed with a warning.
    Warning,
}

/// A single verification check.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct VerificationCheck {
    /// Check identifier.
    pub name: String,
    /// Check status.
    pub status: CheckStatus,
    /// Human-readable detail.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub detail: Option<String>,
}

/// Structured verifier error.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct VerificationError {
    /// Stable error code.
    pub code: String,
    /// Human-readable message.
    pub message: String,
}

/// Stable verifier JSON report.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct VerificationReport {
    /// Verifier implementation version.
    pub verifier_version: String,
    /// Protocol version.
    pub protocol_version: String,
    /// Overall status.
    pub status: CheckStatus,
    /// Cryptographic layer status.
    pub cryptographic_status: CheckStatus,
    /// Trust-policy layer status.
    pub trust_policy_status: CheckStatus,
    /// Bundle format.
    pub bundle_format: BundleFormat,
    /// Computed bundle commitment.
    pub bundle_commitment: String,
    /// Receipt commitments computed during verification.
    pub receipt_commitments: Vec<String>,
    /// Individual checks.
    pub checks: Vec<VerificationCheck>,
    /// Warnings.
    pub warnings: Vec<String>,
    /// Errors.
    pub errors: Vec<VerificationError>,
}

/// Verify a bundle path.
pub fn verify_path(path: impl AsRef<Path>) -> Result<VerificationReport> {
    let bundle = load_bundle(path)?;
    verify_bundle(&bundle)
}

/// Verify a loaded bundle.
pub fn verify_bundle(bundle: &LoadedBundle) -> Result<VerificationReport> {
    let mut builder = ReportBuilder::new(bundle);

    verify_bundle_commitment(bundle, &mut builder);
    verify_receipts(bundle, &mut builder)?;
    verify_policy(bundle, &mut builder)?;

    Ok(builder.finish())
}

fn verify_bundle_commitment(bundle: &LoadedBundle, builder: &mut ReportBuilder) {
    match &bundle.declared_bundle_commitment {
        Some(declared) if commitment_equal(declared, &bundle.computed_bundle_commitment, "bundle") => {
            builder.crypto_check(
                "bundle.commitment.matches",
                CheckStatus::Pass,
                Some(bundle.computed_bundle_commitment.clone()),
            );
        }
        Some(declared) => {
            builder.crypto_check(
                "bundle.commitment.matches",
                CheckStatus::Fail,
                Some(format!(
                    "declared {declared}, computed {}",
                    bundle.computed_bundle_commitment
                )),
            );
            builder.error("BUNDLE_COMMITMENT_MISMATCH", "bundle commitment mismatch");
        }
        None => {
            builder.crypto_check(
                "bundle.commitment.present",
                CheckStatus::Indeterminate,
                Some("bundle has no declared bundle_commitment".to_owned()),
            );
            builder
                .warnings
                .push("bundle commitment is missing; cryptographic status is indeterminate".to_owned());
        }
    }
}

fn verify_receipts(bundle: &LoadedBundle, builder: &mut ReportBuilder) -> Result<()> {
    if bundle.receipts.is_empty() {
        builder.crypto_check(
            "receipt.present",
            CheckStatus::Indeterminate,
            Some("bundle contains no receipts".to_owned()),
        );
        return Ok(());
    }

    for (index, receipt) in bundle.receipts.iter().enumerate() {
        let prefix = format!("receipt.{index}");
        let metadata = match receipt_metadata(receipt) {
            Ok(metadata) => metadata,
            Err(error) => {
                builder.crypto_check(
                    format!("{prefix}.parse"),
                    CheckStatus::Fail,
                    Some(error.to_string()),
                );
                builder.error("RECEIPT_MALFORMED", error.to_string());
                continue;
            }
        };

        let commitment = receipt_commitment(receipt)?;
        builder.receipt_commitments.push(commitment.clone());
        match metadata.receipt_commitment.as_deref() {
            Some(declared) if receipt_commitment_matches(receipt, declared)? => {
                builder.crypto_check(
                    format!("{prefix}.commitment.matches"),
                    CheckStatus::Pass,
                    Some(commitment),
                );
            }
            Some(declared) => {
                builder.crypto_check(
                    format!("{prefix}.commitment.matches"),
                    CheckStatus::Fail,
                    Some(format!("declared {declared}, computed {commitment}")),
                );
                builder.error("RECEIPT_COMMITMENT_MISMATCH", "receipt commitment mismatch");
            }
            None => {
                builder.crypto_check(
                    format!("{prefix}.commitment.present"),
                    CheckStatus::Indeterminate,
                    Some("receipt_commitment is missing".to_owned()),
                );
            }
        }

        match metadata.body_digest.as_deref() {
            Some(declared) => match body_digest_matches(receipt, declared)? {
                Some(true) => builder.crypto_check(
                    format!("{prefix}.body_digest.matches"),
                    CheckStatus::Pass,
                    Some(declared.to_owned()),
                ),
                Some(false) => {
                    builder.crypto_check(
                        format!("{prefix}.body_digest.matches"),
                        CheckStatus::Fail,
                        Some(declared.to_owned()),
                    );
                    builder.error("BODY_DIGEST_MISMATCH", "receipt body digest mismatch");
                }
                None => builder.crypto_check(
                    format!("{prefix}.body_digest.matches"),
                    CheckStatus::Skipped,
                    Some("receipt has no payload field".to_owned()),
                ),
            },
            None => builder.crypto_check(
                format!("{prefix}.body_digest.present"),
                CheckStatus::Skipped,
                Some("legacy receipt has no body_digest".to_owned()),
            ),
        }

        if let Some(record) = bundle.records.first() {
            match legacy_record_hash_matches(receipt, record)? {
                Some(true) => builder.crypto_check(
                    format!("{prefix}.record_hash.matches"),
                    CheckStatus::Pass,
                    None,
                ),
                Some(false) => {
                    builder.crypto_check(
                        format!("{prefix}.record_hash.matches"),
                        CheckStatus::Fail,
                        None,
                    );
                    builder.error("RECORD_HASH_MISMATCH", "record hash mismatch");
                }
                None => builder.crypto_check(
                    format!("{prefix}.record_hash.matches"),
                    CheckStatus::Skipped,
                    Some("receipt has no legacy record_hash".to_owned()),
                ),
            }
        }

        verify_receipt_signature(bundle, builder, &prefix, receipt, metadata.signature.as_ref())?;
    }
    Ok(())
}

fn verify_receipt_signature(
    bundle: &LoadedBundle,
    builder: &mut ReportBuilder,
    prefix: &str,
    receipt: &Value,
    signature: Option<&SignatureInfo>,
) -> Result<()> {
    let Some(signature) = signature else {
        let status = if bundle
            .trust_policy
            .as_ref()
            .is_some_and(|policy| policy.require_signature)
        {
            CheckStatus::Fail
        } else {
            CheckStatus::Indeterminate
        };
        builder.crypto_check(
            format!("{prefix}.signature.valid"),
            status,
            Some("receipt has no signature block".to_owned()),
        );
        if status == CheckStatus::Fail {
            builder.error("SIGNATURE_MISSING", "trust policy requires a signature");
        }
        return Ok(());
    };

    let algorithm = normalize_algorithm(&signature.algorithm);
    let Some(key) = bundle.keys.iter().find(|key| key.key_id == signature.key_id) else {
        builder.crypto_check(
            format!("{prefix}.signature.valid"),
            CheckStatus::Indeterminate,
            Some(format!("public key unavailable: {}", signature.key_id)),
        );
        return Ok(());
    };

    if bundle.revocation.contains(&signature.key_id)
        || bundle
            .trust_policy
            .as_ref()
            .is_some_and(|policy| policy.revoked_key_ids.iter().any(|key| key == &signature.key_id))
    {
        builder.crypto_check(
            format!("{prefix}.signature.valid"),
            CheckStatus::Fail,
            Some(format!("key is revoked: {}", signature.key_id)),
        );
        builder.error("KEY_REVOKED", "signature key is revoked");
        return Ok(());
    }

    let key_algorithm = normalize_algorithm(&key.algorithm);
    if key_algorithm != algorithm {
        builder.crypto_check(
            format!("{prefix}.signature.valid"),
            CheckStatus::Fail,
            Some(format!(
                "signature algorithm {algorithm} does not match key algorithm {key_algorithm}"
            )),
        );
        builder.error("SIGNATURE_KEY_ALGORITHM_MISMATCH", "signature algorithm does not match key");
        return Ok(());
    }

    let signing_bytes = receipt_signing_bytes(receipt)?;
    match verify_signature(
        &signature.algorithm,
        key,
        &signing_bytes,
        &signature.value,
    ) {
        Ok(()) => builder.crypto_check(
            format!("{prefix}.signature.valid"),
            CheckStatus::Pass,
            Some(format!("{} verified", signature.key_id)),
        ),
        Err(AgEvidenceError::UnsupportedProtocol(message)) => {
            builder.crypto_check(
                format!("{prefix}.signature.valid"),
                CheckStatus::Fail,
                Some(message.clone()),
            );
            builder.error("SIGNATURE_ALGORITHM_UNSUPPORTED", message);
        }
        Err(error) => {
            builder.crypto_check(
                format!("{prefix}.signature.valid"),
                CheckStatus::Fail,
                Some(error.to_string()),
            );
            builder.error("SIGNATURE_INVALID", error.to_string());
        }
    }
    Ok(())
}

fn verify_policy(bundle: &LoadedBundle, builder: &mut ReportBuilder) -> Result<()> {
    let Some(policy) = bundle.trust_policy.as_ref() else {
        builder.policy_check(
            "trust_policy.present",
            CheckStatus::Indeterminate,
            Some("bundle has no trust policy".to_owned()),
        );
        return Ok(());
    };
    builder.policy_check(
        "trust_policy.present",
        CheckStatus::Pass,
        policy.policy_id.clone(),
    );
    for (index, receipt) in bundle.receipts.iter().enumerate() {
        let prefix = format!("receipt.{index}.policy");
        let metadata = receipt_metadata(receipt)?;
        verify_policy_receipt_version(policy, builder, &prefix, metadata.receipt_version.as_deref());
        verify_policy_schema(policy, builder, &prefix, metadata.schema_id.as_deref());
        verify_policy_algorithm(
            policy,
            builder,
            &prefix,
            metadata.signature.as_ref().map(|signature| signature.algorithm.as_str()),
        );
        let signer = metadata
            .signature
            .as_ref()
            .map(|signature| signature.key_id.as_str())
            .or(metadata.signer_key_id.as_deref());
        verify_policy_signer(policy, builder, &prefix, signer);
    }
    Ok(())
}

fn verify_policy_receipt_version(
    policy: &TrustPolicy,
    builder: &mut ReportBuilder,
    prefix: &str,
    receipt_version: Option<&str>,
) {
    if policy.permitted_receipt_versions.is_empty() {
        builder.policy_check(
            format!("{prefix}.receipt_version.permitted"),
            CheckStatus::Skipped,
            Some("policy does not restrict receipt versions".to_owned()),
        );
        return;
    }
    match receipt_version {
        Some(value) if policy.permitted_receipt_versions.iter().any(|allowed| allowed == value) => {
            builder.policy_check(
                format!("{prefix}.receipt_version.permitted"),
                CheckStatus::Pass,
                Some(value.to_owned()),
            );
        }
        Some(value) => {
            builder.policy_check(
                format!("{prefix}.receipt_version.permitted"),
                CheckStatus::Fail,
                Some(value.to_owned()),
            );
            builder.error("RECEIPT_VERSION_NOT_PERMITTED", "receipt version not permitted");
        }
        None => {
            builder.policy_check(
                format!("{prefix}.receipt_version.permitted"),
                CheckStatus::Indeterminate,
                Some("receipt has no version".to_owned()),
            );
        }
    }
}

fn verify_policy_schema(
    policy: &TrustPolicy,
    builder: &mut ReportBuilder,
    prefix: &str,
    schema_id: Option<&str>,
) {
    if policy.permitted_schema_ids.is_empty() {
        builder.policy_check(
            format!("{prefix}.schema.permitted"),
            CheckStatus::Skipped,
            Some("policy does not restrict schemas".to_owned()),
        );
        return;
    }
    match schema_id {
        Some(value) if policy.permitted_schema_ids.iter().any(|allowed| allowed == value) => {
            builder.policy_check(
                format!("{prefix}.schema.permitted"),
                CheckStatus::Pass,
                Some(value.to_owned()),
            );
        }
        Some(value) => {
            builder.policy_check(
                format!("{prefix}.schema.permitted"),
                CheckStatus::Fail,
                Some(value.to_owned()),
            );
            builder.error("SCHEMA_NOT_PERMITTED", "schema not permitted");
        }
        None => {
            builder.policy_check(
                format!("{prefix}.schema.permitted"),
                CheckStatus::Indeterminate,
                Some("receipt has no schema_id".to_owned()),
            );
        }
    }
}

fn verify_policy_algorithm(
    policy: &TrustPolicy,
    builder: &mut ReportBuilder,
    prefix: &str,
    algorithm: Option<&str>,
) {
    if policy.allowed_algorithms.is_empty() {
        builder.policy_check(
            format!("{prefix}.algorithm.permitted"),
            CheckStatus::Skipped,
            Some("policy does not restrict algorithms".to_owned()),
        );
        return;
    }
    match algorithm {
        Some(value)
            if policy
                .allowed_algorithms
                .iter()
                .map(|allowed| normalize_algorithm(allowed))
                .any(|allowed| allowed == normalize_algorithm(value)) =>
        {
            builder.policy_check(
                format!("{prefix}.algorithm.permitted"),
                CheckStatus::Pass,
                Some(value.to_owned()),
            );
        }
        Some(value) => {
            builder.policy_check(
                format!("{prefix}.algorithm.permitted"),
                CheckStatus::Fail,
                Some(value.to_owned()),
            );
            builder.error("ALGORITHM_NOT_PERMITTED", "signature algorithm not permitted");
        }
        None => {
            builder.policy_check(
                format!("{prefix}.algorithm.permitted"),
                CheckStatus::Indeterminate,
                Some("receipt has no signature algorithm".to_owned()),
            );
        }
    }
}

fn verify_policy_signer(
    policy: &TrustPolicy,
    builder: &mut ReportBuilder,
    prefix: &str,
    signer: Option<&str>,
) {
    if policy.accepted_signers.is_empty() {
        builder.policy_check(
            format!("{prefix}.signer.accepted"),
            CheckStatus::Skipped,
            Some("policy does not restrict signers".to_owned()),
        );
        return;
    }
    match signer {
        Some(value) if policy.accepted_signers.iter().any(|allowed| allowed == value) => {
            builder.policy_check(
                format!("{prefix}.signer.accepted"),
                CheckStatus::Pass,
                Some(value.to_owned()),
            );
        }
        Some(value) => {
            builder.policy_check(
                format!("{prefix}.signer.accepted"),
                CheckStatus::Fail,
                Some(value.to_owned()),
            );
            builder.error("SIGNER_NOT_ACCEPTED", "signer not accepted by trust policy");
        }
        None => {
            builder.policy_check(
                format!("{prefix}.signer.accepted"),
                CheckStatus::Indeterminate,
                Some("receipt has no signer".to_owned()),
            );
        }
    }
}

fn commitment_equal(declared: &str, computed: &str, domain: &str) -> bool {
    if declared == computed {
        return true;
    }
    match (parse_digest(declared), parse_digest(computed)) {
        (Some(declared), Some(computed)) => {
            declared.algorithm == computed.algorithm
                && declared.value == computed.value
                && (declared.domain.as_deref() == Some(domain) || declared.domain.is_none())
        }
        _ => false,
    }
}

struct ReportBuilder {
    bundle_format: BundleFormat,
    bundle_commitment: String,
    receipt_commitments: Vec<String>,
    checks: Vec<VerificationCheck>,
    warnings: Vec<String>,
    errors: Vec<VerificationError>,
    crypto_statuses: Vec<CheckStatus>,
    policy_statuses: Vec<CheckStatus>,
}

impl ReportBuilder {
    fn new(bundle: &LoadedBundle) -> Self {
        Self {
            bundle_format: bundle.format,
            bundle_commitment: bundle.computed_bundle_commitment.clone(),
            receipt_commitments: vec![],
            checks: vec![],
            warnings: vec![],
            errors: vec![],
            crypto_statuses: vec![],
            policy_statuses: vec![],
        }
    }

    fn crypto_check(
        &mut self,
        name: impl Into<String>,
        status: CheckStatus,
        detail: Option<String>,
    ) {
        self.crypto_statuses.push(status);
        self.checks.push(VerificationCheck {
            name: name.into(),
            status,
            detail,
        });
    }

    fn policy_check(
        &mut self,
        name: impl Into<String>,
        status: CheckStatus,
        detail: Option<String>,
    ) {
        self.policy_statuses.push(status);
        self.checks.push(VerificationCheck {
            name: name.into(),
            status,
            detail,
        });
    }

    fn error(&mut self, code: impl Into<String>, message: impl Into<String>) {
        self.errors.push(VerificationError {
            code: code.into(),
            message: message.into(),
        });
    }

    fn finish(self) -> VerificationReport {
        let cryptographic_status = aggregate_status(&self.crypto_statuses);
        let trust_policy_status = aggregate_status(&self.policy_statuses);
        let status = aggregate_status(&[cryptographic_status, trust_policy_status]);
        VerificationReport {
            verifier_version: env!("CARGO_PKG_VERSION").to_owned(),
            protocol_version: PROTOCOL_VERSION.to_owned(),
            status,
            cryptographic_status,
            trust_policy_status,
            bundle_format: self.bundle_format,
            bundle_commitment: self.bundle_commitment,
            receipt_commitments: self.receipt_commitments,
            checks: self.checks,
            warnings: self.warnings,
            errors: self.errors,
        }
    }
}

fn aggregate_status(statuses: &[CheckStatus]) -> CheckStatus {
    if statuses.iter().any(|status| *status == CheckStatus::Fail) {
        CheckStatus::Fail
    } else if statuses
        .iter()
        .any(|status| *status == CheckStatus::Indeterminate)
    {
        CheckStatus::Indeterminate
    } else if statuses.iter().any(|status| *status == CheckStatus::Warning) {
        CheckStatus::Warning
    } else {
        CheckStatus::Pass
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::bundle::bundle_commitment_for_json_value;
    use crate::canonical::canonicalize_value;
    use crate::crypto::{encode_base64url, sha256_hex, sha256_typed, PublicKey};
    use crate::receipt::{receipt_commitment, receipt_signing_bytes};
    use ed25519_dalek::{Signer, SigningKey};
    use serde_json::json;
    use std::fs::File;
    use std::io::Write;
    use tempfile::tempdir;
    use zip::write::FileOptions;

    #[test]
    fn valid_signed_json_bundle_passes() {
        let bundle = signed_bundle();
        let dir = tempdir().unwrap();
        let path = dir.path().join("bundle.json");
        std::fs::write(&path, serde_json::to_vec_pretty(&bundle).unwrap()).unwrap();

        let report = verify_path(&path).unwrap();

        assert_eq!(report.status, CheckStatus::Pass);
        assert!(report.checks.iter().any(|check| {
            check.name == "receipt.0.signature.valid" && check.status == CheckStatus::Pass
        }));
    }

    #[test]
    fn valid_p256_signed_json_bundle_passes() {
        let bundle = p256_signed_bundle();
        let dir = tempdir().unwrap();
        let path = dir.path().join("bundle.json");
        std::fs::write(&path, serde_json::to_vec_pretty(&bundle).unwrap()).unwrap();

        let report = verify_path(&path).unwrap();

        assert_eq!(report.status, CheckStatus::Pass);
        assert!(report.checks.iter().any(|check| {
            check.name == "receipt.0.signature.valid" && check.status == CheckStatus::Pass
        }));
    }

    #[test]
    fn tampered_receipt_payload_fails() {
        let mut bundle = signed_bundle();
        bundle["receipts"][0]["payload"]["amount"] = json!(43);
        let dir = tempdir().unwrap();
        let path = dir.path().join("bundle.json");
        std::fs::write(&path, serde_json::to_vec_pretty(&bundle).unwrap()).unwrap();

        let report = verify_path(&path).unwrap();

        assert_eq!(report.status, CheckStatus::Fail);
        assert!(report.errors.iter().any(|error| error.code == "BODY_DIGEST_MISMATCH"));
    }

    #[test]
    fn wrong_key_fails_signature_verification() {
        let mut bundle = signed_bundle();
        let wrong_key = SigningKey::from_bytes(&[8_u8; 32]).verifying_key();
        bundle["keys"][0]["public_key"] = json!(encode_base64url(wrong_key.as_bytes()));
        let commitment = bundle_commitment_for_json_value(&bundle).unwrap();
        bundle["bundle_commitment"] = json!(commitment);
        let dir = tempdir().unwrap();
        let path = dir.path().join("bundle.json");
        std::fs::write(&path, serde_json::to_vec_pretty(&bundle).unwrap()).unwrap();

        let report = verify_path(&path).unwrap();

        assert_eq!(report.status, CheckStatus::Fail);
        assert!(report.errors.iter().any(|error| error.code == "SIGNATURE_INVALID"));
    }

    #[test]
    fn malformed_signature_fails() {
        let mut bundle = signed_bundle();
        bundle["receipts"][0]["signature"]["value"] = json!("not_base64url!");
        let commitment = bundle_commitment_for_json_value(&bundle).unwrap();
        bundle["bundle_commitment"] = json!(commitment);
        let dir = tempdir().unwrap();
        let path = dir.path().join("bundle.json");
        std::fs::write(&path, serde_json::to_vec_pretty(&bundle).unwrap()).unwrap();

        let report = verify_path(&path).unwrap();

        assert_eq!(report.status, CheckStatus::Fail);
        assert!(report.errors.iter().any(|error| error.code == "SIGNATURE_INVALID"));
    }

    #[test]
    fn unsupported_signature_algorithm_fails() {
        let mut bundle = signed_bundle();
        bundle["receipts"][0]["signature"]["algorithm"] = json!("rsa-pss-sha256");
        bundle["keys"][0]["algorithm"] = json!("rsa-pss-sha256");
        let commitment = bundle_commitment_for_json_value(&bundle).unwrap();
        bundle["bundle_commitment"] = json!(commitment);
        let dir = tempdir().unwrap();
        let path = dir.path().join("bundle.json");
        std::fs::write(&path, serde_json::to_vec_pretty(&bundle).unwrap()).unwrap();

        let report = verify_path(&path).unwrap();

        assert_eq!(report.status, CheckStatus::Fail);
        assert!(report
            .errors
            .iter()
            .any(|error| error.code == "SIGNATURE_ALGORITHM_UNSUPPORTED"));
    }

    #[test]
    fn revoked_key_fails() {
        let mut bundle = signed_bundle();
        bundle["revocation"]["revoked_key_ids"] = json!(["did:key:test"]);
        let commitment = bundle_commitment_for_json_value(&bundle).unwrap();
        bundle["bundle_commitment"] = json!(commitment);
        let dir = tempdir().unwrap();
        let path = dir.path().join("bundle.json");
        std::fs::write(&path, serde_json::to_vec_pretty(&bundle).unwrap()).unwrap();

        let report = verify_path(&path).unwrap();

        assert_eq!(report.status, CheckStatus::Fail);
        assert!(report.errors.iter().any(|error| error.code == "KEY_REVOKED"));
    }

    #[test]
    fn missing_trust_policy_is_indeterminate() {
        let mut bundle = signed_bundle();
        bundle.as_object_mut().unwrap().remove("trust_policy");
        let commitment = bundle_commitment_for_json_value(&bundle).unwrap();
        bundle["bundle_commitment"] = json!(commitment);
        let dir = tempdir().unwrap();
        let path = dir.path().join("bundle.json");
        std::fs::write(&path, serde_json::to_vec_pretty(&bundle).unwrap()).unwrap();

        let report = verify_path(&path).unwrap();

        assert_eq!(report.status, CheckStatus::Indeterminate);
        assert_eq!(report.cryptographic_status, CheckStatus::Pass);
        assert_eq!(report.trust_policy_status, CheckStatus::Indeterminate);
    }

    #[test]
    fn zip_bundle_commitment_detects_attachment_tampering() {
        let bundle = signed_bundle();
        let dir = tempdir().unwrap();
        let zip_path = dir.path().join("bundle.zip");
        write_zip_bundle(&zip_path, &bundle, b"original attachment", None);

        let report = verify_path(&zip_path).unwrap();
        assert_eq!(report.status, CheckStatus::Pass);

        let tampered_path = dir.path().join("tampered.zip");
        write_zip_bundle(
            &tampered_path,
            &bundle,
            b"changed attachment",
            Some(report.bundle_commitment),
        );
        let tampered = verify_path(&tampered_path).unwrap();
        assert_eq!(tampered.status, CheckStatus::Fail);
        assert!(tampered.errors.iter().any(|error| error.code == "BUNDLE_COMMITMENT_MISMATCH"));
    }

    fn signed_bundle() -> Value {
        let signing_key = SigningKey::from_bytes(&[7_u8; 32]);
        let verifying_key = signing_key.verifying_key();
        let payload = json!({"amount": 42, "subject": "test"});
        let body_digest = sha256_typed("receipt", canonicalize_value(&payload).unwrap().as_bytes());
        let mut receipt = json!({
            "receipt_version": "agevidence.receipt.v1",
            "schema_id": "athian.agevidence.test_receipt.v1",
            "receipt_type": "test_receipt",
            "payload": payload,
            "body_digest": body_digest,
            "signature": {
                "algorithm": "ed25519",
                "key_id": "did:key:test"
            }
        });
        let commitment = receipt_commitment(&receipt).unwrap();
        receipt["receipt_commitment"] = json!(commitment);
        let signing_bytes = receipt_signing_bytes(&receipt).unwrap();
        let signature = signing_key.sign(&signing_bytes);
        receipt["signature"]["value"] = json!(encode_base64url(&signature.to_bytes()));
        let mut bundle = json!({
            "bundle_version": "agevidence.bundle.v1",
            "record": {"record_id": "rec-1"},
            "receipts": [receipt],
            "keys": [
                PublicKey {
                    key_id: "did:key:test".to_owned(),
                    algorithm: "ed25519".to_owned(),
                    public_key: Some(encode_base64url(verifying_key.as_bytes())),
                    public_key_base64url: None,
                    public_key_pem: None
                }
            ],
            "trust_policy": {
                "policy_id": "policy.test.v1",
                "accepted_signers": ["did:key:test"],
                "permitted_schema_ids": ["athian.agevidence.test_receipt.v1"],
                "permitted_receipt_versions": ["agevidence.receipt.v1"],
                "allowed_algorithms": ["ed25519"],
                "require_signature": true
            },
            "revocation": {"revoked_key_ids": []}
        });
        let bundle_commitment = bundle_commitment_for_json_value(&bundle).unwrap();
        bundle["bundle_commitment"] = json!(bundle_commitment);
        bundle
    }

    fn p256_signed_bundle() -> Value {
        use p256::ecdsa::SigningKey as P256SigningKey;
        let signing_key = P256SigningKey::from_slice(&[9_u8; 32]).unwrap();
        let verifying_key = signing_key.verifying_key();
        let payload = json!({"amount": 42, "subject": "p256-test"});
        let body_digest = sha256_typed("receipt", canonicalize_value(&payload).unwrap().as_bytes());
        let mut receipt = json!({
            "receipt_version": "agevidence.receipt.v1",
            "schema_id": "athian.agevidence.test_receipt.v1",
            "receipt_type": "test_receipt",
            "payload": payload,
            "body_digest": body_digest,
            "signature": {
                "algorithm": "es256",
                "key_id": "did:key:p256-test"
            }
        });
        let commitment = receipt_commitment(&receipt).unwrap();
        receipt["receipt_commitment"] = json!(commitment);
        let signing_bytes = receipt_signing_bytes(&receipt).unwrap();
        let signature: p256::ecdsa::Signature = signing_key.sign(&signing_bytes);
        receipt["signature"]["value"] = json!(encode_base64url(&signature.to_bytes()));
        let mut bundle = json!({
            "bundle_version": "agevidence.bundle.v1",
            "record": {"record_id": "rec-p256"},
            "receipts": [receipt],
            "keys": [
                PublicKey {
                    key_id: "did:key:p256-test".to_owned(),
                    algorithm: "es256".to_owned(),
                    public_key: Some(encode_base64url(verifying_key.to_encoded_point(false).as_bytes())),
                    public_key_base64url: None,
                    public_key_pem: None
                }
            ],
            "trust_policy": {
                "policy_id": "policy.test.v1",
                "accepted_signers": ["did:key:p256-test"],
                "permitted_schema_ids": ["athian.agevidence.test_receipt.v1"],
                "permitted_receipt_versions": ["agevidence.receipt.v1"],
                "allowed_algorithms": ["es256"],
                "require_signature": true
            },
            "revocation": {"revoked_key_ids": []}
        });
        let bundle_commitment = bundle_commitment_for_json_value(&bundle).unwrap();
        bundle["bundle_commitment"] = json!(bundle_commitment);
        bundle
    }

    fn write_zip_bundle(
        path: &Path,
        bundle: &Value,
        attachment: &[u8],
        commitment_override: Option<String>,
    ) {
        let mut manifest = json!({
            "contract_version": "agevidence.bundle.v1",
            "record": "records/record.json",
            "receipts": ["receipts/receipt.json"],
            "keys": "trust/keys.json",
            "trust_policy": "trust/trust-policy.json",
            "revocation": "trust/revocation-snapshot.json",
            "attachments": [
                {"path": "attachments/source.txt", "digest": format!("sha256:{}", sha256_hex(attachment))}
            ]
        });

        let record = bundle["record"].clone();
        let receipt = bundle["receipts"][0].clone();
        let keys = json!({"keys": bundle["keys"].clone()});
        let policy = bundle["trust_policy"].clone();
        let revocation = bundle["revocation"].clone();

        let mut entries = vec![
            (
                "manifest.json",
                serde_json::to_vec_pretty(&manifest).unwrap(),
            ),
            ("records/record.json", serde_json::to_vec_pretty(&record).unwrap()),
            ("receipts/receipt.json", serde_json::to_vec_pretty(&receipt).unwrap()),
            ("trust/keys.json", serde_json::to_vec_pretty(&keys).unwrap()),
            (
                "trust/trust-policy.json",
                serde_json::to_vec_pretty(&policy).unwrap(),
            ),
            (
                "trust/revocation-snapshot.json",
                serde_json::to_vec_pretty(&revocation).unwrap(),
            ),
            ("attachments/source.txt", attachment.to_vec()),
        ];
        let file_commitments = {
            let mut file_commitments = Vec::new();
            for (entry_path, bytes) in &entries {
                let commitment_bytes = if *entry_path == "manifest.json" {
                    canonicalize_value(&manifest).unwrap().as_bytes().to_vec()
                } else {
                    bytes.clone()
                };
                file_commitments.push(json!({
                    "path": entry_path,
                    "sha256": sha256_hex(&commitment_bytes)
                }));
            }
            file_commitments.sort_by(|a, b| {
                a["path"]
                    .as_str()
                    .unwrap()
                    .cmp(b["path"].as_str().unwrap())
            });
            file_commitments
        };
        let commitment_manifest = json!({"files": file_commitments});
        manifest["bundle_commitment"] = json!(commitment_override.unwrap_or_else(|| {
            sha256_typed(
                "bundle",
                canonicalize_value(&commitment_manifest).unwrap().as_bytes(),
            )
        }));
        entries[0] = ("manifest.json", serde_json::to_vec_pretty(&manifest).unwrap());

        let file = File::create(path).unwrap();
        let mut zip = zip::ZipWriter::new(file);
        let options = FileOptions::default();
        for (entry_path, bytes) in entries {
            zip.start_file(entry_path, options).unwrap();
            zip.write_all(&bytes).unwrap();
        }
        zip.finish().unwrap();
    }
}
