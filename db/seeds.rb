def upsert(klass, lookup, attrs)
  record = klass.find_or_initialize_by(lookup)
  attrs.each { |key, value| record.public_send("#{key}=", value) }
  record.save!
  record
end

def t(value)
  Time.zone.parse(value)
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

pending_invitation = Invitation.find_or_initialize_by(token: "demo-reviewer-invite")
pending_invitation.assign_attributes(
  organization: org,
  invited_by_user: admin,
  role: reviewer_role,
  email: "reviewer@example.com",
  status: "pending",
  expires_at: 14.days.from_now
)
pending_invitation.save!

projects = [
  ["dit-au-methane", "PRJ-AU-00041", "DIT Methane Intervention Evidence", "Australia", "Beef", "Scope 3", 82, "In review", "info", 3, 3, "In review", "Ready", "2026-08-07 09:52:00"],
  ["meq-au-livestock", "PRJ-AU-00042", "MEQ Livestock Evidence Boundary", "Australia", "Beef quality / livestock evidence", "Scope 3", 64, "Needs evidence", "warning", 4, 1, "Awaiting evidence", "Draft", "2026-08-06 22:10:00"],
  ["rumin8-au-additive", "PRJ-AU-00043", "Rumin8 Additive Trial Evidence", "Australia", "Methane intervention", "Scope 3", 57, "Needs review", "warning", 5, 2, "Open review", "Draft", "2026-08-05 18:21:00"],
  ["dairy-au-methane", "PRJ-AU-00044", "Dairy Methane Evidence Pack", "Australia", "Dairy methane", "Scope 3", 76, "Conditionally eligible", "success", 2, 0, "Review complete", "Ready", "2026-08-04 12:05:00"],
  ["beef-au-feedlot", "PRJ-AU-00045", "Feedlot Cohort Emissions Evidence", "Australia", "Beef", "Scope 3", 48, "Needs mapping", "danger", 6, 3, "Not started", "Draft", "2026-08-03 08:44:00"]
].map do |slug, code, name, jurisdiction, program, scope, readiness, status, tone, open_gaps, critical_gaps, review, artifact_status, last_at|
  upsert(
    Project,
    { slug: slug },
    {
      organization: org,
      project_code: code,
      name: name,
      jurisdiction: jurisdiction,
      program: program,
      scope: scope,
      readiness: readiness,
      status: status,
      status_tone: tone,
      open_gaps: open_gaps,
      critical_gaps: critical_gaps,
      review_status: review,
      artifact_status: artifact_status,
      last_activity_at: t(last_at),
      metadata: {
        "trial" => "DIT Trial",
        "product_lot" => "PL-443",
        "cohort" => "C-18",
        "period" => "12 Jun - 19 Jul 2026",
        "profile" => "AU Agricultural Climate Evidence v0.1"
      }
    }
  )
end

main_project = projects.first

upsert(
  EvidenceCase,
  { organization: org, slug: "dit-au-methane-case" },
  {
    project: main_project,
    case_number: "CASE-AU-00041",
    status: "open",
    metadata_json: JSON.generate({ "profile" => "AU", "artifact" => "RA-AU-000184" })
  }
)

[
  ["act-001", main_project, "2026-08-07 09:52:00", "AgEvidence", "system", "Reliance artifact assembled", "RA-AU-000184 is ready for issuance.", "success"],
  ["act-002", main_project, "2026-08-07 08:31:00", "Emma Clarke", "human", "Review decision recorded", "Measurement provenance accepted with limitation.", "info"],
  ["act-003", main_project, "2026-08-06 21:02:00", "Country Program Engine", "system", "Australia profile evaluated", "18 of 24 requirements satisfied.", "warning"],
  ["act-004", main_project, "2026-08-06 18:20:00", "MEQ Probe", "partner", "Measurement evidence received", "Instrument GF-4412 payload projected.", "success"],
  ["act-005", main_project, "2026-08-05 12:14:00", "DIT AgTech", "partner", "Feeding event received", "Cohort C-18 intake record linked to product lot PL-443.", "success"],
  ["act-006", projects.second, "2026-08-06 22:10:00", "AgEvidence", "system", "Schema gap opened", "Missing verifier organization for reliance artifact.", "danger"]
].each do |code, project, at, actor, actor_kind, title, detail, tone|
  upsert(Activity, { activity_code: code }, { project: project, occurred_at: t(at), actor: actor, actor_kind: actor_kind, title: title, detail: detail, tone: tone })
end

evidence_rows = [
  ["PL-443", "Product lot", "product_lot", "accepted", "product_lot.v1", "DIT AgTech", "2026-08-05 10:00:00", "agevidence.product_lot.v1", "sha256:4f8c114a02ccf3b9", "Accepted", "op_4f8c114a", [["Lot", "PL-443", true], ["Product", "Methane reducing feed additive", false], ["Manufacturer", "DIT AgTech", false]]],
  ["C-18", "Animal cohort", "animal_cohort", "accepted", "animal_cohort.v1", "DIT AgTech", "2026-08-05 10:15:00", "agevidence.animal_cohort.v1", "sha256:a2d4c88b912ea771", "Accepted", "op_a2d4c88b", [["Cohort", "C-18", true], ["Animals", "143 head", false], ["Boundary", "DIT Trial", false]]],
  ["EVT-99231", "Feeding event", "feeding_event", "accepted", "feeding_event.v1", "DIT AgTech", "2026-08-05 12:14:00", "agevidence.feeding_event.v1", "sha256:bb7c18db309b71b4", "Projected", "op_bb7c18db", [["Date", "2026-07-19", false], ["Cohort", "C-18", true], ["Lot", "PL-443", true]]],
  ["MS-828", "Methane measurement", "measurement", "needs_review", "measurement.v1", "MEQ Probe", "2026-08-06 18:20:00", "agevidence.measurement.v1", "sha256:8371e0ab7ba8811a", "Needs review", "op_8371e0ab", [["Instrument", "GF-4412", true], ["Reduction", "42.7 tCO2e", false], ["Calibration", "CAL-204", true]]],
  ["MR-334", "Model execution", "model_execution", "accepted", "model_run.v1", "AgEvidence", "2026-08-06 20:44:00", "agevidence.model_run.v1", "sha256:e1d1280bad988204", "Accepted", "op_e1d1280b", [["Model", "AUS-LIVESTOCK-ME v0.9", true], ["Output", "42.7 tCO2e", false]]],
  ["RV-201", "Measurement provenance review", "review", "needs_review", "review_workpaper.v1", "Emma Clarke", "2026-08-07 08:31:00", "agevidence.review_workpaper.v1", "sha256:cc8cafe988173011", "Human review", "op_cc8cafe9", [["Reviewer", "Emma Clarke", false], ["Requirement", "AU-REQ-12", true]]],
  ["SM-441", "Source manifest", "source_manifest", "schema_error", "source_manifest.v1", "MEQ Probe", "2026-08-07 11:03:00", "agevidence.source_manifest.v1", "sha256:af11881aa2428891", "Schema error", "op_af11881a", [["Manifest", "MEQ-2026-08", true], ["Error", "Missing verifier organization", false]]],
  ["CLM-184", "Claim candidate", "claim_candidate", "pending", "claim_candidate.v1", "AgEvidence", "2026-08-07 09:10:00", "agevidence.claim_candidate.v1", "sha256:e4b7a0912cd83f64", "Draft", "op_e4b7a091", [["Claim", "42.7 tCO2e modeled reduction", false], ["Period", "Q4 2026", false]]]
]

evidence_rows.each do |code, label, record_type, status, schema_name, source, received_at, projection, digest, result, operation_id, summary|
  payload = {
    "id" => code,
    "schema" => schema_name,
    "source" => source,
    "project" => main_project.project_code,
    "received_at" => received_at
  }
  if record_type == "source_manifest"
    payload.merge!(
      "provider" => "DIT AgTech",
      "evidence_type" => "FEEDING_EVENT",
      "lot" => "LOT-88421",
      "cohort" => "CATTLE-29B",
      "facility" => "VIC-012",
      "period" => "2026-07-01 to 2026-07-31",
      "records" => 4,
      "signature" => "VALID"
    )
  end

  upsert(
    EvidenceRecord,
    { record_code: code },
    {
      project: main_project,
      label: label,
      record_type: record_type,
      status: status,
      schema_name: schema_name,
      source: source,
      received_at: t(received_at),
      projection: projection,
      digest: digest,
      inbox_result: result,
      operation_id: operation_id,
      summary: summary.map { |name, value, mono| { "label" => name, "value" => value, "mono" => mono } },
      payload: payload,
      integrity: [
        { "label" => "Digest recomputed", "ok" => true },
        { "label" => "Linked to project boundary", "ok" => status != "schema_error" },
        { "label" => "Schema validation", "ok" => status != "schema_error" }
      ],
      processing: [
        { "step" => "Received", "ok" => true, "note" => source },
        { "step" => "Schema validation", "ok" => status != "schema_error", "note" => schema_name },
        { "step" => "Canonical projection", "ok" => status != "schema_error", "note" => projection }
      ]
    }
  )
end

profiles = [
  ["australia", "AU", "Australia", "Operational", "v0.1", "Agricultural Climate Evidence", "Livestock methane intervention", "AUS-LIVESTOCK-ME v0.9", "AU reliance artifact profile", "controlled-source-plus-review", 24, 19, 5, 6],
  ["new-zealand", "NZ", "New Zealand", "Draft", "v0.1-draft", "Agricultural Climate Evidence", "Livestock methane intervention", "NZ-AG-ME draft", "NZ verification profile", "review-weighted", 21, 15, 6, 5],
  ["united-states", "US", "United States", "In development", "v0.2-draft", "Climate Smart Commodities", "Beef emissions evidence", "US-CSC draft", "US verifier profile", "program-adapter-review", 28, 18, 10, 5],
  ["canada", "CA", "Canada", "Planned", "planned", "Agricultural Clean Tech", "Livestock evidence", nil, nil, nil, 0, 0, 0, 0],
  ["european-union", "EU", "European Union", "In development", "v0.1-draft", "Carbon farming evidence", "Farm system evidence", "EU-CF draft", "EU verification profile", "audit-heavy", 31, 17, 14, 6],
  ["brazil", "BR", "Brazil", "Planned", "planned", "Low carbon agriculture", "Livestock evidence", nil, nil, nil, 0, 0, 0, 0],
  ["japan", "JP", "Japan", "Draft", "v0.1-draft", "Agricultural climate evidence", "Imported beef evidence", "JP import evidence", "JP verification profile", "supply-chain-review", 18, 10, 8, 4]
].map do |slug, code, name, status, version, program, scope, methodology, verification_profile, evidence_policy, req_count, machine, human, classes|
  upsert(
    ProgramProfile,
    { code: code },
    {
      slug: slug,
      name: name,
      status: status,
      profile_version: version,
      program: program,
      scope: scope,
      methodology: methodology,
      verification_profile: verification_profile,
      evidence_policy: evidence_policy,
      requirements_count: req_count,
      machine_evaluable: machine,
      human_review: human,
      profile_classes: classes,
      composition: [
        { "kind" => "methodology", "label" => "Methodology", "identifier" => methodology || "#{code.downcase}.methodology.pending", "version" => "v1.0", "digest" => "sha256:au-methodology-01", "description" => "Interprets modeled livestock methane reduction evidence." },
        { "kind" => "requirements", "label" => "Requirements", "identifier" => "#{code.downcase}.requirements.livestock_evidence", "version" => version, "digest" => "sha256:au-requirements-01", "description" => "Defines machine and human evidence obligations." },
        { "kind" => "claim_policy", "label" => "Claim policy", "identifier" => "shared_supply_chain_claims", "version" => "v1", "digest" => "sha256:au-claim-policy-01", "description" => "Bounds what a reliance artifact may claim." },
        { "kind" => "verification", "label" => "Verification", "identifier" => verification_profile || "#{code.downcase}.verification.pending", "version" => "v1", "digest" => "sha256:au-verification-01", "description" => "Defines digest, signature, and receipt-chain checks." },
        { "kind" => "data_policy", "label" => "Data policy", "identifier" => evidence_policy || "#{code.downcase}.data_policy.pending", "version" => "v1", "digest" => "sha256:au-data-policy-01", "description" => "Defines disclosure and controlled-source handling." },
        { "kind" => "artifact", "label" => "Artifact", "identifier" => "pilot_readiness", "version" => "v1", "digest" => "sha256:au-artifact-01", "description" => "Defines reliance artifact fields, limits, and signatures." }
      ],
      version_diff: [
        { "id" => "#{code}-REQ-018", "kind" => "changed", "note" => "Feed lot provenance now carries supplier identity and chain-of-custody reference.", "effect" => "Previously sufficient evidence may require supplementation." },
        { "id" => "#{code}-REQ-020", "kind" => "added", "note" => "Verifier organization must be named on issued artifact.", "effect" => "Artifacts without reviewer organization remain draft." },
        { "id" => "#{code}-REQ-022", "kind" => "added", "note" => "Model uncertainty must be reported in reliance limitations.", "effect" => "Determinations become conditional until limitations are carried." },
        { "id" => "#{code}-REQ-009", "kind" => "retired", "note" => "Legacy aggregate feed summary retired in favor of controlled source records.", "effect" => "Historical determinations remain inspectable as superseded basis." }
      ],
      version_impact: { "projects" => 5, "unchanged" => 23, "added" => 2, "modified" => 3, "retired" => 1, "newly_conditional" => 1, "newly_insufficient" => 1 },
      comparison: {
        "columns" => [
          { "code" => "AU", "version" => "v0.1", "result" => "Conditional", "requirements" => 24 },
          { "code" => "NZ", "version" => "v0.1-draft", "result" => "Review", "requirements" => 21 },
          { "code" => "US", "version" => "v0.2-draft", "result" => "Conditional", "requirements" => 28 }
        ],
        "rows" => [
          { "label" => "Boundary evidence", "requirement" => "REQ-01", "marks" => ["Pass", "Pass", "Pass"] },
          { "label" => "Measurement provenance", "requirement" => "REQ-12", "marks" => ["Review", "Review", "Pass"] },
          { "label" => "Verifier identity", "requirement" => "REQ-20", "marks" => ["Gap", "Review", "Gap"] }
        ]
      }
    }
  )
end

au = profiles.find { |profile| profile.code == "AU" }

[
  ["AU-REQ-01", "Project boundary identified", "Boundary", "Machine", ["project_boundary.v1", "source_manifest.v1"]],
  ["AU-REQ-04", "Product lot traceable to feeding events", "Traceability", "Machine", ["product_lot.v1", "feeding_event.v1"]],
  ["AU-REQ-08", "Animal cohort remains within declared scope", "Boundary", "Machine", ["animal_cohort.v1"]],
  ["AU-REQ-12", "Measurement provenance accepted", "Measurement", "Human review", ["measurement.v1", "calibration_certificate.v1"]],
  ["AU-REQ-20", "Verifier organization named", "Artifact", "Human review", ["review_workpaper.v1", "reliance_artifact.v1"]],
  ["AU-REQ-22", "Model uncertainty disclosed", "Artifact", "Machine", ["model_run.v1", "reliance_artifact.v1"]]
].each do |code, title, category, mode, accepted|
  upsert(
    Requirement,
    { requirement_code: code },
    {
      program_profile: au,
      title: title,
      category: category,
      evaluation_mode: mode,
      status: "Active",
      authority: "Australia Agricultural Climate Evidence profile #{au.profile_version}",
      accepted_evidence: accepted
    }
  )
end

[
  ["GAP-001", "AU-REQ-12", "high", "Calibration certificate needs reviewer acceptance", "Required before artifact issuance. The measurement instrument certificate is present but needs independent reviewer confirmation.", ["Calibration certificate CAL-204", "Reviewer rationale"], ["Certificate referenced but not accepted"], ["MS-828", "RV-201"], "Record review"],
  ["GAP-002", "AU-REQ-20", "high", "Verifier organization missing", "The reliance artifact must name the party that performed independent review.", ["Verifier organization legal name", "Reviewer engagement reference"], ["Reviewer named, organization missing"], ["RV-201", "RA-AU-000184"], "Add verifier"],
  ["GAP-003", "AU-REQ-22", "medium", "Model uncertainty limitation needs disclosure", "Modeled reduction may be relied on only with uncertainty bounds carried into the artifact.", ["Uncertainty bounds", "Reliance limitation"], ["Model result present without limitation text"], ["MR-334", "CLM-184"], "Add limitation"]
].each do |gap_code, req, severity, title, explanation, expected, observed, related, action|
  upsert(
    Gap,
    { gap_code: gap_code },
    {
      project: main_project,
      requirement_code: req,
      severity: severity,
      title: title,
      explanation: explanation,
      expected: expected,
      observed: observed,
      related_evidence: related,
      action: action
    }
  )
end

review_201 = upsert(Review, { review_code: "RV-201" }, { project: main_project, requirement_code: "AU-REQ-12", title: "Measurement provenance", state: "open" })
review_202 = upsert(Review, { review_code: "RV-202" }, { project: main_project, requirement_code: "AU-REQ-20", title: "Verifier organization", state: "open" })

upsert(
  ReviewDecision,
  { decision_code: "RD-SEED-201" },
  {
    review: review_201,
    decision: "Accept with limitation",
    reviewer: "Emma Clarke",
    recorded_at: t("2026-08-07 08:31:00"),
    rationale: "Calibration certificate CAL-204 matches instrument GF-4412 and covers the measurement date.",
    limitation: "Reliance is limited to the declared instrument and trial period."
  }
)

upsert(
  Artifact,
  { artifact_code: "RA-AU-000184" },
  {
    project: main_project,
    claim: "42.7 tCO2e modeled reduction",
    boundary: "DIT Trial / PL-443 / C-18",
    jurisdiction: "Australia",
    program: "Agricultural climate evidence profile v0.1",
    digest: "sha256:e4b7a0912cd83f6415aa27de90bb35c1f8027ae64d139b0cc7521ea83f4d6610",
    status: "ready",
    issued: false,
    issued_at: nil,
    artifact: {
      "object" => "reliance_artifact",
      "id" => "RA-AU-000184",
      "status" => "ready",
      "schema" => "agevidence.reliance_artifact.v1",
      "claim" => "42.7 tCO2e modeled reduction",
      "program" => { "jurisdiction" => "AU", "profile" => "agricultural_climate_evidence", "version" => "0.1" },
      "boundary" => { "trial" => "DIT Trial", "product_lot" => "PL-443", "cohort" => "C-18" },
      "evidence" => { "accepted" => 18, "critical_gaps" => 0, "limitations" => 2 },
      "integrity" => { "artifact_digest" => "sha256:e4b7a0912cd83f6415aa27de90bb35c1f8027ae64d139b0cc7521ea83f4d6610" }
    },
    integrity: [
      { "label" => "Evidence root valid", "ok" => true },
      { "label" => "Program digest valid", "ok" => true },
      { "label" => "Signature valid", "ok" => false }
    ],
    limitations: [
      { "id" => "LIM-01", "title" => "Measurement scope", "detail" => "Reliance is limited to instrument GF-4412 and cohort C-18 during the declared period." },
      { "id" => "LIM-02", "title" => "Model uncertainty", "detail" => "Modeled reduction carries uncertainty bounds defined by AUS-LIVESTOCK-ME v0.9." }
    ],
    receipt_chain: [
      { "label" => "Evidence root", "digest" => "sha256:41e6cfd9a2321f41" },
      { "label" => "Evaluation", "digest" => "sha256:51f40ce8bd88bd02" },
      { "label" => "Artifact", "digest" => "sha256:e4b7a0912cd83f64" }
    ]
  }
)

upsert(
  Artifact,
  { artifact_code: "RA-AU-000179" },
  {
    project: projects.fourth,
    claim: "18.2 tCO2e modeled reduction",
    boundary: "Dairy Pack / D-12",
    jurisdiction: "Australia",
    program: "Agricultural climate evidence profile v0.1",
    digest: "sha256:179demo",
    status: "issued",
    issued: true,
    issued_at: t("2026-08-06 22:10:00"),
    artifact: { "object" => "reliance_artifact", "id" => "RA-AU-000179", "status" => "issued", "evidence" => { "accepted" => 11, "critical_gaps" => 0 } },
    integrity: [{ "label" => "Signature valid", "ok" => true }],
    limitations: [],
    receipt_chain: [{ "label" => "Artifact", "digest" => "sha256:179demo" }]
  }
)

[
  ["LOG-001", "POST", "/v1/integrations/events", 202, 118, "2026-08-07 11:03:00", "op_af11881a", { "schema" => "source_manifest.v1" }, { "accepted" => false, "error" => "schema_error" }],
  ["LOG-002", "POST", "/v1/projects/PRJ-AU-00041/evidence", 201, 82, "2026-08-07 09:10:00", "op_e4b7a091", { "schema" => "claim_candidate.v1" }, { "accepted" => true }],
  ["LOG-003", "POST", "/v1/artifacts/RA-AU-000184/verify", 200, 44, "2026-08-07 09:52:00", "op_verify_184", { "artifact_id" => "RA-AU-000184" }, { "result" => "valid" }],
  ["LOG-004", "POST", "/v1/developer/projects/dit-production/model_runs", 500, 904, "2026-08-06 18:00:00", "op_model_500", { "model" => "AUS-LIVESTOCK-ME" }, { "error" => "internal_server_error" }]
].each do |code, method, endpoint, status, duration, at, operation, request, response|
  upsert(ApiLog, { log_code: code }, { organization: org, method: method, endpoint: endpoint, status: status, duration_ms: duration, occurred_at: t(at), operation_id: operation, request: request, response: response, trace: [{ "step" => "received", "ok" => true }, { "step" => "processed", "ok" => status < 400 }] })
end

endpoint_one = upsert(WebhookEndpoint, { endpoint_code: "WH-001" }, { organization: org, url: "https://ditagtech.example/webhooks/agevidence", status: "Healthy", events: ["evidence.accepted", "gap.opened", "artifact.issued"] })
endpoint_two = upsert(WebhookEndpoint, { endpoint_code: "WH-002" }, { organization: org, url: "https://meq.example/hooks/evidence", status: "Healthy", events: ["measurement.received", "schema.error"] })

[
  [endpoint_one, "DEL-001", 1, 3, 200, 91, "2026-08-07 09:53:00", { "ok" => true }],
  [endpoint_two, "DEL-002", 2, 3, 500, 1418, "2026-08-07 11:04:00", { "error" => "internal_server_error" }]
].each do |endpoint, code, attempt, max, status, duration, at, response|
  upsert(WebhookDelivery, { delivery_code: code }, { webhook_endpoint: endpoint, attempt: attempt, max_attempts: max, status: status, duration_ms: duration, delivered_at: t(at), response: response, timeline: [{ "label" => "queued", "status" => 200 }, { "label" => "delivered", "status" => status }] })
end

[
  ["INT-001", "DIT Evidence API", "DIT AgTech", "Connected", 2, "2026-08-07 10:00:00", ["feeding_event.created", "product_lot.updated"]],
  ["INT-002", "MEQ Probe", "MEQ", "Degraded", 3, "2026-08-07 11:03:00", ["measurement.received", "schema.error"]],
  ["INT-003", "Rumin8 Trial Feed", "Rumin8", "Connected", 4, "2026-08-06 14:20:00", ["feed_event.created"]],
  ["INT-004", "Verifier Workpapers", "Independent Reviewer", "Connected", 1, "2026-08-07 08:31:00", ["review.recorded"]]
].each do |code, name, provider, status, count, last, events|
  upsert(Integration, { integration_code: code }, { organization: org, name: name, provider: provider, status: status, projects_count: count, last_sync_at: t(last), events: events })
end

[
  ["SCH-001", "agevidence.feeding_event.v1", "1.0", 128, "Active"],
  ["SCH-002", "agevidence.measurement.v1", "1.0", 61, "Active"],
  ["SCH-003", "agevidence.review_workpaper.v1", "1.0", 18, "Active"],
  ["SCH-004", "agevidence.reliance_artifact.v1", "1.0", 42, "Beta"]
].each do |code, name, version, events, status|
  upsert(EvidenceSchema, { schema_code: code }, { name: name, version: version, events_count: events, status: status })
end

[
  ["KEY-001", "Production ingestion", "agev_live_...7f91", "Active", "2026-08-07 11:03:00"],
  ["KEY-002", "Verifier sandbox", "agev_test_...2a10", "Active", "2026-08-05 09:10:00"]
].each do |code, name, hint, status, last|
  upsert(ApiKey, { key_code: code }, { organization: org, name: name, token_hint: hint, status: status, last_used_at: t(last) })
end

[
  ["EVAL-001", "DIT Methane Intervention Evidence", "Eligible with conditions", "18 / 24", false, "2026-08-07 09:20:00"],
  ["EVAL-002", "Dairy Methane Evidence Pack", "Eligible", "21 / 24", true, "2026-08-06 22:01:00"],
  ["EVAL-003", "Feedlot Cohort Emissions Evidence", "Insufficient", "12 / 24", false, "2026-08-05 14:11:00"]
].each do |code, project_name, outcome, satisfied, published, at|
  upsert(Evaluation, { evaluation_code: code }, { program_profile: au, project_name: project_name, outcome: outcome, satisfied: satisfied, published: published, evaluated_at: t(at) })
end

[
  ["DET-001", "Dairy Methane Evidence Pack", "Eligible", "AU v0.1", "sha256:det001", "2026-08-06 22:10:00"],
  ["DET-002", "DIT Methane Intervention Evidence", "Conditional", "AU v0.1", "sha256:det002", "2026-08-07 09:35:00"]
].each do |code, project_name, outcome, adapter, digest, at|
  upsert(Determination, { determination_code: code }, { program_profile: au, project_name: project_name, outcome: outcome, adapter: adapter, digest: digest, published_at: t(at) })
end
