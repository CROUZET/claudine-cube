require_relative '_base'

module Claudine
  module Animations
    module Cube
      # The cube wakes up: a rainbow of warm colors sweeps the whole
      # volume diagonally (bottom-front-left corner -> top-back-right corner),
      # reaches full, then ebbs back and turns off from the opposite corner. A
      # wave rising then descending, across the 5 faces.
      #
      # Signature (colorblind-safe): the diagonal wave that envelops then empties
      # the whole volume is unique; the warm palette (yellow->red->magenta)
      # distinguishes it from session_end (cool) -- movement AND temperature, not
      # hue alone.
      class SessionStart < CubeBase
        UP           = 2.4          # fill duration (s)
        DOWN         = 2.0          # ebb duration (s)
        MIN_DURATION = UP + DOWN    # hold the lock for the whole wave
        DURATION     = UP + DOWN    # full lifetime (read by the preview)
        DMAX         = 21           # d max = (7 + 7 + 7), opposite corner
        EDGE         = 3.5          # thickness of the light front (in units of d)
        SPAN         = DMAX + 2 * EDGE

        # Hue range (h 0..1) spread along the diagonal d=0..DMAX.
        # Warm: yellow-orange (0.15) -> red (0.0) -> magenta (-0.18 == 0.82).
        # The SessionEnd subclass overrides these bounds for a cool palette.
        HUE0 = 0.15
        HUE1 = -0.18

        def render(t, panel)
          panel.clear
          front = front_at(t)

          ALL_FACES.each do |face|
            SIDE.times do |x|
              SIDE.times do |y|
                wx, wy, wz = world(face, x, y)
                d = wx + wy + wz

                # Brightness: full behind the front, fade over EDGE at the front.
                b = ((front - d) / EDGE).clamp(0.0, 1.0)
                next if b <= 0.0

                hue = (self.class::HUE0 + (d.to_f / DMAX) * (self.class::HUE1 - self.class::HUE0)) % 1.0
                px(panel, face, x, y, dim(hsv(hue), b))
              end
            end
          end
        end

        private

        # Front position: rises from -EDGE to DMAX+EDGE over UP (fill),
        # then descends back down to -EDGE over DOWN (ebb, opposite corner first).
        def front_at(t)
          if t <= UP
            -EDGE + (t / UP).clamp(0.0, 1.0) * SPAN
          else
            (DMAX + EDGE) - ((t - UP) / DOWN).clamp(0.0, 1.0) * SPAN
          end
        end

        # World coordinates (X left->right, Y front->back, Z bottom->top),
        # 0..7 on each axis, from (face, x=col, y=row).
        def world(face, x, y)
          case face
          when :front then [x,     0,     y]
          when :right then [7,     x,     y]
          when :back  then [7 - x, 7,     y]
          when :left  then [0,     7 - x, y]
          when :top   then [x,     y,     7]
          end
        end

        # HSV (h 0..1, s=v=1) -> [r, g, b] full (0..255). Saturated rainbow.
        def hsv(h)
          i = (h * 6.0).floor
          f = h * 6.0 - i
          q = 1.0 - f
          r, g, b = case i % 6
                    when 0 then [1.0, f,   0.0]
                    when 1 then [q,   1.0, 0.0]
                    when 2 then [0.0, 1.0, f]
                    when 3 then [0.0, q,   1.0]
                    when 4 then [f,   0.0, 1.0]
                    else        [1.0, 0.0, q]
                    end
          [(r * 255).round, (g * 255).round, (b * 255).round]
        end
      end
    end
  end
end
