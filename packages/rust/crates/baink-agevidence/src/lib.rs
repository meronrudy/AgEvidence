#![forbid(unsafe_code)]
#![deny(missing_docs)]
#![deny(unused_must_use)]
#![deny(clippy::unwrap_used)]
#![deny(clippy::expect_used)]
#![deny(clippy::panic)]

//! AgEvidence domain validation for normalized agricultural evidence payloads.

use serde::{Deserialize, Serialize};
use serde_json::Value;
use thiserror::Error;

/// AgEvidence schema identifiers supported by the scaffold.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum AgEvidenceSchema {
    /// Model execution receipt payload.
    ModelExecution,
    /// Evidence candidate receipt payload.
    EvidenceCandidate,
    /// Evidence gap receipt payload.
    EvidenceGap,
    /// Human review receipt payload.
    HumanReview,
    /// Artifact assembly receipt payload.
    ArtifactAssembly,
    /// Reliance event receipt payload.
    RelianceEvent,
    /// Country adapter commitment payload.
    CountryAdapterCommitment,
    /// Country compatibility determination payload.
    CountryDetermination,
}

impl AgEvidenceSchema {
    /// Parse a schema name or schema id into a scaffold schema enum.
    pub fn parse(value: &str) -> Result<Self, AgEvidenceError> {
        match value {
            "model_execution" | "athian.agevidence.model_execution.v1" => Ok(Self::ModelExecution),
            "evidence_candidate" | "athian.agevidence.evidence_candidate.v1" => {
                Ok(Self::EvidenceCandidate)
            }
            "evidence_gap" | "athian.agevidence.evidence_gap.v1" => Ok(Self::EvidenceGap),
            "human_review" | "athian.agevidence.human_review.v1" => Ok(Self::HumanReview),
            "artifact_assembly" | "athian.agevidence.artifact_assembly.v1" => {
                Ok(Self::ArtifactAssembly)
            }
            "reliance_event" | "athian.agevidence.reliance_event.v1" => Ok(Self::RelianceEvent),
            "country_adapter_commitment" | "athian.agevidence.country_adapter_commitment.v1" => {
                Ok(Self::CountryAdapterCommitment)
            }
            "country_determination" | "athian.country_determination.v1" => {
                Ok(Self::CountryDetermination)
            }
            other => Err(AgEvidenceError::UnknownSchema(other.to_owned())),
        }
    }

    /// Return the versioned schema id.
    pub fn schema_id(self) -> &'static str {
        match self {
            Self::ModelExecution => "athian.agevidence.model_execution.v1",
            Self::EvidenceCandidate => "athian.agevidence.evidence_candidate.v1",
            Self::EvidenceGap => "athian.agevidence.evidence_gap.v1",
            Self::HumanReview => "athian.agevidence.human_review.v1",
            Self::ArtifactAssembly => "athian.agevidence.artifact_assembly.v1",
            Self::RelianceEvent => "athian.agevidence.reliance_event.v1",
            Self::CountryAdapterCommitment => "athian.agevidence.country_adapter_commitment.v1",
            Self::CountryDetermination => "athian.country_determination.v1",
        }
    }

    /// Return the receipt type used by the Rails projection.
    pub fn receipt_type(self) -> &'static str {
        match self {
            Self::ModelExecution => "model_execution_receipt",
            Self::EvidenceCandidate => "evidence_candidate_receipt",
            Self::EvidenceGap => "evidence_gap_receipt",
            Self::HumanReview => "human_review_receipt",
            Self::ArtifactAssembly => "artifact_assembly_receipt",
            Self::RelianceEvent => "reliance_event_receipt",
            Self::CountryAdapterCommitment => "country_adapter_commitment_receipt",
            Self::CountryDetermination => "country_compatibility_determination_receipt",
        }
    }

    /// Return whether an issued receipt for this schema requires a parent.
    pub fn requires_parent(self) -> bool {
        matches!(
            self,
            Self::HumanReview | Self::RelianceEvent | Self::CountryDetermination
        )
    }
}

/// A validated payload summary emitted by the domain adapter.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ValidatedPayload {
    /// Schema that was validated.
    pub schema: AgEvidenceSchema,
    /// Versioned schema id.
    pub schema_id: String,
    /// Receipt type that should be issued.
    pub receipt_type: String,
    /// Required fields that were present.
    pub required_fields: Vec<String>,
    /// Whether this payload needs at least one parent receipt.
    pub parent_required: bool,
}

/// Errors returned by AgEvidence validation.
#[derive(Debug, Error, PartialEq, Eq)]
pub enum AgEvidenceError {
    /// The requested schema id is unknown.
    #[error("unknown AgEvidence schema: {0}")]
    UnknownSchema(String),
    /// The payload is not a JSON object.
    #[error("payload must be a JSON object")]
    NotObject,
    /// A required field is missing or empty.
    #[error("missing required field: {0}")]
    MissingField(&'static str),
    /// A required array is missing or empty.
    #[error("missing required array: {0}")]
    MissingArray(&'static str),
}

/// Validate a payload for the selected AgEvidence schema.
pub fn validate_payload(
    schema: AgEvidenceSchema,
    payload: &Value,
) -> Result<ValidatedPayload, AgEvidenceError> {
    match schema {
        AgEvidenceSchema::ModelExecution => validate_model_execution(payload),
        AgEvidenceSchema::EvidenceCandidate => validate_evidence_candidate(payload),
        AgEvidenceSchema::EvidenceGap => validate_evidence_gap(payload),
        AgEvidenceSchema::HumanReview => validate_human_review(payload),
        AgEvidenceSchema::ArtifactAssembly => validate_artifact_assembly(payload),
        AgEvidenceSchema::RelianceEvent => validate_reliance_event(payload),
        AgEvidenceSchema::CountryAdapterCommitment => validate_country_adapter_commitment(payload),
        AgEvidenceSchema::CountryDetermination => validate_country_determination(payload),
    }
}

/// Validate a model execution receipt payload.
pub fn validate_model_execution(payload: &Value) -> Result<ValidatedPayload, AgEvidenceError> {
    let fields = require_fields(
        payload,
        &[
            "base_model_id",
            "weights_digest",
            "adapter_id",
            "adapter_digest",
            "model_license",
            "runtime",
            "generation_config",
            "system_prompt_digest",
            "retrieval_corpus_digest",
            "normalized_output_digest",
            "policy_version",
            "execution_timestamp",
            "issuer",
            "signer",
        ],
    )?;
    require_array(payload, "source_document_commitments")?;
    require_array(payload, "limitations")?;
    Ok(summary(AgEvidenceSchema::ModelExecution, fields))
}

/// Validate an evidence candidate receipt payload.
pub fn validate_evidence_candidate(payload: &Value) -> Result<ValidatedPayload, AgEvidenceError> {
    let fields = require_fields(
        payload,
        &[
            "candidate_id",
            "candidate_type",
            "claim_text",
            "model_run_receipt",
            "review_status",
        ],
    )?;
    require_array(payload, "source_references")?;
    Ok(summary(AgEvidenceSchema::EvidenceCandidate, fields))
}

/// Validate an evidence gap receipt payload.
pub fn validate_evidence_gap(payload: &Value) -> Result<ValidatedPayload, AgEvidenceError> {
    let fields = require_fields(
        payload,
        &[
            "gap_type",
            "requirement",
            "description",
            "severity",
            "model_run_receipt",
        ],
    )?;
    Ok(summary(AgEvidenceSchema::EvidenceGap, fields))
}

/// Validate a human review receipt payload.
pub fn validate_human_review(payload: &Value) -> Result<ValidatedPayload, AgEvidenceError> {
    let fields = require_fields(
        payload,
        &[
            "candidate_receipt",
            "reviewer_role",
            "decision",
            "reason",
            "protocol_version",
            "policy_version",
            "timestamp",
            "signer",
        ],
    )?;
    Ok(summary(AgEvidenceSchema::HumanReview, fields))
}

/// Validate an artifact assembly receipt payload.
pub fn validate_artifact_assembly(payload: &Value) -> Result<ValidatedPayload, AgEvidenceError> {
    let fields = require_fields(
        payload,
        &[
            "artifact_digest",
            "product_code",
            "artifact_version",
            "declared_scope",
        ],
    )?;
    require_array(payload, "included_receipts")?;
    Ok(summary(AgEvidenceSchema::ArtifactAssembly, fields))
}

/// Validate a reliance event receipt payload.
pub fn validate_reliance_event(payload: &Value) -> Result<ValidatedPayload, AgEvidenceError> {
    let fields = require_fields(
        payload,
        &[
            "artifact_digest",
            "relying_institution",
            "decision_type",
            "outcome",
            "declared_scope",
            "timestamp",
        ],
    )?;
    Ok(summary(AgEvidenceSchema::RelianceEvent, fields))
}

/// Validate a country adapter commitment receipt payload.
pub fn validate_country_adapter_commitment(
    payload: &Value,
) -> Result<ValidatedPayload, AgEvidenceError> {
    let fields = require_fields(
        payload,
        &[
            "adapter_id",
            "adapter_version",
            "country_code",
            "method_id",
            "method_version",
            "eligibility_rules_digest",
            "claim_policy_digest",
            "verification_profile_digest",
            "data_policy_digest",
            "authority_declaration",
        ],
    )?;
    require_array(payload, "artifact_profile_digests")?;
    require_array(payload, "limitations")?;
    Ok(summary(AgEvidenceSchema::CountryAdapterCommitment, fields))
}

/// Validate a country compatibility determination payload.
pub fn validate_country_determination(
    payload: &Value,
) -> Result<ValidatedPayload, AgEvidenceError> {
    let fields = require_fields(
        payload,
        &[
            "contract",
            "project_id",
            "country_code",
            "adapter_id",
            "adapter_version",
            "method_id",
            "method_version",
            "status",
            "matched_context",
            "authority",
            "determination_role",
            "evaluated_at",
        ],
    )?;
    require_array(payload, "required_evidence")?;
    require_array(payload, "limitations")?;
    Ok(summary(AgEvidenceSchema::CountryDetermination, fields))
}

fn require_fields(
    payload: &Value,
    names: &'static [&'static str],
) -> Result<Vec<String>, AgEvidenceError> {
    let object = payload.as_object().ok_or(AgEvidenceError::NotObject)?;
    let mut present = Vec::with_capacity(names.len());
    for name in names {
        let Some(value) = object.get(*name) else {
            return Err(AgEvidenceError::MissingField(name));
        };
        if value.is_null() || value.as_str().is_some_and(str::is_empty) {
            return Err(AgEvidenceError::MissingField(name));
        }
        present.push((*name).to_owned());
    }
    Ok(present)
}

fn require_array(payload: &Value, name: &'static str) -> Result<(), AgEvidenceError> {
    let object = payload.as_object().ok_or(AgEvidenceError::NotObject)?;
    match object.get(name).and_then(Value::as_array) {
        Some(values) if !values.is_empty() => Ok(()),
        _ => Err(AgEvidenceError::MissingArray(name)),
    }
}

fn summary(schema: AgEvidenceSchema, required_fields: Vec<String>) -> ValidatedPayload {
    ValidatedPayload {
        schema,
        schema_id: schema.schema_id().to_owned(),
        receipt_type: schema.receipt_type().to_owned(),
        required_fields,
        parent_required: schema.requires_parent(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn validates_model_execution_payload() {
        let payload = json!({
            "base_model_id": "Qwen/Qwen3.5-4B",
            "weights_digest": "sha256:weights",
            "adapter_id": "qwen3.5-4b-reference",
            "adapter_digest": "sha256:adapter",
            "model_license": "reference declaration",
            "runtime": "fixture",
            "generation_config": { "temperature": 0, "seed": 42 },
            "system_prompt_digest": "sha256:prompt",
            "retrieval_corpus_digest": "sha256:retrieval",
            "source_document_commitments": ["sha256:doc"],
            "normalized_output_digest": "sha256:output",
            "policy_version": "ATH-AGEV-POLICY-v1",
            "limitations": ["candidate evidence only"],
            "execution_timestamp": "2026-08-04T16:30:00Z",
            "issuer": "Athian AgEvidence",
            "signer": "did:key:athian-agevidence"
        });

        let validated = match validate_model_execution(&payload) {
            Ok(value) => value,
            Err(error) => panic!("{}", error),
        };

        assert_eq!(validated.receipt_type, "model_execution_receipt");
        assert!(!validated.parent_required);
    }

    #[test]
    fn rejects_human_review_without_candidate_parent_field() {
        let payload = json!({
            "reviewer_role": "scientific reviewer",
            "decision": "accepted",
            "reason": "source linked",
            "protocol_version": "ATH-LI-CH4 v1",
            "policy_version": "ATH-AGEV-POLICY-v1",
            "timestamp": "2026-08-04T16:30:00Z",
            "signer": "did:key:reviewer"
        });

        assert_eq!(
            validate_human_review(&payload),
            Err(AgEvidenceError::MissingField("candidate_receipt"))
        );
    }

    #[test]
    fn parses_versioned_schema_id() {
        let schema = match AgEvidenceSchema::parse("athian.agevidence.reliance_event.v1") {
            Ok(value) => value,
            Err(error) => panic!("{}", error),
        };

        assert_eq!(schema.receipt_type(), "reliance_event_receipt");
        assert!(schema.requires_parent());
    }

    #[test]
    fn validates_country_adapter_commitment_payload() {
        let payload = json!({
            "adapter_id": "athian-country-ca-beef-v1",
            "adapter_version": "v1",
            "country_code": "CA",
            "method_id": "CA-FED-REME-BC",
            "method_version": "v1.0",
            "eligibility_rules_digest": "sha256:eligibility",
            "claim_policy_digest": "sha256:claim",
            "verification_profile_digest": "sha256:verification",
            "data_policy_digest": "sha256:data",
            "artifact_profile_digests": ["sha256:artifact"],
            "authority_declaration": "Athian compatibility implementation",
            "limitations": ["Final authority remains external."]
        });

        let validated = match validate_country_adapter_commitment(&payload) {
            Ok(value) => value,
            Err(error) => panic!("{}", error),
        };

        assert_eq!(validated.receipt_type, "country_adapter_commitment_receipt");
        assert!(!validated.parent_required);
    }

    #[test]
    fn country_determination_requires_parent() {
        let schema = match AgEvidenceSchema::parse("country_determination") {
            Ok(value) => value,
            Err(error) => panic!("{}", error),
        };

        assert!(schema.requires_parent());
    }
}
