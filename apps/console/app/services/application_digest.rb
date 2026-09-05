require "digest"

class ApplicationDigest
  def self.sha256(value)
    "app:sha256:#{Digest::SHA256.hexdigest(StableJson.generate(value))}"
  end
end
