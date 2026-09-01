module ApiRequestLogging
  extend ActiveSupport::Concern

  included do
    before_action :log_request
    after_action :log_response
  end

  private

  def log_request
    @request_id = SecureRandom.uuid
    organization_id = @api_key&.organization_id
    method = request.request_method
    path = request.path
    route = "#{request.path_parameters[:controller]}##{request.path_parameters[:action]}"

    logger.info(
      "API Request: organization_id=#{organization_id}, request_id=#{@request_id}, " \
      "method=#{method}, path=#{path}, route=#{route}"
    )
  end

  def log_response
    duration = Time.current.to_f - @request_start_time.to_f

    logger.info(
      "API Response: request_id=#{@request_id}, " \
      "status=#{response.status}, duration=#{duration.round(3)}s"
    )
  end
end
