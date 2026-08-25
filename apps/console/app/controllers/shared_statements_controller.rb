class SharedStatementsController < ApplicationController
  def show
    @share = StatementShare.find_active_by_token(params[:token])
    return not_found unless @share

    @share.record_access!
    @statement = @share.artifact
    @project = @statement.project
    @evaluation = @project.evaluations.order(evaluated_at: :desc).first if expose_summary?
    @determination = @project.determinations.order(published_at: :desc).first if expose_summary?
    @evidence_records = @project.evidence_records.order(:record_code) if expose_full_bundle?
  end

  private

  def expose_summary?
    @share.access_level.in?(%w[statement_and_summary full_bundle])
  end

  def expose_full_bundle?
    @share.access_level == "full_bundle"
  end
end
