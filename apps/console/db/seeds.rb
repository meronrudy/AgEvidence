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

def token_hint_for(token)
  "#{token.first(10)}...#{token.last(4)}"
end

def ensure_api_key!(organization:, key_code:, name:, token:, scopes:)
  digest = ApiKey.digest_token(token)
  key = ApiKey.find_by(key_code: key_code) || ApiKey.find_by(token_digest: digest) || ApiKey.new
  key.assign_attributes(
    key_code: key_code,
    organization: organization,
    name: name,
    token_digest: digest,
    token_hint: token_hint_for(token),
    scopes: scopes,
    status: "Active",
    revoked_at: nil
  )
  key.save!
  key
end

def ensure_membership!(user:, organization:, role:)
  membership = OrganizationMembership.find_or_initialize_by(user: user, organization: organization)
  membership.role = role
  membership.status = "active"
  membership.joined_at ||= Time.current
  membership.save!
  membership
end

def ensure_requirement!(profile, code, title, category:, accepted:)
  upsert(
    Requirement,
    { requirement_code: code },
    {
      program_profile: profile,
      title: title,
      category: category,
      evaluation_mode: "machine",
      status: "Active",
      authority: profile.program,
      accepted_evidence: accepted
    }
  )
end

def ensure_activity!(project, code, at, title, tone: "neutral", actor: "AgEvidence", detail: nil)
  upsert(
    Activity,
    { activity_code: code },
    {
      project: project,
      occurred_at: t(at),
      actor: actor,
      actor_kind: actor == "AgEvidence" ? "system" : "human",
      title: title,
      detail: detail,
      tone: tone
    }
  )
end

def ensure_artifact!(artifact_code, attrs)
  artifact = Artifact.find_or_initialize_by(artifact_code: artifact_code)
  return artifact if artifact.persisted? && artifact.issued?

  artifact.assign_attributes(attrs)
  artifact.save!
  artifact
end

dit_org = upsert(
  Organization,
  { name: "DIT AgTech" },
  {
    environment: "Production",
    deployment_mode: "shared_managed",
    brand_name: "AgEvidence",
    legal_entity_name: "DIT AgTech",
    default_currency: "USD",
    default_locale: "en"
  }
)

Role.default_roles_for_organization(dit_org)
admin_role = dit_org.role(:org_admin)
reviewer_role = dit_org.role(:reviewer)

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

ensure_membership!(user: admin, organization: dit_org, role: admin_role)

ensure_api_key!(
  organization: dit_org,
  key_code: "KEY-001",
  name: "DIT production server key",
  token: "agev_live_demo_7f91",
  scopes: ["*"]
)
ensure_api_key!(
  organization: dit_org,
  key_code: "agev_test_demo_2a10",
  name: "DIT verification test key",
  token: "agev_test_demo_2a10",
  scopes: ["statements:read", "artifacts:read", "artifacts:verify", "schemas:read", "reliance_events:create"]
)

dit_project = upsert(
  Project,
  { project_code: "PRJ-AU-00041" },
  {
    organization: dit_org,
    slug: "dit-production",
    name: "DIT Production Evidence",
    jurisdiction: "Australia",
    program: "Methane intervention",
    scope: "Scope 3",
    readiness: 82,
    status: "In review",
    status_tone: "info",
    open_gaps: 2,
    critical_gaps: 0,
    review_status: "2 open",
    artifact_status: "Ready with qualification",
    last_activity_at: t("2026-08-07T09:44:00Z"),
    metadata: { "trial" => "uDOSE", "product_lot" => "PL-443", "cohort" => "C-18" }
  }
)

au_profile = upsert(
  ProgramProfile,
  { code: CANONICAL_PROFILE_CODE },
  {
    slug: "au-methane-intervention-v1",
    name: "AU Methane Intervention",
    status: "Operational",
    profile_version: "v1.0",
    program: "Agricultural Climate Evidence",
    scope: "Australia methane intervention",
    methodology: "AU livestock methane intervention",
    verification_profile: "AgEvidence placeholder verifier",
    evidence_policy: "controlled source commitments",
    requirements_count: 15,
    machine_evaluable: 10,
    human_review: 5,
    profile_classes: 3,
    effective_from: Date.new(2026, 1, 1),
    requirements_digest: digest_for(%w[AE-METH-001 AE-METH-015]),
    outcome_vocabulary: ["Eligible", "Eligible with conditions", "Not eligible"],
    issuance_policy: { "human_review_required" => true },
    limitation_templates: [{ "code" => "LIM-AU", "statement" => "Bounded to supplied records." }],
    artifact_profile_selection: "au_methane_statement",
    composition: [{ "layer" => "Evidence", "name" => "Source records" }],
    version_diff: [],
    version_impact: {},
    comparison: {
      "columns" => [
        { "code" => CANONICAL_PROFILE_CODE, "label" => "AU v1.0" },
        { "code" => PENDING_PROFILE_CODE, "label" => "AU v1.1" }
      ]
    }
  }
)

pending_profile = upsert(
  ProgramProfile,
  { code: PENDING_PROFILE_CODE },
  {
    slug: "au-methane-intervention-v1-1",
    name: "AU Methane Intervention",
    status: "Pending",
    profile_version: "v1.1",
    program: "Agricultural Climate Evidence",
    scope: "Australia methane intervention",
    methodology: "AU livestock methane intervention",
    verification_profile: "AgEvidence placeholder verifier",
    evidence_policy: "controlled source commitments",
    requirements_count: 16,
    machine_evaluable: 11,
    human_review: 5,
    profile_classes: 3,
    effective_from: Date.new(2026, 10, 1),
    requirements_digest: digest_for(%w[AE-METH-001 AE-METH-016]),
    outcome_vocabulary: ["Eligible", "Eligible with conditions", "Not eligible"],
    issuance_policy: { "human_review_required" => true },
    limitation_templates: [],
    artifact_profile_selection: "au_methane_statement",
    composition: [],
    version_diff: [],
    version_impact: {},
    comparison: {}
  }
)

15.times do |index|
  ensure_requirement!(
    au_profile,
    "AE-METH-#{(index + 1).to_s.rjust(3, '0')}",
    "Methane intervention requirement #{index + 1}",
    category: index < 8 ? "Evidence" : "Review",
    accepted: index.zero? ? ["agevidence.intervention_event.v1"] : ["agevidence.source_record.v1", "agevidence.observation.v1"]
  )
end

ensure_requirement!(pending_profile, "AE-METH-016", "Pending profile delta", category: "Evidence", accepted: ["agevidence.delta.v1"])

upsert(
  ArtifactProfile,
  { profile_code: "au_methane_statement", profile_version: "v1" },
  {
    program_profile: au_profile,
    status: "active",
    layout: { "title" => "Evidence Statement" },
    recipient_rules: { "default_access" => "statement_and_summary" },
    retention: { "years" => 7 }
  }
)

source = upsert(
  SourceRecord,
  { record_code: "SR-DIT-SDK" },
  {
    organization: dit_org,
    project: dit_project,
    source_system: "uDOSE SDK",
    document_id: "DOC-DIT-SDK-001",
    evidence_type: "intervention_event",
    evidence_class: "controlled_source",
    controlled_uri: "https://sources.example/DOC-DIT-SDK-001",
    commitment: "sha256:#{'a' * 32}",
    disclosure_status: "available",
    status: "received",
    metadata: { "restricted_reason" => "internal_only" }
  }
)

[
  ["SRC-PL-443", "Product lot", "source_record", "agevidence.source_record.v1", { "product_lot" => "PL-443" }],
  ["SRC-C-18", "Animal cohort", "source_record", "agevidence.source_record.v1", { "cohort" => "C-18" }],
  ["EVT-99231", "Intervention event", "intervention_event", "agevidence.intervention_event.v1", { "event_type" => "product_lot", "product_lot" => "PL-443" }],
  ["OP-22019", "Feeding operation", "operational_event", "agevidence.operational_event.v1", { "operation_id" => "OP-22019" }],
  ["OBS-828", "Methane observation", "observation", "agevidence.observation.v1", { "instrument" => "GF-4412", "value" => 42 }],
  ["MR-334", "Model run projection", "model_run", "agevidence.model_run.v1", { "model" => "AUS-LIVESTOCK-ME" }]
].each_with_index do |(code, label, type, schema, payload), index|
  upsert(
    EvidenceRecord,
    { record_code: code },
    {
      project: dit_project,
      source_record: code == "EVT-99231" ? source : nil,
      label: label,
      record_type: type,
      status: "accepted",
      schema_name: schema,
      source: "uDOSE SDK",
      received_at: t("2026-08-07T0#{index}:00:00Z"),
      projection: "agevidence.seed_projection.v0",
      digest: digest_for(payload),
      inbox_result: "Accepted",
      operation_id: "op-#{code.downcase}",
      summary: [{ "label" => "Record", "value" => code, "mono" => true }],
      payload: payload,
      integrity: [{ "label" => "Digest valid", "ok" => true }],
      processing: [{ "step" => "seed", "ok" => true }]
    }
  )
end

model_run = upsert(
  ModelRun,
  { run_code: "RUN-AU-00041" },
  {
    organization: dit_org,
    project: dit_project,
    adapter_name: "AUS-LIVESTOCK-ME",
    adapter_version: "v0.9",
    input_commitment: "sha256:seededinput0001",
    status: "completed",
    started_at: t("2026-08-07T06:00:00Z"),
    completed_at: t("2026-08-07T06:01:00Z"),
    output: { "ok" => true },
    metadata: {}
  }
)

upsert(
  EvidenceCandidate,
  { candidate_code: "EC-AU-00041-1" },
  {
    model_run: model_run,
    evidence_record: EvidenceRecord.find_by!(record_code: "MR-334"),
    candidate_type: "bounded_statement",
    claim: "Methane intervention evidence supports qualified statement issuance.",
    confidence: 0.87,
    status: "review_required",
    basis: [{ "record_code" => "MR-334" }],
    limitations: []
  }
)

upsert(
  Gap,
  { gap_code: "GAP-AU-001" },
  {
    project: dit_project,
    evidence_record: EvidenceRecord.find_by!(record_code: "OBS-828"),
    requirement_code: "AE-METH-008",
    severity: "medium",
    title: "Calibration evidence requires attention",
    explanation: "Calibration support is present but needs human review.",
    expected: ["calibration certificate"],
    observed: ["instrument reference"],
    related_evidence: ["OBS-828"],
    action: "Review calibration support",
    status: "open",
    blocking: false
  }
)

%w[RV-201 RV-202].each_with_index do |code, index|
  upsert(
    Review,
    { review_code: code },
    {
      project: dit_project,
      requirement_code: "AE-METH-00#{index + 8}",
      title: index.zero? ? "Artifact limitation wording" : "Calibration continuity",
      state: "open"
    }
  )
end

evaluation = upsert(
  Evaluation,
  { evaluation_code: "EVAL-AU-METH-001" },
  {
    program_profile: au_profile,
    project: dit_project,
    project_name: dit_project.name,
    outcome: "Eligible with conditions",
    satisfied: "13 / 15",
    published: true,
    evaluated_at: t("2026-08-07T07:30:00Z"),
    input_digest: "sha256:seeded-evaluation-input",
    profile_version: au_profile.profile_version,
    status: "current",
    result: {
      "contract_version" => "evaluation-result.v0",
      "satisfied_requirement_codes" => ["AE-METH-001"],
      "unsatisfied_requirement_codes" => ["AE-METH-008"]
    }
  }
)

determination = upsert(
  Determination,
  { determination_code: "DET-AU-000184" },
  {
    program_profile: au_profile,
    project: dit_project,
    evaluation: evaluation,
    project_name: dit_project.name,
    outcome: "Eligible with conditions",
    adapter: "#{au_profile.code} #{au_profile.profile_version}",
    digest: "sha256:seeded-determination",
    published_at: t("2026-08-07T08:00:00Z"),
    status: "published",
    result: {
      "contract_version" => "determination-result.v0",
      "limitations" => [
        { "code" => "LIM-01", "statement" => "Bounded to supplied DIT source records.", "basis" => "DET-AU-000184", "detail" => "Secondary evidence supports treatment continuity." }
      ]
    }
  }
)

manifest = {
  "contract_version" => "artifact-manifest.v0",
  "artifact_code" => "AE-AU-000184",
  "project" => { "project_code" => dit_project.project_code, "name" => dit_project.name },
  "determination" => { "determination_code" => determination.determination_code, "digest" => determination.digest },
  "limitations" => determination.result.fetch("limitations"),
  "receipt_chain" => [{ "label" => "Determination", "digest" => determination.digest }]
}
manifest["digest"] = digest_for(manifest)

artifact = ensure_artifact!(
  "AE-AU-000184",
  project: dit_project,
  claim: determination.outcome,
  boundary: "#{dit_project.name} / #{dit_project.scope}",
  jurisdiction: dit_project.jurisdiction,
  program: "#{au_profile.program} #{au_profile.profile_version}",
  digest: manifest.fetch("digest"),
  status: "issued",
  issued: true,
  issued_at: t("2026-08-07T08:30:00Z"),
  issued_by_user: admin,
  contract_version: "artifact-manifest.v0",
  artifact: manifest,
  integrity: [{ "label" => "Artifact digest valid", "ok" => true }],
  limitations: manifest.fetch("limitations"),
  receipt_chain: manifest.fetch("receipt_chain")
)

draft_manifest = manifest.merge("artifact_code" => "AE-AU-000179")
ensure_artifact!(
  "AE-AU-000179",
  project: dit_project,
  claim: "Draft methane evidence statement",
  boundary: "#{dit_project.name} / #{dit_project.scope}",
  jurisdiction: dit_project.jurisdiction,
  program: "#{au_profile.program} #{au_profile.profile_version}",
  digest: digest_for(draft_manifest),
  status: "issued",
  issued: true,
  issued_at: t("2026-08-06T08:30:00Z"),
  issued_by_user: admin,
  contract_version: "artifact-manifest.v0",
  artifact: draft_manifest,
  integrity: [{ "label" => "Artifact digest valid", "ok" => true }],
  limitations: manifest.fetch("limitations"),
  receipt_chain: manifest.fetch("receipt_chain")
)

upsert(
  VerifierResult,
  { result_code: "VR-AU-000184" },
  {
    organization: dit_org,
    project: dit_project,
    artifact: artifact,
    contract_version: "verifier-result.v0",
    verifier_name: "AgEvidence placeholder verifier",
    verifier_version: "v0",
    status: "locally_consistent",
    artifact_digest: artifact.digest,
    checked_at: t("2026-08-07T08:31:00Z"),
    checks: [{ "label" => "Digest recomputed", "ok" => true }],
    result: { "statement" => "AgEvidence internal placeholder only; no independent verifier was invoked." },
    metadata: {}
  }
)

upsert(
  RelianceEvent,
  { event_code: "REL-AU-000184" },
  {
    organization: dit_org,
    project: dit_project,
    artifact: artifact,
    relying_party: "Recipient application",
    relying_party_role: "recipient",
    reliance_kind: "assurance",
    status: "recorded",
    occurred_at: t("2026-08-07T09:00:00Z"),
    basis: { "artifact_code" => artifact.artifact_code },
    metadata: {}
  }
)

endpoint = upsert(
  WebhookEndpoint,
  { endpoint_code: "WH-DIT-001" },
  {
    organization: dit_org,
    url: "https://dit.example/webhooks/agevidence",
    status: "Active",
    events: ["statement.issued", "reliance.recorded"]
  }
)
upsert(
  WebhookDelivery,
  { delivery_code: "DEL-002" },
  {
    webhook_endpoint: endpoint,
    attempt: 1,
    max_attempts: 3,
    status: 500,
    duration_ms: 120,
    delivered_at: t("2026-08-07T09:05:00Z"),
    response: { "status" => 500 },
    timeline: [{ "label" => "Delivery failed", "status" => 500, "ok" => false }]
  }
)

upsert(
  Integration,
  { integration_code: "INT-DIT-UDOSE" },
  {
    organization: dit_org,
    name: "uDOSE Production",
    provider: "uDOSE",
    status: "Connected",
    projects_count: 1,
    last_sync_at: t("2026-08-07T09:10:00Z"),
    events: ["source_record.created"]
  }
)

%w[
  artifact-manifest.v0
  verifier-result.v0
  webhook-envelope.v0
  error-response.v0
].each do |version|
  upsert(
    EvidenceSchema,
    { schema_code: version },
    {
      name: version,
      version: version,
      events_count: 1,
      status: "Active"
    }
  )
end

upsert(
  EvidenceCase,
  { case_number: "CASE-DIT-001", organization: dit_org },
  {
    project: dit_project,
    slug: "dit-production-case",
    status: "open",
    metadata_json: "{}"
  }
)

upsert(
  Invitation,
  { token: "demo-reviewer-invite" },
  {
    organization: dit_org,
    invited_by_user: admin,
    role: reviewer_role,
    email: "reviewer@example.com",
    expires_at: 30.days.from_now,
    status: "pending"
  }
)

ensure_activity!(dit_project, "ACT-DIT-001", "2026-08-07T09:30:00Z", "Artifact AE-AU-000184 verified", tone: "success")
ensure_activity!(dit_project, "ACT-DIT-002", "2026-08-07T08:45:00Z", "Review queue updated", tone: "warning")

earthodic_org = upsert(
  Organization,
  { name: "Earthodic Demo" },
  {
    environment: "Sandbox",
    portfolio_product_pack: "earthodic",
    portfolio_product_pack_version: "1.0.0",
    deployment_mode: "shared_managed",
    brand_name: "Biobarc Qualification",
    brand_domain: "qualification.earthodic.com",
    support_email: "support@earthodic.example",
    legal_entity_name: "Earthodic",
    default_currency: "AUD",
    default_locale: "en-AU"
  }
)
Role.default_roles_for_organization(earthodic_org)
ensure_membership!(user: admin, organization: earthodic_org, role: earthodic_org.role(:org_admin))

ensure_api_key!(
  organization: earthodic_org,
  key_code: "KEY-EARTHODIC-001",
  name: "Earthodic demo server key",
  token: "earthodic_demo_2026",
  scopes: ["*"]
)

upsert(
  DomainMapping,
  { hostname: "qualification.earthodic.com" },
  {
    organization: earthodic_org,
    status: "verified",
    verified_at: t("2026-08-20T00:00:00Z"),
    primary: true
  }
)

earthodic_application = upsert(
  ProgramProfile,
  { code: "earthodic.application.v1" },
  {
    slug: "earthodic-application-v1",
    name: "Earthodic Application Qualification",
    status: "Operational",
    profile_version: "v1",
    program: "Earthodic Qualification Cloud",
    scope: "Biobarc application qualification",
    methodology: "Material application qualification",
    verification_profile: "AgEvidence placeholder verifier",
    evidence_policy: "controlled external objects and commitments",
    requirements_count: 4,
    machine_evaluable: 3,
    human_review: 1,
    profile_classes: 2,
    effective_from: Date.new(2026, 8, 20),
    requirements_digest: digest_for(%w[EARTH-APP-001 EARTH-APP-004]),
    outcome_vocabulary: ["Qualified", "Qualified with conditions", "Not qualified"],
    issuance_policy: { "human_review_required" => true },
    limitation_templates: [{ "code" => "E-LIM-01", "statement" => "Bounded to supplied converter and lab records." }],
    artifact_profile_selection: "application_qualification_pack",
    composition: [{ "layer" => "Material", "name" => "Application evidence" }],
    version_diff: [],
    version_impact: {},
    comparison: { "columns" => [{ "code" => "earthodic.application.v1", "label" => "Application v1" }] }
  }
)

earthodic_recyclability = upsert(
  ProgramProfile,
  { code: "earthodic.recyclability.v1" },
  {
    slug: "earthodic-recyclability-v1",
    name: "Earthodic Recyclability Claim",
    status: "Operational",
    profile_version: "v1",
    program: "Earthodic Qualification Cloud",
    scope: "Recyclability claim evidence",
    methodology: "Claim substantiation",
    verification_profile: "AgEvidence placeholder verifier",
    evidence_policy: "controlled external objects and commitments",
    requirements_count: 3,
    machine_evaluable: 2,
    human_review: 1,
    profile_classes: 2,
    effective_from: Date.new(2026, 8, 20),
    requirements_digest: digest_for(%w[EARTH-REC-001 EARTH-REC-003]),
    outcome_vocabulary: ["Supported", "Supported with limitations", "Not supported"],
    issuance_policy: { "human_review_required" => true },
    limitation_templates: [],
    artifact_profile_selection: "batch_claim_passport",
    composition: [],
    version_diff: [],
    version_impact: {},
    comparison: {}
  }
)

earthodic_maintenance = upsert(
  ProgramProfile,
  { code: "earthodic.maintenance.v1" },
  {
    slug: "earthodic-maintenance-v1",
    name: "Earthodic Qualification Maintenance",
    status: "Operational",
    profile_version: "v1",
    program: "Earthodic Qualification Cloud",
    scope: "Maintained qualification delta",
    methodology: "Qualification delta review",
    verification_profile: "AgEvidence placeholder verifier",
    evidence_policy: "controlled external objects and commitments",
    requirements_count: 2,
    machine_evaluable: 1,
    human_review: 1,
    profile_classes: 1,
    effective_from: Date.new(2026, 8, 20),
    requirements_digest: digest_for(%w[EARTH-MTN-001 EARTH-MTN-002]),
    outcome_vocabulary: ["Maintained", "Changed", "Not maintained"],
    issuance_policy: { "human_review_required" => true },
    limitation_templates: [],
    artifact_profile_selection: "qualification_delta",
    composition: [],
    version_diff: [],
    version_impact: {},
    comparison: {}
  }
)

[
  [earthodic_application, "EARTH-APP-001", "Product lot identity", "Source", ["earthodic.product_lot.v1"]],
  [earthodic_application, "EARTH-APP-002", "Converter configuration", "Source", ["earthodic.converter_configuration.v1"]],
  [earthodic_application, "EARTH-APP-003", "Coating run observations", "Observation", ["earthodic.coating_run.v1"]],
  [earthodic_application, "EARTH-APP-004", "Laboratory result commitment", "Observation", ["earthodic.laboratory_observation.v1"]],
  [earthodic_recyclability, "EARTH-REC-001", "Batch identity", "Source", ["earthodic.product_lot.v1"]],
  [earthodic_recyclability, "EARTH-REC-002", "Recyclability observation", "Observation", ["earthodic.recyclability_observation.v1"]],
  [earthodic_recyclability, "EARTH-REC-003", "Claim boundary", "Review", ["earthodic.claim_boundary.v1"]],
  [earthodic_maintenance, "EARTH-MTN-001", "Prior qualification", "Source", ["earthodic.prior_qualification.v1"]],
  [earthodic_maintenance, "EARTH-MTN-002", "Material/process delta", "Review", ["earthodic.qualification_delta.v1"]]
].each do |profile, code, title, category, accepted|
  ensure_requirement!(profile, code, title, category: category, accepted: accepted)
end

[
  [earthodic_application, "application_qualification_pack", "v1"],
  [earthodic_recyclability, "batch_claim_passport", "v1"],
  [earthodic_maintenance, "qualification_delta", "v1"]
].each do |profile, code, version|
  upsert(
    ArtifactProfile,
    { profile_code: code, profile_version: version },
    {
      program_profile: profile,
      status: "active",
      layout: { "issuer_name" => "Earthodic", "product_name" => "Biobarc Qualification" },
      recipient_rules: { "default_access" => "statement_and_summary" },
      retention: { "years" => 7 }
    }
  )
end

earth_project = upsert(
  Project,
  { project_code: "PRJ-EARTH-APP-001" },
  {
    organization: earthodic_org,
    slug: "earthodic-application-demo",
    name: "Biobarc Application Qualification Demo",
    jurisdiction: "Australia",
    program: "Earthodic Qualification Cloud",
    scope: "Application qualification",
    readiness: 90,
    status: "Ready",
    status_tone: "success",
    open_gaps: 0,
    critical_gaps: 0,
    review_status: "Complete",
    artifact_status: "Issued",
    last_activity_at: t("2026-08-20T06:00:00Z"),
    metadata: { "product_code" => "application_qualification", "converter" => "Demo converter", "material_sku" => "BIO-APP-001" }
  }
)

earth_source = upsert(
  SourceRecord,
  { record_code: "SR-EARTH-LAB-001" },
  {
    organization: earthodic_org,
    project: earth_project,
    source_system: "Earthodic Laboratory",
    document_id: "EARTH-LAB-001",
    evidence_type: "laboratory_observation",
    evidence_class: "controlled_source",
    controlled_uri: "https://earthodic.example/controlled/EARTH-LAB-001",
    commitment: "sha256:#{'b' * 32}",
    disclosure_status: "available",
    status: "validated",
    metadata: {}
  }
)

[
  ["EV-EARTH-LOT-001", "Product lot identity", "product_lot", "earthodic.product_lot.v1", { "material_sku" => "BIO-APP-001" }],
  ["EV-EARTH-CONV-001", "Converter configuration", "converter_configuration", "earthodic.converter_configuration.v1", { "line" => "Line A" }],
  ["EV-EARTH-RUN-001", "Coating run", "coating_run", "earthodic.coating_run.v1", { "run" => "RUN-001" }],
  ["EV-EARTH-LAB-001", "Laboratory observation", "laboratory_observation", "earthodic.laboratory_observation.v1", { "commitment" => earth_source.commitment }]
].each_with_index do |(code, label, type, schema, payload), index|
  upsert(
    EvidenceRecord,
    { record_code: code },
    {
      project: earth_project,
      source_record: earth_source,
      label: label,
      record_type: type,
      status: "accepted",
      schema_name: schema,
      source: "Earthodic",
      received_at: t("2026-08-20T0#{index}:00:00Z"),
      projection: "earthodic.qualification_projection.v1",
      digest: digest_for(payload),
      inbox_result: "Accepted",
      operation_id: "op-#{code.downcase}",
      summary: [{ "label" => "Record", "value" => code, "mono" => true }],
      payload: payload,
      integrity: [{ "label" => "Digest valid", "ok" => true }],
      processing: [{ "step" => "seed", "ok" => true }]
    }
  )
end

upsert(
  Gap,
  { gap_code: "GAP-EARTH-APP-001" },
  {
    project: earth_project,
    evidence_record: EvidenceRecord.find_by!(record_code: "EV-EARTH-LAB-001"),
    requirement_code: "EARTH-APP-004",
    severity: "low",
    title: "Laboratory boundary review",
    explanation: "Laboratory observation is present and requires bounded-review wording before issuance.",
    expected: ["controlled laboratory observation commitment"],
    observed: ["laboratory commitment supplied"],
    related_evidence: ["EV-EARTH-LAB-001"],
    action: "Confirm qualification limitation wording",
    status: "resolved",
    blocking: false
  }
)

earth_run = upsert(
  ModelRun,
  { run_code: "RUN-EARTH-APP-001" },
  {
    organization: earthodic_org,
    project: earth_project,
    adapter_name: "EARTHODIC-QUALIFICATION",
    adapter_version: "v1",
    input_commitment: "sha256:earthodicinput001",
    status: "completed",
    started_at: t("2026-08-20T04:00:00Z"),
    completed_at: t("2026-08-20T04:03:00Z"),
    output: { "qualification" => "supported" },
    metadata: {}
  }
)

earth_review = upsert(
  Review,
  { review_code: "RV-EARTH-001" },
  {
    project: earth_project,
    requirement_code: "EARTH-APP-004",
    title: "Laboratory observation boundary",
    state: "decided"
  }
)
upsert(
  ReviewDecision,
  { decision_code: "RD-EARTH-001" },
  {
    review: earth_review,
    user: admin,
    decision: "SUPPORTED WITH QUALIFICATION",
    reviewer: admin.full_name,
    recorded_at: t("2026-08-20T04:10:00Z"),
    rationale: "Controlled laboratory observation commitment supports the qualification.",
    limitation: "Bounded to supplied converter configuration and laboratory evidence."
  }
)

earth_eval = upsert(
  Evaluation,
  { evaluation_code: "EVAL-EARTH-APP-001" },
  {
    program_profile: earthodic_application,
    project: earth_project,
    project_name: earth_project.name,
    outcome: "Qualified with conditions",
    satisfied: "4 / 4",
    published: true,
    evaluated_at: t("2026-08-20T04:20:00Z"),
    input_digest: "sha256:earthodic-evaluation-input",
    profile_version: earthodic_application.profile_version,
    status: "current",
    result: { "contract_version" => "evaluation-result.v0", "satisfied_requirement_codes" => %w[EARTH-APP-001 EARTH-APP-002 EARTH-APP-003 EARTH-APP-004] }
  }
)

earth_det = upsert(
  Determination,
  { determination_code: "DET-EARTH-APP-001" },
  {
    program_profile: earthodic_application,
    project: earth_project,
    evaluation: earth_eval,
    project_name: earth_project.name,
    outcome: "Qualified with conditions",
    adapter: "#{earthodic_application.code} #{earthodic_application.profile_version}",
    digest: "sha256:earthodic-determination",
    published_at: t("2026-08-20T04:30:00Z"),
    status: "published",
    result: {
      "contract_version" => "determination-result.v0",
      "limitations" => [
        { "code" => "E-LIM-01", "statement" => "Bounded to supplied converter and lab records.", "basis" => "DET-EARTH-APP-001", "detail" => "No raw customer evidence is embedded." }
      ]
    }
  }
)

earth_manifest = {
  "contract_version" => "artifact-manifest.v0",
  "artifact_code" => "QA-EARTH-APP-001",
  "portfolio_product_code" => "application_qualification",
  "issuer" => { "name" => "Earthodic", "product_name" => "Biobarc Qualification" },
  "project" => { "project_code" => earth_project.project_code, "name" => earth_project.name },
  "determination" => { "determination_code" => earth_det.determination_code, "digest" => earth_det.digest },
  "limitations" => earth_det.result.fetch("limitations"),
  "receipt_chain" => [{ "label" => "Determination", "digest" => earth_det.digest }]
}
earth_manifest["digest"] = digest_for(earth_manifest)
earth_artifact = ensure_artifact!(
  "QA-EARTH-APP-001",
  project: earth_project,
  claim: earth_det.outcome,
  boundary: "#{earth_project.name} / #{earth_project.scope}",
  jurisdiction: earth_project.jurisdiction,
  program: "#{earthodic_application.program} #{earthodic_application.profile_version}",
  digest: earth_manifest.fetch("digest"),
  status: "issued",
  issued: true,
  issued_at: t("2026-08-20T04:40:00Z"),
  issued_by_user: admin,
  contract_version: "artifact-manifest.v0",
  artifact: earth_manifest,
  integrity: [{ "label" => "Artifact digest valid", "ok" => true }],
  limitations: earth_manifest.fetch("limitations"),
  receipt_chain: earth_manifest.fetch("receipt_chain")
)

price = upsert(
  PriceVersion,
  { organization: earthodic_org, product_code: "application_qualification", product_version: "1.2", currency: "AUD", pricing_unit: "application" },
  {
    list_price_cents: 2_500_000,
    minimum_price_cents: 1_900_000,
    pricing_formula: { "model" => "fixed" },
    effective_from: t("2026-08-20T00:00:00Z"),
    status: "active",
    metadata: { "source" => "portfolio_hosted_product_factory_dossier" }
  }
)

PortfolioProducts::Registry.fetch("earthodic").catalog.products.reject { |product| product.code == "application_qualification" }.each do |product|
  upsert(
    PriceVersion,
    { organization: earthodic_org, product_code: product.code, product_version: product.product_version, currency: "AUD", pricing_unit: product.pricing_units.first },
    {
      list_price_cents: nil,
      minimum_price_cents: nil,
      pricing_formula: { "model" => "quote_only" },
      effective_from: t("2026-08-20T00:00:00Z"),
      status: "active",
      metadata: { "source" => "quote_only_seed" }
    }
  )
end

experiment = upsert(
  PricingExperiment,
  { organization: earthodic_org, product_code: "application_qualification", product_version: "1.2", name: "Application vs maintained approval" },
  {
    price_version: price,
    hypothesis: "Can qualification become paid and accelerate material conversion?",
    customer_segment: "converter",
    geography: "AU",
    pricing_unit: "application",
    status: "active",
    started_at: t("2026-08-20T00:00:00Z"),
    metadata: {
      "bundle" => { "qualification_artifact" => true, "third_party_testing" => false, "monitoring" => false },
      "sales_cycle_days" => 19,
      "recurring_value_cents" => 1_200_000,
      "workload" => { "reviewer_minutes" => 180, "support_minutes" => 90, "evidence_records" => 143, "artifacts" => 2 }
    }
  }
)

quote = upsert(
  PricingQuote,
  { quote_id: "QUOTE-EARTH-APP-001" },
  {
    organization: earthodic_org,
    project: earth_project,
    price_version: price,
    pricing_experiment: experiment,
    product_code: "application_qualification",
    product_version: "1.2",
    currency: "AUD",
    pricing_unit: "application",
    list_price_cents: 2_500_000,
    offered_price_cents: 1_900_000,
    discount_cents: 600_000,
    quantity: 1,
    commercial_terms: { "expiry_days" => 30, "bundle" => "qualification_artifact" },
    breakdown: [{ "label" => "Biobarc Application Qualification", "list_price_cents" => 2_500_000, "offered_price_cents" => 1_900_000 }],
    status: "accepted",
    quoted_at: t("2026-08-20T05:00:00Z"),
    expires_at: t("2026-09-19T05:00:00Z"),
    accepted_at: t("2026-08-20T05:19:00Z")
  }
)

order = upsert(
  ArtifactOrder,
  { order_id: "ORDER-EARTH-APP-001" },
  {
    organization: earthodic_org,
    project: earth_project,
    pricing_quote: quote,
    product_code: "application_qualification",
    artifact_profile_code: "application_qualification_pack",
    quantity: 1,
    status: "checkout_completed",
    checkout_completed_at: t("2026-08-20T05:25:00Z"),
    metadata: {}
  }
)

upsert(
  CommercialOutcome,
  { organization: earthodic_org, pricing_quote: quote, state: "won" },
  {
    artifact_order: order,
    pricing_experiment: experiment,
    product_code: "application_qualification",
    occurred_at: t("2026-08-20T05:25:00Z"),
    sales_cycle_days: 19,
    accepted_price_cents: 1_900_000,
    recurring_value_cents: 1_200_000,
    metadata: { "expansion" => true }
  }
)

%w[quote_created order_created quote_accepted artifact_issued reliance_recorded].each do |event_type|
  upsert(
    CommercialEvent,
    { organization: earthodic_org, event_type: event_type, product_code: "application_qualification" },
    {
      project: earth_project,
      pricing_quote: quote,
      artifact_order: order,
      occurred_at: t("2026-08-20T05:30:00Z"),
      value: {
        "organization_class" => "portfolio_company",
        "product_code" => "application_qualification",
        "product_version" => "1.2",
        "customer_segment" => "converter",
        "geography" => "AU",
        "pricing_unit" => "application",
        "currency" => "AUD",
        "list_price" => 2_500_000,
        "offered_price" => 1_900_000,
        "accepted_price" => 1_900_000,
        "quote_outcome" => "won",
        "sales_cycle_days" => 19,
        "source_records_ingested" => earth_project.source_records.count,
        "evidence_records_generated" => earth_project.evidence_records.count,
        "model_or_evaluation_runs" => earth_project.model_runs.count + earth_project.evaluations.count,
        "artifacts_generated" => earth_project.artifacts.count,
        "reviewer_actions" => earth_project.reviews.joins(:review_decisions).count,
        "reviewer_minutes" => 180,
        "support_minutes" => 90,
        "api_requests" => ApiLog.where(organization: earthodic_org).count,
        "exports_or_external_recipients" => earth_artifact.statement_shares.count,
        "reliance_events" => earth_project.reliance_events.count,
        "renewal" => nil,
        "expansion" => true,
        "recurring_value" => 1_200_000
      }
    }
  )
end

upsert(
  RelianceEvent,
  { event_code: "REL-EARTH-APP-001" },
  {
    organization: earthodic_org,
    project: earth_project,
    artifact: earth_artifact,
    relying_party: "Converter procurement team",
    relying_party_role: "recipient",
    reliance_kind: "procurement",
    status: "recorded",
    occurred_at: t("2026-08-20T05:45:00Z"),
    basis: { "artifact_code" => earth_artifact.artifact_code },
    metadata: { "product_code" => "application_qualification" }
  }
)
