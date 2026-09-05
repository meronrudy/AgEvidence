require "json"
require "net/http"
require "uri"
require "agevidence/config"
require "agevidence/errors"
require "agevidence/models"
require "agevidence/resources/artifacts"
require "agevidence/resources/evidence"
require "agevidence/resources/evaluations"
require "agevidence/resources/program_profiles"
require "agevidence/resources/reliance_events"
require "agevidence/resources/reviews"
require "agevidence/resources/schemas"
require "agevidence/resources/source_records"
require "agevidence/resources/statements"

module AgEvidence
  class Client
    IDEMPOTENT_METHODS = %w[GET HEAD OPTIONS].freeze
    RETRY_STATUS_CODES = [408, 429, 500, 502, 503, 504].freeze

    attr_reader :base_url, :api_token, :timeout, :retries

    def initialize(base_url: nil, api_token: nil, timeout: 10, retries: 1)
      config = Config.load
      @base_url = (base_url || config.base_url).sub(%r{/\z}, "")
      @api_token = api_token.nil? ? config.api_token : api_token
      @timeout = timeout
      @retries = retries

      @evidence = Resources::Evidence.new(self)
      @source_records = Resources::SourceRecords.new(self)
      @evaluations = Resources::Evaluations.new(self)
      @reviews = Resources::Reviews.new(self)
      @program_profiles = Resources::ProgramProfiles.new(self)
      @statements = Resources::Statements.new(self)
      @artifacts = Resources::Artifacts.new(self)
      @reliance_events = Resources::RelianceEvents.new(self)
      @schemas = Resources::Schemas.new(self)
    end

    attr_reader :evidence, :source_records, :evaluations, :reviews,
                :program_profiles, :statements, :artifacts, :reliance_events,
                :schemas

    def request(method, path, json: nil, headers: {}, idempotency_key: nil)
      attempts = retryable?(method, idempotency_key) ? retries + 1 : 1
      last_error = nil
      attempts.times do |attempt|
        response = perform_request(method, api_path(path), json: json, headers: headers, idempotency_key: idempotency_key)
        return decode_response(response) unless retry_response?(response) && attempt + 1 < attempts

        sleep(0.2 * (attempt + 1))
      rescue IOError, SystemCallError, Timeout::Error => e
        last_error = e
        raise if attempt + 1 >= attempts

        sleep(0.2 * (attempt + 1))
      end
      raise Error.new("HTTP request failed.", code: "HTTP_REQUEST_FAILED", response_body: last_error&.message)
    end

    private

    def perform_request(method, path, json:, headers:, idempotency_key:)
      uri = URI.join(base_url + "/", path.sub(%r{\A/}, ""))
      request = request_class(method).new(uri)
      request["Accept"] = "application/json"
      request["Content-Type"] = "application/json" if json
      request["Authorization"] = "Bearer #{api_token}" if api_token
      request["Idempotency-Key"] = idempotency_key if idempotency_key
      headers.each { |key, value| request[key] = value }
      request.body = JSON.generate(Models.deep_stringify(json)) if json

      Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https", read_timeout: timeout, open_timeout: timeout) do |http|
        http.request(request)
      end
    end

    def request_class(method)
      Net::HTTP.const_get(method.to_s.capitalize)
    end

    def decode_response(response)
      body = response.body.to_s.empty? ? nil : JSON.parse(response.body)
      return body if response.code.to_i < 400

      error = body.is_a?(Hash) ? body.fetch("error", {}) : {}
      raise Error.new(
        error["message"] || response.message,
        code: error["code"],
        status_code: response.code.to_i,
        response_body: body
      )
    rescue JSON::ParserError
      raise Error.new(response.message, status_code: response.code.to_i, response_body: response.body)
    end

    def retryable?(method, idempotency_key)
      IDEMPOTENT_METHODS.include?(method.to_s.upcase) || !idempotency_key.nil?
    end

    def retry_response?(response)
      RETRY_STATUS_CODES.include?(response.code.to_i)
    end

    def api_path(path)
      path.start_with?("/api/v1") ? path : "/api/v1#{path.start_with?("/") ? path : "/#{path}"}"
    end
  end
end
