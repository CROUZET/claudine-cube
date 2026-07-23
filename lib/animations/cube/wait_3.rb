# frozen_string_literal: true

require_relative "_base"

module Claudine
  module Animations
    module Cube
      # Wait (inverse variant of Wait2): only the TWO OUTER
      # square rings of each face blink (the frame: d=0 and d=1), the 4x4
      # core staying off.
      # Signature: fast, crisp square blinking of a bright frame at the border
      # of each face. The manager draws at random between Wait,
      # Wait2 (core) and Wait3 (frame).
      class Wait3 < CubeBase
        MIN_DURATION = 0.9
        RATE  = 3.0 # blinks per second (approx)
        COLOR = [255, 130, 0].freeze
        OUTER = [0, 1].freeze # the 2 outer concentric rings

        def render(t, panel)
          panel.clear
          on = (t * RATE).to_i.even?
          rgb = on ? COLOR : dim(COLOR, 0.08)
          ALL_FACES.each do |face|
            OUTER.each { |d| face_ring(panel, face, d, rgb) }
          end
        end
      end
    end
  end
end
