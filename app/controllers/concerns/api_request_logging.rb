module ApiRequestLogging
  module ClassMethods
    def included(base)
      base.before_action :log_request
      base.after_action :log_response
    end
  end

  private
    def log_request
      @request_id = SecureRandom.uuid
      organization_id = @api_key&.organization_id
      method = request.request_method
      path = request.path
      route = request.path_parameters[:controller] + '#' + request.path_parameters[:action]
      
      # Log basic request info without sensitive data
      logger.info(
        "API Request: organization_id=#{organization_id}, request_id=#{@request_id}, " +
        "method=#{method}, path=#{path}, route=#{route}"
      )
    end

    def log_response(status)
      duration = Time.current.to_f - @request_start_time.to_f
      response_status = status
      
      logger.info(
        "API Response: request_id=#{@request_id}, " +
        "status=#{response_status}, duration=#{duration.round(3)}s"
      )
    end
  end