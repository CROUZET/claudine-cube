require_relative 'session_start'

module Claudine
  module Animations
    module Bunny
      # End of session: the bunnies fall asleep. They start lit up (ears
      # up) then the ears lower, the eyes close, and the whole
      # cube (bunnies + top frame) fades out progressively from start to
      # finish. COLD rainbow. "Sleep" mirror of the wake-up (session_start).
      class SessionEnd < SessionStart
        HUE0 = 0.25               # cold: yellow-green -> ... -> violet
        HUE1 = 0.85
        DUR  = 2.6                # complete falling asleep (fade to black)
        SINK = 0.8                # lowering of the ears (s)
        MIN_DURATION = DUR
        DURATION     = DUR        # duration shown by the preview

        EYES = [[2, 3], [5, 3]].freeze   # eye gaps (same positions A and B)

        def render(t, panel)
          panel.clear
          fade = [1.0 - t / DUR, 0.0].max        # progressive fade all along
          return if fade <= 0.0                  # asleep: cube off
          ear_top = 7 - ([t / SINK, 1.0].min * 3).round   # ears 7 -> 4
          asleep  = t >= SINK                    # eyes closed once dozed off

          # Model A: front + back (mirror). No wink (it's sleeping).
          draw_a(panel, :front, fade, ear_top, false, false)
          draw_a(panel, :back,  fade, ear_top, false, true)
          # Model B: right + left (mirror).
          blit(panel, :right, B_BODY, fade, false)
          blit(panel, :left,  B_BODY, fade, true)
          # Closed eyes (gaps filled) on the 4 bunnies once asleep.
          close_eyes(panel, fade) if asleep
          # Top: the full frame fades out with the rest.
          TOP_PATH.each { |x, y| px(panel, :top, x, y, warm(:top, x, y, fade)) }
        end

        private

        def close_eyes(panel, fade)
          %i[front back right left].each do |face|
            EYES.each { |x, y| px(panel, face, x, y, warm(face, x, y, fade)) }
          end
        end
      end
    end
  end
end
