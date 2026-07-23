# frozen_string_literal: true

require "socket"
require_relative "../event"
require_relative "../logger"
require_relative "../../config/settings"

module Claudine
  module Connectors
    # Minimal HTTP server on localhost that receives Claude Code hooks.
    #
    # Expected protocol: POST /event/<type>   (body ignored)
    # Each Claude Code hook typically runs: curl -sX POST http://localhost:9292/event/session_start
    #
    # The incoming <type> is pushed onto the bus as-is; the AnimationManager
    # picks the animation for that type from the active set (see
    # CLAUDINE_ANIMATION_SET). No translation table lives here anymore.
    class ClaudeCode
      # `config` (optional) gates event ingestion: when the `claude_code`
      # integration is disabled, incoming hooks still get a 204 (hooks never
      # error) but are dropped rather than pushed onto the bus.
      def initialize(bus:, port: Settings::CLAUDE_CODE_PORT, config: nil)
        @bus = bus
        @port = port
        @config = config
      end

      def start
        @server = TCPServer.new(Settings::LOCAL_HOST, @port)
        Claudine.logger.info "ClaudeCode: listening on http://#{Settings::LOCAL_HOST}:#{@port}"
        @thread = Thread.new { serve }
        @thread.report_on_exception = true
      end

      def stop
        @server&.close # unblocks accept()
        @thread&.join
        Claudine.logger.info "ClaudeCode: stopped"
      end

      private

      def serve
        loop do
          client = @server.accept
          handle_client(client)
        rescue IOError
          break # server closed, clean exit
        rescue StandardError => e
          Claudine.logger.error "ClaudeCode: error — #{e.class}: #{e.message}"
        end
      end

      def handle_client(client)
        request_line = client.gets
        return unless request_line

        method, path, _http = request_line.split(" ", 3)

        # Drain the headers; body ignored (not needed for the MVP).
        while (line = client.gets) && line != "\r\n"
        end

        if method == "POST" && path&.start_with?("/event/")
          type = path.sub("/event/", "").chomp.to_sym
          if enabled?
            Claudine.logger.debug "ClaudeCode: #{type}"
            @bus.push(Claudine::Event.new(type: type, payload: {}))
          else
            Claudine.logger.debug "ClaudeCode: #{type} dropped (integration disabled)"
          end
          respond(client, 204)
        else
          respond(client, 404)
        end
      ensure
        client&.close
      end

      def enabled?
        @config.nil? || @config.integration_enabled?(:claude_code)
      end

      def respond(client, status)
        reason = { 204 => "No Content", 404 => "Not Found" }.fetch(status, "OK")
        client.write("HTTP/1.1 #{status} #{reason}\r\nContent-Length: 0\r\nConnection: close\r\n\r\n")
      end
    end
  end
end
