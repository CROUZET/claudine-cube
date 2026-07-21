require_relative '_base'

module Claudine
  module Animations
    module Bunny
      # Subagent start: a small bunny springs up from the bottom (spring effect)
      # on each of the 4 lateral faces, then the 4 bunnies go around the cube
      # jumping to the right, each to the next one's spot, 4 times (full
      # turn). Light blue (start event -> light color). Overlay.
      # Signature: the bunnies spring up then turn around the cube jumping.
      class Fork < BunnyBase
        COLOR  = [120, 200, 255]   # light blue (start)
        POP    = 0.45              # duration of the spring-up (s)
        JUMPS  = 4                 # number of jumps (full turn)
        JUMP_T = 1.0               # duration of one jump (s)
        HOP_H  = 3.0               # height of one jump (px)
        BASE_X = 2                 # position of the bunny in its face (centered, 4 px)
        MIN_DURATION = POP + JUMPS * JUMP_T
        DURATION     = MIN_DURATION

        # Small bunny (dx, dy; 0 = paws).
        #   # . . #   ears
        #   # . . #
        #   # # # #   body
        #   # # # #
        #   # # # #
        BODY = [
          [0, 4],                 [3, 4],
          [0, 3],                 [3, 3],
          [0, 2], [1, 2], [2, 2], [3, 2],
          [0, 1], [1, 1], [2, 1], [3, 1],
          [0, 0], [1, 0], [2, 0], [3, 0],
        ].freeze

        def render(t, panel)
          panel.clear
          4.times do |i|
            base = i * SIDE + BASE_X          # starting column of bunny i
            col, by = pose(t, base)
            BODY.each { |dx, dy| plot(panel, col + dx, by + dy, self.class::COLOR) }
          end
        end

        private

        # Returns [column, vertical_offset] of the bunny at time t.
        def pose(t, base)
          if t < POP                          # vertical spring-up, in place
            off = (-5 * (1.0 - ease_out_back(t / POP))).round
            [base, off]
          else
            total = (t - POP) / JUMP_T         # progress in "jumps" (0..JUMPS)
            if total >= JUMPS
              [base + JUMPS * SIDE, 0]         # landed (= home, modulo the ring)
            else
              p = total - total.floor          # phase of the current jump
              [base + total * SIDE, Math.sin(Math::PI * p) * HOP_H]
            end
          end
        end

        # Ease-out "back": overshoots 1 then comes back (spring effect visible ~1 px).
        def ease_out_back(p)
          c1 = 3.2
          c3 = c1 + 1
          1 + c3 * (p - 1)**3 + c1 * (p - 1)**2
        end

        # Pixel on the ring; overflows onto the top if y >= 8 (cf. user_prompt).
        def plot(panel, col, yy, rgb)
          yi = yy.to_i
          if yi <= 7
            ring_px(panel, col, yy, rgb)
          else
            c    = col.to_i % RING
            face = LATERAL[c / SIDE]
            lx   = c % SIDE
            tx, ty = top_edge_px(face, lx, yi - 8)
            px(panel, :top, tx, ty, rgb) if tx
          end
        end
      end
    end
  end
end
