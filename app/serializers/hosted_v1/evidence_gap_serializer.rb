module HostedV1
  class EvidenceGapSerializer
    def initialize(gap)
      @gap = gap
    end

    def as_json
      {
        id: @gap.gap_code,
        model_run_id: @gap.model_run&.run_code,
        gap_type: @gap.gap_type,
        description: @gap.description,
        severity: @gap.severity,
        status: @gap.status,
        created_at: @gap.created_at&.iso8601
      }
    end
  end
end