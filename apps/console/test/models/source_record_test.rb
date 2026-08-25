require "test_helper"

class SourceRecordTest < ActiveSupport::TestCase
  setup do
    seed_demo!
    @project = Project.find_by!(slug: "dit-production")
  end

  test "validates required fields" do
    record = SourceRecord.new(project: @project, organization: @project.organization)

    assert_not record.valid?
    assert_includes record.errors.attribute_names, :source_system
    assert_includes record.errors.attribute_names, :controlled_uri
  end

  test "rejects unsupported uri schemes" do
    record = build_source_record(controlled_uri: "file:///tmp/raw.csv")

    assert_not record.valid?
    assert_includes record.errors[:controlled_uri], "must use https://, s3://, or evidence://"
  end

  test "rejects tenant mismatch" do
    other_org = Organization.create!(name: "Other Org", environment: "Test")
    record = build_source_record(organization: other_org)

    assert_not record.valid?
    assert_includes record.errors[:project], "must belong to the same organization"
  end

  test "rejects duplicate source identity per project" do
    original = SourceRecord.find_by!(record_code: "SR-DIT-SDK")
    duplicate = build_source_record(document_id: original.document_id)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:document_id], "has already been taken"
  end

  test "metadata defaults to an empty hash" do
    record = build_source_record(document_id: "DOC-DEFAULTS")

    assert_equal({}, record.metadata)
  end

  private

  def build_source_record(attrs = {})
    SourceRecord.new({
      project: @project,
      organization: @project.organization,
      source_system: "uDOSE SDK",
      document_id: "DOC-#{SecureRandom.hex(3)}",
      evidence_type: "intervention_event",
      evidence_class: "controlled_source",
      controlled_uri: "evidence://dit-production/source/#{SecureRandom.hex(3)}",
      commitment: "sha256:#{SecureRandom.hex(16)}",
      disclosure_status: "available",
      status: "received"
    }.merge(attrs))
  end
end
