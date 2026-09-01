class AddPortfolioProductFactory < ActiveRecord::Migration[8.1]
  def change
    change_table :organizations do |t|
      t.string :portfolio_product_pack
      t.string :portfolio_product_pack_version
      t.string :deployment_mode, null: false, default: "shared_managed"
      t.string :brand_name
      t.string :brand_domain
      t.string :support_email
      t.string :legal_entity_name
      t.string :default_currency, null: false, default: "USD"
      t.string :default_locale, null: false, default: "en"
    end

    create_table :domain_mappings do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :hostname, null: false
      t.string :status, null: false, default: "pending"
      t.datetime :verified_at
      t.boolean :primary, null: false, default: false

      t.timestamps
    end
    add_index :domain_mappings, :hostname, unique: true
    add_index :domain_mappings, [:organization_id, :primary]

    create_table :price_versions do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :product_code, null: false
      t.string :product_version, null: false
      t.string :currency, null: false
      t.string :pricing_unit, null: false
      t.integer :list_price_cents
      t.integer :minimum_price_cents
      t.text :pricing_formula_json, null: false, default: "{}"
      t.datetime :effective_from, null: false
      t.datetime :effective_to
      t.string :status, null: false, default: "active"
      t.text :metadata_json, null: false, default: "{}"

      t.timestamps
    end
    add_index :price_versions, [:organization_id, :product_code, :product_version, :currency, :pricing_unit], name: "index_price_versions_on_org_product_version_unit"
    add_index :price_versions, [:organization_id, :product_code, :status]

    create_table :pricing_experiments do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :price_version, foreign_key: true
      t.string :product_code, null: false
      t.string :product_version, null: false
      t.string :name, null: false
      t.text :hypothesis
      t.string :customer_segment
      t.string :geography
      t.string :pricing_unit, null: false
      t.string :status, null: false, default: "active"
      t.datetime :started_at
      t.datetime :ended_at
      t.text :metadata_json, null: false, default: "{}"

      t.timestamps
    end
    add_index :pricing_experiments, [:organization_id, :product_code, :status], name: "index_pricing_experiments_on_org_product_status"

    create_table :pricing_quotes do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :project, foreign_key: true
      t.references :price_version, null: false, foreign_key: true
      t.references :pricing_experiment, foreign_key: true
      t.string :quote_id, null: false
      t.string :product_code, null: false
      t.string :product_version, null: false
      t.string :currency, null: false
      t.string :pricing_unit, null: false
      t.integer :list_price_cents
      t.integer :offered_price_cents
      t.integer :discount_cents
      t.integer :quantity, null: false, default: 1
      t.text :commercial_terms_json, null: false, default: "{}"
      t.text :breakdown_json, null: false, default: "[]"
      t.string :status, null: false, default: "quoted"
      t.datetime :quoted_at, null: false
      t.datetime :expires_at
      t.datetime :accepted_at

      t.timestamps
    end
    add_index :pricing_quotes, :quote_id, unique: true
    add_index :pricing_quotes, [:organization_id, :product_code, :status]

    create_table :artifact_orders do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :project, foreign_key: true
      t.references :pricing_quote, foreign_key: true
      t.string :order_id, null: false
      t.string :product_code, null: false
      t.string :artifact_profile_code
      t.integer :quantity, null: false, default: 1
      t.string :status, null: false, default: "created"
      t.datetime :checkout_completed_at
      t.text :metadata_json, null: false, default: "{}"

      t.timestamps
    end
    add_index :artifact_orders, :order_id, unique: true
    add_index :artifact_orders, [:organization_id, :product_code, :status]

    create_table :commercial_outcomes do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :pricing_quote, foreign_key: true
      t.references :artifact_order, foreign_key: true
      t.references :pricing_experiment, foreign_key: true
      t.string :product_code, null: false
      t.string :state, null: false
      t.datetime :occurred_at, null: false
      t.integer :sales_cycle_days
      t.integer :accepted_price_cents
      t.integer :recurring_value_cents
      t.string :reason
      t.text :metadata_json, null: false, default: "{}"

      t.timestamps
    end
    add_index :commercial_outcomes, [:organization_id, :product_code, :state]

    create_table :commercial_events do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :project, foreign_key: true
      t.references :pricing_quote, foreign_key: true
      t.references :artifact_order, foreign_key: true
      t.string :product_code
      t.string :event_type, null: false
      t.datetime :occurred_at, null: false
      t.text :value_json, null: false, default: "{}"

      t.timestamps
    end
    add_index :commercial_events, [:organization_id, :event_type, :occurred_at]
    add_index :commercial_events, [:organization_id, :product_code, :occurred_at]
  end
end
