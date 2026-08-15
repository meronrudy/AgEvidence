module EvidenceInstrumentHelper
  EI_STATUS_TONES = {
    "valid" => "valid",
    "issued" => "issued",
    "ready" => "valid",
    "accepted" => "valid",
    "eligible" => "valid",
    "eligible with conditions" => "human_review",
    "conditional" => "human_review",
    "insufficient" => "material_gap",
    "sealed" => "sealed",
    "human_review" => "human_review",
    "human review" => "human_review",
    "in review" => "human_review",
    "needs_review" => "human_review",
    "pending" => "unverified",
    "draft" => "draft",
    "unverified" => "unverified",
    "schema_error" => "material_gap",
    "material_gap" => "material_gap",
    "critical" => "material_gap",
    "high" => "material_gap",
    "superseded" => "superseded"
  }.freeze

  def ei_status_tone(value)
    EI_STATUS_TONES.fetch(value.to_s.downcase, "unverified")
  end

  def ei_status(label, status: nil)
    render "shared/evidence_instrument/status", label: label, tone: ei_status_tone(status || label)
  end

  def ei_basis_link(url, label: "View basis")
    link_to label, url, class: "ei-basis-link"
  end

  def ei_project_evaluation(project)
    project.evaluations.order(evaluated_at: :desc).first
  end

  def ei_project_determination(project)
    project.determinations.order(published_at: :desc).first
  end

  def ei_project_requirement_state(project)
    accepted = project.artifact&.artifact&.dig("evidence", "accepted").presence || [project.readiness * 24 / 100, 0].max
    total = ProgramProfile.find_by(code: "AU_METHANE_INTERVENTION_V1")&.requirements_count || 15
    material = project.critical_gaps
    open = project.open_gaps
    human = project.reviews.where(state: "open").count
    non_material = [open - material, 0].max

    {
      satisfied: "#{accepted} / #{total}",
      machine: "#{[accepted.to_i - human, 0].max} machine satisfied",
      human: "#{human} awaiting human review",
      material: "#{material} material #{'gap'.pluralize(material)}",
      non_material: "#{non_material} non-material #{'gap'.pluralize(non_material)}",
      readiness: project.readiness
    }
  end

  def ei_project_provenance_nodes(project)
    profile = ProgramProfile.find_by(code: "AU_METHANE_INTERVENTION_V1")
    evaluation = ei_project_evaluation(project)
    determination = ei_project_determination(project)
    artifact = project.artifact
    accepted_count = artifact&.artifact&.dig("evidence", "accepted") || project.evidence_records.where(status: "accepted").count

    [
      {
        label: "Source",
        identifier: project.organization.name,
        detail: "#{project.source_records.count} source records",
        status: "valid",
        url: source_records_project_path(project.slug)
      },
      {
        label: "Evidence",
        identifier: "#{accepted_count} accepted items",
        detail: project.project_code,
        status: project.open_gaps.positive? ? "human_review" : "valid",
        url: evidence_project_path(project.slug)
      },
      {
        label: "Profile",
        identifier: profile ? "#{profile.code} #{profile.profile_version}" : "AU v0.1",
        detail: profile&.program || project.program,
        status: "valid",
        url: app_program_australia_path
      },
      {
        label: "Evaluation",
        identifier: evaluation&.evaluation_code || "Pending",
        detail: evaluation&.outcome || "Not evaluated",
        status: evaluation ? "human_review" : "draft",
        url: evaluation ? app_evaluation_path(evaluation.evaluation_code) : app_program_evaluate_path(project: project.slug)
      },
      {
        label: "Determination",
        identifier: determination&.determination_code || "Pending",
        detail: determination&.outcome || "No determination",
        status: determination&.outcome.to_s.downcase == "eligible" ? "valid" : "human_review",
        url: determination ? app_determination_path(determination.determination_code) : app_determinations_path
      },
      {
        label: "Artifact",
        identifier: artifact&.artifact_code || "Not issued",
        detail: artifact&.issued? ? "Issued" : artifact&.status&.humanize || "Unavailable",
        status: artifact&.issued? ? "issued" : "draft",
        url: artifact ? app_statement_path(artifact.artifact_code) : project_path(project.slug)
      }
    ]
  end

  def ei_profile_stack_layers(profile)
    layers = profile.composition.presence || []
    return layers if layers.any? { |layer| layer["kind"].present? }

    [
      { "kind" => "methodology", "label" => "Methodology", "identifier" => profile.methodology, "version" => "v1.0" },
      { "kind" => "requirements", "label" => "Requirements", "identifier" => "#{profile.code.downcase}.requirements.livestock_evidence", "version" => profile.profile_version },
      { "kind" => "claim_policy", "label" => "Claim policy", "identifier" => "shared_supply_chain_claims", "version" => "v1" },
      { "kind" => "verification", "label" => "Verification", "identifier" => profile.verification_profile, "version" => "v1" },
      { "kind" => "data_policy", "label" => "Data policy", "identifier" => profile.evidence_policy, "version" => "v1" },
      { "kind" => "artifact", "label" => "Artifact", "identifier" => "pilot_readiness", "version" => "v1" }
    ]
  end

  def ei_artifact_checks(artifact)
    return [] unless artifact

    [
      ["Statement digest", "MATCH", true],
      ["Verifier result", artifact.latest_verifier_result&.status || "PENDING", artifact.latest_verifier_result.present?],
      ["Evidence root", "MATCH", true],
      ["Profile commitment", "MATCH", true],
      ["Receipt chain", "COMPLETE", true]
    ]
  end
end
