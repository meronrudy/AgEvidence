class EvidenceController < ApplicationController
  before_action :authenticate_app_user!
  before_action :use_app_shell

  def index
    @tab = params[:tab].presence || "all"
    @records = tenant_records.includes(:project).order(received_at: :desc)
    @records = filter_records(@records, @tab)
    @selected_record = @records.find_by(record_code: params[:selected]) || @records.first
  end

  def records
    @records = tenant_records
      .where(status: ["accepted", "projected", "needs_review"])
      .includes(:project)
      .order(received_at: :desc, record_code: :asc)
    @selected_record = @records.find_by(record_code: params[:selected]) || @records.first
  end

  private

  def tenant_records
    current_organization.evidence_records
  end

  def filter_records(records, tab)
    case tab
    when "attention"
      records.where(status: ["needs_mapping", "schema_error", "needs_review"])
    when "accepted"
      records.where(status: ["accepted", "projected"])
    when "rejected"
      records.where(status: ["rejected", "schema_error"])
    else
      records
    end
  end
end
