require_relative '_base'

module Claudine
  module Animations
    module Bunny
      # Notification: front (1) + back (3) -> close-up of a bunny head
      # (with the eye and one ear) doing peekaboo with the paw (yellow);
      # right (2) + left (4) -> close-up of a carrot (red body + green
      # tops) bouncing; top (5) -> outer yellow ring that turns.
      # Short overlay.
      # Signature: bunny waving + carrot jumping.
      class Notification < BunnyBase
        MIN_DURATION = 1.5
        COLOR  = [255, 200, 0]   # yellow (bunny)
        BODY_C = [255, 0, 0]     # carrot body (red)
        LEAF   = [0, 170, 0]     # tops
        FREQ   = 2.5             # frequency (Hz)
        SPIN     = 0.15          # turns/second of the top ring
        SEGMENTS = 8             # number of segments (yellow arcs / holes) of the ring

        # Head close-up (fixed). dx, dy ; 0 = bottom. Eye = gap at (2,2).
        #   . # # . . . . .   ear
        #   . # # . . . . .
        #   . # # . . . . .
        #   # # # . . . . .
        #   # # # # . . . .
        #   # # . # # . . .   eye (gap at 2)
        #   # # # # # . . .
        #   # # # # . . . .
        HEAD = [
                  [1, 7], [2, 7],
                  [1, 6], [2, 6],
                  [1, 5], [2, 5],
          [0, 4], [1, 4], [2, 4],
          [0, 3], [1, 3], [2, 3], [3, 3],
          [0, 2], [1, 2],         [3, 2], [4, 2],
          [0, 1], [1, 1], [2, 1], [3, 1], [4, 1],
          [0, 0], [1, 0], [2, 0], [3, 0],
        ].freeze

        # Raised paw (columns 6,7 ; shifts horizontally to wave).
        PAW = [
          [6, 4], [7, 4],
          [6, 3], [7, 3],
          [6, 2], [7, 2],
          [6, 1], [7, 1],
          [6, 0], [7, 0],
        ].freeze

        # Carrot, close-up on the TOP: large green tops + wide red body
        # that fills the face and exits at the bottom (no tip).
        #   # . # . # .   tops
        #   # # # # # #
        #   . # # # . .   base of the tops
        #   # # # # # # #  body (red), wide
        #   # # # # # # #
        #   # # # # # # #
        #   . # # # # .
        #   . # # # # .
        LEAVES = [
          [1, 7],         [3, 7],         [5, 7],
          [1, 6], [2, 6], [3, 6], [4, 6], [5, 6],
                  [2, 5], [3, 5], [4, 5],
        ].freeze
        CARROT = [
          [1, 4], [2, 4], [3, 4], [4, 4], [5, 4], [6, 4],
          [1, 3], [2, 3], [3, 3], [4, 3], [5, 3], [6, 3],
          [1, 2], [2, 2], [3, 2], [4, 2], [5, 2], [6, 2],
                  [2, 1], [3, 1], [4, 1], [5, 1],
                  [2, 0], [3, 0], [4, 0], [5, 0],
        ].freeze

        def render(t, panel)
          panel.clear
          w   = Math.sin(2 * Math::PI * FREQ * t).round   # -1..1 (peekaboo)
          bob = Math.sin(2 * Math::PI * FREQ * t).round   # -1..1 (carrot bounce)
          draw_bunny(panel, :front, w)    # 1 : bunny
          draw_bunny(panel, :back,  w)    # 3 : bunny
          draw_carrot(panel, :right, bob) # 2 : carrot
          draw_carrot(panel, :left,  bob) # 4 : carrot
          draw_top_ring(panel, t)         # 5 : turning yellow ring
        end

        private

        # Top: outer 2 px ring, yellow arcs that turn.
        def draw_top_ring(panel, t)
          rot = t * SPIN
          SIDE.times do |x|
            SIDE.times do |y|
              next unless [x, y, SIDE - 1 - x, SIDE - 1 - y].min <= 1  # 2 outer rings
              u   = Math.atan2(y - 3.5, x - 3.5) / (2 * Math::PI) + 0.5 # 0..1 (angle)
              seg = ((u + rot) * SEGMENTS).floor
              px(panel, :top, x, y, COLOR) if seg.even?   # yellow arcs (holes otherwise)
            end
          end
        end

        def draw_bunny(panel, face, w)
          HEAD.each { |x, y| px(panel, face, x,     y, COLOR) }
          PAW.each  { |x, y| px(panel, face, x + w, y, COLOR) }
        end

        def draw_carrot(panel, face, bob)
          LEAVES.each { |x, y| px(panel, face, x, y + bob, LEAF) }
          CARROT.each { |x, y| px(panel, face, x, y + bob, BODY_C) }
        end
      end
    end
  end
end
