# frozen_string_literal: true

require_relative "_base"
require_relative "think"

module Claudine
  module Animations
    module Bunny
      # End of turn (success): the bunnies run around the cube (like
      # user_prompt) then stop and turn to face front (a front bunny
      # centered on each lateral face), before fading out. Yellow
      # (end event -> yellow).
      # Signature: the running stops, the bunnies look, then fade away.
      class Stop < BunnyBase
        COLOR   = [255, 200, 0].freeze # yellow (end)
        SPEED   = 16.0 # columns/second (running)
        HOP_LEN = Think::HOP_LEN # same jump as user_prompt
        HOP_H   = [3.0, 5.0, 4.0].freeze # varied jump heights
        NB      = HOP_H.size
        RUN     = Think::RABBIT # running sprite (profile) from user_prompt

        T_RUN  = 2.0                       # duration of the running
        T_FADE = 2.0                       # duration of the fade (after the stop)
        DUR    = T_RUN + T_FADE
        MIN_DURATION = DUR
        DURATION     = DUR                 # full duration (read by the preview)

        # Small front bunny (whole body), 4 px wide; centered via FRONT_X.
        #   # . . #   ears
        #   # . . #
        #   # # # #   body
        #   # # # #
        #   # # # #
        FRONT = [
          [0, 4],                 [3, 4],
          [0, 3],                 [3, 3],
          [0, 2], [1, 2], [2, 2], [3, 2],
          [0, 1], [1, 1], [2, 1], [3, 1],
          [0, 0], [1, 0], [2, 0], [3, 0],
        ].freeze
        FRONT_X = 2 # centers the sprite (4 px) on the face
        FRONT_FACES = %i[front right back left].freeze

        def render(t, panel)
          panel.clear
          if t < T_RUN
            draw_run(panel, t)
          else
            fade = 1.0 - ((t - T_RUN) / T_FADE)
            return if fade <= 0.0

            c = dim(COLOR, fade)
            FRONT_FACES.each { |face| FRONT.each { |x, y| px(panel, face, FRONT_X + x, y, c) } }
          end
        end

        private

        # Running: bunnies jumping around the ring (like user_prompt).
        def draw_run(panel, t)
          head = t * SPEED
          NB.times do |i|
            col    = head + (i * (RING.to_f / NB))
            hop    = Math.sin(Math::PI * ((col % HOP_LEN) / HOP_LEN))
            base_y = hop * HOP_H[i]
            RUN.each { |dx, dy| plot(panel, col + dx, base_y + dy, COLOR) }
          end
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
