require 'json'
require_relative '../config/settings'
require_relative 'logger'

module Claudine
  # Single source of truth for the live-tunable settings, persisted to ~/.claudine.
  #
  # The admin server (a control-plane connector) writes here; the Runner reads
  # `#brightness` at the top of each frame and pushes it onto the Panel. A float
  # read on the render thread + a guarded write on the admin thread is safe under
  # the GIL; a Mutex guards the in-memory value and the file write.
  #
  # v1 holds only :brightness. Adding a knob later (theme, integrations) = a new
  # key here + an endpoint + a UI control; the observe-in-the-loop mechanism is
  # already in place. Unknown keys already in the file are preserved on write.
  class Config
    PATH = File.join(Dir.home, '.claudine')

    # Above this factor, brightness is a *session boost*: applied live but never
    # persisted, so a fresh boot (possibly USB-only) can never brown out on a
    # stale high value. See docs/HARDWARE.md (thermal / power / brownout).
    BOOST_CEILING = 0.25

    # Source integrations and their default state (all on). Turning one off gates
    # that source's event ingestion (the connector still answers, it just doesn't
    # push) — the render path is untouched. Only `claude_code` exists today.
    DEFAULT_INTEGRATIONS = { 'claude_code' => true }.freeze

    def initialize(path: PATH)
      @path       = path
      @mutex      = Mutex.new
      @brightness   = load_brightness
      @integrations = load_integrations
      Claudine.logger.info "Config: brightness=#{@brightness} (source: #{@source}), integrations=#{@integrations}"
    end

    def brightness
      @mutex.synchronize { @brightness }
    end

    # Sets the working brightness. Clamped to [0, 1]. Persisted only when within
    # the safe ceiling; a higher value is a volatile session boost (not written),
    # so it is never auto-restored on the next boot.
    def brightness=(value)
      v = value.to_f.clamp(0.0, 1.0)
      @mutex.synchronize do
        @brightness = v
        if v <= BOOST_CEILING
          persist_key('brightness', v)
        else
          Claudine.logger.info "Config: brightness #{v} > #{BOOST_CEILING} → session boost (not persisted)"
        end
      end
      v
    end

    def boost?
      brightness > BOOST_CEILING
    end

    # Is the named source integration on? Unknown names default to on.
    def integration_enabled?(name)
      @mutex.synchronize { @integrations.fetch(name.to_s, true) }
    end

    # Enables/disables a source integration and persists the whole map.
    def set_integration(name, enabled)
      on = !!enabled
      @mutex.synchronize do
        @integrations[name.to_s] = on
        persist_key('integrations', @integrations)
      end
      on
    end

    def to_state
      { brightness: brightness, boost_ceiling: BOOST_CEILING, integrations: integrations }
    end

    def integrations
      @mutex.synchronize { @integrations.dup }
    end

    private

    # Precedence: ENV (explicit dev override, honored as-is — may exceed the
    # ceiling since it is a deliberate act) > ~/.claudine (clamped to the ceiling
    # as a defense against a hand-edited file) > Settings default.
    def load_brightness
      if (env = ENV['CLAUDINE_BRIGHTNESS'])
        @source = 'ENV'
        return env.to_f.clamp(0.0, 1.0)
      end
      raw = read_file['brightness']
      if raw
        @source = @path
        return raw.to_f.clamp(0.0, BOOST_CEILING)
      end
      @source = 'default'
      Settings::BRIGHTNESS
    end

    # Defaults (all on) overlaid with whatever the file stored; unknown/future
    # keys in the file are preserved. Values are coerced to booleans.
    def load_integrations
      base   = DEFAULT_INTEGRATIONS.dup
      stored = read_file['integrations']
      base.merge!(stored.transform_values { |v| !!v }) if stored.is_a?(Hash)
      base
    end

    def read_file
      return {} unless File.exist?(@path)
      data = JSON.parse(File.read(@path))
      data.is_a?(Hash) ? data : {}
    rescue JSON::ParserError => e
      Claudine.logger.warn "Config: #{@path} is not valid JSON (#{e.message}) — using defaults"
      {}
    rescue => e
      Claudine.logger.warn "Config: cannot read #{@path} (#{e.class}: #{e.message}) — using defaults"
      {}
    end

    # Merge-and-write so future keys (theme, integrations) are not clobbered.
    # Atomic (tmp + rename) so a crash mid-write cannot corrupt the file.
    def persist_key(key, value)
      data = read_file
      data[key] = value
      tmp = "#{@path}.tmp"
      File.write(tmp, JSON.pretty_generate(data) + "\n")
      File.rename(tmp, @path)
    rescue => e
      Claudine.logger.warn "Config: cannot write #{@path} (#{e.class}: #{e.message})"
    end
  end
end
