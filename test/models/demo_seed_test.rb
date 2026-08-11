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
      evidence_records: EvidenceRecord.count,
      evidence_cases: EvidenceCase.count,
      program_profiles: ProgramProfile.count,
      artifacts: Artifact.count
    }

    seed_demo!

    assert_equal counts, {
      organizations: Organization.count,
      users: User.count,
      roles: Role.count,
      organization_memberships: OrganizationMembership.count,
      invitations: Invitation.count,
      projects: Project.count,
      evidence_records: EvidenceRecord.count,
      evidence_cases: EvidenceCase.count,
      program_profiles: ProgramProfile.count,
      artifacts: Artifact.count
    }
    assert_equal "RA-AU-000184", Artifact.find_by!(artifact_code: "RA-AU-000184").artifact_code
    assert_equal "dit-au-methane", Project.find_by!(project_code: "PRJ-AU-00041").slug
    assert_equal "DET-002", Determination.find_by!(project_name: "DIT Methane Intervention Evidence").determination_code
    assert_equal "EVAL-001", Evaluation.find_by!(project_name: "DIT Methane Intervention Evidence").evaluation_code
    assert_equal "VIC-012", EvidenceRecord.find_by!(record_code: "SM-441").payload.fetch("facility")
    user = User.find_by!(email: "emma@agevidence.example")
    assert user.can_access_organization?(Organization.find_by!(name: "DIT AgTech"))
    assert user.valid_password?("demo")
    assert_equal user, User.find_for_database_authentication(email: "demo")
  end
end
