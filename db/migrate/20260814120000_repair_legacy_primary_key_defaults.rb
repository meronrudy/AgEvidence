class RepairLegacyPrimaryKeyDefaults < ActiveRecord::Migration[8.1]
  LEGACY_INTEGER_PRIMARY_KEY_TABLES = %w[
    activities
    determinations
    evaluations
    evidence_records
    gaps
    projects
    requirements
    reviews
    webhook_deliveries
  ].freeze

  def up
    raise "RepairLegacyPrimaryKeyDefaults requires PostgreSQL" unless postgresql?

    LEGACY_INTEGER_PRIMARY_KEY_TABLES.each do |table|
      quoted_table = connection.quote_table_name(table)
      sequence = "#{table}_id_seq"
      quoted_sequence = connection.quote_table_name(sequence)
      sequence_literal = connection.quote(sequence)

      execute <<~SQL.squish
        CREATE SEQUENCE IF NOT EXISTS #{quoted_sequence}
      SQL

      execute <<~SQL.squish
        ALTER SEQUENCE #{quoted_sequence} OWNED BY #{quoted_table}.id
      SQL

      execute <<~SQL.squish
        SELECT setval(
          #{sequence_literal},
          COALESCE((SELECT MAX(id) FROM #{quoted_table}), 0) + 1,
          false
        )
      SQL

      execute <<~SQL.squish
        ALTER TABLE #{quoted_table}
        ALTER COLUMN id SET DEFAULT nextval(#{sequence_literal}::regclass)
      SQL
    end
  end

  def down
    raise "RepairLegacyPrimaryKeyDefaults requires PostgreSQL" unless postgresql?

    LEGACY_INTEGER_PRIMARY_KEY_TABLES.each do |table|
      quoted_table = connection.quote_table_name(table)
      sequence = "#{table}_id_seq"
      quoted_sequence = connection.quote_table_name(sequence)

      execute <<~SQL.squish
        ALTER TABLE #{quoted_table}
        ALTER COLUMN id DROP DEFAULT
      SQL

      execute <<~SQL.squish
        DROP SEQUENCE IF EXISTS #{quoted_sequence}
      SQL
    end
  end

  private

  def postgresql?
    connection.adapter_name.casecmp("PostgreSQL").zero?
  end
end
