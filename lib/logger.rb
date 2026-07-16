require 'logger'

module Claudine
  class << self
    attr_writer :logger

    def logger
      @logger ||= build_logger
    end

    private

    def build_logger
      level_name = (ENV['CLAUDINE_LOG_LEVEL'] || 'INFO').upcase
      level = ::Logger.const_defined?(level_name) ? ::Logger.const_get(level_name) : ::Logger::INFO
      $stdout.sync = true  # live logs even when stdout is piped / redirected
      log = ::Logger.new($stdout)
      log.level = level
      log.formatter = proc do |severity, datetime, _progname, msg|
        "[#{datetime.strftime('%H:%M:%S.%L')}] #{severity.ljust(5)} #{msg}\n"
      end
      log
    end
  end
end
