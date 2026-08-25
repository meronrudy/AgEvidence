# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_15_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "activities", id: :serial, force: :cascade do |t|
    t.string "activity_code", null: false
    t.string "actor", null: false
    t.string "actor_kind", default: "system", null: false
    t.datetime "created_at", null: false
    t.text "detail"
    t.datetime "occurred_at", precision: nil, null: false
    t.integer "project_id"
    t.string "title", null: false
    t.string "tone", default: "neutral", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_code"], name: "index_activities_on_activity_code", unique: true
    t.index ["project_id"], name: "index_activities_on_project_id"
  end

  create_table "api_idempotency_keys", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.string "method", null: false
    t.integer "organization_id", null: false
    t.string "path", null: false
    t.text "response_json", null: false
    t.integer "status", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "key", "method", "path"], name: "index_api_idempotency_keys_on_org_key_method_path", unique: true
    t.index ["organization_id"], name: "index_api_idempotency_keys_on_organization_id"
  end

  create_table "api_keys", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key_code", null: false
    t.datetime "last_used_at", precision: nil
    t.string "name", null: false
    t.integer "organization_id"
    t.datetime "revoked_at", precision: nil
    t.text "scopes_json", default: "[]", null: false
    t.string "status", null: false
    t.string "token_digest"
    t.string "token_hint", null: false
    t.datetime "updated_at", null: false
    t.index ["key_code"], name: "index_api_keys_on_key_code", unique: true
    t.index ["organization_id"], name: "index_api_keys_on_organization_id"
    t.index ["token_digest"], name: "index_api_keys_on_token_digest", unique: true
  end

  create_table "api_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "duration_ms", null: false
    t.string "endpoint", null: false
    t.string "log_code", null: false
    t.string "method", null: false
    t.datetime "occurred_at", precision: nil, null: false
    t.string "operation_id", null: false
    t.integer "organization_id"
    t.text "request_json"
    t.text "response_json"
    t.integer "status", null: false
    t.text "trace_json"
    t.datetime "updated_at", null: false
    t.index ["log_code"], name: "index_api_logs_on_log_code", unique: true
    t.index ["organization_id"], name: "index_api_logs_on_organization_id"
  end

  create_table "artifact_profiles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "layout_json", default: "{}", null: false
    t.string "profile_code", null: false
    t.string "profile_version", null: false
    t.integer "program_profile_id", null: false
    t.text "recipient_rules_json", default: "{}", null: false
    t.text "retention_json", default: "{}", null: false
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.index ["profile_code", "profile_version"], name: "index_artifact_profiles_on_profile_code_and_profile_version", unique: true
    t.index ["program_profile_id"], name: "index_artifact_profiles_on_program_profile_id"
  end

  create_table "artifacts", force: :cascade do |t|
    t.string "artifact_code", null: false
    t.text "artifact_json"
    t.string "boundary", null: false
    t.string "claim", null: false
    t.string "contract_version", default: "artifact-manifest.v0", null: false
    t.datetime "created_at", null: false
    t.string "digest", null: false
    t.text "integrity_json"
    t.boolean "issued", default: false, null: false
    t.datetime "issued_at", precision: nil
    t.integer "issued_by_user_id"
    t.string "jurisdiction", null: false
    t.text "limitations_json"
    t.string "program", null: false
    t.integer "project_id", null: false
    t.text "receipt_chain_json"
    t.string "status", default: "ready", null: false
    t.integer "supersedes_artifact_id"
    t.datetime "updated_at", null: false
    t.index ["artifact_code"], name: "index_artifacts_on_artifact_code", unique: true
    t.index ["issued_by_user_id"], name: "index_artifacts_on_issued_by_user_id"
    t.index ["project_id"], name: "index_artifacts_on_project_id"
    t.index ["supersedes_artifact_id"], name: "index_artifacts_on_supersedes_artifact_id"
  end

  create_table "audit_events", force: :cascade do |t|
    t.string "action", null: false
    t.integer "actor_id"
    t.integer "auditable_id"
    t.string "auditable_type"
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.text "metadata_json", default: "{}", null: false
    t.integer "organization_id"
    t.string "request_id"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.index ["actor_id"], name: "index_audit_events_on_actor_id"
    t.index ["auditable_type", "auditable_id", "created_at"], name: "index_audit_events_on_auditable_and_created_at"
    t.index ["auditable_type", "auditable_id"], name: "index_audit_events_on_auditable"
    t.index ["organization_id", "created_at"], name: "index_audit_events_on_organization_id_and_created_at"
    t.index ["organization_id"], name: "index_audit_events_on_organization_id"
  end

  create_table "determinations", id: :serial, force: :cascade do |t|
    t.string "adapter", null: false
    t.datetime "created_at", null: false
    t.string "determination_code", null: false
    t.string "digest", null: false
    t.integer "evaluation_id"
    t.string "outcome", null: false
    t.integer "program_profile_id", null: false
    t.integer "project_id", null: false
    t.string "project_name", null: false
    t.datetime "published_at", precision: nil, null: false
    t.text "result_json", default: "{}", null: false
    t.string "status", default: "published", null: false
    t.datetime "superseded_at", precision: nil
    t.integer "supersedes_determination_id"
    t.datetime "updated_at", null: false
    t.index ["determination_code"], name: "index_determinations_on_determination_code", unique: true
    t.index ["evaluation_id"], name: "index_determinations_on_evaluation_id"
    t.index ["program_profile_id"], name: "index_determinations_on_program_profile_id"
    t.index ["project_id", "program_profile_id", "published_at"], name: "index_determinations_on_project_profile_published"
    t.index ["project_id"], name: "index_determinations_on_project_id"
    t.index ["supersedes_determination_id"], name: "index_determinations_on_supersedes_determination_id"
  end

  create_table "evaluations", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "evaluated_at", precision: nil, null: false
    t.string "evaluation_code", null: false
    t.string "input_digest", null: false
    t.string "outcome", null: false
    t.string "profile_version", null: false
    t.integer "program_profile_id", null: false
    t.integer "project_id", null: false
    t.string "project_name", null: false
    t.boolean "published", default: false, null: false
    t.text "result_json", default: "{}", null: false
    t.string "satisfied", null: false
    t.datetime "stale_at", precision: nil
    t.string "status", default: "current", null: false
    t.datetime "updated_at", null: false
    t.index ["evaluation_code"], name: "index_evaluations_on_evaluation_code", unique: true
    t.index ["program_profile_id"], name: "index_evaluations_on_program_profile_id"
    t.index ["project_id", "program_profile_id", "evaluated_at"], name: "index_evaluations_on_project_profile_evaluated"
    t.index ["project_id"], name: "index_evaluations_on_project_id"
  end

  create_table "evidence_candidate_dispositions", force: :cascade do |t|
    t.integer "actor_id"
    t.datetime "created_at", null: false
    t.integer "evidence_candidate_id", null: false
    t.text "metadata_json", default: "{}", null: false
    t.text "reason", null: false
    t.datetime "recorded_at", precision: nil, null: false
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_evidence_candidate_dispositions_on_actor_id"
    t.index ["evidence_candidate_id", "recorded_at"], name: "index_candidate_dispositions_on_candidate_and_recorded_at"
    t.index ["evidence_candidate_id"], name: "index_evidence_candidate_dispositions_on_evidence_candidate_id"
  end

  create_table "evidence_candidates", force: :cascade do |t|
    t.text "basis_json", default: "[]", null: false
    t.string "candidate_code", null: false
    t.string "candidate_type", null: false
    t.text "claim", null: false
    t.decimal "confidence", precision: 5, scale: 4
    t.datetime "created_at", null: false
    t.text "disposition_reason"
    t.integer "evidence_record_id"
    t.text "limitations_json", default: "[]", null: false
    t.integer "model_run_id", null: false
    t.datetime "reviewed_at", precision: nil
    t.integer "reviewed_by_user_id"
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.index ["candidate_code"], name: "index_evidence_candidates_on_candidate_code", unique: true
    t.index ["evidence_record_id"], name: "index_evidence_candidates_on_evidence_record_id"
    t.index ["model_run_id", "status"], name: "index_evidence_candidates_on_model_run_id_and_status"
    t.index ["model_run_id"], name: "index_evidence_candidates_on_model_run_id"
    t.index ["reviewed_by_user_id"], name: "index_evidence_candidates_on_reviewed_by_user_id"
  end

  create_table "evidence_cases", force: :cascade do |t|
    t.string "case_number", null: false
    t.datetime "created_at", null: false
    t.text "metadata_json", default: "{}", null: false
    t.integer "organization_id", null: false
    t.integer "project_id", null: false
    t.string "slug", null: false
    t.string "status", default: "open", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "case_number"], name: "index_evidence_cases_on_organization_id_and_case_number", unique: true
    t.index ["organization_id", "slug"], name: "index_evidence_cases_on_organization_id_and_slug", unique: true
    t.index ["organization_id"], name: "index_evidence_cases_on_organization_id"
    t.index ["project_id"], name: "index_evidence_cases_on_project_id"
  end

  create_table "evidence_records", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "digest", null: false
    t.string "inbox_result"
    t.text "integrity_json"
    t.string "label", null: false
    t.string "operation_id"
    t.text "payload_json"
    t.text "processing_json"
    t.integer "project_id", null: false
    t.string "projection", null: false
    t.datetime "received_at", precision: nil, null: false
    t.string "record_code", null: false
    t.string "record_type", null: false
    t.string "schema_name", null: false
    t.string "source", null: false
    t.integer "source_record_id"
    t.string "status", null: false
    t.text "summary_json"
    t.datetime "updated_at", null: false
    t.index ["project_id", "source_record_id"], name: "index_evidence_records_on_project_id_and_source_record_id"
    t.index ["project_id"], name: "index_evidence_records_on_project_id"
    t.index ["record_code"], name: "index_evidence_records_on_record_code", unique: true
    t.index ["source_record_id"], name: "index_evidence_records_on_source_record_id"
  end

  create_table "feature_flags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "enabled", default: false, null: false
    t.string "flag_key", null: false
    t.text "metadata_json", default: "{}", null: false
    t.integer "organization_id", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "flag_key"], name: "index_feature_flags_on_organization_id_and_flag_key", unique: true
    t.index ["organization_id"], name: "index_feature_flags_on_organization_id"
  end

  create_table "gaps", id: :serial, force: :cascade do |t|
    t.string "action", null: false
    t.boolean "blocking", default: false, null: false
    t.datetime "created_at", null: false
    t.integer "evidence_record_id"
    t.text "expected_json"
    t.text "explanation", null: false
    t.string "gap_code", null: false
    t.text "observed_json"
    t.integer "project_id", null: false
    t.text "related_evidence_json"
    t.string "requirement_code", null: false
    t.string "severity", null: false
    t.integer "source_record_id"
    t.string "status", default: "open", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["evidence_record_id"], name: "index_gaps_on_evidence_record_id"
    t.index ["gap_code"], name: "index_gaps_on_gap_code", unique: true
    t.index ["project_id", "requirement_code", "status"], name: "index_gaps_on_project_id_and_requirement_code_and_status"
    t.index ["project_id"], name: "index_gaps_on_project_id"
    t.index ["source_record_id"], name: "index_gaps_on_source_record_id"
  end

  create_table "integrations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "events_json"
    t.string "integration_code", null: false
    t.datetime "last_sync_at", precision: nil
    t.string "name", null: false
    t.integer "organization_id"
    t.integer "projects_count", default: 0, null: false
    t.string "provider", null: false
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.index ["integration_code"], name: "index_integrations_on_integration_code", unique: true
    t.index ["organization_id"], name: "index_integrations_on_organization_id"
  end

  create_table "invitations", force: :cascade do |t|
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "expires_at", null: false
    t.integer "invited_by_user_id"
    t.integer "organization_id", null: false
    t.integer "role_id", null: false
    t.string "status", default: "pending", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["invited_by_user_id"], name: "index_invitations_on_invited_by_user_id"
    t.index ["organization_id", "email", "status"], name: "index_invitations_on_organization_id_and_email_and_status"
    t.index ["organization_id"], name: "index_invitations_on_organization_id"
    t.index ["role_id"], name: "index_invitations_on_role_id"
    t.index ["token"], name: "index_invitations_on_token", unique: true
  end

  create_table "model_runs", force: :cascade do |t|
    t.string "adapter_name", null: false
    t.string "adapter_version", null: false
    t.datetime "completed_at", precision: nil
    t.datetime "created_at", null: false
    t.text "failure_reason"
    t.string "input_commitment", null: false
    t.text "metadata_json", default: "{}", null: false
    t.integer "organization_id", null: false
    t.text "output_json", default: "{}", null: false
    t.integer "project_id", null: false
    t.string "run_code", null: false
    t.datetime "started_at", precision: nil, null: false
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "project_id"], name: "index_model_runs_on_organization_id_and_project_id"
    t.index ["organization_id"], name: "index_model_runs_on_organization_id"
    t.index ["project_id"], name: "index_model_runs_on_project_id"
    t.index ["run_code"], name: "index_model_runs_on_run_code", unique: true
  end

  create_table "organization_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "joined_at"
    t.integer "organization_id", null: false
    t.integer "role_id", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["organization_id"], name: "index_organization_memberships_on_organization_id"
    t.index ["role_id"], name: "index_organization_memberships_on_role_id"
    t.index ["user_id", "organization_id"], name: "index_memberships_on_user_and_org", unique: true
    t.index ["user_id"], name: "index_organization_memberships_on_user_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "environment", default: "Production", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "program_profiles", force: :cascade do |t|
    t.string "artifact_profile_selection"
    t.string "code", null: false
    t.text "comparison_json"
    t.text "composition_json"
    t.datetime "created_at", null: false
    t.date "effective_from"
    t.date "effective_to"
    t.string "evidence_policy"
    t.integer "human_review", default: 0, null: false
    t.text "issuance_policy_json", default: "{}", null: false
    t.text "limitation_templates_json", default: "[]", null: false
    t.integer "machine_evaluable", default: 0, null: false
    t.string "methodology"
    t.string "name", null: false
    t.text "outcome_vocabulary_json", default: "[]", null: false
    t.integer "profile_classes", default: 0, null: false
    t.string "profile_version", null: false
    t.string "program", null: false
    t.integer "requirements_count", default: 0, null: false
    t.string "requirements_digest"
    t.string "scope", null: false
    t.string "slug", null: false
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.string "verification_profile"
    t.text "version_diff_json"
    t.text "version_impact_json"
    t.index ["code"], name: "index_program_profiles_on_code", unique: true
    t.index ["slug"], name: "index_program_profiles_on_slug", unique: true
  end

  create_table "projects", id: :serial, force: :cascade do |t|
    t.string "artifact_status", null: false
    t.datetime "created_at", null: false
    t.integer "critical_gaps", default: 0, null: false
    t.string "jurisdiction", null: false
    t.datetime "last_activity_at", precision: nil
    t.text "metadata_json"
    t.string "name", null: false
    t.integer "open_gaps", default: 0, null: false
    t.integer "organization_id", null: false
    t.string "program", null: false
    t.string "project_code", null: false
    t.integer "readiness", default: 0, null: false
    t.string "review_status", null: false
    t.string "scope", null: false
    t.string "slug", null: false
    t.string "status", null: false
    t.string "status_tone", default: "neutral", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_projects_on_organization_id"
    t.index ["project_code"], name: "index_projects_on_project_code", unique: true
    t.index ["slug"], name: "index_projects_on_slug", unique: true
  end

  create_table "reliance_events", force: :cascade do |t|
    t.integer "artifact_id", null: false
    t.text "basis_json", default: "{}", null: false
    t.datetime "created_at", null: false
    t.string "event_code", null: false
    t.text "metadata_json", default: "{}", null: false
    t.datetime "occurred_at", precision: nil, null: false
    t.integer "organization_id", null: false
    t.integer "project_id", null: false
    t.integer "recorded_by_user_id"
    t.string "reliance_kind", null: false
    t.string "relying_party", null: false
    t.string "relying_party_role", null: false
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.index ["artifact_id", "occurred_at"], name: "index_reliance_events_on_artifact_id_and_occurred_at"
    t.index ["artifact_id"], name: "index_reliance_events_on_artifact_id"
    t.index ["event_code"], name: "index_reliance_events_on_event_code", unique: true
    t.index ["organization_id", "project_id", "occurred_at"], name: "index_reliance_events_on_org_project_occurred"
    t.index ["organization_id"], name: "index_reliance_events_on_organization_id"
    t.index ["project_id"], name: "index_reliance_events_on_project_id"
    t.index ["recorded_by_user_id"], name: "index_reliance_events_on_recorded_by_user_id"
  end

  create_table "requirements", id: :serial, force: :cascade do |t|
    t.text "accepted_evidence_json"
    t.text "authority"
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.string "evaluation_mode", null: false
    t.integer "program_profile_id", null: false
    t.string "requirement_code", null: false
    t.string "status", default: "Active", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["program_profile_id"], name: "index_requirements_on_program_profile_id"
    t.index ["requirement_code"], name: "index_requirements_on_requirement_code", unique: true
  end

  create_table "resource_grants", force: :cascade do |t|
    t.string "access_level", default: "read", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.integer "grantable_id", null: false
    t.string "grantable_type", null: false
    t.integer "granted_by_user_id"
    t.datetime "last_downloaded_at", precision: nil
    t.string "recipient_email"
    t.string "recipient_name"
    t.datetime "revoked_at"
    t.integer "revoked_by_user_id"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["grantable_type", "grantable_id"], name: "index_resource_grants_on_grantable"
    t.index ["granted_by_user_id"], name: "index_resource_grants_on_granted_by_user_id"
    t.index ["revoked_by_user_id"], name: "index_resource_grants_on_revoked_by_user_id"
    t.index ["user_id", "grantable_type", "grantable_id"], name: "index_resource_grants_on_user_and_resource"
    t.index ["user_id"], name: "index_resource_grants_on_user_id"
  end

  create_table "review_decisions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "decision", null: false
    t.string "decision_code", null: false
    t.text "limitation"
    t.text "rationale", null: false
    t.datetime "recorded_at", precision: nil, null: false
    t.integer "review_id", null: false
    t.string "reviewer", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["decision_code"], name: "index_review_decisions_on_decision_code", unique: true
    t.index ["review_id"], name: "index_review_decisions_on_review_id"
    t.index ["user_id"], name: "index_review_decisions_on_user_id"
  end

  create_table "reviews", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "project_id", null: false
    t.string "requirement_code", null: false
    t.string "review_code", null: false
    t.string "state", default: "open", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_reviews_on_project_id"
    t.index ["review_code"], name: "index_reviews_on_review_code", unique: true
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "name", null: false
    t.integer "organization_id", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "name"], name: "index_roles_on_organization_id_and_name", unique: true
    t.index ["organization_id"], name: "index_roles_on_organization_id"
  end

  create_table "schemas", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "events_count", default: 0, null: false
    t.string "name", null: false
    t.string "schema_code", null: false
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.string "version", null: false
    t.index ["schema_code"], name: "index_schemas_on_schema_code", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address", null: false
    t.datetime "last_seen_at"
    t.integer "organization_id", null: false
    t.datetime "revoked_at"
    t.integer "role_id", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent", null: false
    t.integer "user_id", null: false
    t.index ["organization_id"], name: "index_sessions_on_organization_id"
    t.index ["role_id"], name: "index_sessions_on_role_id"
    t.index ["user_id", "status"], name: "index_sessions_on_user_id_and_status"
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "source_records", force: :cascade do |t|
    t.string "commitment", null: false
    t.string "controlled_uri", null: false
    t.datetime "created_at", null: false
    t.string "disclosure_status", null: false
    t.string "document_id", null: false
    t.string "evidence_class", null: false
    t.string "evidence_type", null: false
    t.text "metadata_json", default: "{}", null: false
    t.integer "organization_id", null: false
    t.integer "project_id", null: false
    t.string "record_code", null: false
    t.string "source_system", null: false
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "project_id"], name: "index_source_records_on_organization_id_and_project_id"
    t.index ["organization_id"], name: "index_source_records_on_organization_id"
    t.index ["project_id", "document_id"], name: "index_source_records_on_project_id_and_document_id", unique: true
    t.index ["project_id"], name: "index_source_records_on_project_id"
    t.index ["record_code"], name: "index_source_records_on_record_code", unique: true
  end

  create_table "statement_shares", force: :cascade do |t|
    t.integer "access_count", default: 0, null: false
    t.string "access_level", null: false
    t.bigint "artifact_id", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_user_id"
    t.datetime "expires_at", null: false
    t.datetime "last_accessed_at"
    t.datetime "revoked_at"
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["artifact_id", "revoked_at"], name: "index_statement_shares_on_artifact_id_and_revoked_at"
    t.index ["artifact_id"], name: "index_statement_shares_on_artifact_id"
    t.index ["created_by_user_id"], name: "index_statement_shares_on_created_by_user_id"
    t.index ["token_digest"], name: "index_statement_shares_on_token_digest", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "external_id"
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.string "platform_role"
    t.string "provider", default: "email", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.string "status", default: "active", null: false
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "external_id"], name: "index_users_on_provider_and_external_id", unique: true, where: "(external_id IS NOT NULL)"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "verifier_results", force: :cascade do |t|
    t.string "artifact_digest", null: false
    t.integer "artifact_id", null: false
    t.datetime "checked_at", precision: nil, null: false
    t.text "checks_json", default: "[]", null: false
    t.string "contract_version", null: false
    t.datetime "created_at", null: false
    t.text "metadata_json", default: "{}", null: false
    t.integer "organization_id", null: false
    t.integer "project_id", null: false
    t.string "result_code", null: false
    t.text "result_json", default: "{}", null: false
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.string "verifier_name", null: false
    t.string "verifier_version", null: false
    t.index ["artifact_id", "checked_at"], name: "index_verifier_results_on_artifact_id_and_checked_at"
    t.index ["artifact_id"], name: "index_verifier_results_on_artifact_id"
    t.index ["organization_id"], name: "index_verifier_results_on_organization_id"
    t.index ["project_id"], name: "index_verifier_results_on_project_id"
    t.index ["result_code"], name: "index_verifier_results_on_result_code", unique: true
  end

  create_table "webhook_deliveries", id: :serial, force: :cascade do |t|
    t.integer "attempt", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "delivered_at", precision: nil, null: false
    t.string "delivery_code", null: false
    t.integer "duration_ms", default: 0, null: false
    t.integer "max_attempts", default: 3, null: false
    t.text "response_json"
    t.integer "status", default: 200, null: false
    t.text "timeline_json"
    t.datetime "updated_at", null: false
    t.integer "webhook_endpoint_id", null: false
    t.index ["delivery_code"], name: "index_webhook_deliveries_on_delivery_code", unique: true
    t.index ["webhook_endpoint_id"], name: "index_webhook_deliveries_on_webhook_endpoint_id"
  end

  create_table "webhook_endpoints", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "endpoint_code", null: false
    t.text "events_json"
    t.integer "organization_id"
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.index ["endpoint_code"], name: "index_webhook_endpoints_on_endpoint_code", unique: true
    t.index ["organization_id"], name: "index_webhook_endpoints_on_organization_id"
  end

  add_foreign_key "activities", "projects"
  add_foreign_key "api_idempotency_keys", "organizations"
  add_foreign_key "api_keys", "organizations"
  add_foreign_key "api_logs", "organizations"
  add_foreign_key "artifact_profiles", "program_profiles"
  add_foreign_key "artifacts", "artifacts", column: "supersedes_artifact_id"
  add_foreign_key "artifacts", "projects"
  add_foreign_key "artifacts", "users", column: "issued_by_user_id"
  add_foreign_key "audit_events", "organizations"
  add_foreign_key "audit_events", "users", column: "actor_id"
  add_foreign_key "determinations", "determinations", column: "supersedes_determination_id"
  add_foreign_key "determinations", "evaluations"
  add_foreign_key "determinations", "program_profiles"
  add_foreign_key "determinations", "projects"
  add_foreign_key "evaluations", "program_profiles"
  add_foreign_key "evaluations", "projects"
  add_foreign_key "evidence_candidate_dispositions", "evidence_candidates"
  add_foreign_key "evidence_candidate_dispositions", "users", column: "actor_id"
  add_foreign_key "evidence_candidates", "evidence_records"
  add_foreign_key "evidence_candidates", "model_runs"
  add_foreign_key "evidence_candidates", "users", column: "reviewed_by_user_id"
  add_foreign_key "evidence_cases", "organizations"
  add_foreign_key "evidence_cases", "projects"
  add_foreign_key "evidence_records", "projects"
  add_foreign_key "evidence_records", "source_records"
  add_foreign_key "feature_flags", "organizations"
  add_foreign_key "gaps", "evidence_records"
  add_foreign_key "gaps", "projects"
  add_foreign_key "gaps", "source_records"
  add_foreign_key "integrations", "organizations"
  add_foreign_key "invitations", "organizations"
  add_foreign_key "invitations", "roles"
  add_foreign_key "invitations", "users", column: "invited_by_user_id"
  add_foreign_key "model_runs", "organizations"
  add_foreign_key "model_runs", "projects"
  add_foreign_key "organization_memberships", "organizations"
  add_foreign_key "organization_memberships", "roles"
  add_foreign_key "organization_memberships", "users"
  add_foreign_key "projects", "organizations"
  add_foreign_key "reliance_events", "artifacts"
  add_foreign_key "reliance_events", "organizations"
  add_foreign_key "reliance_events", "projects"
  add_foreign_key "reliance_events", "users", column: "recorded_by_user_id"
  add_foreign_key "requirements", "program_profiles"
  add_foreign_key "resource_grants", "users"
  add_foreign_key "resource_grants", "users", column: "granted_by_user_id"
  add_foreign_key "resource_grants", "users", column: "revoked_by_user_id"
  add_foreign_key "review_decisions", "reviews"
  add_foreign_key "review_decisions", "users"
  add_foreign_key "reviews", "projects"
  add_foreign_key "roles", "organizations"
  add_foreign_key "sessions", "organizations"
  add_foreign_key "sessions", "roles"
  add_foreign_key "sessions", "users"
  add_foreign_key "source_records", "organizations"
  add_foreign_key "source_records", "projects"
  add_foreign_key "statement_shares", "artifacts"
  add_foreign_key "statement_shares", "users", column: "created_by_user_id"
  add_foreign_key "verifier_results", "artifacts"
  add_foreign_key "verifier_results", "organizations"
  add_foreign_key "verifier_results", "projects"
  add_foreign_key "webhook_deliveries", "webhook_endpoints"
  add_foreign_key "webhook_endpoints", "organizations"
end
