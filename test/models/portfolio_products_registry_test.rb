require "test_helper"
require "rake"

class PortfolioProductsRegistryTest < ActiveSupport::TestCase
  setup do
    seed_demo!
  end

  test "earthodic product pack validates against database and rake task" do
    assert PortfolioProducts::Registry.validate_all!(database: true)

    Rails.application.load_tasks unless Rake::Task.task_defined?("portfolio_products:validate")
    Rake::Task["portfolio_products:validate"].reenable

    assert_output(/Validated 1 portfolio product pack/) do
      Rake::Task["portfolio_products:validate"].invoke
    end
  end

  test "validation rejects unpinned pack versions" do
    data = earthodic_pack_data
    data["version"] = "1.0"

    error = assert_raises(PortfolioProducts::Registry::ValidationError) do
      PortfolioProducts::Registry.validate!(PortfolioProducts::Pack.new(data))
    end

    assert_includes error.message, "version must be pinned"
  end

  test "validation rejects bad navigation targets duplicate products and invalid pricing units" do
    data = earthodic_pack_data
    data["navigation"] = [{ "label" => "Broken", "items" => [{ "target" => "missing", "label" => "Missing" }] }]
    assert_validation_error(data, "unknown navigation targets")

    data = earthodic_pack_data
    data["products"] << data["products"].first.deep_dup
    assert_validation_error(data, "duplicate product codes")

    data = earthodic_pack_data
    data["products"].first["pricing_units"] = ["unknown_unit"]
    assert_validation_error(data, "invalid pricing units")
  end

  test "validation rejects product profile references outside the pack manifest" do
    data = earthodic_pack_data
    data["products"].first["program_profiles"] = ["earthodic.unknown.v1"]
    assert_validation_error(data, "undeclared program profiles")

    data = earthodic_pack_data
    data["products"].first["artifact_profile"] = "unknown_pack"
    assert_validation_error(data, "undeclared artifact profile")
  end

  private

  def earthodic_pack_data
    PortfolioProducts::Registry.fetch("earthodic").data.deep_dup
  end

  def assert_validation_error(data, message)
    error = assert_raises(PortfolioProducts::Registry::ValidationError) do
      PortfolioProducts::Registry.validate!(PortfolioProducts::Pack.new(data))
    end

    assert_includes error.message, message
  end
end
