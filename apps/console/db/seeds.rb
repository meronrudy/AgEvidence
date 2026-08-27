require "digest"

CANONICAL_PROFILE_CODE = "AU_METHANE_INTERVENTION_V1" unless defined?(CANONICAL_PROFILE_CODE)
PENDING_PROFILE_CODE = "AU_METHANE_INTERVENTION_V1_1" unless defined?(PENDING_PROFILE_CODE)

def upsert(klass, lookup, attrs)
  record = klass.find_or_initialize_by(lookup)
  attrs.each { |key, value| record.public_send("#{key}=", value) }
  record.save!
  record
end

def t(value)
  Time.zone.parse(value)
end

def digest_for(value)
  "sha256:#{Digest::SHA256.hexdigest(value.to_json)}"
end

org = upsert(
  Organization,
  { name: "DIT AgTech" },
  { environment: "Production" }
)

Role.default_roles_for_organization(org)
admin_role = org.role(:org_admin)
reviewer_role = org.role(:reviewer)

admin = User.find_or_initialize_by(email: "emma@agevidence.example")
admin.assign_attributes(
  first_name: "Emma",
  last_name: "Clarke",
  provider: "email",
  status: "active",
  confirmed_at: Time.current
)
if admin.encrypted_password.blank? || Rails.env.local?
  admin.password = "demo"
  admin.password_confirmation = "demo"
end
admin.save!

upsert(
  OrganizationMembership,
  { user: admin, organization: org },
  { role: admin_role, status: "active", joined_at: Time.current }
)

org.projects.where.not(slug: "dit-production").destroy_all

main_project = upsert(
  Project,
  { slug: "dit-production" },
  {
    organization: org,
    project_code: "PRJ-AU-00041",
    name: "DIT Production Evidence",
    jurisdiction: "Australia",
    program: "Methane Intervention Evidence",
    scope: "Production evidence boundary",
    readiness: 91,
    status: "Ready with qualification",
    status_tone: "warning",
    open_gaps: 1,
    critical_gaps: 0,
    review_status: "Review required",
    artifact_status: "Ready with qualification",
    last_activity_at: t("2026-08-14 21:04:18"),
    metadata: {
      "workspace_kind" => "EvidenceWorkspace",
      "product_lot" => "PL-443",
      "cohort" => "C-18",
      "period" => "12 Jun - 19 Jul 2026",
      "profile" => CANONICAL_PROFILE_CODE
    }
  }
)

[
  main_project.reliance_events,
  main_project.verifier_results,
  main_project.artifacts,
  main_project.determinations,
  main_project.evaluations,
  main_project.reviews,
  main_project.gaps,
  main_project.model_runs,
  main_project.evidence_records,
  main_project.source_records,
  main_project.activities,
  main_project.evidence_cases
].each(&:destroy_all)

org.api_logs.destroy_all
org.webhook_endpoints.destroy_all
org.integrations.destroy_all
org.api_keys.destroy_all
org.invitations.destroy_all
User.where(email: "review.partner@agevidence.example").destroy_all

stale_profiles = ProgramProfile.where.not(code: [CANONICAL_PROFILE_CODE, PENDING_PROFILE_CODE])
Determination.where(program_profile: stale_profiles).destroy_all
Evaluation.where(program_profile: stale_profiles).destroy_all
stale_profiles.destroy_all

profile = upsert(
  ProgramProfile,
  { code: CANONICAL_PROFILE_CODE },
  {
    slug: "au-methane-intervention-v1",
    name: "AU Methane Intervention Evidence",
    status: "Operational",
    profile_version: "v1.0",
    program: "Methane Intervention Evidence",
    scope: "Livestock methane intervention evidence",
    methodology: "AU Methane Intervention Evidence v1",
    verification_profile: "AU evidence statement verification v1",
    evidence_policy: "canonical-sdk-primitives",
    effective_from: Date.new(2026, 8, 12),
    effective_to: nil,
    requirements_digest: "sha256:au-methane-intervention-v1-requirements",
    outcome_vocabulary: ["READY", "READY WITH QUALIFICATION", "REVIEW REQUIRED", "NOT READY"],
    issuance_policy: {
      "contract_version" => "program-issuance-policy.v1",
      "requires_profile_version" => true,
      "requires_non_stale_evaluation" => true,
      "blocks_on_blocking_gaps" => true,
      "qualification_must_be_included" => true
    },
    limitation_templates: [
      { "code" => "AE-METH-LIM-001", "statement" => "Statement is limited to the declared lot, cohort, period, and profile version." }
    ],
    artifact_profile_selection: "au-methane-statement-v1",
    requirements_count: 15,
    machine_evaluable: 10,
    human_review: 5,
    profile_classes: 3,
    composition: [
      { "kind" => "sdk_ontology", "label" => "SDK primitives", "identifier" => "SourceRecord Observation InterventionEvent OperationalEvent ModelRun", "version" => "v1", "digest" => "sha256:sdk-primitives-v1" },
      { "kind" => "requirements", "label" => "Requirements", "identifier" => "au.methane_intervention.requirements", "version" => "v1.0", "digest" => "sha256:au-methane-requirements-v1" },
      { "kind" => "evaluation", "label" => "Continuous evaluation", "identifier" => "evidence_plane.evaluation", "version" => "v1", "digest" => "sha256:evaluation-v1" },
      { "kind" => "statement", "label" => "Evidence Statement", "identifier" => "au.methane.statement", "version" => "v1", "digest" => "sha256:statement-profile-v1" }
    ],
    version_diff: [
      { "id" => "AE-METH-006", "kind" => "changed", "note" => "Treatment continuity accepts secondary operational evidence when primary telemetry is unavailable.", "effect" => "Some reviews become qualified rather than blocked." },
      { "id" => "AE-METH-008", "kind" => "changed", "note" => "Calibration evidence must include instrument identity and effective period.", "effect" => "Observation-backed evaluations may require recalculation." },
      { "id" => "AE-METH-014", "kind" => "added", "note" => "Correction history must be carried into statement lifecycle checks.", "effect" => "Draft statements may need regeneration." }
    ],
    version_impact: {
      "from" => "v1.0",
      "to" => "v1.1",
      "changed_requirements" => 3,
      "evidence_records_potentially_affected" => 418,
      "evaluations_require_recalculation" => 2,
      "draft_statements_potentially_affected" => 1
    },
    comparison: {
      "columns" => [
        { "code" => CANONICAL_PROFILE_CODE, "version" => "v1.0", "result" => "READY WITH QUALIFICATION", "requirements" => 15 }
      ],
      "rows" => [
        { "label" => "Treatment continuity", "requirement" => "AE-METH-006", "marks" => ["Review"] },
        { "label" => "Calibration evidence", "requirement" => "AE-METH-008", "marks" => ["Gap"] },
        { "label" => "Model uncertainty", "requirement" => "AE-METH-013", "marks" => ["Pass"] }
      ]
    }
  }
)

upsert(
  ProgramProfile,
  { code: PENDING_PROFILE_CODE },
  {
    slug: "au-methane-intervention-v1-1",
    name: "AU Methane Intervention Evidence",
    status: "Pending",
    profile_version: "v1.1",
    program: profile.program,
    scope: profile.scope,
    methodology: profile.methodology,
    verification_profile: profile.verification_profile,
    evidence_policy: profile.evidence_policy,
    effective_from: Date.new(2026, 9, 1),
    effective_to: nil,
    requirements_digest: "sha256:au-methane-intervention-v1-1-requirements",
    outcome_vocabulary: profile.outcome_vocabulary,
    issuance_policy: profile.issuance_policy,
    limitation_templates: profile.limitation_templates,
    artifact_profile_selection: profile.artifact_profile_selection,
    requirements_count: 15,
    machine_evaluable: 10,
    human_review: 5,
    profile_classes: 3,
    composition: profile.composition,
    version_diff: profile.version_diff,
    version_impact: profile.version_impact,
    comparison: profile.comparison
  }
)

requirements = [
  ["AE-METH-001", "Source identity", "Source", "machine evaluable", ["agevidence.source_record.v1"], "PASS"],
  ["AE-METH-002", "Product lot identity", "Product", "machine evaluable", ["agevidence.source_record.v1"], "PASS"],
  ["AE-METH-003", "Cohort boundary", "Boundary", "machine evaluable", ["agevidence.source_record.v1"], "PASS"],
  ["AE-METH-004", "Intervention identity", "Intervention", "machine evaluable", ["agevidence.intervention_event.v1"], "PASS"],
  ["AE-METH-005", "Dose record completeness", "Intervention", "machine evaluable", ["agevidence.intervention_event.v1"], "PASS"],
  ["AE-METH-006", "Treatment continuity", "Operations", "human review", ["agevidence.operational_event.v1"], "REVIEW"],
  ["AE-METH-007", "Instrument identity", "Observation", "machine evaluable", ["agevidence.observation.v1"], "PASS"],
  ["AE-METH-008", "Calibration evidence", "Observation", "hybrid", ["agevidence.observation.v1"], "GAP"],
  ["AE-METH-009", "Observation period", "Observation", "machine evaluable", ["agevidence.observation.v1"], "PASS"],
  ["AE-METH-010", "Model identity", "Model", "machine evaluable", ["agevidence.model_run.v1"], "PASS"],
  ["AE-METH-011", "Model version", "Model", "machine evaluable", ["agevidence.model_run.v1"], "PASS"],
  ["AE-METH-012", "Baseline provenance", "Model", "hybrid", ["agevidence.model_run.v1", "agevidence.source_record.v1"], "PASS"],
  ["AE-METH-013", "Uncertainty disclosure", "Model", "hybrid", ["agevidence.model_run.v1"], "PASS"],
  ["AE-METH-014", "Correction history", "Governance", "machine evaluable", ["agevidence.operational_event.v1"], "PASS"],
  ["AE-METH-015", "Evidence retention", "Governance", "human review", ["agevidence.source_record.v1"], "NOT APPLICABLE"]
]

profile.requirements.where.not(requirement_code: requirements.map(&:first)).destroy_all
requirements.each do |code, title, category, mode, accepted, state|
  upsert(
    Requirement,
    { requirement_code: code },
    {
      program_profile: profile,
      title: title,
      category: category,
      evaluation_mode: mode,
      status: "Active",
      authority: "#{profile.name} #{profile.profile_version}",
      accepted_evidence: accepted.map { |schema| { "schema" => schema, "result" => state } }
    }
  )
end

upsert(
  EvidenceCase,
  { organization: org, slug: "dit-production-evidence-case" },
  {
    project: main_project,
    case_number: "CASE-AU-00041",
    status: "open",
    metadata_json: JSON.generate({ "profile" => CANONICAL_PROFILE_CODE, "statement" => "AE-AU-000184" })
  }
)

sdk_source = upsert(
  SourceRecord,
  { record_code: "SR-DIT-SDK" },
  {
    organization: org,
    project: main_project,
    source_system: "uDOSE Production",
    document_id: "DIT-SDK-BUNDLE-2026-07",
    evidence_type: "source_record",
    evidence_class: "canonical_sdk_bundle",
    controlled_uri: "evidence://dit-production/sdk/DIT-SDK-BUNDLE-2026-07",
    commitment: "sha256:4f8c114a02ccf3b9",
    disclosure_status: "available",
    status: "validated",
    metadata: { "contract_version" => "source-record.v1", "sdk_version" => "agevidence-sdk-v1" }
  }
)

measurement_source = upsert(
  SourceRecord,
  { record_code: "SR-DIT-MEASUREMENT" },
  {
    organization: org,
    project: main_project,
    source_system: "Measurement Provider",
    document_id: "MP-OBS-828",
    evidence_type: "observation",
    evidence_class: "instrument_record",
    controlled_uri: "evidence://dit-production/measurement/OBS-828",
    commitment: "sha256:8371e0ab7ba8811a",
    disclosure_status: "restricted",
    status: "validated",
    metadata: { "instrument" => "GF-4412", "contract_version" => "source-record.v1" }
  }
)

evidence_rows = [
  ["SRC-PL-443", "Product lot", "source_record", "accepted", "agevidence.source_record.v1", "uDOSE SDK", "2026-08-14 21:04:15", "PROJECTED", "op_pl443", sdk_source, [["Primitive", "SourceRecord", true], ["Lot", "PL-443", true], ["Product", "Methane reducing feed additive", false]], { "type" => "SourceRecord", "external_id" => "dit-src-pl-443", "product_lot" => "PL-443" }],
  ["SRC-C-18", "Animal cohort", "source_record", "accepted", "agevidence.source_record.v1", "uDOSE SDK", "2026-08-14 21:04:16", "PROJECTED", "op_c18", sdk_source, [["Primitive", "SourceRecord", true], ["Cohort", "C-18", true], ["Animals", "143 head", false]], { "type" => "SourceRecord", "external_id" => "dit-src-c-18", "cohort_id" => "C-18" }],
  ["EVT-99231", "Feed intervention delivery", "intervention_event", "accepted", "agevidence.intervention_event.v1", "uDOSE SDK", "2026-08-14 21:04:17", "PROJECTED", "op_bb7c18db", sdk_source, [["Primitive", "InterventionEvent", true], ["Cohort", "C-18", true], ["Lot", "PL-443", true]], { "type" => "InterventionEvent", "external_id" => "dit-evt-99231", "subject" => { "cohort_id" => "C-18" }, "intervention" => { "product_lot" => "PL-443", "delivery" => "dose_record" } }],
  ["OP-22019", "Pump telemetry continuity", "operational_event", "needs_review", "agevidence.operational_event.v1", "uDOSE Production", "2026-08-14 21:04:17", "PROJECTED", "op_22019", sdk_source, [["Primitive", "OperationalEvent", true], ["Pump", "uDOSE-7", true], ["Continuity gap", "4h17m", false]], { "type" => "OperationalEvent", "external_id" => "dit-op-22019", "operation" => { "pump_id" => "uDOSE-7", "continuity_gap" => "PT4H17M" } }],
  ["OBS-828", "Methane measurement", "observation", "accepted", "agevidence.observation.v1", "Measurement Provider", "2026-08-14 21:04:18", "PROJECTED", "op_8371e0ab", measurement_source, [["Primitive", "Observation", true], ["Instrument", "GF-4412", true], ["Reduction", "42.7 tCO2e", false]], { "type" => "Observation", "external_id" => "dit-obs-828", "instrument" => "GF-4412", "measurement" => { "methane_reduction_tco2e" => 42.7 } }],
  ["MR-334", "Modeled reduction", "model_run", "accepted", "agevidence.model_run.v1", "AgEvidence Model Runner", "2026-08-14 21:04:18", "PROJECTED", "op_e1d1280b", measurement_source, [["Primitive", "ModelRun", true], ["Model", "AUS-METHANE-REDUCTION", true], ["Version", "v1.0", true]], { "type" => "ModelRun", "external_id" => "dit-mr-334", "model" => { "name" => "AUS-METHANE-REDUCTION", "version" => "v1.0", "modeled_reduction_tco2e" => 42.7 } }]
]

evidence_rows.each do |code, label, record_type, status, schema_name, source, received_at, result, operation_id, source_record, summary, payload|
  payload = payload.merge(
    "schema" => schema_name,
    "source" => source,
    "received_at" => received_at,
    "workspace" => main_project.project_code
  )
  digest = digest_for(payload)
  upsert(
    EvidenceRecord,
    { record_code: code },
    {
      project: main_project,
      source_record: source_record,
      label: label,
      record_type: record_type,
      status: status,
      schema_name: schema_name,
      source: source,
      received_at: t(received_at),
      projection: schema_name,
      digest: digest,
      inbox_result: result,
      operation_id: operation_id,
      summary: summary.map { |name, value, mono| { "label" => name, "value" => value, "mono" => mono } },
      payload: payload,
      integrity: [
        { "label" => "Canonical encoding", "ok" => true },
        { "label" => "Digest recomputed", "ok" => true },
        { "label" => "Lineage linked", "ok" => true }
      ],
      processing: [
        { "step" => "Received", "ok" => true, "note" => source },
        { "step" => "Schema validation", "ok" => true, "note" => schema_name },
        { "step" => "Canonical projection", "ok" => true, "note" => result }
      ]
    }
  )
end

model_run = upsert(
  ModelRun,
  { run_code: "MR-334" },
  {
    organization: org,
    project: main_project,
    adapter_name: "AUS-METHANE-REDUCTION",
    adapter_version: "v1.0",
    input_commitment: EvidenceRecord.find_by!(record_code: "OBS-828").digest,
    status: "completed",
    started_at: t("2026-08-14 21:04:18"),
    completed_at: t("2026-08-14 21:04:18"),
    failure_reason: nil,
    output: {
      "contract_version" => "model-run-output.v1",
      "modeled_reduction_tco2e" => 42.7,
      "uncertainty" => "carried into qualification"
    },
    metadata: { "evidence_record_code" => "MR-334" }
  }
)

upsert(
  EvidenceCandidate,
  { candidate_code: "EC-AU-00041-1" },
  {
    model_run: model_run,
    evidence_record: EvidenceRecord.find_by!(record_code: "MR-334"),
    candidate_type: "evidence_statement_scope",
    claim: "Methane intervention evidence for PL-443 and C-18",
    confidence: 0.9100,
    status: "review_required",
    basis: [{ "record_code" => "MR-334", "digest" => EvidenceRecord.find_by!(record_code: "MR-334").digest }],
    limitations: [{ "code" => "QUAL-001", "statement" => "Treatment continuity relies on secondary operational evidence for a 4h17m primary telemetry gap." }]
  }
)

upsert(
  Gap,
  { gap_code: "GAP-METH-008" },
  {
    project: main_project,
    requirement_code: "AE-METH-008",
    severity: "medium",
    title: "Calibration evidence requires confirmation",
    explanation: "Instrument GF-4412 identity is present, but calibration effective-period evidence requires confirmation.",
    expected: ["Calibration certificate effective period", "Instrument identity GF-4412"],
    observed: ["Instrument identity present", "Effective period not projected"],
    related_evidence: ["OBS-828"],
    action: "Confirm calibration effective period",
    status: "open",
    blocking: false,
    evidence_record: EvidenceRecord.find_by!(record_code: "OBS-828")
  }
)

review_201 = upsert(
  Review,
  { review_code: "RV-201" },
  {
    project: main_project,
    requirement_code: "AE-METH-006",
    title: "Treatment continuity",
    state: "open"
  }
)

input_digest = digest_for(evidence_rows.map(&:first))
evaluation = upsert(
  Evaluation,
  { evaluation_code: "EVAL-AU-METH-001" },
  {
    program_profile: profile,
    project: main_project,
    project_name: main_project.name,
    outcome: "READY WITH QUALIFICATION",
    satisfied: "12 / 15",
    published: true,
    evaluated_at: t("2026-08-14 21:04:18"),
    input_digest: input_digest,
    profile_version: profile.profile_version,
    status: "current",
    result: {
      "contract_version" => "evaluation-result.v1",
      "plane_status" => "READY WITH QUALIFICATION",
      "last_trigger" => "EVT-99231",
      "affected_requirements" => %w[AE-METH-004 AE-METH-005 AE-METH-006 AE-METH-014],
      "counts" => { "PASS" => 12, "REVIEW" => 1, "GAP" => 1, "NOT APPLICABLE" => 1 },
      "requirements" => requirements.map { |code, title, _category, mode, _accepted, state| { "code" => code, "title" => title, "mode" => mode, "state" => state } }
    }
  }
)

determination = upsert(
  Determination,
  { determination_code: "DET-AU-000184" },
  {
    program_profile: profile,
    project: main_project,
    evaluation: evaluation,
    project_name: main_project.name,
    outcome: "SUPPORTED WITH QUALIFICATION",
    adapter: "#{profile.code} #{profile.profile_version}",
    digest: digest_for(["DET-AU-000184", evaluation.input_digest]),
    published_at: t("2026-08-14 21:04:19"),
    status: "published",
    result: {
      "contract_version" => "determination-result.v1",
      "decision" => "SUPPORTED WITH QUALIFICATION",
      "rationale" => "Secondary flow meter and operator event evidence support treatment continuity during the primary telemetry gap.",
      "qualification" => "Primary pump telemetry was unavailable for 4h17m; continuity is supported by secondary operational evidence.",
      "reviewer" => "Emma Clarke",
      "timestamp" => "2026-08-14T21:04:19Z",
      "evidence_basis" => ["EVT-99231", "OP-22019", "OBS-828", "MR-334"],
      "limitations" => [
        { "code" => "QUAL-001", "statement" => "Primary pump telemetry was unavailable for 4h17m; continuity is supported by secondary operational evidence.", "basis" => "RV-201" }
      ]
    }
  }
)

statement_payload = {
  "object" => "evidence_statement",
  "id" => "AE-AU-000184",
  "status" => "ready_with_qualification",
  "schema" => "agevidence.evidence_statement.v1",
  "scope" => "Methane intervention evidence",
  "period" => "12 Jun - 19 Jul 2026",
  "profile" => { "name" => profile.name, "code" => profile.code, "version" => profile.profile_version },
  "evaluation" => { "code" => evaluation.evaluation_code, "status" => evaluation.outcome },
  "determination" => { "code" => determination.determination_code, "decision" => determination.outcome },
  "evidence_records" => 418,
  "human_determinations" => 1,
  "qualifications" => 1
}
statement_digest = digest_for(statement_payload)

statement_184 = upsert(
  Artifact,
  { artifact_code: "AE-AU-000184" },
  {
    project: main_project,
    claim: "Methane intervention evidence",
    boundary: "PL-443 / C-18 / 12 Jun - 19 Jul 2026",
    jurisdiction: "Australia",
    program: "#{profile.name} #{profile.profile_version}",
    digest: statement_digest,
    status: "ready_with_qualification",
    issued: false,
    issued_at: nil,
    created_at: t("2026-08-14 21:04:20"),
    updated_at: t("2026-08-14 21:04:20"),
    artifact: statement_payload.merge("digest" => statement_digest),
    integrity: [
      { "label" => "Statement digest", "ok" => true },
      { "label" => "Canonical encoding", "ok" => true },
      { "label" => "Receipt chain", "ok" => true },
      { "label" => "Signature valid", "ok" => false }
    ],
    limitations: [
      { "id" => "QUAL-001", "title" => "Treatment continuity", "detail" => "Primary pump telemetry was unavailable for 4h17m; continuity is supported by secondary operational evidence." }
    ],
    receipt_chain: [
      { "label" => "Evidence", "digest" => input_digest },
      { "label" => "Evaluation", "digest" => evaluation.input_digest },
      { "label" => "Determination", "digest" => determination.digest },
      { "label" => "Statement", "digest" => statement_digest }
    ]
  }
)

[
  ["AE-AU-000179", "Q2 evidence", "issued", true, "2026-08-10 16:30:00"],
  ["AE-AU-000171", "Previous period", "superseded", true, "2026-07-31 09:10:00"],
  ["AE-AU-000166", "Earlier production run", "revoked", true, "2026-07-14 11:45:00"]
].each do |code, scope, status, issued, issued_at|
  payload = {
    "object" => "evidence_statement",
    "id" => code,
    "status" => status,
    "schema" => "agevidence.evidence_statement.v1",
    "scope" => scope,
    "profile" => { "name" => profile.name, "code" => profile.code, "version" => profile.profile_version }
  }
  digest = digest_for(payload)
  upsert(
    Artifact,
    { artifact_code: code },
    {
      project: main_project,
      claim: scope,
      boundary: "DIT Production Evidence",
      jurisdiction: "Australia",
      program: "#{profile.name} #{profile.profile_version}",
      digest: digest,
      status: status,
      issued: issued,
      issued_at: t(issued_at),
      issued_by_user: admin,
      created_at: t(issued_at),
      updated_at: t(issued_at),
      artifact: payload.merge("digest" => digest),
      integrity: [
        { "label" => "Statement digest", "ok" => true },
        { "label" => "Signature valid", "ok" => true }
      ],
      limitations: [],
      receipt_chain: [{ "label" => "Statement", "digest" => digest }]
    }
  )
end

upsert(
  VerifierResult,
  { result_code: "VR-SEED-184" },
  {
    organization: org,
    project: main_project,
    artifact: statement_184,
    contract_version: "verifier-result.v1",
    verifier_name: "AgEvidence verifier",
    verifier_version: "v1",
    status: "pending_external_verifier",
    artifact_digest: statement_184.digest,
    checked_at: t("2026-08-14 21:04:20"),
    checks: [
      { "code" => "statement_digest", "status" => "passed" },
      { "code" => "canonical_encoding", "status" => "passed" },
      { "code" => "receipt_chain", "status" => "passed" },
      { "code" => "signature", "status" => "pending" }
    ],
    result: { "statement" => "Statement is internally consistent and ready for issue." },
    metadata: {}
  }
)

upsert(
  RelianceEvent,
  { event_code: "REL-SEED-179" },
  {
    organization: org,
    project: main_project,
    artifact: Artifact.find_by!(artifact_code: "AE-AU-000179"),
    relying_party: "Recipient application",
    relying_party_role: "recipient",
    reliance_kind: "assurance",
    status: "recorded",
    occurred_at: t("2026-08-14 22:15:00"),
    recorded_by_user: admin,
    basis: { "statement_code" => "AE-AU-000179", "terms" => "Seeded statement verification" },
    metadata: { "contract_version" => "reliance-event.v1" }
  }
)

[
  ["act-001", "2026-08-14 21:04:17", "uDOSE SDK", "partner", "InterventionEvent EVT-99231 received", "Feed intervention delivery linked to PL-443 and C-18.", "success"],
  ["act-002", "2026-08-14 21:04:17", "Evidence Plane", "system", "Schema validation passed", "agevidence.intervention_event.v1 accepted.", "success"],
  ["act-003", "2026-08-14 21:04:18", "Evidence Plane", "system", "Canonical evidence projected", "EVT-99231 projected into the tenant evidence workspace.", "success"],
  ["act-004", "2026-08-14 21:04:18", "Evidence Plane", "system", "4 dependent requirements identified", "AE-METH-004, AE-METH-005, AE-METH-006, AE-METH-014.", "info"],
  ["act-005", "2026-08-14 21:04:18", "Evidence Plane", "system", "AU Methane Intervention v1 reevaluated", "Continuous evaluation updated EVAL-AU-METH-001.", "info"],
  ["act-006", "2026-08-14 21:04:18", "Evidence Plane", "system", "AE-METH-006 Treatment continuity", "PASS -> REVIEW", "warning"],
  ["act-007", "2026-08-14 21:04:19", "Emma Clarke", "human", "Determination recorded", "SUPPORTED WITH QUALIFICATION for treatment continuity.", "success"],
  ["act-008", "2026-08-14 21:04:20", "Evidence Plane", "system", "Evidence Statement generated", "AE-AU-000184 ready with qualification.", "success"]
].each do |code, at, actor, actor_kind, title, detail, tone|
  upsert(Activity, { activity_code: code }, { project: main_project, occurred_at: t(at), actor: actor, actor_kind: actor_kind, title: title, detail: detail, tone: tone })
end

[
  ["LOG-001", "POST", "/api/v1/evidence", 201, 118, "2026-08-14 21:04:17", "op_bb7c18db", { "type" => "InterventionEvent", "schema" => "agevidence.intervention_event.v1" }, { "accepted" => true, "record_code" => "EVT-99231" }],
  ["LOG-002", "GET", "/api/v1/evidence/EVT-99231", 200, 82, "2026-08-14 21:04:18", "op_get_evt_99231", { "record_code" => "EVT-99231" }, { "accepted" => true }],
  ["LOG-003", "GET", "/api/v1/evaluations", 200, 44, "2026-08-14 21:04:18", "op_eval_index", { "profile" => CANONICAL_PROFILE_CODE }, { "count" => 1 }],
  ["LOG-004", "POST", "/api/v1/statements/AE-AU-000184/shares", 201, 96, "2026-08-14 21:04:21", "op_share_184", { "access_level" => "statement_and_summary" }, { "created" => true }]
].each do |code, method, endpoint, status, duration, at, operation, request, response|
  upsert(ApiLog, { log_code: code }, { organization: org, method: method, endpoint: endpoint, status: status, duration_ms: duration, occurred_at: t(at), operation_id: operation, request: request, response: response, trace: [{ "step" => "received", "ok" => true }, { "step" => "processed", "ok" => status < 400 }] })
end

webhook_events = [
  "evidence.accepted",
  "evidence.rejected",
  "evaluation.updated",
  "evaluation.gap_opened",
  "review.required",
  "review.completed",
  "determination.recorded",
  "statement.ready",
  "statement.issued",
  "statement.superseded",
  "statement.revoked",
  "program_profile.updated",
  "integrity.failed",
  "integrity.restored"
]

endpoint_one = upsert(WebhookEndpoint, { endpoint_code: "WH-001" }, { organization: org, url: "https://ditagtech.example/webhooks/agevidence", status: "HEALTHY", events: webhook_events })
endpoint_two = upsert(WebhookEndpoint, { endpoint_code: "WH-002" }, { organization: org, url: "https://ditagtech.example/webhooks/retry", status: "ATTENTION", events: ["evaluation.updated", "statement.ready", "integrity.failed"] })

[
  [endpoint_one, "DEL-001", 1, 3, 200, 91, "2026-08-14 21:04:20", { "ok" => true }],
  [endpoint_two, "DEL-002", 2, 3, 500, 1418, "2026-08-14 21:04:21", { "error" => "retrying" }]
].each do |endpoint, code, attempt, max, status, duration, at, response|
  upsert(WebhookDelivery, { delivery_code: code }, { webhook_endpoint: endpoint, attempt: attempt, max_attempts: max, status: status, duration_ms: duration, delivered_at: t(at), response: response, timeline: [{ "label" => "queued", "status" => 200 }, { "label" => "delivered", "status" => status }] })
end

[
  ["INT-001", "uDOSE Production", "DIT AgTech", "HEALTHY", 1, "2026-08-14 21:04:18", ["SourceRecord", "InterventionEvent", "OperationalEvent"]],
  ["INT-002", "Measurement Provider", "Measurement Provider", "HEALTHY", 1, "2026-08-14 21:04:18", ["Observation"]],
  ["INT-003", "AgEvidence Model Runner", "AgEvidence", "HEALTHY", 1, "2026-08-14 21:04:18", ["ModelRun"]]
].each do |code, name, provider, status, count, last, events|
  upsert(Integration, { integration_code: code }, { organization: org, name: name, provider: provider, status: status, projects_count: count, last_sync_at: t(last), events: events })
end

EvidenceSchema.where.not(name: [
  "agevidence.source_record.v1",
  "agevidence.intervention_event.v1",
  "agevidence.operational_event.v1",
  "agevidence.observation.v1",
  "agevidence.model_run.v1",
  "agevidence.evidence_statement.v1"
]).destroy_all

[
  ["SCH-001", "agevidence.source_record.v1", "1.0", 2, "Active"],
  ["SCH-002", "agevidence.intervention_event.v1", "1.0", 1, "Active"],
  ["SCH-003", "agevidence.operational_event.v1", "1.0", 1, "Active"],
  ["SCH-004", "agevidence.observation.v1", "1.0", 1, "Active"],
  ["SCH-005", "agevidence.model_run.v1", "1.0", 1, "Active"],
  ["SCH-006", "agevidence.evidence_statement.v1", "1.0", 4, "Active"]
].each do |code, name, version, events, status|
  upsert(EvidenceSchema, { schema_code: code }, { name: name, version: version, events_count: events, status: status })
end

[
  ["KEY-001", "Production SDK integration", "agev_live_demo_7f91", "agev_live_...7f91", "Active", "2026-08-14 21:04:21", ["evidence:create", "evidence:read", "evaluations:read", "reviews:read", "program_profiles:read", "statements:read", "statements:share", "schemas:read", "source_records:create", "source_records:read", "artifacts:read", "artifacts:verify", "reliance_events:create"]],
  ["KEY-002", "Verifier sandbox", "agev_test_demo_2a10", "agev_test_...2a10", "Active", "2026-08-14 21:04:20", ["statements:read", "artifacts:read", "artifacts:verify", "schemas:read", "reliance_events:create"]]
].each do |code, name, token, hint, status, last, scopes|
  upsert(ApiKey, { key_code: code }, { organization: org, name: name, token_hint: hint, token_digest: ApiKey.digest_token(token), scopes: scopes, status: status, last_used_at: t(last) })
end

upsert(
  Invitation,
  { token: "demo-reviewer-invite" },
  {
    organization: org,
    email: "review.partner@agevidence.example",
    role: reviewer_role,
    invited_by_user: admin,
    status: "pending",
    expires_at: 7.days.from_now,
    accepted_at: nil
  }
)
