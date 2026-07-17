require_relative 'logger'
require_relative '../config/settings'
require_relative 'animations/base'

module Claudine
  # Owns the current animation and swaps it on each incoming event.
  #
  # The set of animations is picked at construction time from
  # ENV['CLAUDINE_ANIMATION_SET'] (default: 'default'). Each set lives under
  # lib/animations/<set>/ with one .rb per Claude Code hook. The filename
  # matches the hook name (e.g. session_start.rb → SessionStart class).
  #
  # A hook may declare several *variations* in additional files whose basename
  # ends with `_<digits>` (e.g. `post_tool_2.rb`, `post_tool_3.rb` alongside
  # `post_tool.rb`). All variations share the same hook symbol; on each event
  # one is picked at random. This lets high-frequency events (like post_tool)
  # avoid looking repetitive.
  #
  # Files whose basename starts with `system_` (e.g. `system_idle.rb`) are
  # *system* animations — triggered by the manager itself rather than by a
  # connector event. They register under `:system_<name>` and follow the
  # same variant convention (`system_idle_2.rb` is a variant of the idle).
  # `system_idle` is currently the only system slot: after
  # `Settings::IDLE_TIMEOUT` seconds without any event, the manager
  # activates it (or clears the panel if the set has none).
  #
  # For each event, a fresh animation instance is created and installed as
  # current. `render(t, panel)` passes the time *since activation* to the
  # animation, so time-based effects always play from the top.
  #
  # Display lock: while an animation has been showing for less than its
  # minimum duration (`Settings::MIN_ANIMATION_DURATION`, overridable per
  # animation via a `MIN_DURATION` constant on the class), new incoming
  # events don't take over — the latest one is buffered in a 1-slot cache
  # and applied as soon as the lock expires. Older buffered events are
  # dropped (latest-wins).
  class AnimationManager
    DEFAULT_SET = 'cube'.freeze

    # Two-layer state model (see #render):
    #   - BACKGROUND events start a persistent "busy/working" loop that keeps
    #     playing until a CLEAR event ends it. This is what shows during
    #     thinking (e.g. user_prompt looping).
    #   - CLEAR events end the background and display their own thing.
    #   - Any other event is a transient OVERLAY: it plays once (for its
    #     MIN_DURATION) then reverts to the background loop, if one is active.
    BACKGROUND_EVENTS = %i[user_prompt].freeze
    CLEAR_EVENTS      = %i[stop stop_failure session_end session_start].freeze

    attr_reader :set

    def initialize(set: ENV['CLAUDINE_ANIMATION_SET'] || DEFAULT_SET)
      @set                  = set
      @registry             = load_set(set)
      @current              = nil
      @activated            = nil
      @min_duration         = 0.0
      @pending              = nil
      @is_idle              = false
      @last_event_t         = nil
      @background           = nil    # persistent "busy" animation instance (or nil)
      @background_activated = nil
      @overlay              = false  # is @current a transient overlay?
      @overlay_until        = nil    # time at which the overlay reverts to @background
      @idle_off_at          = nil    # time at which the idle plays-once ends → cube off
    end

    def handle(event, t)
      variants = @registry[event.type]
      if variants.nil? || variants.empty?
        Claudine.logger.warn "AnimationManager: no animation for #{event.type} in set '#{@set}'"
        return
      end
      klass = variants.sample
      @last_event_t = t

      if lock_open?(t)
        activate(event, klass, t)
      else
        if @pending
          Claudine.logger.debug "AnimationManager: dropping buffered #{@pending.type} (superseded by #{event.type})"
        else
          Claudine.logger.debug "AnimationManager: buffering #{event.type} (#{remaining(t).round(2)}s left on #{@current.class.name})"
        end
        @pending = event
      end
    end

    def render(t, panel)
      if @pending && lock_open?(t)
        variants = @registry[@pending.type]
        activate(@pending, variants.sample, t) if variants && !variants.empty?
        @pending = nil
      end

      # A finished transient overlay hands back to the busy/working loop.
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

    def activate(event, klass, t)
      anim = klass.new(event.payload || {})
      dur  = klass.const_defined?(:MIN_DURATION) ? klass::MIN_DURATION : Settings::MIN_ANIMATION_DURATION
      @is_idle      = false
      @idle_off_at  = nil
      @current      = anim
      @activated    = t
      @min_duration = dur

      case category(event.type)
      when :background
        @background           = anim
        @background_activated = t
        @overlay              = false
      when :clear
        @background           = nil
        @overlay              = false
      else # :transient — plays once, then reverts to the background loop
        @overlay       = true
        @overlay_until = t + dur
      end
      Claudine.logger.info "AnimationManager: #{event.type} → #{klass.name} (#{category(event.type)}, min #{dur}s)"
    end

    def category(type)
      return :background if BACKGROUND_EVENTS.include?(type)
      return :clear      if CLEAR_EVENTS.include?(type)
      :transient
    end

    def idle_due?(t)
      return false if @is_idle
      return false unless Settings::IDLE_TIMEOUT && @last_event_t
      (t - @last_event_t) >= Settings::IDLE_TIMEOUT
    end

    def enter_idle(t, panel)
      idle_variants = @registry[:system_idle]
      if idle_variants && !idle_variants.empty?
        klass         = idle_variants.sample
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
        Claudine.logger.info "AnimationManager: idle after #{Settings::IDLE_TIMEOUT}s (no system_idle in set '#{@set}') → panel cleared"
      end
      @is_idle    = true
      @background = nil     # going idle ends any busy/working state
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
      # Files starting with `_` are helpers (shared sprites, palettes, ...) —
      # required so animations can `require_relative` them, but not registered
      # as hook classes. Files ending with `_<digits>` (e.g. `post_tool_2.rb`)
      # are extra variations of the base hook (`post_tool`); when the event
      # fires, one variation is picked at random.
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
        hook_name  = base.sub(/_\d+\z/, '')
        registry[hook_name.to_sym] << klass
      end
      variant_total = registry.values.sum(&:size)
      Claudine.logger.info "AnimationManager: loaded set '#{set}' with #{registry.size} hook(s), #{variant_total} variation(s)"
      registry
    end

    def camelize(snake)
      snake.split('_').map { |w| w[0].upcase + w[1..] }.join
    end
  end
end
