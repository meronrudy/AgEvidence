class PortfolioProvisioningService
  EARTHODIC_PRICING = {
    "application_qualification" => {
      "product_version" => "1.2",
      "currency" => "AUD",
      "pricing_unit" => "application",
      "list_price_cents" => 2_500_000,
      "minimum_price_cents" => 1_900_000
    }
  }.freeze

  Result = Data.define(:organization, :api_key, :raw_api_token, :invitation)

  def self.call(company:, product_pack: nil, environment: "Sandbox", admin_email:, domain: nil)
    new(
      company: company,
      product_pack: product_pack,
      environment: environment,
      admin_email: admin_email,
      domain: domain
    ).call
  end

  def initialize(company:, product_pack:, environment:, admin_email:, domain:)
    @company = company.to_s
    @product_pack_code = (product_pack.presence || @company).to_s
    @environment = environment
    @admin_email = admin_email
    @domain = domain
    @pack = PortfolioProducts::Registry.fetch(@product_pack_code)
  end

  def call
    ActiveRecord::Base.transaction do
      ensure_profiles!
      organization = ensure_organization!
      Role.default_roles_for_organization(organization)
      ensure_feature_flags!(organization)
      raw_token = "agev_#{@company}_#{SecureRandom.hex(12)}"
      api_key = ensure_api_key!(organization, raw_token)
      ensure_domain!(organization)
      ensure_price_versions!(organization)
      ensure_pricing_experiment!(organization)
      ensure_webhook!(organization)
      invitation = ensure_invitation!(organization)

      Result.new(
        organization: organization,
        api_key: api_key,
        raw_api_token: raw_token,
        invitation: invitation
      )
    end
  end

  private

  def ensure_organization!
    Organization.find_or_initialize_by(name: "#{@pack.brand.company_name} #{@environment}").tap do |organization|
      organization.assign_attributes(
        environment: @environment,
        portfolio_product_pack: @pack.company_code,
        portfolio_product_pack_version: @pack.version,
        deployment_mode: @pack.deployment_mode,
        brand_name: @pack.brand.product_name,
        brand_domain: @domain.presence || @pack.data["custom_domain"],
        support_email: @pack.brand.support["email"],
        legal_entity_name: @pack.brand.company_name,
        default_currency: default_currency,
        default_locale: "en-AU"
      )
      organization.save!
    end
  end

  def ensure_profiles!
    return unless @company == "earthodic"

    profile = ProgramProfile.find_or_create_by!(code: "earthodic.application.v1") do |record|
      record.slug = "earthodic-application-v1"
      record.name = "Earthodic Application Qualification"
      record.status = "Operational"
      record.profile_version = "v1"
      record.program = "Earthodic Qualification Cloud"
      record.scope = "Biobarc application qualification"
      record.methodology = "Material application qualification"
      record.verification_profile = "AgEvidence placeholder verifier"
      record.evidence_policy = "controlled external objects and commitments"
      record.requirements_count = 1
      record.machine_evaluable = 1
      record.human_review = 0
      record.profile_classes = 1
      record.effective_from = Date.new(2026, 8, 20)
      record.requirements_digest = "sha256:earthodic-application"
      record.outcome_vocabulary = ["Qualified", "Qualified with conditions", "Not qualified"]
      record.issuance_policy = {}
      record.limitation_templates = []
      record.artifact_profile_selection = "application_qualification_pack"
    end

    @pack.program_profiles.each do |code|
      next if ProgramProfile.exists?(code: code)

      ProgramProfile.create!(
        code: code,
        slug: code.tr(".", "-"),
        name: code.titleize,
        status: "Operational",
        profile_version: "v1",
        program: "Earthodic Qualification Cloud",
        scope: "Earthodic product pack profile",
        requirements_count: 0,
        machine_evaluable: 0,
        human_review: 0,
        profile_classes: 0
      )
    end

    @pack.artifact_profiles.each do |code|
      next if ArtifactProfile.exists?(profile_code: code)

      ArtifactProfile.create!(
        program_profile: profile,
        profile_code: code,
        profile_version: "v1",
        status: "active",
        layout: { "issuer_name" => "Earthodic", "product_name" => "Biobarc Qualification" },
        recipient_rules: {},
        retention: { "years" => 7 }
      )
    end
  end

  def ensure_feature_flags!(organization)
    PortfolioProducts::Registry::KNOWN_FEATURE_FLAGS.each do |flag|
      organization.feature_flags.find_or_initialize_by(flag_key: flag).tap do |feature_flag|
        feature_flag.enabled = @pack.enabled?(flag)
        feature_flag.metadata = { "source" => "portfolio_product_pack", "pack_version" => @pack.version }
        feature_flag.save!
      end
    end
  end

  def ensure_api_key!(organization, raw_token)
    organization.api_keys.find_or_initialize_by(key_code: "KEY-#{@company.upcase}-INITIAL").tap do |key|
      key.name = "#{@pack.brand.company_name} initial API key"
      key.token_digest = ApiKey.digest_token(raw_token)
      key.token_hint = "#{raw_token.first(10)}...#{raw_token.last(4)}"
      key.scopes = ["*"]
      key.status = "Active"
      key.revoked_at = nil
      key.save!
    end
  end

  def ensure_domain!(organization)
    hostname = @domain.presence || organization.brand_domain
    return if hostname.blank?

    organization.domain_mappings.find_or_initialize_by(hostname: hostname).tap do |mapping|
      mapping.status = "verified"
      mapping.verified_at ||= Time.current
      mapping.primary = true
      mapping.save!
    end
  end

  def ensure_price_versions!(organization)
    @pack.catalog.products.each do |product|
      pricing = EARTHODIC_PRICING.fetch(product.code, {})
      unit = pricing["pricing_unit"] || product.pricing_units.first
      currency = pricing["currency"] || product.currency || organization.default_currency

      organization.price_versions.find_or_initialize_by(
        product_code: product.code,
        product_version: product.product_version,
        currency: currency,
        pricing_unit: unit
      ).tap do |price|
        price.list_price_cents = pricing["list_price_cents"]
        price.minimum_price_cents = pricing["minimum_price_cents"]
        price.pricing_formula = { "model" => product.pricing_model }
        price.effective_from ||= Time.current
        price.status = "active"
        price.metadata = { "source" => "portfolio_provisioning" }
        price.save!
      end
    end
  end

  def ensure_pricing_experiment!(organization)
    return unless @company == "earthodic"

    price = organization.price_versions.find_by!(product_code: "application_qualification", pricing_unit: "application")
    organization.pricing_experiments.find_or_initialize_by(
      product_code: "application_qualification",
      product_version: "1.2",
      name: "Application vs maintained approval"
    ).tap do |experiment|
      experiment.price_version = price
      experiment.hypothesis = "Can qualification become paid and accelerate material conversion?"
      experiment.customer_segment = "converter"
      experiment.geography = "AU"
      experiment.pricing_unit = "application"
      experiment.status = "active"
      experiment.started_at ||= Time.current
      experiment.metadata = {
        "sales_cycle_days" => 19,
        "recurring_value_cents" => 1_200_000,
        "workload" => { "reviewer_minutes" => 180, "support_minutes" => 90 }
      }
      experiment.save!
    end
  end

  def ensure_webhook!(organization)
    organization.webhook_endpoints.find_or_initialize_by(endpoint_code: "WH-#{@company.upcase}-001").tap do |endpoint|
      endpoint.url = "https://#{organization.brand_domain || "#{@company}.example"}/webhooks/agevidence"
      endpoint.status = "Active"
      endpoint.events = ["artifact.issued", "reliance.recorded", "quote.accepted"]
      endpoint.save!
    end
  end

  def ensure_invitation!(organization)
    organization.invitations.find_or_initialize_by(email: @admin_email, status: "pending").tap do |invitation|
      invitation.role = organization.role(:org_admin)
      invitation.expires_at ||= 30.days.from_now
      invitation.token ||= "#{@company}-admin-invite"
      invitation.save!
    end
  end

  def default_currency
    @pack.catalog.products.map(&:currency).compact.first || "USD"
  end
end
