require "yaml"

module PortfolioProducts
  class Registry
    REQUIRED_KEYS = %w[
      id
      company_code
      version
      display_name
      product_family
      workflows
      artifact_profiles
      program_profiles
      terminology
      feature_flags
    ].freeze

    KNOWN_FEATURE_FLAGS = %w[
      reviews
      programs
      artifact_orders
      reliance
      developer_api
      webhooks
      pricing
      subscriptions
      public_verification
      customer_portal
    ].freeze

    PRICING_UNITS = %w[
      application
      material_sku
      converter
      production_line
      qualification_event
      customer_program
      annual_maintained_approval
      qualification
      annual_workspace
      artifact
      site
      machine
      hectare
      program
      assurance_cycle
      api_usage
      trial
      fleet_plan
      operation
    ].freeze

    PRICING_MODELS = %w[fixed quantity tiered recurring quote_only negotiated bundle].freeze

    NAV_TARGETS = {
      "dashboard" => :app_home_path,
      "qualifications" => :projects_path,
      "projects" => :projects_path,
      "evidence" => :app_evidence_path,
      "reviews" => :app_reviews_path,
      "artifacts" => :app_statements_path,
      "programs" => :app_programs_path,
      "integrations" => :app_integrations_path,
      "developer" => :app_developer_path,
      "webhooks" => :app_developer_webhooks_path,
      "pricing" => :app_pricing_path,
      "organization" => :app_organization_path,
      "settings" => :app_settings_path
    }.freeze

    class ValidationError < StandardError; end

    class << self
      def fetch(company_code, version: nil)
        return NullPack.new if company_code.blank?

        pack = packs.fetch(company_code.to_s) do
          raise KeyError, "unknown portfolio product pack #{company_code}"
        end
        return pack if version.blank? || pack.version == version.to_s

        raise KeyError, "portfolio product pack #{company_code} version #{version} is unavailable"
      end

      def fetch_for_organization(organization)
        return NullPack.new if organization.blank? || organization.portfolio_product_pack.blank?

        fetch(
          organization.portfolio_product_pack,
          version: organization.portfolio_product_pack_version
        )
      end

      def all
        packs.values
      end

      def validate_all!(database: false)
        all.each { |pack| validate!(pack, database: database) }
      end

      def validate!(pack, database: false)
        missing = REQUIRED_KEYS.select { |key| pack.data[key].blank? }
        raise ValidationError, "#{pack.id} is missing required keys: #{missing.join(', ')}" if missing.any?

        unless pack.version.to_s.match?(/\A\d+\.\d+\.\d+\z/)
          raise ValidationError, "#{pack.id} version must be pinned as MAJOR.MINOR.PATCH"
        end

        unknown_flags = pack.feature_flags - KNOWN_FEATURE_FLAGS
        raise ValidationError, "#{pack.id} references unknown feature flags: #{unknown_flags.join(', ')}" if unknown_flags.any?

        unknown_targets = pack.navigation.targets - NAV_TARGETS.keys
        raise ValidationError, "#{pack.id} references unknown navigation targets: #{unknown_targets.join(', ')}" if unknown_targets.any?

        duplicate_products = pack.catalog.codes.tally.select { |_code, count| count > 1 }.keys
        raise ValidationError, "#{pack.id} has duplicate product codes: #{duplicate_products.join(', ')}" if duplicate_products.any?

        pack.catalog.products.each do |product|
          validate_product!(pack, product)
        end

        validate_profiles!(pack) if database

        true
      end

      def path_for(company_code)
        Rails.root.join("config/portfolio_products", company_code.to_s)
      end

      def default_navigation
        [
          {
            "label" => "Overview",
            "items" => [{ "target" => "dashboard", "label" => "Overview" }]
          },
          {
            "label" => "Evidence",
            "items" => [
              { "target" => "projects", "label" => "Projects" },
              { "target" => "evidence", "label" => "Evidence" },
              { "target" => "reviews", "label" => "Reviews" },
              { "target" => "artifacts", "label" => "Statements" }
            ]
          },
          {
            "label" => "Programs",
            "items" => [{ "target" => "programs", "label" => "Programs" }]
          },
          {
            "label" => "Developer",
            "items" => [
              { "target" => "integrations", "label" => "Integrations" },
              { "target" => "developer", "label" => "Developer" },
              { "target" => "webhooks", "label" => "Webhooks" }
            ]
          }
        ]
      end

      private

      def packs
        @packs ||= Dir[Rails.root.join("config/portfolio_products/*")].filter_map do |dir|
          next unless File.directory?(dir)

          pack = load_pack(Pathname.new(dir))
          [pack.company_code, pack]
        end.to_h
      end

      def load_pack(dir)
        product = read_yaml(dir.join("product.yml"))
        data = product.merge(
          "branding" => read_yaml(dir.join("branding.yml")),
          "navigation" => read_yaml(dir.join("navigation.yml")).fetch("navigation", []),
          "products" => read_yaml(dir.join("products.yml")).fetch("products", []),
          "telemetry" => read_yaml(dir.join("telemetry.yml")).fetch("telemetry", {})
        )
        Pack.new(data.deep_stringify_keys)
      end

      def read_yaml(path)
        return {} unless path.exist?

        YAML.safe_load(path.read, permitted_classes: [Date, Time], aliases: false) || {}
      end

      def validate_product!(pack, product)
        missing = %i[code name product_version artifact_profile program_profiles pricing_units pricing_model].select { |method| product.public_send(method).blank? }
        raise ValidationError, "#{pack.id} product #{product.code} is missing: #{missing.join(', ')}" if missing.any?

        if product.product_version.to_s == "latest"
          raise ValidationError, "#{pack.id} product #{product.code} must pin product_version"
        end

        unknown_program_profiles = product.program_profiles - pack.program_profiles
        if unknown_program_profiles.any?
          raise ValidationError, "#{pack.id} product #{product.code} references undeclared program profiles: #{unknown_program_profiles.join(', ')}"
        end

        if product.artifact_profile.present? && !pack.artifact_profiles.include?(product.artifact_profile)
          raise ValidationError, "#{pack.id} product #{product.code} references undeclared artifact profile #{product.artifact_profile}"
        end

        unknown_units = product.pricing_units - PRICING_UNITS
        raise ValidationError, "#{pack.id} product #{product.code} has invalid pricing units: #{unknown_units.join(', ')}" if unknown_units.any?

        unless PRICING_MODELS.include?(product.pricing_model)
          raise ValidationError, "#{pack.id} product #{product.code} has invalid pricing model #{product.pricing_model}"
        end
      end

      def validate_profiles!(pack)
        return unless ActiveRecord::Base.connection.data_source_exists?("program_profiles")

        missing_programs = pack.program_profiles - ProgramProfile.where(code: pack.program_profiles).pluck(:code)
        raise ValidationError, "#{pack.id} references unavailable program profiles: #{missing_programs.join(', ')}" if missing_programs.any?

        missing_artifacts = pack.artifact_profiles - ArtifactProfile.where(profile_code: pack.artifact_profiles).distinct.pluck(:profile_code)
        raise ValidationError, "#{pack.id} references unavailable artifact profiles: #{missing_artifacts.join(', ')}" if missing_artifacts.any?
      end
    end
  end
end
