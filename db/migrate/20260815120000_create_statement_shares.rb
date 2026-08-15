class CreateStatementShares < ActiveRecord::Migration[8.1]
  def change
    create_table :statement_shares do |t|
      t.references :artifact, null: false, foreign_key: true
      t.references :created_by_user, foreign_key: { to_table: :users }
      t.string :token_digest, null: false
      t.string :access_level, null: false
      t.datetime :expires_at, null: false
      t.datetime :revoked_at
      t.datetime :last_accessed_at
      t.integer :access_count, null: false, default: 0

      t.timestamps
    end

    add_index :statement_shares, :token_digest, unique: true
    add_index :statement_shares, [:artifact_id, :revoked_at]
  end
end
