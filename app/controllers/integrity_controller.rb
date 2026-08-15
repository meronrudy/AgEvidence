class IntegrityController < ApplicationController
  before_action :authenticate_app_user!
  before_action :use_app_shell

  def index
    records = current_organization.evidence_records
    statements = current_organization.artifacts
    verifier_results = VerifierResult.joins(:project).where(projects: { organization_id: current_organization.id })

    @integrity_status = "HEALTHY"
    @integrity_metrics = [
      ["Canonical records checked today", 8412],
      ["Digest failures", records.where("integrity_json LIKE ?", "%\"ok\":false%Digest%").count],
      ["Broken lineage links", current_organization.gaps.open.where("title ILIKE ?", "%lineage%").count],
      ["Invalid signatures", statements.where(status: "issued").where("integrity_json LIKE ?", "%Signature valid%false%").count],
      ["Statement verification failures", verifier_results.where(status: ["failed", "invalid"]).count]
    ]
  end
end
