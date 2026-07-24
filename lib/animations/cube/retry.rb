# frozen_string_literal: true

require_relative "_base"

module Claudine
  module Animations
    module Cube
      # After a tool (failure): DOUBLE sharp red blink of the whole cube.
      # Signature: two brief flashes (distinct from the single flash of post_tool), readable even without perceiving the color.
      class Retry < CubeBase
        MIN_DURATION = 0.8
        COLOR = [255, 0, 0].freeze

        def render(t, panel)
          on = (t < 0.12) || (t >= 0.26 && t < 0.38)
          fill(panel, on ? COLOR : [0, 0, 0])
        end
      end
    end
  end
end
