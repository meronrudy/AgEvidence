require "json"

module AgEvidence
  module CanonicalJson
    MAX_SAFE_JSON_INTEGER = 9_007_199_254_740_991

    module_function

    def generate(value)
      case value
      when nil
        "null"
      when true
        "true"
      when false
        "false"
      when String
        JSON.generate(value, ascii_only: false)
      when Integer
        raise ArgumentError, "integer is outside the RFC 8785 interoperable JSON number range" if value.abs > MAX_SAFE_JSON_INTEGER

        value.to_s
      when Float
        format_float(value)
      when Array
        "[" + value.map { |child| generate(child) }.join(",") + "]"
      when Hash
        pairs = value.keys.sort_by { |key| utf16_sort_key(key.to_s) }.map do |key|
          raise TypeError, "JCS object keys must be strings" unless key.is_a?(String)

          "#{generate(key)}:#{generate(value[key])}"
        end
        "{" + pairs.join(",") + "}"
      else
        raise TypeError, "unsupported JSON value: #{value.class}"
      end
    end

    def digest(value, domain: "app")
      require "digest"
      "#{domain}:sha256:#{Digest::SHA256.hexdigest(generate(value))}"
    end

    def format_float(value)
      raise ArgumentError, "NaN and Infinity are not valid RFC 8785 JSON numbers" unless value.finite?
      return "0" if value.zero?

      sign = value.negative? ? "-" : ""
      text = value.abs.to_s.downcase
      coefficient, exponent_text = text.include?("e") ? text.split("e", 2) : [text, "0"]
      exponent = exponent_text.to_i
      if coefficient.include?(".")
        integer, fraction = coefficient.split(".", 2)
        decimal_point = integer.length + exponent
        digits = integer + fraction
      else
        decimal_point = coefficient.length + exponent
        digits = coefficient
      end
      leading_zeroes = digits.length - digits.sub(/\A0+/, "").length
      digits = digits.sub(/\A0+/, "")
      digits = "0" if digits.empty?
      decimal_point -= leading_zeroes
      digits = digits.sub(/0+\z/, "")
      digits = "0" if digits.empty?
      adjusted_exponent = decimal_point - 1

      if adjusted_exponent >= -6 && adjusted_exponent < 21
        rendered =
          if decimal_point <= 0
            "0." + ("0" * -decimal_point) + digits
          elsif decimal_point >= digits.length
            digits + ("0" * (decimal_point - digits.length))
          else
            digits[0...decimal_point] + "." + digits[decimal_point..-1]
          end
        rendered = rendered.sub(/\.?0+\z/, "") if rendered.include?(".")
        sign + rendered
      else
        mantissa = digits.length == 1 ? digits : digits[0] + "." + digits[1..-1]
        exponent_sign = adjusted_exponent >= 0 ? "+" : ""
        "#{sign}#{mantissa}e#{exponent_sign}#{adjusted_exponent}"
      end
    end

    def utf16_sort_key(value)
      value.encode("UTF-16BE").bytes
    end
  end
end
