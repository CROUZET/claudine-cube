require 'webrick'
require 'json'
require_relative '../logger'

module Claudine
  module Connectors
    # Control-plane HTTP server (WEBrick) on localhost. Serves the admin page and
    # a tiny JSON API to tune the cube live.
    #
    # It writes to a shared Config; the Runner observes Config each frame and
    # pushes the value onto the Panel (see lib/runner.rb). This server is NOT an
    # event source — it never touches the render/animation path (cf. CLAUDE.md:
    # adding a control never touches the render path).
    #
    # Routes:
    #   GET  /                → the admin page (self-contained HTML)
    #   GET  /api/state       → { "brightness": .., "boost_ceiling": .., "integrations": {..} }
    #   POST /api/brightness  → body { "value": <0..1> } → 204 (400 on bad input)
    #   POST /api/integration → body { "name": "claude_code", "enabled": bool } → 204
    class AdminServer
      DEFAULT_PORT = 9293
      HOST         = '127.0.0.1'
      INDEX        = File.expand_path('admin/index.html', __dir__)

      def initialize(config:, port: DEFAULT_PORT)
        @config = config
        @port   = port
      end

      def start
        @server = WEBrick::HTTPServer.new(
          BindAddress: HOST,
          Port:        @port,
          Logger:      WEBrick::Log.new(File::NULL), # silence WEBrick's own logs
          AccessLog:   []
        )
        mount_routes
        @thread = Thread.new { @server.start }
        @thread.report_on_exception = true
        Claudine.logger.info "AdminServer: listening on http://#{HOST}:#{@port}"
      end

      def stop
        @server&.shutdown
        @thread&.join
        Claudine.logger.info 'AdminServer: stopped'
      end

      private

      def mount_routes
        # WEBrick routes to the longest matching mount, so /api/* win over '/'.
        @server.mount_proc('/') do |req, res|
          req.path == '/' ? serve_index(res) : (res.status = 404)
        end

        @server.mount_proc('/api/state') do |_req, res|
          res.status = 200
          res['Content-Type'] = 'application/json'
          res.body = JSON.generate(@config.to_state)
        end

        @server.mount_proc('/api/brightness') do |req, res|
          req.request_method == 'POST' ? handle_brightness(req, res) : (res.status = 405)
        end

        @server.mount_proc('/api/integration') do |req, res|
          req.request_method == 'POST' ? handle_integration(req, res) : (res.status = 405)
        end
      end

      def serve_index(res)
        res.status = 200
        res['Content-Type'] = 'text/html; charset=utf-8'
        res.body = File.read(INDEX)
      rescue => e
        Claudine.logger.error "AdminServer: cannot read #{INDEX} (#{e.message})"
        res.status = 500
      end

      def handle_brightness(req, res)
        value = JSON.parse(req.body || '{}')['value']
        unless value.is_a?(Numeric)
          res.status = 400
          return
        end
        @config.brightness = value
        res.status = 204
      rescue JSON::ParserError
        res.status = 400
      end

      def handle_integration(req, res)
        data    = JSON.parse(req.body || '{}')
        name    = data['name']
        enabled = data['enabled']
        unless name.is_a?(String) && !name.empty? && [true, false].include?(enabled)
          res.status = 400
          return
        end
        @config.set_integration(name, enabled)
        res.status = 204
      rescue JSON::ParserError
        res.status = 400
      end
    end
  end
end
