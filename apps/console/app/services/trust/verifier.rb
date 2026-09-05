require "json"
require "open3"
require "shellwords"
require "tempfile"

module Trust
  class Verifier
    CONTRACT_VERSION = "verifier-result.v0"
    VERIFIER_NAME = "AgEvidence Rust verifier"
    PROTOCOL_VERSION = "agevidence.trust.v1"

    def self.verify(bundle_path, command: nil)
      new(command: command).verify(bundle_path)
    end

    def self.record_artifact!(artifact:, actor:, metadata: {}, bundle_path: nil)
      new.record_artifact!(artifact: artifact, actor: actor, metadata: metadata, bundle_path: bundle_path)
    end

    def initialize(command: nil)
      @command = command || ENV["AGEVIDENCE_VERIFIER_COMMAND"].presence || default_command
    end

    def verify(bundle_path)
      return unavailable_report unless command_available?

      argv = Shellwords.split(@command) + ["verify", bundle_path.to_s, "--json"]
      stdout, stderr, status = Open3.capture3(*argv)
      parsed = parse_json(stdout)
      return failed_execution_report(argv, stdout, stderr, status.exitstatus) if parsed.blank?

      parsed.merge(
        "command" => argv,
        "returncode" => status.exitstatus,
        "stdout" => stdout,
        "stderr" => stderr
      )
    rescue Errno::ENOENT => e
      unavailable_report(e.message)
    end

    def record_artifact!(artifact:, actor:, metadata: {}, bundle_path: nil)
      report = bundle_path ? verify(bundle_path) : verify_artifact_manifest(artifact)
      result = VerifierResult.create!(
        organization: artifact.organization,
        project: artifact.project,
        artifact: artifact,
        contract_version: CONTRACT_VERSION,
        verifier_name: VERIFIER_NAME,
        verifier_version: report["verifier_version"] || "unavailable",
        status: rails_status(report["status"]),
        artifact_digest: artifact.digest,
        checked_at: Time.current,
        checks: Array(report["checks"]),
        result: report,
        metadata: metadata
      )

      AuditEvent.log!(
        action: "verifier_result_recorded",
        actor: actor,
        organization: artifact.organization,
        auditable: result,
        metadata: metadata.merge(artifact_code: artifact.artifact_code, status: result.status)
      )

      result
    end

    private

    def verify_artifact_manifest(artifact)
      Tempfile.create(["agevidence-artifact-", ".json"]) do |file|
        file.write(JSON.pretty_generate(artifact.artifact))
        file.flush
        verify(file.path)
      end
    end

    def rails_status(status)
      case status.to_s
      when "pass"
        "locally_consistent"
      when "fail", "malformed", "unsupported", "error"
        "failed"
      else
        "pending_external_verifier"
      end
    end

    def command_available?
      executable = Shellwords.split(@command.to_s).first
      executable.present? && File.executable?(executable)
    end

    def default_command
      Rails.root.join("..", "..", "packages", "rust", "target", "debug", "agevidence").expand_path.to_s
    end

    def parse_json(value)
      JSON.parse(value) if value.to_s.strip.present?
    rescue JSON::ParserError
      nil
    end

    def unavailable_report(message = "Verifier command is unavailable")
      {
        "verifier_version" => "unavailable",
        "protocol_version" => PROTOCOL_VERSION,
        "status" => "indeterminate",
        "cryptographic_status" => "indeterminate",
        "trust_policy_status" => "indeterminate",
        "checks" => [
          { "name" => "verifier.execution", "status" => "indeterminate", "detail" => message }
        ],
        "warnings" => [message],
        "errors" => []
      }
    end

    def failed_execution_report(argv, stdout, stderr, exitstatus)
      {
        "verifier_version" => "unavailable",
        "protocol_version" => PROTOCOL_VERSION,
        "status" => "error",
        "cryptographic_status" => "indeterminate",
        "trust_policy_status" => "indeterminate",
        "checks" => [
          { "name" => "verifier.execution", "status" => "fail", "detail" => stderr.presence || "exit #{exitstatus}" }
        ],
        "warnings" => [],
        "errors" => [
          { "code" => "VERIFIER_EXECUTION_FAILED", "message" => stderr.presence || "Verifier command failed." }
        ],
        "command" => argv,
        "returncode" => exitstatus,
        "stdout" => stdout,
        "stderr" => stderr
      }
    end
  end
end
