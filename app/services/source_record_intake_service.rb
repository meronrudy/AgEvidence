class SourceRecordIntakeService
  def self.create!(project:, actor:, attributes:, metadata: {})
    new(project: project, actor: actor, attributes: attributes, metadata: metadata).create!
  end

  def initialize(project:, actor:, attributes:, metadata:)
    @project = project
    @actor = actor
    @attributes = attributes.to_h
    @metadata = metadata
  end

  def create!
    SourceRecord.transaction do
      source_record = @project.source_records.create!(@attributes.merge(organization: @project.organization))

      AuditEvent.log!(
        action: "source_record_intaked",
        actor: @actor,
        organization: @project.organization,
        auditable: source_record,
        metadata: @metadata.merge(record_code: source_record.record_code, project_code: @project.project_code)
      )

      source_record
    end
  end
end
