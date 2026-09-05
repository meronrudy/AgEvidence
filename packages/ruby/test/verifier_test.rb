require "minitest/autorun"
require "agevidence"

class VerifierTest < Minitest::Test
  def test_missing_command_fails_clearly
    error = assert_raises(AgEvidence::VerifierUnavailableError) do
      AgEvidence::Verifier.new(command: nil).verify_bundle("bundle.zip")
    end

    assert_equal "VERIFIER_COMMAND_MISSING", error.code
  end
end
