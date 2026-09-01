namespace :portfolio do
  desc "Provision a portfolio product tenant, for example bin/rails portfolio:provision[earthodic]"
  task :provision, [:company] => :environment do |_task, args|
    company = args[:company].presence || raise(ArgumentError, "company is required")
    result = PortfolioProvisioningService.call(
      company: company,
      admin_email: ENV.fetch("ADMIN_EMAIL", "admin@#{company}.example"),
      environment: ENV.fetch("PORTFOLIO_ENVIRONMENT", "Sandbox"),
      domain: ENV["DOMAIN"]
    )

    puts "Provisioned #{result.organization.name}"
    puts "API key code: #{result.api_key.key_code}"
    puts "Initial API token: #{result.raw_api_token}"
    puts "Invitation: #{result.invitation.email}"
  end
end

namespace :portfolio_products do
  desc "Validate portfolio product pack configuration against the Rails database"
  task validate: :environment do
    PortfolioProducts::Registry.validate_all!(database: true)
    puts "Validated #{PortfolioProducts::Registry.all.count} portfolio product pack(s)."
  end
end
