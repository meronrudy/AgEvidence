require "json"
require "open3"
require "shellwords"
require "agevidence/config"
require "agevidence/errors"

module AgEvidence
  class Verifier
    attr_reader :command

    def initialize(command: nil)
      @command = command || Config.load.verifier_command
    end

    def verify_bundle(bundle)
      raise VerifierUnavailableError.new("Set AGEVIDENCE_VERIFIER_COMMAND.", code: "VERIFIER_COMMAND_MISSING") if command.to_s.strip.empty?

      argv = Shellwords.split(command) + ["verify", bundle.to_s, "--json"]
      stdout, stderr, status = Open3.capture3(*argv)
      parsed = parse_json(stdout)
      if status.exitstatus == 5 || (!status.success? && parsed.nil?)
        raise VerifierFailedError.new(
          "Verifier command failed.",
          code: "VERIFIER_FAILED",
          status_code: status.exitstatus,
          response_body: { "stdout" => stdout, "stderr" => stderr, "command" => argv }
        )
      end
      (parsed || { "status" => "pass" }).merge(
        "command" => argv,
        "returncode" => status.exitstatus,
        "stdout" => stdout,
        "stderr" => stderr
      )
    rescue Errno::ENOENT => e
      raise VerifierUnavailableError.new("Verifier command was not found: #{argv&.first || command}", code: "VERIFIER_COMMAND_NOT_FOUND", response_body: e.message)
    end

    private

    def parse_json(value)
      return nil if value.to_s.strip.empty?

      JSON.parse(value)
    rescue JSON::ParserError
      nil
    end
  end
end
