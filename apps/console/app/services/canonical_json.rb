require "digest"

class CanonicalJson
  def self.generate(value)
    JSON.generate(normalize(value))
  end

  def self.pretty(value)
    JSON.pretty_generate(normalize(value))
  end

  def self.digest(value)
    "sha256:#{Digest::SHA256.hexdigest(generate(value))}"
  end

  def self.normalize(value)
    case value
    when Hash
      value.each_with_object({}) do |(key, nested), normalized|
        normalized[key.to_s] = normalize(nested)
      end.sort.to_h
    when Array
      value.map { |nested| normalize(nested) }
    when Time, ActiveSupport::TimeWithZone
      value.utc.iso8601
    when Date
      value.iso8601
    else
      value
    end
  end
end
