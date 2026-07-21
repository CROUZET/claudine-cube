require_relative '_base'

module Claudine
  module Animations
    module Cube
      # Before compaction: a checkerboard of 2x2 squares on the 5 faces, which
      # inverts at regular intervals (the lit and unlit squares swap places).
      # Signature: a blinking checkerboard alternating over the whole cube.
      class PreCompact < CubeBase
        MIN_DURATION = 1.0
        PHASE  = 0.3             # duration of a phase before the checkerboard inverts
        SQUARE = 2               # side of a square (px)
        COLOR  = [210, 210, 210] # neutral gray

        def render(t, panel)
          panel.clear
          lit = (t / PHASE).to_i.even? ? 0 : 1   # which parity is lit
          ALL_FACES.each do |face|
            SIDE.times do |x|
              SIDE.times do |y|
                next unless (x / SQUARE + y / SQUARE) % 2 == lit
                px(panel, face, x, y, self.class::COLOR)
              end
            end
          end
        end
      end
    end
  end
end
