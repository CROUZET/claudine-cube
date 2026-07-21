require_relative 'logger'
require_relative '../config/settings'
require_relative 'animations/base'
require_relative 'intentions'
require_relative 'profiles/claude_code'

module Claudine
  # Owns the current animation and swaps it on each incoming event.
  #
  # Animations are indexed by *intention* (see lib/intentions.rb), not by hook.
  # A connector pushes a raw source event (e.g. :pre_tool); a *profile* maps that
  # event onto an intention (:start); the manager renders the animation the
  # active set provides for that intention. Adding a source = a new profile.
  #
  # The set is picked at construction from ENV['CLAUDINE_ANIMATION_SET']
  # (default 'cube'). Each set lives under lib/animations/<set>/ with one .rb per
  # intention; the filename is the intention (e.g. think.rb → Think class).
  #
  # An intention may declare several *variations* in extra files whose basename
  # ends with `_<digits>` (e.g. `wait_2.rb`, `wait_3.rb` alongside `wait.rb`).
  # They share the same intention; one is picked at random per event, so
  # frequent intentions don't look repetitive.
  #
  # If the active set doesn't provide the resolved intention, the manager walks
  # the vocabulary fallback chain (Intentions.resolve) until it finds one it has.
  #
  # The temporal role comes from the intention's `kind` (Intentions.kind):
  #   :ambient  → persistent "working" background loop
  #   :boundary → cuts the background and shows itself (terminal)
  #   :pulse    → transient overlay: plays once (its MIN_DURATION) then reverts
  #               to the background loop, if one is active
  #   :dormant  → the idle animation (see #enter_idle)
  #
  # Display lock: while an animation has shown for less than its minimum duration
  # (Settings::MIN_ANIMATION_DURATION, overridable per animation via a
  # MIN_DURATION constant), new events don't take over — the latest is buffered
  # in a 1-slot cache and applied when the lock expires (latest-wins).
  class AnimationManager
    DEFAULT_SET    = 'cube'.freeze
    IDLE_INTENTION = :sleep

    attr_reader :set

    def initialize(set: ENV['CLAUDINE_ANIMATION_SET'] || DEFAULT_SET,
                   profile: Profiles::CLAUDE_CODE)
      @set                  = set
      @profile              = profile
      @registry             = load_set(set)
      @current              = nil
      @activated            = nil
      @min_duration         = 0.0
      @pending              = nil    # [intention, payload] buffered during the lock
      @is_idle              = false
      @last_event_t         = nil
      @background           = nil    # persistent "working" animation instance (or nil)
      @background_activated = nil
      @overlay              = false  # is @current a transient overlay?
      @overlay_until        = nil    # time at which the overlay reverts to @background
      @idle_off_at          = nil    # time at which the idle plays-once ends → cube off
    end

    def handle(event, t)
      intention = resolve(event.type)
      return if intention.nil?
      @last_event_t = t

      if lock_open?(t)
        activate(intention, event.payload, t)
      else
        if @pending
          Claudine.logger.debug "AnimationManager: dropping buffered :#{@pending[0]} (superseded by :#{intention})"
        else
          Claudine.logger.debug "AnimationManager: buffering :#{intention} (#{remaining(t).round(2)}s left on #{@current.class.name})"
        end
        @pending = [intention, event.payload]
      end
    end

    def render(t, panel)
      if @pending && lock_open?(t)
        activate(@pending[0], @pending[1], t)
        @pending = nil
      end

      # A finished transient overlay hands back to the working loop.
      if @overlay && @background && t >= @overlay_until
        @current   = @background
        @activated = @background_activated
        @overlay   = false
        Claudine.logger.debug "AnimationManager: overlay done → resume background #{@current.class.name}"
      end

      enter_idle(t, panel) if idle_due?(t)

      # The idle animation plays once; when its lifetime ends, turn the cube off
      # and stop rendering (the blank frame keeps being pushed by the Runner).
      if @idle_off_at && t >= @idle_off_at
        panel.clear
        @current     = nil
        @idle_off_at = nil
        Claudine.logger.info 'AnimationManager: idle animation done → cube off'
      end

      return unless @current
      @current.render(t - @activated, panel)
    end

    private

    # Event type → intention (via profile) → intention the set actually provides
    # (via the fallback chain). Returns nil (and logs) if either step fails.
    def resolve(event_type)
      intention = @profile[event_type]
      if intention.nil?
        Claudine.logger.warn "AnimationManager: event #{event_type} not in profile — ignored"
        return nil
      end
      resolved = Intentions.resolve(intention, @registry.keys)
      if resolved.nil?
        Claudine.logger.warn "AnimationManager: set '#{@set}' has no animation for :#{intention} (nor fallback)"
        return nil
      end
      if resolved != intention
        Claudine.logger.debug "AnimationManager: #{event_type} → :#{intention} (fallback → :#{resolved})"
      end
      resolved
    end

    def activate(intention, payload, t)
      klass = @registry[intention].sample
      anim  = klass.new(payload || {})
      dur   = klass.const_defined?(:MIN_DURATION) ? klass::MIN_DURATION : Settings::MIN_ANIMATION_DURATION
      @is_idle      = false
      @idle_off_at  = nil
      @current      = anim
      @activated    = t
      @min_duration = dur

      case Intentions.kind(intention)
      when :ambient
        @background           = anim
        @background_activated = t
        @overlay              = false
      when :boundary
        @background           = nil
        @overlay              = false
      when :dormant
        # A source that explicitly emits a dormant intention behaves like idle.
        @background  = nil
        @overlay     = false
        @is_idle     = true
        @idle_off_at = klass.const_defined?(:DURATION) ? t + klass::DURATION : nil
      else # :pulse — plays once, then reverts to the background loop
        @overlay       = true
        @overlay_until = t + dur
      end
      Claudine.logger.info "AnimationManager: :#{intention} → #{klass.name} (#{Intentions.kind(intention)}, min #{dur}s)"
    end

    def idle_due?(t)
      return false if @is_idle
      return false unless Settings::IDLE_TIMEOUT && @last_event_t
      (t - @last_event_t) >= Settings::IDLE_TIMEOUT
    end

    def enter_idle(t, panel)
      intention = Intentions.resolve(IDLE_INTENTION, @registry.keys)
      if intention
        klass         = @registry[intention].sample
        @current      = klass.new({})
        @activated    = t
        @min_duration = klass.const_defined?(:MIN_DURATION) ? klass::MIN_DURATION : Settings::MIN_ANIMATION_DURATION
        # Plays once: schedule the cube to turn off after the idle's lifetime.
        @idle_off_at  = klass.const_defined?(:DURATION) ? t + klass::DURATION : nil
        Claudine.logger.info "AnimationManager: idle after #{Settings::IDLE_TIMEOUT}s → #{klass.name}"
      else
        @current     = nil
        @activated   = t
        @idle_off_at = nil
        panel.clear
        Claudine.logger.info "AnimationManager: idle after #{Settings::IDLE_TIMEOUT}s (no :sleep in set '#{@set}') → panel cleared"
      end
      @is_idle    = true
      @background = nil     # going idle ends any working state
      @overlay    = false
    end

    def lock_open?(t)
      return true if @is_idle
      @current.nil? || (t - @activated) >= @min_duration
    end

    def remaining(t)
      return 0.0 if @activated.nil?
      [@min_duration - (t - @activated), 0.0].max
    end

    def load_set(set)
      dir = File.expand_path("animations/#{set}", __dir__)
      raise "AnimationManager: unknown animation set '#{set}' (expected #{dir})" unless Dir.exist?(dir)

      set_module_name = camelize(set)
      registry = Hash.new { |h, k| h[k] = [] }
      # Files starting with `_` are helpers (shared sprites, palettes, base
      # class) — required so animations can `require_relative` them, but not
      # registered. Files ending with `_<digits>` (e.g. `wait_2.rb`) are extra
      # variations of the base intention (`wait`); one is picked at random.
      Dir.glob("#{dir}/*.rb").sort.each do |path|
        base = File.basename(path, '.rb')
        if base.start_with?('_')
          require path
          next
        end
        class_name = camelize(base)
        require path
        full_name  = "Claudine::Animations::#{set_module_name}::#{class_name}"
        klass      = Object.const_get(full_name)
        intention  = base.sub(/_\d+\z/, '').to_sym
        registry[intention] << klass
      end

      unknown = registry.keys.reject { |i| Intentions.known?(i) }
      Claudine.logger.warn "AnimationManager: set '#{set}' has unknown intentions #{unknown.inspect}" unless unknown.empty?
      missing_core = Intentions::CORE - registry.keys
      Claudine.logger.warn "AnimationManager: set '#{set}' is missing core intentions #{missing_core.inspect}" unless missing_core.empty?

      variant_total = registry.values.sum(&:size)
      Claudine.logger.info "AnimationManager: loaded set '#{set}' with #{registry.size} intention(s), #{variant_total} variation(s)"
      registry
    end

    def camelize(snake)
      snake.split('_').map { |w| w[0].upcase + w[1..] }.join
    end
  end
end
