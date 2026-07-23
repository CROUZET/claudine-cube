# frozen_string_literal: true

source "https://rubygems.org"

ruby "4.0.5"

gem "json", "~> 2.21" # Config persistence + admin JSON API
gem "logger", "~> 1.7" # used by lib/logger.rb (left default gems in Ruby 4.0)
gem "rubyserial", "~> 0.6" # >= 0.6.0 is required for the high baud rate
gem "webrick", "~> 1.9" # admin control-plane HTTP server (left default gems in Ruby 3+)

group :test do
  gem "minitest", "~> 5.27"
  gem "rake", "~> 13.4"

  # Linting — rules to be defined in .rubocop.yml. require: false (not loaded at runtime).
  gem "rubocop", "~> 1.88", require: false
  gem "rubocop-minitest", "~> 0.40", require: false
  gem "rubocop-performance", "~> 1.26", require: false
  gem "rubocop-rake", "~> 0.7", require: false
end
