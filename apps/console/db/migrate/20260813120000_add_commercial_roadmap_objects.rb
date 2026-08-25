class AddCommercialRoadmapObjects < ActiveRecord::Migration[8.1]
  def up
    create_table :source_records do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.string :record_code, null: false
      t.string :source_system, null: false
      t.string :document_id, null: false
      t.string :evidence_type, null: false
      t.string :evidence_class, null: false
      t.string :controlled_uri, null: false
      t.string :commitment, null: false
      t.string :disclosure_status, null: false
      t.string :status, null: false
      t.text :metadata_json, null: false, default: "{}"

      t.timestamps
    end
    add_index :source_records, :record_code, unique: true
    add_index :source_records, [:project_id, :document_id], unique: true
    add_index :source_records, [:organization_id, :project_id]

    add_reference :evidence_records, :source_record, foreign_key: true
    add_index :evidence_records, [:project_id, :source_record_id]

    create_table :model_runs do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.string :run_code, null: false
      t.string :adapter_name, null: false
      t.string :adapter_version, null: false
      t.string :input_commitment, null: false
      t.string :status, null: false
      t.datetime :started_at, null: false
      t.datetime :completed_at
      t.text :failure_reason
      t.text :output_json, null: false, default: "{}"
      t.text :metadata_json, null: false, default: "{}"

      t.timestamps
    end
    add_index :model_runs, :run_code, unique: true
    add_index :model_runs, [:organization_id, :project_id]

    create_table :evidence_candidates do |t|
      t.references :model_run, null: false, foreign_key: true
      t.references :evidence_record, foreign_key: true
      t.references :reviewed_by_user, foreign_key: { to_table: :users }
      t.string :candidate_code, null: false
      t.string :candidate_type, null: false
      t.text :claim, null: false
      t.decimal :confidence, precision: 5, scale: 4
      t.string :status, null: false
      t.text :basis_json, null: false, default: "[]"
      t.text :limitations_json, null: false, default: "[]"
      t.text :disposition_reason
      t.datetime :reviewed_at

      t.timestamps
    end
    add_index :evidence_candidates, :candidate_code, unique: true
    add_index :evidence_candidates, [:model_run_id, :status]

    create_table :evidence_candidate_dispositions do |t|
      t.references :evidence_candidate, null: false, foreign_key: true
      t.references :actor, foreign_key: { to_table: :users }
      t.string :status, null: false
      t.text :reason, null: false
      t.datetime :recorded_at, null: false
      t.text :metadata_json, null: false, default: "{}"

      t.timestamps
    end
    add_index :evidence_candidate_dispositions, [:evidence_candidate_id, :recorded_at], name: "index_candidate_dispositions_on_candidate_and_recorded_at"

    add_column :gaps, :status, :string, null: false, default: "open"
    add_column :gaps, :blocking, :boolean, null: false, default: false
    add_reference :gaps, :source_record, foreign_key: true
    add_reference :gaps, :evidence_record, foreign_key: true
    add_index :gaps, [:project_id, :requirement_code, :status]

    add_reference :evaluations, :project, foreign_key: true
    add_column :evaluations, :input_digest, :string
    add_column :evaluations, :profile_version, :string
    add_column :evaluations, :status, :string, null: false, default: "current"
    add_column :evaluations, :result_json, :text, null: false, default: "{}"
    add_column :evaluations, :stale_at, :datetime
    backfill_project_reference("evaluations")
    change_column_null :evaluations, :project_id, false
    change_column_null :evaluations, :input_digest, false, "sha256:seeded-evaluation-input"
    change_column_null :evaluations, :profile_version, false, "v0.1"
    add_index :evaluations, [:project_id, :program_profile_id, :evaluated_at]

    add_reference :determinations, :project, foreign_key: true
    add_reference :determinations, :evaluation, foreign_key: true
    add_reference :determinations, :supersedes_determination, foreign_key: { to_table: :determinations }
    add_column :determinations, :status, :string, null: false, default: "published"
    add_column :determinations, :result_json, :text, null: false, default: "{}"
    add_column :determinations, :superseded_at, :datetime
    backfill_project_reference("determinations")
    backfill_determination_evaluation_reference
    change_column_null :determinations, :project_id, false
    add_index :determinations, [:project_id, :program_profile_id, :published_at]

    add_column :program_profiles, :effective_from, :date
    add_column :program_profiles, :effective_to, :date
    add_column :program_profiles, :requirements_digest, :string
    add_column :program_profiles, :outcome_vocabulary_json, :text, null: false, default: "[]"
    add_column :program_profiles, :issuance_policy_json, :text, null: false, default: "{}"
    add_column :program_profiles, :limitation_templates_json, :text, null: false, default: "[]"
    add_column :program_profiles, :artifact_profile_selection, :string

    create_table :artifact_profiles do |t|
      t.references :program_profile, null: false, foreign_key: true
      t.string :profile_code, null: false
      t.string :profile_version, null: false
      t.string :status, null: false
      t.text :layout_json, null: false, default: "{}"
      t.text :recipient_rules_json, null: false, default: "{}"
      t.text :retention_json, null: false, default: "{}"

      t.timestamps
    end
    add_index :artifact_profiles, [:profile_code, :profile_version], unique: true

    add_column :artifacts, :contract_version, :string, null: false, default: "artifact-manifest.v0"
    add_reference :artifacts, :supersedes_artifact, foreign_key: { to_table: :artifacts }

    create_table :verifier_results do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.references :artifact, null: false, foreign_key: true
      t.string :result_code, null: false
      t.string :contract_version, null: false
      t.string :verifier_name, null: false
      t.string :verifier_version, null: false
      t.string :status, null: false
      t.string :artifact_digest, null: false
      t.datetime :checked_at, null: false
      t.text :checks_json, null: false, default: "[]"
      t.text :result_json, null: false, default: "{}"
      t.text :metadata_json, null: false, default: "{}"

      t.timestamps
    end
    add_index :verifier_results, :result_code, unique: true
    add_index :verifier_results, [:artifact_id, :checked_at]

    create_table :reliance_events do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.references :artifact, null: false, foreign_key: true
      t.references :recorded_by_user, foreign_key: { to_table: :users }
      t.string :event_code, null: false
      t.string :relying_party, null: false
      t.string :relying_party_role, null: false
      t.string :reliance_kind, null: false
      t.string :status, null: false
      t.datetime :occurred_at, null: false
      t.text :basis_json, null: false, default: "{}"
      t.text :metadata_json, null: false, default: "{}"

      t.timestamps
    end
    add_index :reliance_events, :event_code, unique: true
    add_index :reliance_events, [:organization_id, :project_id, :occurred_at]
    add_index :reliance_events, [:artifact_id, :occurred_at]

    add_column :api_keys, :token_digest, :string
    add_column :api_keys, :scopes_json, :text, null: false, default: "[]"
    add_column :api_keys, :revoked_at, :datetime
    add_index :api_keys, :token_digest, unique: true

    create_table :api_idempotency_keys do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :key, null: false
      t.string :method, null: false
      t.string :path, null: false
      t.integer :status, null: false
      t.text :response_json, null: false

      t.timestamps
    end
    add_index :api_idempotency_keys, [:organization_id, :key, :method, :path], unique: true, name: "index_api_idempotency_keys_on_org_key_method_path"

    add_column :resource_grants, :recipient_name, :string
    add_column :resource_grants, :recipient_email, :string
    add_reference :resource_grants, :revoked_by_user, foreign_key: { to_table: :users }
    add_column :resource_grants, :last_downloaded_at, :datetime

    create_table :feature_flags do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :flag_key, null: false
      t.boolean :enabled, null: false, default: false
      t.text :metadata_json, null: false, default: "{}"

      t.timestamps
    end
    add_index :feature_flags, [:organization_id, :flag_key], unique: true
  end

  def down
    drop_table :feature_flags
    remove_column :resource_grants, :last_downloaded_at
    remove_reference :resource_grants, :revoked_by_user, foreign_key: { to_table: :users }
    remove_column :resource_grants, :recipient_email
    remove_column :resource_grants, :recipient_name
    drop_table :api_idempotency_keys
    remove_index :api_keys, :token_digest
    remove_column :api_keys, :revoked_at
    remove_column :api_keys, :scopes_json
    remove_column :api_keys, :token_digest
    drop_table :reliance_events
    drop_table :verifier_results
    remove_reference :artifacts, :supersedes_artifact, foreign_key: { to_table: :artifacts }
    remove_column :artifacts, :contract_version
    drop_table :artifact_profiles
    remove_column :program_profiles, :artifact_profile_selection
    remove_column :program_profiles, :limitation_templates_json
    remove_column :program_profiles, :issuance_policy_json
    remove_column :program_profiles, :outcome_vocabulary_json
    remove_column :program_profiles, :requirements_digest
    remove_column :program_profiles, :effective_to
    remove_column :program_profiles, :effective_from
    remove_index :determinations, [:project_id, :program_profile_id, :published_at]
    remove_column :determinations, :superseded_at
    remove_column :determinations, :result_json
    remove_column :determinations, :status
    remove_reference :determinations, :supersedes_determination, foreign_key: { to_table: :determinations }
    remove_reference :determinations, :evaluation, foreign_key: true
    remove_reference :determinations, :project, foreign_key: true
    remove_index :evaluations, [:project_id, :program_profile_id, :evaluated_at]
    remove_column :evaluations, :stale_at
    remove_column :evaluations, :result_json
    remove_column :evaluations, :status
    remove_column :evaluations, :profile_version
    remove_column :evaluations, :input_digest
    remove_reference :evaluations, :project, foreign_key: true
    remove_index :gaps, [:project_id, :requirement_code, :status]
    remove_reference :gaps, :evidence_record, foreign_key: true
    remove_reference :gaps, :source_record, foreign_key: true
    remove_column :gaps, :blocking
    remove_column :gaps, :status
    drop_table :evidence_candidate_dispositions
    drop_table :evidence_candidates
    drop_table :model_runs
    remove_index :evidence_records, [:project_id, :source_record_id]
    remove_reference :evidence_records, :source_record, foreign_key: true
    drop_table :source_records
  end

  private

  def backfill_project_reference(table_name)
    execute <<~SQL.squish
      UPDATE #{table_name}
      SET project_id = projects.id
      FROM projects
      WHERE #{table_name}.project_name = projects.name
    SQL
  end

  def backfill_determination_evaluation_reference
    execute <<~SQL.squish
      UPDATE determinations
      SET evaluation_id = latest_evaluations.id
      FROM (
        SELECT DISTINCT ON (project_id, program_profile_id) id, project_id, program_profile_id
        FROM evaluations
        ORDER BY project_id, program_profile_id, evaluated_at DESC
      ) latest_evaluations
      WHERE determinations.project_id = latest_evaluations.project_id
        AND determinations.program_profile_id = latest_evaluations.program_profile_id
    SQL
  end
end
