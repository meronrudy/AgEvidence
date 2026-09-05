module AgEvidence
  class Error < StandardError
    attr_reader :code, :status_code, :response_body

    def initialize(message, code: nil, status_code: nil, response_body: nil)
      super(message)
      @code = code
      @status_code = status_code
      @response_body = response_body
    end
  end

  class VerifierUnavailableError < Error; end
  class VerifierFailedError < Error; end
end
