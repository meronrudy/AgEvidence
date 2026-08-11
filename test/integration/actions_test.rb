require "test_helper"

class ActionsTest < ActionDispatch::IntegrationTest
  setup do
    seed_demo!
  end

  test "records a review decision" do
    sign_in_demo_user!
    review = Review.find_by!(review_code: "RV-202")

    assert_difference -> { review.review_decisions.count }, 1 do
      assert_difference -> { AuditEvent.where(action: "review_decision_created").count }, 1 do
      post review_decisions_project_path("dit-au-methane"), params: {
        review_code: review.review_code,
        decision: "Accept",
        rationale: "Verifier organization confirmed.",
        limitation: ""
      }
      end
    end

    assert_redirected_to review_project_path("dit-au-methane", review: review.review_code)
  end

  test "issues artifact and persists signature state" do
    sign_in_demo_user!
    artifact = Artifact.find_by!(artifact_code: "RA-AU-000184")
    artifact.update!(issued: false, issued_at: nil, status: "ready")

    assert_difference -> { AuditEvent.where(action: "artifact_issued").count }, 1 do
      post artifact_issue_project_path("dit-au-methane")
    end

    assert_redirected_to artifact_project_path("dit-au-methane")
    artifact.reload
    assert artifact.issued?
    assert_equal "issued", artifact.status
    assert artifact.artifact.fetch("integrity").key?("signature")
  end

  test "downloads artifact json" do
    sign_in_demo_user!

    get artifact_download_project_path("dit-au-methane")

    assert_response :success
    assert_equal "application/json", response.media_type
    assert_includes response.body, "RA-AU-000184"
  end

  test "retries webhook delivery" do
    sign_in_demo_user!
    delivery = WebhookDelivery.find_by!(delivery_code: "DEL-002")
    original_attempt = delivery.attempt

    assert_difference -> { AuditEvent.where(action: "webhook_delivery_retry_scheduled").count }, 1 do
      post app_developer_webhook_retry_path(delivery.delivery_code)
    end

    assert_redirected_to app_developer_webhooks_path(delivery: delivery.delivery_code)
    assert_equal original_attempt + 1, delivery.reload.attempt
  end

  test "verification lookup redirects to artifact result" do
    post verify_path, params: { artifact_id: "RA-AU-000184" }

    assert_redirected_to verify_artifact_path("RA-AU-000184")
  end

  test "accepts invitation and signs in new user" do
    invitation = Invitation.find_by!(token: "demo-reviewer-invite")

    assert_difference -> { User.count }, 1 do
      post accept_invitation_path(invitation.token), params: {
        user: {
          first_name: "Review",
          last_name: "Partner",
          password: "correct-horse-battery-staple",
          password_confirmation: "correct-horse-battery-staple"
        }
      }
    end

    assert_redirected_to app_home_path
    assert_equal "accepted", invitation.reload.status
  end
end
