source 'https://rubygems.org'

ruby '3.4.10'

gem 'rails', '~> 8.1.0'
gem 'sprockets-rails', '~> 3.5'
gem 'puma', '>= 6.4'
gem 'bootsnap', require: false

gem 'pg', '~> 1.5'

gem 'devise', '>= 5.0.4', '< 6.0'
gem 'nokogiri', '>= 1.19.4'
gem 'omniauth', '~> 2.1'
gem 'omniauth-rails_csrf_protection', '~> 2.0'
gem 'pundit', '~> 2.4'
gem 'rack-attack', '~> 6.7'
gem 'solid_queue', '~> 1.2'
gem 'sentry-rails', '~> 5.22'
gem 'sentry-ruby', '~> 5.22'
gem 'bcrypt', '~> 3.1'

group :development, :test do
  gem 'brakeman', require: false
  gem 'bundler-audit', require: false
  gem 'debug', platforms: %i[mri windows], require: 'debug/prelude'
  gem 'rubocop-rails', require: false
  gem 'sqlite3', '~> 2.1'
end

group :development do
  gem 'listen', '~> 3.10'
  gem 'web-console', '~> 4.2'
end

group :test do
  gem 'capybara', '~> 3.40'
  gem 'selenium-webdriver', '~> 4.25'
end
