# frozen_string_literal: true

source "https://rubygems.org"

ruby "4.0.5"

# ~> X.Y.Z pins major+minor and allows only patch updates on `bundle update`;
# the committed Gemfile.lock still pins the exact versions for reproducibility.
gem "json", "~> 2.21.1" # Config persistence + admin JSON API
gem "logger", "~> 1.7.0" # used by lib/logger.rb (left default gems in Ruby 4.0)
gem "rubyserial", "~> 0.6.0" # >= 0.6.0 is required for the high baud rate
gem "webrick", "~> 1.9.2" # admin control-plane HTTP server (left default gems in Ruby 3+)

group :test do
  gem "minitest", "~> 5.27.0"
  gem "rake", "~> 13.4.2"

  # Linting — rules to be defined in .rubocop.yml. require: false (not loaded at runtime).
  gem "rubocop", "~> 1.88.2", require: false
  gem "rubocop-minitest", "~> 0.40.0", require: false
  gem "rubocop-performance", "~> 1.26.1", require: false
  gem "rubocop-rake", "~> 0.7.1", require: false
end
