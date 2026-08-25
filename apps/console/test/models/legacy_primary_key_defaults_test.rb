require "test_helper"

class LegacyPrimaryKeyDefaultsTest < ActiveSupport::TestCase
  TABLES = %w[
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

  test "legacy integer primary key tables generate ids after schema load" do
    suffix = SecureRandom.hex(4)
    now = Time.current

    organization = Organization.create!(name: "PK Default Org #{suffix}", environment: "Test")
    project_id = insert_row("projects", {
      organization_id: organization.id,
      slug: "pk-default-project-#{suffix}",
      project_code: "PRJ-PK-#{suffix.upcase}",
      name: "PK Default Project",
      jurisdiction: "Australia",
      program: "Beef",
      scope: "Scope 3",
      status: "Draft",
      review_status: "Not started",
      artifact_status: "Draft",
      created_at: now,
      updated_at: now
    })

    profile = ProgramProfile.create!(
      slug: "pk-default-profile-#{suffix}",
      code: "PK-#{suffix.upcase}",
      name: "PK Default Profile",
      status: "Draft",
      profile_version: "v0",
      program: "Agricultural Climate Evidence",
      scope: "Test"
    )
    webhook_endpoint = WebhookEndpoint.create!(
      organization: organization,
      endpoint_code: "WHE-PK-#{suffix.upcase}",
      url: "https://hooks.example/#{suffix}",
      status: "active",
      events: ["artifact.issued"]
    )

    ids = {
      "activities" => insert_row("activities", {
        project_id: project_id,
        activity_code: "ACT-PK-#{suffix.upcase}",
        occurred_at: now,
        actor: "Test",
        actor_kind: "system",
        title: "Primary key default check",
        created_at: now,
        updated_at: now
      }),
      "evidence_records" => insert_row("evidence_records", {
        project_id: project_id,
        record_code: "EV-PK-#{suffix.upcase}",
        label: "Primary key default evidence",
        record_type: "source_manifest",
        status: "accepted",
        schema_name: "pk_default.v0",
        source: "Test",
        received_at: now,
        projection: "agevidence.pk_default.v0",
        digest: "sha256:#{SecureRandom.hex(16)}",
        created_at: now,
        updated_at: now
      }),
      "requirements" => insert_row("requirements", {
        program_profile_id: profile.id,
        requirement_code: "REQ-PK-#{suffix.upcase}",
        title: "Primary key default requirement",
        category: "evidence",
        evaluation_mode: "machine",
        created_at: now,
        updated_at: now
      }),
      "gaps" => insert_row("gaps", {
        project_id: project_id,
        gap_code: "GAP-PK-#{suffix.upcase}",
        requirement_code: "REQ-PK-#{suffix.upcase}",
        severity: "low",
        title: "Primary key default gap",
        explanation: "This gap exists only to verify id defaults.",
        action: "No action",
        created_at: now,
        updated_at: now
      }),
      "reviews" => insert_row("reviews", {
        project_id: project_id,
        review_code: "REV-PK-#{suffix.upcase}",
        requirement_code: "REQ-PK-#{suffix.upcase}",
        title: "Primary key default review",
        created_at: now,
        updated_at: now
      }),
      "evaluations" => insert_row("evaluations", {
        program_profile_id: profile.id,
        project_id: project_id,
        evaluation_code: "EVAL-PK-#{suffix.upcase}",
        project_name: "PK Default Project",
        outcome: "Eligible",
        satisfied: "1 / 1",
        published: false,
        evaluated_at: now,
        input_digest: "sha256:#{SecureRandom.hex(16)}",
        profile_version: "v0",
        status: "current",
        created_at: now,
        updated_at: now
      }),
      "webhook_deliveries" => insert_row("webhook_deliveries", {
        webhook_endpoint_id: webhook_endpoint.id,
        delivery_code: "WHD-PK-#{suffix.upcase}",
        delivered_at: now,
        created_at: now,
        updated_at: now
      })
    }
    ids["determinations"] = insert_row("determinations", {
      program_profile_id: profile.id,
      project_id: project_id,
      evaluation_id: ids.fetch("evaluations"),
      determination_code: "DET-PK-#{suffix.upcase}",
      project_name: "PK Default Project",
      outcome: "Eligible",
      adapter: "PK v0",
      digest: "sha256:#{SecureRandom.hex(16)}",
      published_at: now,
      status: "published",
      created_at: now,
      updated_at: now
    })
    ids["projects"] = project_id

    assert_equal TABLES.sort, ids.keys.sort
    ids.each do |table, id|
      assert_operator id, :>, 0, "#{table} did not generate a primary key"
    end
  end

  private

  def insert_row(table, attributes)
    quoted_columns = attributes.keys.map { |column| connection.quote_column_name(column) }
    quoted_values = attributes.values.map { |value| connection.quote(value) }

    connection.select_value(<<~SQL.squish).to_i
      INSERT INTO #{connection.quote_table_name(table)} (#{quoted_columns.join(", ")})
      VALUES (#{quoted_values.join(", ")})
      RETURNING id
    SQL
  end

  def connection
    ActiveRecord::Base.connection
  end
end
