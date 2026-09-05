module AgEvidence
  module Models
    def self.deep_stringify(value)
      case value
      when Hash
        value.each_with_object({}) { |(key, child), out| out[key.to_s] = deep_stringify(child) }
      when Array
        value.map { |child| deep_stringify(child) }
      else
        value
      end
    end
  end
end
