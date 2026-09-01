require "test_helper"

class PortfolioPublicBrandingTest < ActionDispatch::IntegrationTest
  setup do
    seed_demo!
  end

  test "earthodic public verification renders issuing organization brand and canonical digest" do
    artifact = Artifact.find_by!(artifact_code: "QA-EARTH-APP-001")

    host! "qualification.earthodic.com"
    get verify_artifact_path(artifact.artifact_code)

    assert_response :success
    assert_includes response.body, "Biobarc Qualification"
    assert_includes response.body, "Qualification Pack hash"
    assert_includes response.body, artifact.digest
    assert_includes response.body, artifact.artifact_code
  end

  test "verification of another issuer uses the artifact issuer brand" do
    artifact = Artifact.find_by!(artifact_code: "AE-AU-000184")

    host! "qualification.earthodic.com"
    get verify_artifact_path(artifact.artifact_code)

    assert_response :success
    assert_includes response.body, "AgEvidence"
    assert_includes response.body, "Evidence Statement hash"
    assert_includes response.body, artifact.digest
  end

  test "earthodic share page is branded without changing artifact contract fields" do
    artifact = Artifact.find_by!(artifact_code: "QA-EARTH-APP-001")
    share = artifact.statement_shares.create!(
      access_level: "statement_and_summary",
      expires_at: 1.day.from_now
    )

    get shared_statement_path(share.token)

    assert_response :success
    assert_includes response.body, "Biobarc Qualification"
    assert_includes response.body, "Qualification Pack QA-EARTH-APP-001"
    assert_includes response.body, artifact.digest
    assert_includes response.body, "Bounded to supplied converter and lab records."
  end

  test "unknown custom domains do not fall through to another tenant" do
    host! "unknown-custom-domain.test-company.invalid"

    get verify_artifact_path("QA-EARTH-APP-001")

    assert_response :not_found
    refute_includes response.body, "QA-EARTH-APP-001"
  end
end
