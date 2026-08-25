module Api
  module V1
    class SchemasController < BaseController
      CONTRACTS = {
        "artifact-manifest.v0" => "artifact-manifest.v0.json",
        "verifier-result.v0" => "verifier-result.v0.json",
        "webhook-envelope.v0" => "webhook-envelope.v0.json",
        "error-response.v0" => "error-response.v0.json"
      }.freeze

      def show
        require_scope!("schemas:read")
        filename = CONTRACTS.fetch(params[:contract_version])
        path = Rails.root.join("docs/contracts", filename)
        envelope(JSON.parse(path.read))
      rescue KeyError
        not_found
      end
    end
  end
end
