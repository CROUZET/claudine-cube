module Claudine
  module Animations
    # Common interface for every animation.
    #
    # Contract: `render(t, panel)` fully populates the panel state
    # at time `t` (seconds since the animation started).
    # The animation is responsible for its own clearing (typically via
    # `panel.clear` or `panel.fill`) — the Runner does not clear, to allow
    # trail effects if needed.
    class Base
      def render(t, panel)
        raise NotImplementedError, "#{self.class}#render(t, panel)"
      end
    end
  end
end
