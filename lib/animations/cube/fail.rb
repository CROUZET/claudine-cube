# frozen_string_literal: true

require_relative "_base"

module Claudine
  module Animations
    module Cube
      # End of turn (failure): slow, insistent red pulsing (a calm alert).
      # Signature: broad, regular pulsing (distinct from the sharp double-flash of
      # post_tool_fail) -- the rhythm, not the color, carries the info.
      class Fail < CubeBase
        MIN_DURATION = 1.0
        PERIOD = 1.2
        COLOR  = [255, 0, 0].freeze

        def render(t, panel)
          fill(panel, dim(COLOR, 0.15 + (0.85 * wave(t, PERIOD))))
        end
      end
    end
  end
end
