# frozen_string_literal: true

require_relative "panel"
require_relative "logger"
require_relative "event_bus"
require_relative "config"
require_relative "status"

module Claudine
  # Fixed-cadence render loop.
  # Every frame: reflects the live Config brightness onto the panel, drains the
  # event bus, calls manager.render(t, panel), then panel.show. Measures elapsed
  # real time to hold the requested FPS. Catches Ctrl-C to blank the panel
  # cleanly on shutdown.
  class Runner
    attr_reader :bus

    def initialize(manager:, bus: EventBus.new, fps: Settings::FPS,
                   config: Config.new, status: Status.new)
      @manager = manager
      @bus = bus
      @fps = fps
      @frame_time = 1.0 / fps
      @config = config
      @status = status
      @applied_theme = config.theme # the set the manager was built with
    end

    def start
      panel = Panel.new(brightness: @config.brightness)
      Claudine.logger.info "Runner: started (#{@fps} fps)"
      begin
        run_loop(panel)
      rescue Interrupt
        Claudine.logger.info "Runner: interrupted (Ctrl-C)"
      ensure
        panel.clear
        panel.show
        panel.close
      end
    end

    private

    def run_loop(panel)
      t0 = monotonic
      frames = 0
      loop do
        frame_start = monotonic
        t = frame_start - t0

        active = @config.any_integration_enabled?
        panel.brightness = @config.brightness # live control-plane value (hot)

        if @config.theme != @applied_theme # hot theme swap (only on change)
          @manager.switch_set(@config.theme)
          @applied_theme = @config.theme
        end

        if active
          @bus.drain.each { |event| @manager.handle(event, t) }
          @manager.render(t, panel)
        else
          # No source is driving the cube → turn it off. Reset once on the
          # on→off transition so a later resume starts blank, and drop any
          # already-queued events so they don't replay on resume.
          @manager.reset if @sources_active
          @bus.drain
          panel.clear
        end
        @sources_active = active
        publish_status(t, active)
        panel.show
        frames += 1

        elapsed = monotonic - frame_start
        if elapsed < @frame_time
          sleep(@frame_time - elapsed)
        else
          Claudine.logger.debug(
            "Runner: frame #{frames} late (#{(elapsed * 1000).round(1)} ms > #{(@frame_time * 1000).round} ms)"
          )
        end
      end
    end

    def monotonic
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    # Publishes a runtime snapshot for the admin status panel. `:off` overrides
    # the manager's state when no source is driving the cube (it's blanked).
    def publish_status(t, active)
      snap = @manager.status(t).merge(
        uptime_s: t.round,
        fps: @fps,
        source_active: active,
        brightness: @config.brightness.round(3)
      )
      snap[:state] = :off unless active
      @status.publish(snap)
    end
  end
end
