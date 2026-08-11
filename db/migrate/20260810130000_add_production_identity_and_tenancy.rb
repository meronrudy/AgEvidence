class AddProductionIdentityAndTenancy < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.integer :sign_in_count, null: false, default: 0
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string :current_sign_in_ip
      t.string :last_sign_in_ip
      t.string :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string :unconfirmed_email
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :provider, null: false, default: "email"
      t.string :external_id
      t.string :platform_role
      t.string :status, null: false, default: "active"

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :confirmation_token, unique: true
    add_index :users, [:provider, :external_id], unique: true, where: "external_id IS NOT NULL"

    create_table :roles do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.string :description

      t.timestamps
    end
    add_index :roles, [:organization_id, :name], unique: true

    create_table :organization_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.references :role, null: false, foreign_key: true
      t.string :status, null: false, default: "active"
      t.datetime :joined_at

      t.timestamps
    end
    add_index :organization_memberships, [:user_id, :organization_id], unique: true, name: "index_memberships_on_user_and_org"

    create_table :invitations do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :invited_by_user, foreign_key: { to_table: :users }
      t.references :role, null: false, foreign_key: true
      t.string :email, null: false
      t.string :token, null: false
      t.string :status, null: false, default: "pending"
      t.datetime :expires_at, null: false
      t.datetime :accepted_at

      t.timestamps
    end
    add_index :invitations, :token, unique: true
    add_index :invitations, [:organization_id, :email, :status]

    create_table :sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.references :role, null: false, foreign_key: true
      t.string :status, null: false, default: "active"
      t.string :ip_address, null: false
      t.string :user_agent, null: false
      t.datetime :last_seen_at
      t.datetime :revoked_at

      t.timestamps
    end
    add_index :sessions, [:user_id, :status]

    create_table :evidence_cases do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.string :case_number, null: false
      t.string :slug, null: false
      t.string :status, null: false, default: "open"
      t.text :metadata_json, null: false, default: "{}"

      t.timestamps
    end
    add_index :evidence_cases, [:organization_id, :case_number], unique: true
    add_index :evidence_cases, [:organization_id, :slug], unique: true

    create_table :resource_grants do |t|
      t.references :user, null: false, foreign_key: true
      t.references :grantable, null: false, polymorphic: true
      t.references :granted_by_user, foreign_key: { to_table: :users }
      t.string :access_level, null: false, default: "read"
      t.datetime :expires_at, null: false
      t.datetime :revoked_at

      t.timestamps
    end
    add_index :resource_grants, [:user_id, :grantable_type, :grantable_id], name: "index_resource_grants_on_user_and_resource"

    create_table :audit_events do |t|
      t.references :actor, foreign_key: { to_table: :users }
      t.references :organization, foreign_key: true
      t.references :auditable, polymorphic: true
      t.string :action, null: false
      t.text :metadata_json, null: false, default: "{}"
      t.string :ip_address
      t.string :user_agent
      t.string :request_id

      t.timestamps
    end
    add_index :audit_events, [:organization_id, :created_at]
    add_index :audit_events, [:auditable_type, :auditable_id, :created_at], name: "index_audit_events_on_auditable_and_created_at"

    add_reference :api_keys, :organization, foreign_key: true
    add_reference :api_logs, :organization, foreign_key: true
    add_reference :integrations, :organization, foreign_key: true
    add_reference :webhook_endpoints, :organization, foreign_key: true
    add_reference :review_decisions, :user, foreign_key: true
    add_reference :artifacts, :issued_by_user, foreign_key: { to_table: :users }
  end
end
