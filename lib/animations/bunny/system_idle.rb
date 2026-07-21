require_relative '_base'

module Claudine
  module Animations
    module Bunny
      # Idle (no event since IDLE_TIMEOUT): on the 4 lateral faces, a
      # bunny in "loaf" form (loaf, ears folded) sleeps breathing gently,
      # with little bubbles that rise in zigzag and fade away above.
      # After HOLD, everything fades out; the manager cuts the cube at DURATION.
      # Signature: sleeping bunnies breathing, with sleep bubbles.
      class SystemIdle < BunnyBase
        PERIOD   = 2.6                  # breathing period (s)
        HOLD     = 4.0                  # visible sleep before the fade
        FADE     = 2.0                  # extinction
        DURATION = HOLD + FADE          # lifetime (read by the manager)
        COLOR    = [80, 150, 220]       # soft blue (idle)
        FACES    = %i[front right back left].freeze

        # Sleep bubbles: little dots that rise in zigzag and fade away.
        NB_BUB = 3                      # number of staggered bubbles
        RISE   = 3.9                    # rise duration of one bubble (s)
        AMP    = 1.0                    # amplitude of the zigzag (px)
        ZIG    = 2.0                    # number of oscillations during the rise
        BUB_X  = 6                      # center column of the bubbles (right side)

        # "Loaf" bunny (dx, dy; 0 = bottom): oval shape, ears folded.
        #   . . # . . # . .   folded ears
        #   . # # # # # # .
        #   # # # # # # # #   body
        #   # # # # # # # #
        #   . # # # # # # .
        LOAF = [
                  [2, 4],                         [5, 4],
          [1, 3], [2, 3], [3, 3], [4, 3], [5, 3], [6, 3],
          [0, 2], [1, 2], [2, 2], [3, 2], [4, 2], [5, 2], [6, 2], [7, 2],
          [0, 1], [1, 1], [2, 1], [3, 1], [4, 1], [5, 1], [6, 1], [7, 1],
                  [1, 0], [2, 0], [3, 0], [4, 0], [5, 0], [6, 0],
        ].freeze

        def render(t, panel)
          panel.clear
          env    = t < HOLD ? 1.0 : (1.0 - (t - HOLD) / FADE).clamp(0.0, 1.0)
          return if env <= 0.0
          breath = 0.35 + 0.35 * wave(t, PERIOD)     # breathing 0.35..0.70
          loaf_c = dim(COLOR, breath * env)

          FACES.each do |face|
            LOAF.each { |x, y| px(panel, face, x, y, loaf_c) }
            NB_BUB.times do |i|
              ph = ((t / RISE) + i.to_f / NB_BUB) % 1.0        # 0..1: the bubble rises
              bx = BUB_X + (AMP * Math.sin(ph * ZIG * 2 * Math::PI)).round  # zigzag
              by = (5 + ph * 5).round                          # y from 5 to 10 (overflows onto the top)
              bubble(panel, face, bx, by, dim(COLOR, (1.0 - ph) * env))     # fades away
            end
          end
        end

        private

        # Bubble: on the lateral face; beyond the top (y >= 8), moves onto the
        # perimeter of the top along the edge (top_edge_px).
        def bubble(panel, face, x, y, color)
          if y <= 7
            px(panel, face, x, y, color)
          else
            tx, ty = top_edge_px(face, x.clamp(0, 7), y - 8)
            px(panel, :top, tx, ty, color) if tx
          end
        end
      end
    end
  end
end
