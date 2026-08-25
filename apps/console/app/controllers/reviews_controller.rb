class ReviewsController < ApplicationController
  before_action :authenticate_app_user!
  before_action :use_app_shell

  def index
    @reviews = current_organization.reviews
      .includes(:project, :review_decisions)
      .order(state: :asc, review_code: :asc)
  end

  def show
    @review = current_organization.reviews
      .includes(:project, :review_decisions)
      .find_by!(review_code: params[:code])
    @project = @review.project
    authorize @project
    @gap = @project.gaps.open.find_by(requirement_code: @review.requirement_code)
    @evidence_records = @project.evidence_records.order(:record_type, :record_code)
    @decisions = @review.review_decisions.order(recorded_at: :desc)
  end
end
