use serde::{Deserialize, Serialize};
use serde_json::Value;
use thiserror::Error;

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

/// A canonical decision record retained for compatibility fixtures.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct DecisionRecord {
    /// Schema version.
    pub schema_version: SchemaVersion,
    /// Institution ID.
    pub institution: InstitutionId,
    /// Workflow ID.
    pub workflow: WorkflowId,
    /// Decision ID.
    pub decision_id: DecisionId,
    /// Timestamp.
    pub timestamp: Timestamp,
    /// Subject reference.
    pub subject_ref: SubjectRef,
    /// Input references.
    pub inputs: Vec<InputRef>,
    /// Model reference.
    pub model_ref: Option<ModelRef>,
    /// Policy reference.
    pub policy_ref: PolicyRef,
    /// Control assertions.
    pub controls: Vec<ControlAssertion>,
    /// Decision outcome.
    pub outcome: DecisionOutcome,
}

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
    pub fn parse(value: &str) -> std::result::Result<Self, AgEvidenceSchemaError> {
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
            other => Err(AgEvidenceSchemaError::UnknownSchema(other.to_owned())),
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
}

/// Schema validation summary emitted by the compatibility validator.
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
}

/// Errors returned by AgEvidence payload validation.
#[derive(Debug, Error, PartialEq, Eq)]
pub enum AgEvidenceSchemaError {
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
) -> std::result::Result<ValidatedPayload, AgEvidenceSchemaError> {
    let fields = match schema {
        AgEvidenceSchema::ModelExecution => require_fields(
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
        )?,
        AgEvidenceSchema::EvidenceCandidate => require_fields(
            payload,
            &[
                "candidate_id",
                "candidate_type",
                "claim_text",
                "model_run_receipt",
                "review_status",
            ],
        )?,
        AgEvidenceSchema::EvidenceGap => require_fields(
            payload,
            &[
                "gap_type",
                "requirement",
                "description",
                "severity",
                "model_run_receipt",
            ],
        )?,
        AgEvidenceSchema::HumanReview => require_fields(
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
        )?,
        AgEvidenceSchema::ArtifactAssembly => {
            require_array(payload, "included_receipts")?;
            require_fields(
                payload,
                &[
                    "artifact_digest",
                    "product_code",
                    "artifact_version",
                    "declared_scope",
                ],
            )?
        }
        AgEvidenceSchema::RelianceEvent => require_fields(
            payload,
            &[
                "artifact_digest",
                "relying_institution",
                "decision_type",
                "outcome",
                "declared_scope",
                "timestamp",
            ],
        )?,
        AgEvidenceSchema::CountryAdapterCommitment => {
            require_array(payload, "artifact_profile_digests")?;
            require_array(payload, "limitations")?;
            require_fields(
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
            )?
        }
        AgEvidenceSchema::CountryDetermination => {
            require_array(payload, "required_evidence")?;
            require_array(payload, "limitations")?;
            require_fields(
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
            )?
        }
    };
    Ok(ValidatedPayload {
        schema,
        schema_id: schema.schema_id().to_owned(),
        receipt_type: schema.receipt_type().to_owned(),
        required_fields: fields,
    })
}

fn require_fields(
    payload: &Value,
    names: &'static [&'static str],
) -> std::result::Result<Vec<String>, AgEvidenceSchemaError> {
    let object = payload.as_object().ok_or(AgEvidenceSchemaError::NotObject)?;
    let mut present = Vec::with_capacity(names.len());
    for name in names {
        let Some(value) = object.get(*name) else {
            return Err(AgEvidenceSchemaError::MissingField(name));
        };
        if value.is_null() || value.as_str().is_some_and(str::is_empty) {
            return Err(AgEvidenceSchemaError::MissingField(name));
        }
        present.push((*name).to_owned());
    }
    Ok(present)
}

fn require_array(
    payload: &Value,
    name: &'static str,
) -> std::result::Result<(), AgEvidenceSchemaError> {
    let object = payload.as_object().ok_or(AgEvidenceSchemaError::NotObject)?;
    match object.get(name).and_then(Value::as_array) {
        Some(values) if !values.is_empty() => Ok(()),
        _ => Err(AgEvidenceSchemaError::MissingArray(name)),
    }
}
