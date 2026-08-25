require "test_helper"

class StatementSharesTest < ActionDispatch::IntegrationTest
  setup do
    seed_demo!
    @statement = Artifact.find_by!(artifact_code: "AE-AU-000184")
  end

  test "active share exposes authorized statement scope" do
    share = @statement.statement_shares.create!(
      access_level: "statement_only",
      expires_at: 1.day.from_now
    )

    get shared_statement_path(share.token)

    assert_response :success
    assert_includes response.body, "Evidence Statement AE-AU-000184"
    assert_includes response.body, "Statement only"
    refute_includes response.body, "Evaluation"
  end

  test "full bundle share exposes evidence records" do
    share = @statement.statement_shares.create!(
      access_level: "full_bundle",
      expires_at: 1.day.from_now
    )

    get shared_statement_path(share.token)

    assert_response :success
    assert_includes response.body, "EVT-99231"
    assert_includes response.body, "InterventionEvent"
  end

  test "revoked share is not accessible" do
    share = @statement.statement_shares.create!(
      access_level: "statement_and_summary",
      expires_at: 1.day.from_now
    )
    token = share.token
    share.revoke!

    get shared_statement_path(token)

    assert_response :not_found
  end

  test "expired share is not accessible" do
    share = @statement.statement_shares.create!(
      access_level: "statement_and_summary",
      expires_at: 1.day.ago
    )

    get shared_statement_path(share.token)

    assert_response :not_found
  end
end
