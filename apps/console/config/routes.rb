Rails.application.routes.draw do
  get "health", to: "health#show", as: :health

  devise_for :users, skip: [:registrations], controllers: {
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  root "marketing#index"

  get "verify", to: "verification#index", as: :verify
  post "verify", to: "verification#lookup"
  get "verify/:id", to: "verification#show", as: :verify_artifact
  get "s/:token", to: "shared_statements#show", as: :shared_statement

  get "invitations/:token", to: "invitations#show", as: :invitation
  post "invitations/:token/accept", to: "invitations#accept", as: :accept_invitation

  scope "/app" do
    root "app#overview", as: :app_home
    get "reviews", to: "reviews#index", as: :app_reviews
    get "reviews/:code", to: "reviews#show", as: :app_review
    get "artifacts", to: "statements#index", as: :app_artifacts
    get "statements", to: "statements#index", as: :app_statements
    get "statements/:code", to: "statements#show", as: :app_statement
    post "statements/:code/issue", to: "statements#issue", as: :issue_app_statement
    post "statements/:code/shares", to: "statement_shares#create", as: :app_statement_shares
    delete "statements/:code/shares/:share_id", to: "statement_shares#destroy", as: :app_statement_share
    get "integrations", to: "app#integrations", as: :app_integrations
    get "integrity", to: "integrity#index", as: :app_integrity
    get "determinations", to: "determinations#index", as: :app_determinations
    get "determinations/:code", to: "determinations#show", as: :app_determination
    get "evaluations", to: "evaluations#index", as: :app_evaluations
    get "evaluations/:code", to: "evaluations#show", as: :app_evaluation
    get "organization", to: "app#organization", as: :app_organization
    post "organization/switch", to: "organizations#switch", as: :app_organization_switch
    post "organization/invitations", to: "invitations#create", as: :app_organization_invitations
    get "settings", to: "app#settings", as: :app_settings

    get "evidence", to: "evidence#index", as: :app_evidence
    get "evidence/records", to: "evidence#records", as: :app_evidence_records
    get "evidence/gaps", to: "gaps#index", as: :app_gaps

    resources :projects, param: :slug, only: [:index, :show], path_names: { new: "new", edit: "edit" } do
      member do
        get "evidence", to: "projects#evidence"
        get "source_records", to: "projects#source_records"
        post "source_records", to: "projects#create_source_record"
        get "runs", to: "projects#runs"
        get "gaps", to: "projects#gaps"
        get "assessment", to: "projects#assessment"
        get "review", to: "projects#review"
        post "review_decisions", to: "projects#create_review_decision"
        get "artifact", to: "projects#artifact"
        post "artifact/issue", to: "projects#issue_artifact"
        get "artifact/download", to: "projects#download_artifact"
        get "artifact/bundle", to: "projects#download_bundle"
        get "reliance", to: "projects#reliance"
        post "reliance_events", to: "projects#create_reliance_event"
        get "activity", to: "projects#activity"
      end
    end

    get "programs", to: "programs#index", as: :app_programs
    get "programs/requirements", to: "programs#requirements", as: :app_program_requirements
    get "programs/profiles", to: "programs#profiles", as: :app_program_profiles
    get "programs/versions", to: "programs#versions", as: :app_program_versions
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

  namespace :api do
    namespace :v1 do
      post "evidence", to: "evidence#create"
      get "evidence/:id", to: "evidence#show"
      get "evaluations", to: "evaluations#index"
      get "evaluations/:id", to: "evaluations#show"
      get "reviews", to: "reviews#index"
      get "program_profiles", to: "program_profiles#index"
      get "program_profiles/:id", to: "program_profiles#show"
      get "statements", to: "statements#index"
      get "statements/:id", to: "statements#show"
      post "statements/:id/shares", to: "statement_shares#create"
      post "projects/:project_code/source-records", to: "source_records#create"
      get "projects/:project_code/source-records/:record_code", to: "source_records#show"
      get "artifacts/:artifact_code", to: "artifacts#show"
      post "artifacts/:artifact_code/verify", to: "artifacts#verify"
      post "artifacts/:artifact_code/reliance-events", to: "reliance_events#create"
      get "schemas/:contract_version", to: "schemas#show", constraints: { contract_version: /[^\/]+/ }, format: false
    end
  end
end
