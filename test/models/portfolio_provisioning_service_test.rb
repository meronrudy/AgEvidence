require "test_helper"

class PortfolioProvisioningServiceTest < ActiveSupport::TestCase
  setup do
    seed_demo!
  end

  test "earthodic provisioning creates managed tenant resources" do
    domain = "smoke-#{SecureRandom.hex(4)}.earthodic.example"

    result = PortfolioProvisioningService.call(
      company: "earthodic",
      environment: "Provisioning Smoke",
      admin_email: "demo-admin@earthodic.example",
      domain: domain
    )

    organization = result.organization
    assert_equal "earthodic", organization.portfolio_product_pack
    assert_equal "1.0.0", organization.portfolio_product_pack_version
    assert_equal "shared_managed", organization.deployment_mode
    assert_equal "Biobarc Qualification", organization.brand_name
    assert_equal "AUD", organization.default_currency

    assert_equal result.api_key, ApiKey.authenticate(result.raw_api_token)
    assert_equal ["*"], result.api_key.scopes
    assert_equal "verified", organization.domain_mappings.find_by!(hostname: domain).status
    assert_equal PortfolioProducts::Registry::KNOWN_FEATURE_FLAGS.sort,
      organization.feature_flags.pluck(:flag_key).sort
    assert organization.feature_flags.find_by!(flag_key: "pricing").enabled?

    assert_equal 7, organization.price_versions.count
    assert organization.pricing_experiments.exists?(
      product_code: "application_qualification",
      product_version: "1.2",
      pricing_unit: "application"
    )
    assert organization.webhook_endpoints.exists?(endpoint_code: "WH-EARTHODIC-001")
    assert_equal "demo-admin@earthodic.example", result.invitation.email
    assert_equal organization.role(:org_admin), result.invitation.role
  end
end
