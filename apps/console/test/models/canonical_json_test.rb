require "test_helper"

class StableJsonTest < ActiveSupport::TestCase
  test "stable JSON sorts keys for application digests" do
    value = { "z" => 1, "a" => { "b" => 2, "a" => 1 } }
    expected = '{"a":{"a":1,"b":2},"z":1}'

    assert_equal expected, StableJson.generate(value)
  end

  test "application digest uses app namespace" do
    assert_match(/\Aapp:sha256:[a-f0-9]{64}\z/, ApplicationDigest.sha256("a" => 1))
  end
end
