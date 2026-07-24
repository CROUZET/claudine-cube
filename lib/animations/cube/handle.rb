# frozen_string_literal: true

require_relative "_base"

module Claudine
  module Animations
    module Cube
      # New task: on the 5 faces, the 2 outer rings and the 2 inner rings light up in regular alternation ("inside / outside" breathing synchronized across the whole cube).
      # Signature: alternating concentric blinking, identical on each face.
      class Handle < CubeBase
        MIN_DURATION = 0.6
        PHASE = 0.4 # duration of a phase (seconds) before switching
        COLOR = [0, 180, 120].freeze

        def render(t, panel)
          panel.clear
          outer = (t / PHASE).to_i.even? # true: outer rings; false: inner
          rings = outer ? [0, 1] : [2, 3]
          ALL_FACES.each do |face|
            rings.each { |d| face_ring(panel, face, d, self.class::COLOR) }
          end
        end
      end
    end
  end
end
