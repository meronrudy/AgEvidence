require "digest"

# Compatibility wrapper for pre-boundary Rails code. New application code should
# use StableJson and ApplicationDigest; receipt commitments are Rust-owned.
class CanonicalJson
  def self.generate(value)
    StableJson.generate(value)
  end

  def self.pretty(value)
    StableJson.pretty(value)
  end

  def self.digest(value)
    ApplicationDigest.sha256(value)
  end

  def self.normalize(value)
    StableJson.normalize(value)
  end
end
