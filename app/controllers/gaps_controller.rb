class GapsController < ApplicationController
  before_action :authenticate_app_user!
  before_action :use_app_shell

  def index
    @gaps = current_organization.gaps
      .includes(:project, :source_record, :evidence_record)
      .order(blocking: :desc, severity: :asc, gap_code: :asc)
  end
end
