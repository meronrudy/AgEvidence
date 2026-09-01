if Rails.env.production? && ENV["SKIP_PORTFOLIO_PRODUCT_VALIDATION"] != "1"
  Rails.application.config.after_initialize do
    begin
      if ActiveRecord::Base.connection.data_source_exists?("program_profiles")
        PortfolioProducts::Registry.validate_all!(database: true)
      end
    rescue ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished
      Rails.logger.warn("Skipping portfolio product validation because the database is unavailable.")
    end
  end
end
