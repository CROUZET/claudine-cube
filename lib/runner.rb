require_relative 'panel'
require_relative 'logger'
require_relative 'event_bus'
require_relative 'config'

module Claudine
  # Fixed-cadence render loop.
  # Every frame: reflects the live Config brightness onto the panel, drains the
  # event bus, calls manager.render(t, panel), then panel.show. Measures elapsed
  # real time to hold the requested FPS. Catches Ctrl-C to blank the panel
  # cleanly on shutdown.
  class Runner
    attr_reader :bus

    def initialize(manager:, bus: EventBus.new, fps: Settings::FPS, config: Config.new)
      @manager    = manager
      @bus        = bus
      @fps        = fps
      @frame_time = 1.0 / fps
      @config     = config
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
        panel.brightness = @config.brightness    # live control-plane value (hot)
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
  end
end
