require "test_helper"

class DemoSeedTest < ActiveSupport::TestCase
  test "seed creates canonical demo data and is idempotent" do
    seed_demo!

    counts = {
      organizations: Organization.count,
      users: User.count,
      roles: Role.count,
      organization_memberships: OrganizationMembership.count,
      invitations: Invitation.count,
      projects: Project.count,
      source_records: SourceRecord.count,
      evidence_records: EvidenceRecord.count,
      model_runs: ModelRun.count,
      evidence_candidates: EvidenceCandidate.count,
      evidence_cases: EvidenceCase.count,
      program_profiles: ProgramProfile.count,
      artifact_profiles: ArtifactProfile.count,
      artifacts: Artifact.count,
      verifier_results: VerifierResult.count,
      reliance_events: RelianceEvent.count
    }

    seed_demo!

    assert_equal counts, {
      organizations: Organization.count,
      users: User.count,
      roles: Role.count,
      organization_memberships: OrganizationMembership.count,
      invitations: Invitation.count,
      projects: Project.count,
      source_records: SourceRecord.count,
      evidence_records: EvidenceRecord.count,
      model_runs: ModelRun.count,
      evidence_candidates: EvidenceCandidate.count,
      evidence_cases: EvidenceCase.count,
      program_profiles: ProgramProfile.count,
      artifact_profiles: ArtifactProfile.count,
      artifacts: Artifact.count,
      verifier_results: VerifierResult.count,
      reliance_events: RelianceEvent.count
    }
    assert_equal 1, Organization.count
    assert_equal "AE-AU-000184", Artifact.find_by!(artifact_code: "AE-AU-000184").artifact_code
    assert_equal "dit-production", Project.find_by!(project_code: "PRJ-AU-00041").slug
    assert_equal "DET-AU-000184", Determination.find_by!(project_name: "DIT Production Evidence").determination_code
    assert_equal "EVAL-AU-METH-001", Evaluation.find_by!(project_name: "DIT Production Evidence").evaluation_code
    assert_equal "dit-production", Evaluation.find_by!(evaluation_code: "EVAL-AU-METH-001").project.slug
    assert_equal "AU_METHANE_INTERVENTION_V1", ProgramProfile.find_by!(slug: "au-methane-intervention-v1").code
    assert_equal 15, ProgramProfile.find_by!(code: "AU_METHANE_INTERVENTION_V1").requirements.count
    primitive_chain = %w[SRC-PL-443 SRC-C-18 EVT-99231 OP-22019 OBS-828 MR-334].map { |code| EvidenceRecord.find_by!(record_code: code).record_type }
    assert_equal %w[source_record source_record intervention_event operational_event observation model_run], primitive_chain
    fixture_chain = JSON.parse(Rails.root.join("test/fixtures/evidence/dit_production_chain.json").read).fetch("records").map { |record| record.fetch("id") }
    assert_equal %w[SRC-PL-443 SRC-C-18 EVT-99231 OP-22019 OBS-828 MR-334], fixture_chain
    assert_equal "SR-DIT-SDK", SourceRecord.find_by!(record_code: "SR-DIT-SDK").record_code
    assert_equal "SR-DIT-SDK", EvidenceRecord.find_by!(record_code: "EVT-99231").source_record.record_code
    assert_equal "GF-4412", EvidenceRecord.find_by!(record_code: "OBS-828").payload.fetch("instrument")
    user = User.find_by!(email: "emma@agevidence.example")
    assert user.can_access_organization?(Organization.find_by!(name: "DIT AgTech"))
    assert user.valid_password?("demo")
    assert_equal user, User.find_for_database_authentication(email: "demo")
  end
end
