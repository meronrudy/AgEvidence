require "test_helper"

class CanonicalJsonTest < ActiveSupport::TestCase
  test "canonical JSON matches shared fixture bytes" do
    fixture_dir = Rails.root.join("..", "..", "protocol", "conformance", "fixtures", "canonicalization").expand_path
    value = JSON.parse((fixture_dir / "input.json").read)
    expected = (fixture_dir / "expected.json").binread.chomp

    assert_equal expected.bytes, CanonicalJson.generate(value).bytes
  end
end
