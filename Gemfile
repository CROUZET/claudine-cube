source "https://rubygems.org"

ruby "4.0.5"

gem "rubyserial", '>= 0.6.0'
gem "webrick"       # admin control-plane HTTP server (removed from default gems in Ruby 3+)
gem "logger"        # used by lib/logger.rb (removed from default gems in Ruby 4.0)
gem "json"          # Config persistence + admin JSON API

group :test do
  gem "rake"
  gem "minitest", "~> 5"
end
