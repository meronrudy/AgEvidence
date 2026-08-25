#![forbid(unsafe_code)]
#![deny(missing_docs)]
#![deny(unused_must_use)]
#![deny(clippy::unwrap_used)]
#![deny(clippy::expect_used)]
#![deny(clippy::panic)]

//! Decision record schemas for the BAINK kernel.

use baink_core::{
    ControlAssertion, DecisionId, DecisionOutcome, InputRef, InstitutionId, ModelRef, PolicyRef,
    SchemaVersion, SubjectRef, Timestamp, WorkflowId,
};
use serde::{Deserialize, Serialize};

/// A canonical decision record.
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

impl DecisionRecord {
    /// Create a new builder for a DecisionRecord.
    pub fn builder() -> DecisionRecordBuilder {
        DecisionRecordBuilder::default()
    }
}

/// Builder for DecisionRecord.
#[derive(Default)]
pub struct DecisionRecordBuilder {
    schema_version: Option<SchemaVersion>,
    institution: Option<InstitutionId>,
    workflow: Option<WorkflowId>,
    decision_id: Option<DecisionId>,
    timestamp: Option<Timestamp>,
    subject_ref: Option<SubjectRef>,
    inputs: Vec<InputRef>,
    model_ref: Option<ModelRef>,
    policy_ref: Option<PolicyRef>,
    controls: Vec<ControlAssertion>,
    outcome: Option<DecisionOutcome>,
}

impl DecisionRecordBuilder {
    /// Set schema version.
    pub fn schema_version(mut self, v: impl Into<String>) -> Self {
        self.schema_version = Some(SchemaVersion(v.into()));
        self
    }
    /// Set institution.
    pub fn institution(mut self, v: impl Into<String>) -> Self {
        self.institution = Some(InstitutionId(v.into()));
        self
    }
    /// Set workflow.
    pub fn workflow(mut self, v: impl Into<String>) -> Self {
        self.workflow = Some(WorkflowId(v.into()));
        self
    }
    /// Set decision ID.
    pub fn decision_id(mut self, v: impl Into<String>) -> Self {
        self.decision_id = Some(DecisionId(v.into()));
        self
    }
    /// Set timestamp.
    pub fn timestamp(mut self, v: impl Into<String>) -> Self {
        self.timestamp = Some(Timestamp(v.into()));
        self
    }
    /// Set subject ref.
    pub fn subject_ref(mut self, v: impl Into<String>) -> Self {
        self.subject_ref = Some(SubjectRef(v.into()));
        self
    }
    /// Add input ref.
    pub fn add_input(mut self, v: impl Into<String>) -> Self {
        self.inputs.push(InputRef(v.into()));
        self
    }
    /// Set model ref.
    pub fn model_ref(mut self, v: impl Into<String>) -> Self {
        self.model_ref = Some(ModelRef(v.into()));
        self
    }
    /// Set policy ref.
    pub fn policy_ref(mut self, v: impl Into<String>) -> Self {
        self.policy_ref = Some(PolicyRef(v.into()));
        self
    }
    /// Add control assertion.
    pub fn add_control(mut self, v: impl Into<String>) -> Self {
        self.controls.push(ControlAssertion(v.into()));
        self
    }
    /// Set outcome.
    pub fn outcome(mut self, v: DecisionOutcome) -> Self {
        self.outcome = Some(v);
        self
    }

    /// Build the DecisionRecord.
    pub fn build(self) -> Result<DecisionRecord, &'static str> {
        Ok(DecisionRecord {
            schema_version: self.schema_version.unwrap_or(SchemaVersion("v0.1".into())),
            institution: self.institution.ok_or("missing institution")?,
            workflow: self.workflow.ok_or("missing workflow")?,
            decision_id: self.decision_id.ok_or("missing decision_id")?,
            timestamp: self.timestamp.unwrap_or(Timestamp("".into())), // In a real app, generate current time
            subject_ref: self.subject_ref.unwrap_or(SubjectRef("".into())),
            inputs: self.inputs,
            model_ref: self.model_ref,
            policy_ref: self.policy_ref.ok_or("missing policy_ref")?,
            controls: self.controls,
            outcome: self.outcome.ok_or("missing outcome")?,
        })
    }
}
