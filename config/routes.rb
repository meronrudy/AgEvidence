Rails.application.routes.draw do
  get "health", to: "health#show", as: :health

  devise_for :users, skip: [:registrations], controllers: {
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  root "marketing#index"

  get "verify", to: "verification#index", as: :verify
  post "verify", to: "verification#lookup"
  get "verify/:id", to: "verification#show", as: :verify_artifact

  get "invitations/:token", to: "invitations#show", as: :invitation
  post "invitations/:token/accept", to: "invitations#accept", as: :accept_invitation

  scope "/app" do
    root "app#overview", as: :app_home
    get "reviews", to: "app#reviews", as: :app_reviews
    get "artifacts", to: "app#artifacts", as: :app_artifacts
    get "integrations", to: "app#integrations", as: :app_integrations
    get "methodologies", to: "app#methodologies", as: :app_methodologies
    get "verification", to: "app#verification", as: :app_verification
    get "determinations", to: "determinations#index", as: :app_determinations
    get "determinations/:code", to: "determinations#show", as: :app_determination
    get "evaluations/:code", to: "evaluations#show", as: :app_evaluation
    get "organization", to: "app#organization", as: :app_organization
    post "organization/switch", to: "organizations#switch", as: :app_organization_switch
    post "organization/invitations", to: "invitations#create", as: :app_organization_invitations
    get "settings", to: "app#settings", as: :app_settings
    get "documentation", to: "app#documentation", as: :app_documentation

    get "evidence", to: "evidence#index", as: :app_evidence

    resources :projects, param: :slug, only: [:index, :show], path_names: { new: "new", edit: "edit" } do
      member do
        get "evidence", to: "projects#evidence"
        get "assessment", to: "projects#assessment"
        get "review", to: "projects#review"
        post "review_decisions", to: "projects#create_review_decision"
        get "artifact", to: "projects#artifact"
        post "artifact/issue", to: "projects#issue_artifact"
        get "artifact/download", to: "projects#download_artifact"
        get "artifact/bundle", to: "projects#download_bundle"
        get "activity", to: "projects#activity"
      end
    end

    get "programs", to: "programs#index", as: :app_programs
    get "programs/requirements", to: "programs#requirements", as: :app_program_requirements
    get "programs/profiles", to: "programs#profiles", as: :app_program_profiles
    get "programs/evaluate", to: "programs#evaluate", as: :app_program_evaluate
    get "programs/compare", to: "programs#compare", as: :app_program_compare
    get "programs/australia", to: "programs#australia", as: :app_program_australia
    get "programs/australia/requirements", to: "programs#australia_requirements", as: :app_program_australia_requirements
    get "programs/australia/profiles", to: "programs#australia_profiles", as: :app_program_australia_profiles
    get "programs/australia/versions", to: "programs#australia_versions", as: :app_program_australia_versions
    get "programs/australia/evaluations", to: "programs#australia_evaluations", as: :app_program_australia_evaluations
    get "programs/australia/determinations", to: "programs#australia_determinations", as: :app_program_australia_determinations

    get "developer", to: "developer#index", as: :app_developer
    get "developer/logs", to: "developer#logs", as: :app_developer_logs
    get "developer/webhooks", to: "developer#webhooks", as: :app_developer_webhooks
    post "developer/webhooks/:id/retry", to: "developer#retry_webhook", as: :app_developer_webhook_retry
    get "developer/keys", to: "developer#keys", as: :app_developer_keys
    get "developer/schemas", to: "developer#schemas", as: :app_developer_schemas
    get "developer/openapi", to: "developer#openapi", as: :app_developer_openapi
  end
end
