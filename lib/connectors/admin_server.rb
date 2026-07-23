require 'webrick'
require 'json'
require_relative '../logger'
require_relative '../event'
require_relative '../intentions'
require_relative '../animation_manager'
require_relative '../status'
require_relative '../../config/settings'

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
    #   GET  /api/state       → { "brightness", "boost_ceiling", "theme", "themes", "integrations" }
    #   GET  /api/status      → live runtime snapshot (state, animation, uptime, …), read-only
    #   POST /api/brightness  → body { "value": <0..1> } → 204 (400 on bad input)
    #   POST /api/integration → body { "name": "claude_code", "enabled": bool } → 204
    #   POST /api/theme       → body { "theme": "<set>" } → 204 (400 if unknown)
    #   POST /api/trigger     → body { "intention": "<name>" } → 204 (pushes onto the bus)
    class AdminServer
      INDEX = File.expand_path('admin/index.html', __dir__)

      # `bus` (optional) lets the trigger buttons push an intention event; when
      # nil, POST /api/trigger is unavailable (503).
      def initialize(config:, status: Status.new, bus: nil, port: Settings::ADMIN_PORT)
        @config = config
        @status = status
        @bus    = bus
        @port   = port
      end

      def start
        @server = WEBrick::HTTPServer.new(
          BindAddress: Settings::LOCAL_HOST,
          Port:        @port,
          Logger:      WEBrick::Log.new(File::NULL), # silence WEBrick's own logs
          AccessLog:   []
        )
        mount_routes
        @thread = Thread.new { @server.start }
        @thread.report_on_exception = true
        Claudine.logger.info "AdminServer: listening on http://#{Settings::LOCAL_HOST}:#{@port}"
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
          res.body = JSON.generate(@config.to_state.merge(
            themes:     AnimationManager.available_sets,
            intentions: Intentions::VOCAB.keys
          ))
        end

        @server.mount_proc('/api/status') do |_req, res|
          res.status = 200
          res['Content-Type'] = 'application/json'
          res.body = JSON.generate(@status.current)
        end

        @server.mount_proc('/api/brightness') do |req, res|
          req.request_method == 'POST' ? handle_brightness(req, res) : (res.status = 405)
        end

        @server.mount_proc('/api/integration') do |req, res|
          req.request_method == 'POST' ? handle_integration(req, res) : (res.status = 405)
        end

        @server.mount_proc('/api/theme') do |req, res|
          req.request_method == 'POST' ? handle_theme(req, res) : (res.status = 405)
        end

        @server.mount_proc('/api/trigger') do |req, res|
          req.request_method == 'POST' ? handle_trigger(req, res) : (res.status = 405)
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

      def handle_theme(req, res)
        theme = JSON.parse(req.body || '{}')['theme']
        unless theme.is_a?(String) && AnimationManager.available_sets.include?(theme)
          res.status = 400
          return
        end
        @config.theme = theme
        res.status = 204
      rescue JSON::ParserError
        res.status = 400
      end

      def handle_trigger(req, res)
        if @bus.nil?
          res.status = 503
          return
        end
        name = JSON.parse(req.body || '{}')['intention']
        unless name.is_a?(String) && Intentions.known?(name.to_sym)
          res.status = 400
          return
        end
        # `once: true` → the manager plays it a single time (overlay), never as a
        # looping background, then reverts to the working loop or blanks.
        @bus.push(Claudine::Event.new(type: name.to_sym, payload: { once: true }))
        res.status = 204
      rescue JSON::ParserError
        res.status = 400
      end
    end
  end
end
