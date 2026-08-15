class VerificationController < ApplicationController
  def index
    @recent_artifacts = Artifact.where(issued: true).order(updated_at: :desc).limit(5)
    @issued_artifact_count = Artifact.where(issued: true).count
    @ready_artifact_count = Artifact.where(issued: false).count
  end

  def lookup
    id = params[:artifact_id].to_s.strip
    return redirect_to verify_path, alert: "Enter an Evidence Statement ID." if id.blank?

    redirect_to verify_artifact_path(id)
  end

  def show
    @artifact = Artifact.find_by(artifact_code: params[:id])
    @recent_artifacts = Artifact.where(issued: true).order(updated_at: :desc).limit(5)
    @issued_artifact_count = Artifact.where(issued: true).count
    @ready_artifact_count = Artifact.where(issued: false).count
    render status: (@artifact ? :ok : :not_found)
  end
end
