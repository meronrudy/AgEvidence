module JsonBacked
  extend ActiveSupport::Concern

  class_methods do
    def json_field(*names, default:)
      names.each do |name|
        define_method(name) do
          raw = public_send("#{name}_json")
          raw.present? ? JSON.parse(raw) : default.deep_dup
        end

        define_method("#{name}=") do |value|
          public_send("#{name}_json=", JSON.generate(value.nil? ? default : value))
        end
      end
    end
  end
end
