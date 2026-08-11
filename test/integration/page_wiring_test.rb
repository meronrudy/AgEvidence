require "test_helper"

class PageWiringTest < ActionDispatch::IntegrationTest
  setup do
    seed_demo!
    @public_paths = [
      root_path,
      health_path,
      verify_path,
      verify_artifact_path("RA-AU-000184")
    ]
    @app_paths = [
      app_home_path,
      projects_path,
      project_path("dit-au-methane"),
      evidence_project_path("dit-au-methane"),
      assessment_project_path("dit-au-methane"),
      review_project_path("dit-au-methane"),
      artifact_project_path("dit-au-methane"),
      activity_project_path("dit-au-methane"),
      app_evidence_path,
      app_programs_path,
      app_program_requirements_path,
      app_program_profiles_path,
      app_program_evaluate_path,
      app_program_compare_path,
      app_program_australia_path,
      app_program_australia_requirements_path,
      app_program_australia_profiles_path,
      app_program_australia_versions_path,
      app_program_australia_evaluations_path,
      app_program_australia_determinations_path,
      app_determinations_path,
      app_determination_path("DET-002"),
      app_evaluation_path("EVAL-001"),
      app_developer_path,
      app_developer_logs_path,
      app_developer_webhooks_path,
      app_developer_keys_path,
      app_developer_schemas_path,
      app_developer_openapi_path,
      app_reviews_path,
      app_artifacts_path,
      app_integrations_path,
      app_methodologies_path,
      app_verification_path,
      app_organization_path,
      app_settings_path,
      app_documentation_path
    ]
  end

  test "public pages render without authentication" do
    @public_paths.each do |path|
      get path
      assert_response :success, path
    end
  end

  test "app pages redirect to sign in when unauthenticated" do
    @app_paths.each do |path|
      get path
      assert_redirected_to new_user_session_path, path
    end
  end

  test "app nav linked pages render after sign in" do
    sign_in_demo_user!

    @app_paths.each do |path|
      get path
      assert_response :success, path
    end
  end

  test "app overview is evidence control surface" do
    sign_in_demo_user!

    get app_home_path

    assert_response :success
    assert_includes response.body, "Evidence control"
    assert_includes response.body, "Source evidence"
    assert_includes response.body, "Program basis"
    assert_includes response.body, "Reliance"
    refute_includes response.body, "Evidence operations"
  end

  test "root is the AgEvidence landing page" do
    get root_path

    assert_response :success
    assert_includes response.body, "Portable evidence infrastructure"
    refute_includes response.body, "Yay! You're on Rails!"
  end

  test "unknown project slug returns not found for authenticated users" do
    sign_in_demo_user!

    get project_path("missing-project")

    assert_response :not_found
    assert_includes response.body, "Page not found"
  end

  test "unknown verification artifact shows not found result" do
    get verify_artifact_path("RA-AU-DOES-NOT-EXIST")

    assert_response :not_found
    assert_includes response.body, "Artifact not found"
  end

  test "unknown determination and evaluation return not found" do
    sign_in_demo_user!

    get app_determination_path("DET-404")
    assert_response :not_found

    get app_evaluation_path("EVAL-404")
    assert_response :not_found
  end
end
