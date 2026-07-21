require_relative '_base'

module Claudine
  module Animations
    module Bunny
      # Wake-up: bunnies appear on 4 faces, colored by the WARM rainbow
      # of the cube session_start (hue based on the cube diagonal d=X+Y+Z).
      #  - front (1) + back (3): model A (straight ears), in mirror
      #    symmetry; the ears rise then a wink (left eye).
      #  - right (2) + left (4): model B (spread ears), in symmetry.
      # (The top stays empty for now.)
      # Signature: bunnies waking up all around the facade.
      class Welcome < BunnyBase
        RISE     = 0.7            # appearance + ears rising (s)
        TOP_FILL = 2.0            # filling of the loader on the top (s)
        MIN_DURATION = 1.4
        DURATION     = 4.0        # duration shown by the preview (see 2 blinks)

        # Warm palette, identical to the cube session_start: hue along the
        # diagonal d=0..DMAX (orange-yellow -> red -> magenta).
        DMAX = 21
        HUE0 = 0.15
        HUE1 = -0.18

        BLINK_PERIOD = 2.6        # time between two blinks (s)
        BLINK_DUR    = 0.14       # duration of closed eyelid (s)
        BLINK_OFFSET = 1.3        # sets the 1st blink shortly after wake-up

        # --- Model A: front bunny, straight ears, full width. ---
        # Body + head (without ears). Eyes (x=2,5 at y=3) left off.
        A_BODY = [
          [0, 4], [1, 4], [2, 4], [3, 4], [4, 4], [5, 4], [6, 4], [7, 4],
          [0, 3], [1, 3],         [3, 3], [4, 3],         [6, 3], [7, 3],
          [0, 2], [1, 2], [2, 2], [3, 2], [4, 2], [5, 2], [6, 2], [7, 2],
                  [1, 1], [2, 1], [3, 1], [4, 1], [5, 1], [6, 1],
                          [2, 0], [3, 0], [4, 0], [5, 0],
        ].freeze
        A_EARS = [1, 2, 5, 6].freeze  # straight ears (rise from y=5 to y=7)
        A_WINK = [2, 3].freeze        # winking eye (left)

        # --- Model B: bunny with spread ears (in a V). ---
        B_BODY = [
          [0, 7],                                                 [7, 7],
          [0, 6], [1, 6],                                 [6, 6], [7, 6],
                  [1, 5], [2, 5],                 [5, 5], [6, 5],
                  [1, 4], [2, 4], [3, 4], [4, 4], [5, 4], [6, 4],
                  [1, 3],         [3, 3], [4, 3],         [6, 3],
                  [1, 2], [2, 2], [3, 2], [4, 2], [5, 2], [6, 2],
                          [2, 1], [3, 1], [4, 1], [5, 1],
                          [2, 0], [3, 0], [4, 0], [5, 0],
        ].freeze

        # --- Top: loader path on the 2 outer rings. ---
        # A square ring d traversed clockwise (closed loop).
        def self.ring_path(d)
          lo = d
          hi = 7 - d
          path = []
          (lo..hi).each        { |x| path << [x, lo] }   # bottom: left -> right
          ((lo + 1)..hi).each  { |y| path << [hi, y] }   # right: bottom -> top
          (hi - 1).downto(lo).each     { |x| path << [x, hi] }  # top: right -> left
          (hi - 1).downto(lo + 1).each { |y| path << [lo, y] }  # left: top -> bottom
          path
        end

        # Spiral: outer loop (d=0) then inner loop (d=1).
        TOP_PATH = (ring_path(0) + ring_path(1)).freeze

        def render(t, panel)
          panel.clear
          k       = [t / RISE, 1.0].min      # appearance fade 0 -> 1
          ear_top = 4 + (k * 3).round
          wink    = t >= RISE && blinking?(t)

          # Model A: front (1) + back (3), mirror symmetry.
          draw_a(panel, :front, k, ear_top, wink, false)
          draw_a(panel, :back,  k, ear_top, wink, true)
          # Model B: right (2) + left (4), mirror symmetry.
          blit(panel, :right, B_BODY, k, false)
          blit(panel, :left,  B_BODY, k, true)
          # Top: cumulative loader around the perimeter (2 outer rings).
          draw_top_loader(panel, t)
        end

        private

        def blinking?(t)
          ((t + BLINK_OFFSET) % BLINK_PERIOD) < BLINK_DUR
        end

        # Draws model A (body + rising ears + possible wink).
        def draw_a(panel, face, k, ear_top, wink, mirror)
          blit(panel, face, A_BODY, k, mirror)
          A_EARS.each { |x| (5..ear_top).each { |y| put(panel, face, x, y, k, mirror) } }
          put(panel, face, A_WINK[0], A_WINK[1], k, mirror) if wink
        end

        # Draws a list of pixels on a face, horizontally mirrored if requested.
        def blit(panel, face, pixels, k, mirror)
          pixels.each { |x, y| put(panel, face, x, y, k, mirror) }
        end

        # Lights a pixel with the warm hue corresponding to its 3D position,
        # dimmed by k (fade). The mirror applies to the column.
        def put(panel, face, x, y, k, mirror)
          dx = mirror ? 7 - x : x
          px(panel, face, dx, y, warm(face, dx, y, k))
        end

        # Loader: cumulatively fills the top path up to the head,
        # which advances over TOP_FILL seconds (then stays full).
        def draw_top_loader(panel, t)
          path = top_path
          n    = ((t / TOP_FILL).clamp(0.0, 1.0) * path.size).floor
          path.first(n).each { |x, y| px(panel, :top, x, y, warm(:top, x, y, 1.0)) }
        end

        # Loader traversal order (overridden by Bye to reverse it).
        def top_path
          TOP_PATH
        end

        # Hue based on 3D position and the palette (HUE0..HUE1 of the class),
        # dimmed by k. Warm by default; cold for Bye.
        def warm(face, x, y, k)
          wx, wy, wz = world(face, x, y)
          d   = wx + wy + wz
          hue = (self.class::HUE0 + (d.to_f / DMAX) * (self.class::HUE1 - self.class::HUE0)) % 1.0
          dim(hsv(hue), k)
        end

        # World coordinates (X left->right, Y front->back, Z bottom->top).
        def world(face, x, y)
          case face
          when :front then [x,     0,     y]
          when :right then [7,     x,     y]
          when :back  then [7 - x, 7,     y]
          when :left  then [0,     7 - x, y]
          when :top   then [x,     y,     7]
          end
        end

        # HSV (h 0..1, s=v=1) -> [r, g, b] full (0..255).
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
