class VerificationController < ApplicationController
  def index
    @brand = BrandResolver.resolve(organization: @domain_organization)
    set_public_artifact_metrics
  end

  def lookup
    id = params[:artifact_id].to_s.strip
    return redirect_to verify_path, alert: "Enter an Evidence Statement ID." if id.blank?

    redirect_to verify_artifact_path(id)
  end

  def show
    @artifact = Artifact.find_by(artifact_code: params[:id])
    @brand = @artifact ? BrandResolver.resolve(artifact: @artifact) : BrandResolver.resolve(organization: @domain_organization)
    set_public_artifact_metrics
    render status: (@artifact ? :ok : :not_found)
  end

  private

  def set_public_artifact_metrics
    organization = @artifact&.organization || @domain_organization
    scope = organization ? organization.artifacts : Artifact.all
    @recent_artifacts = scope.where(issued: true).order(updated_at: :desc).limit(5)
    @issued_artifact_count = scope.where(issued: true).count
    @ready_artifact_count = scope.where(issued: false).count
  end
end
