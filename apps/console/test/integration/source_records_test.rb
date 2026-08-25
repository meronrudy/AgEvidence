require "test_helper"

class SourceRecordsTest < ActionDispatch::IntegrationTest
  setup do
    seed_demo!
    sign_in_demo_user!
  end

  test "member intakes a source record" do
    assert_difference -> { SourceRecord.count }, 1 do
      assert_difference -> { AuditEvent.where(action: "source_record_intaked").count }, 1 do
        post source_records_project_path("dit-production"), params: {
          source_record: {
            source_system: "uDOSE SDK",
            document_id: "DOC-INTEGRATION-001",
            evidence_type: "source_manifest",
            evidence_class: "controlled_source",
            controlled_uri: "https://sources.example/DOC-INTEGRATION-001",
            commitment: "sha256:#{SecureRandom.hex(16)}",
            disclosure_status: "available",
            status: "received"
          }
        }
      end
    end

    assert_redirected_to source_records_project_path("dit-production")
  end

  test "invalid intake renders validation errors" do
    assert_no_difference -> { SourceRecord.count } do
      post source_records_project_path("dit-production"), params: {
        source_record: {
          source_system: "uDOSE SDK",
          document_id: "DOC-INTEGRATION-002",
          evidence_type: "source_manifest",
          evidence_class: "controlled_source",
          controlled_uri: "file:///tmp/raw.csv",
          commitment: "missing-algorithm",
          disclosure_status: "available",
          status: "received"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "Source record was not intaked"
  end

  test "member cannot view or create source records for another organization" do
    other_org = Organization.create!(name: "Other Org", environment: "Test")
    Role.default_roles_for_organization(other_org)
    other_project = Project.create!(
      organization: other_org,
      slug: "other-project",
      project_code: "PRJ-OTHER-001",
      name: "Other Project",
      jurisdiction: "Australia",
      program: "Beef",
      scope: "Scope 3",
      status: "Draft",
      review_status: "Not started",
      artifact_status: "Draft"
    )

    get source_records_project_path(other_project.slug)
    assert_response :not_found

    post source_records_project_path(other_project.slug), params: {
      source_record: {
        source_system: "Other",
        document_id: "DOC-OTHER-001",
        evidence_type: "source_manifest",
        evidence_class: "controlled_source",
        controlled_uri: "evidence://other/source/DOC-OTHER-001",
        commitment: "sha256:#{SecureRandom.hex(16)}",
        disclosure_status: "available",
        status: "received"
      }
    }
    assert_response :not_found
  end
end
