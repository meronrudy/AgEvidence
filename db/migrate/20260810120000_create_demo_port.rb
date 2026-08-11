class CreateDemoPort < ActiveRecord::Migration[6.1]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :environment, null: false, default: "Production"

      t.timestamps
    end

    create_table :projects do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :slug, null: false
      t.string :project_code, null: false
      t.string :name, null: false
      t.string :jurisdiction, null: false
      t.string :program, null: false
      t.string :scope, null: false
      t.integer :readiness, null: false, default: 0
      t.string :status, null: false
      t.string :status_tone, null: false, default: "neutral"
      t.integer :open_gaps, null: false, default: 0
      t.integer :critical_gaps, null: false, default: 0
      t.string :review_status, null: false
      t.string :artifact_status, null: false
      t.datetime :last_activity_at
      t.text :metadata_json

      t.timestamps
    end
    add_index :projects, :slug, unique: true
    add_index :projects, :project_code, unique: true

    create_table :activities do |t|
      t.references :project, foreign_key: true
      t.string :activity_code, null: false
      t.datetime :occurred_at, null: false
      t.string :actor, null: false
      t.string :actor_kind, null: false, default: "system"
      t.string :title, null: false
      t.text :detail
      t.string :tone, null: false, default: "neutral"

      t.timestamps
    end
    add_index :activities, :activity_code, unique: true

    create_table :evidence_records do |t|
      t.references :project, null: false, foreign_key: true
      t.string :record_code, null: false
      t.string :label, null: false
      t.string :record_type, null: false
      t.string :status, null: false
      t.string :schema_name, null: false
      t.string :source, null: false
      t.datetime :received_at, null: false
      t.string :projection, null: false
      t.string :digest, null: false
      t.string :inbox_result
      t.string :operation_id
      t.text :summary_json
      t.text :payload_json
      t.text :integrity_json
      t.text :processing_json

      t.timestamps
    end
    add_index :evidence_records, :record_code, unique: true

    create_table :program_profiles do |t|
      t.string :slug, null: false
      t.string :code, null: false
      t.string :name, null: false
      t.string :status, null: false
      t.string :profile_version, null: false
      t.string :program, null: false
      t.string :scope, null: false
      t.string :methodology
      t.string :verification_profile
      t.string :evidence_policy
      t.integer :requirements_count, null: false, default: 0
      t.integer :machine_evaluable, null: false, default: 0
      t.integer :human_review, null: false, default: 0
      t.integer :profile_classes, null: false, default: 0
      t.text :composition_json
      t.text :version_diff_json
      t.text :version_impact_json
      t.text :comparison_json

      t.timestamps
    end
    add_index :program_profiles, :slug, unique: true
    add_index :program_profiles, :code, unique: true

    create_table :requirements do |t|
      t.references :program_profile, null: false, foreign_key: true
      t.string :requirement_code, null: false
      t.string :title, null: false
      t.string :category, null: false
      t.string :evaluation_mode, null: false
      t.string :status, null: false, default: "Active"
      t.text :authority
      t.text :accepted_evidence_json

      t.timestamps
    end
    add_index :requirements, :requirement_code, unique: true

    create_table :gaps do |t|
      t.references :project, null: false, foreign_key: true
      t.string :gap_code, null: false
      t.string :requirement_code, null: false
      t.string :severity, null: false
      t.string :title, null: false
      t.text :explanation, null: false
      t.text :expected_json
      t.text :observed_json
      t.text :related_evidence_json
      t.string :action, null: false

      t.timestamps
    end
    add_index :gaps, :gap_code, unique: true

    create_table :reviews do |t|
      t.references :project, null: false, foreign_key: true
      t.string :review_code, null: false
      t.string :requirement_code, null: false
      t.string :title, null: false
      t.string :state, null: false, default: "open"

      t.timestamps
    end
    add_index :reviews, :review_code, unique: true

    create_table :review_decisions do |t|
      t.references :review, null: false, foreign_key: true
      t.string :decision_code, null: false
      t.string :decision, null: false
      t.string :reviewer, null: false
      t.datetime :recorded_at, null: false
      t.text :rationale, null: false
      t.text :limitation

      t.timestamps
    end
    add_index :review_decisions, :decision_code, unique: true

    create_table :artifacts do |t|
      t.references :project, null: false, foreign_key: true
      t.string :artifact_code, null: false
      t.string :claim, null: false
      t.string :boundary, null: false
      t.string :jurisdiction, null: false
      t.string :program, null: false
      t.string :digest, null: false
      t.string :status, null: false, default: "ready"
      t.boolean :issued, null: false, default: false
      t.datetime :issued_at
      t.text :artifact_json
      t.text :integrity_json
      t.text :limitations_json
      t.text :receipt_chain_json

      t.timestamps
    end
    add_index :artifacts, :artifact_code, unique: true

    create_table :api_logs do |t|
      t.string :log_code, null: false
      t.string :method, null: false
      t.string :endpoint, null: false
      t.integer :status, null: false
      t.integer :duration_ms, null: false
      t.datetime :occurred_at, null: false
      t.string :operation_id, null: false
      t.text :request_json
      t.text :response_json
      t.text :trace_json

      t.timestamps
    end
    add_index :api_logs, :log_code, unique: true

    create_table :webhook_endpoints do |t|
      t.string :endpoint_code, null: false
      t.string :url, null: false
      t.string :status, null: false
      t.text :events_json

      t.timestamps
    end
    add_index :webhook_endpoints, :endpoint_code, unique: true

    create_table :webhook_deliveries do |t|
      t.references :webhook_endpoint, null: false, foreign_key: true
      t.string :delivery_code, null: false
      t.integer :attempt, null: false, default: 1
      t.integer :max_attempts, null: false, default: 3
      t.integer :status, null: false, default: 200
      t.integer :duration_ms, null: false, default: 0
      t.datetime :delivered_at, null: false
      t.text :response_json
      t.text :timeline_json

      t.timestamps
    end
    add_index :webhook_deliveries, :delivery_code, unique: true

    create_table :integrations do |t|
      t.string :integration_code, null: false
      t.string :name, null: false
      t.string :provider, null: false
      t.string :status, null: false
      t.integer :projects_count, null: false, default: 0
      t.datetime :last_sync_at
      t.text :events_json

      t.timestamps
    end
    add_index :integrations, :integration_code, unique: true

    create_table :schemas do |t|
      t.string :schema_code, null: false
      t.string :name, null: false
      t.string :version, null: false
      t.integer :events_count, null: false, default: 0
      t.string :status, null: false

      t.timestamps
    end
    add_index :schemas, :schema_code, unique: true

    create_table :api_keys do |t|
      t.string :key_code, null: false
      t.string :name, null: false
      t.string :token_hint, null: false
      t.string :status, null: false
      t.datetime :last_used_at

      t.timestamps
    end
    add_index :api_keys, :key_code, unique: true

    create_table :evaluations do |t|
      t.references :program_profile, null: false, foreign_key: true
      t.string :evaluation_code, null: false
      t.string :project_name, null: false
      t.string :outcome, null: false
      t.string :satisfied, null: false
      t.boolean :published, null: false, default: false
      t.datetime :evaluated_at, null: false

      t.timestamps
    end
    add_index :evaluations, :evaluation_code, unique: true

    create_table :determinations do |t|
      t.references :program_profile, null: false, foreign_key: true
      t.string :determination_code, null: false
      t.string :project_name, null: false
      t.string :outcome, null: false
      t.string :adapter, null: false
      t.string :digest, null: false
      t.datetime :published_at, null: false

      t.timestamps
    end
    add_index :determinations, :determination_code, unique: true
  end
end
