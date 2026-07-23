# frozen_string_literal: true

require_relative "_base"

module Claudine
  module Animations
    module Cube
      # Wait: bold amber blinking (attention request). Only lights up
      # the outer ring (d=0) and the 3rd ring (d=2) of each face, as a
      # target/two concentric frames -- rings d=1 and d=3 stay off.
      # Signature: fast square blinking (crisp on/off), very different from the
      # breathing and fades.
      class Wait < CubeBase
        MIN_DURATION = 0.9
        RATE  = 3.0 # blinks per second (approx)
        COLOR = [255, 130, 0].freeze
        RINGS = [0, 2].freeze # outer ring + 3rd ring

        def render(t, panel)
          panel.clear
          on = (t * RATE).to_i.even?
          rgb = on ? COLOR : dim(COLOR, 0.08)
          ALL_FACES.each do |face|
            RINGS.each { |d| face_ring(panel, face, d, rgb) }
          end
        end
      end
    end
  end
end
