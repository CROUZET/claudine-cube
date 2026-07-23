source "https://rubygems.org"

ruby "4.0.5"

# ~> X.Y.Z pins major+minor and allows only patch updates on `bundle update`;
# the committed Gemfile.lock still pins the exact versions for reproducibility.
gem "rubyserial", "~> 0.6.0"    # >= 0.6.0 is required for the high baud rate
gem "webrick",    "~> 1.9.2"    # admin control-plane HTTP server (left default gems in Ruby 3+)
gem "logger",     "~> 1.7.0"    # used by lib/logger.rb (left default gems in Ruby 4.0)
gem "json",       "~> 2.21.1"   # Config persistence + admin JSON API

group :test do
  gem "rake",     "~> 13.4.2"
  gem "minitest", "~> 5.27.0"
end
