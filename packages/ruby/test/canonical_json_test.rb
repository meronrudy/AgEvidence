require "digest"
require "json"
require "minitest/autorun"
require "agevidence"

class CanonicalJsonTest < Minitest::Test
  def test_matches_protocol_vectors
    root = File.expand_path("../../..", __dir__)
    vectors = Dir[File.join(root, "protocol/conformance/canonicalization/vectors/*")].select { |path| File.directory?(path) }
    vectors.sort.each do |vector|
      metadata = File.read(File.join(vector, "metadata.yaml"))
      if metadata.include?("expected_error:")
        assert_raises(StandardError) do
          AgEvidence::CanonicalJson.generate(JSON.parse(File.read(File.join(vector, "input.json"))))
        end
        next
      end

      value = JSON.parse(File.read(File.join(vector, "input.json")))
      expected = File.binread(File.join(vector, "expected.json")).force_encoding("UTF-8").delete_suffix("\n")
      assert_equal expected, AgEvidence::CanonicalJson.generate(value), File.basename(vector)
      expected_sha = File.read(File.join(vector, "expected.sha256")).strip
      assert_equal expected_sha, Digest::SHA256.hexdigest(expected), File.basename(vector)
    end
  end
end
