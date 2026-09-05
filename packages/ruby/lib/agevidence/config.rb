require "json"
require "pathname"

module AgEvidence
  class Config
    DEFAULT_BASE_URL = "http://localhost:3000"

    attr_accessor :base_url, :api_token, :verifier_command

    def self.load(path: nil)
      config_path = path || default_path
      values = File.exist?(config_path) ? JSON.parse(File.read(config_path)) : {}
      new(
        base_url: ENV["AGEVIDENCE_BASE_URL"] || values["base_url"] || DEFAULT_BASE_URL,
        api_token: ENV["AGEVIDENCE_API_TOKEN"] || values["api_token"],
        verifier_command: ENV["AGEVIDENCE_VERIFIER_COMMAND"] || values["verifier_command"]
      )
    end

    def self.default_path
      root = ENV["XDG_CONFIG_HOME"] || File.expand_path("~/.config")
      File.join(root, "agevidence", "config.json")
    end

    def initialize(base_url: DEFAULT_BASE_URL, api_token: nil, verifier_command: nil)
      @base_url = base_url
      @api_token = api_token
      @verifier_command = verifier_command
    end
  end
end
