# frozen_string_literal: true

require_relative "_base"

module Claudine
  module Animations
    module Cube
      # Wait (variant): instead of blinking the whole cube in amber, only the TWO inner square rings of each face blink (the 4x4 core: d=2 and d=3), the perimeter staying off.
      # Signature: fast, crisp square blinking of a bright core at the center of each face -- same urgency as the original, more compact footprint.
      # The manager draws at random between Wait and Wait2.
      class Wait2 < CubeBase
        MIN_DURATION = 0.9
        RATE = 3.0 # blinks per second (approx)
        COLOR = [255, 130, 0].freeze
        INNER = [2, 3].freeze # the 2 inner concentric rings

        def render(t, panel)
          panel.clear
          on = (t * RATE).to_i.even?
          rgb = on ? COLOR : dim(COLOR, 0.08)
          ALL_FACES.each do |face|
            INNER.each { |d| face_ring(panel, face, d, rgb) }
          end
        end
      end
    end
  end
end
