# frozen_string_literal: true

require_relative "_base"

module Claudine
  module Animations
    module Cube
      # Before a tool: a yellow snake 2 px wide crosses the cube.
      # Path (face numbering: 1 front, 2 right, 3 back, 4 left,
      # 5 top): starts from the bottom-middle of the front, rises, passes over
      # the top, descends on the back down to the middle, turns right to reach
      # the right face, crosses it to its middle, turns right again and rises
      # back up, passes over the top again, arrives on the left and goes out
      # there.
      # Signature: a single bright snake that "navigates" through the volume.
      class Start < CubeBase
        BODY  = 18             # length of the snake (in 2 px "rungs")
        SPEED = 30.0           # rungs per second
        HEAD  = [190, 80, 0].freeze   # orange/amber (head)
        TAIL  = [28, 8, 0].freeze     # very dark amber (tail)

        # Track: ordered list of "rungs", each rung = the 2 pixels (width of
        # the snake) lit at one step of the path. Two consecutive rungs are
        # adjacent on the cube (edge crossings validated by the geometry of
        # CubeMapping).
        def self.build_track
          t = []
          add = ->(face, a, b) { t << [[face, a[0], a[1]], [face, b[0], b[1]]] }

          # Path shifted 1 px to the left (columns 2,3 instead of the center
          # 3,4); the turns happen 1 px past the middle (rows/columns 2,3). The
          # "mirror" columns (4,5) on back/left follow from the continuity of
          # the top<->faces edges (see CubeMapping).
          # 1. Front: bottom -> top (columns 2,3, shifted left).
          (0..7).each { |y| add.call(:front, [2, y], [3, y]) }
          # 2. Top: near -> far.
          (0..7).each { |y| add.call(:top, [2, y], [3, y]) }
          # 3. Back: top -> 1 px below the middle (columns 4,5 by continuity).
          [7, 6, 5, 4, 3].each { |y| add.call(:back, [4, y], [5, y]) }
          # 4. Back: turn, toward the right face (rows 2,3).
          [4, 3, 2, 1, 0].each { |x| add.call(:back, [x, 2], [x, 3]) }
          # 5. Right: back edge -> 1 px before the middle (rows 2,3).
          [7, 6, 5, 4, 3].each { |x| add.call(:right, [x, 2], [x, 3]) }
          # 6. Right: turn, rises back up (columns 2,3).
          [3, 4, 5, 6, 7].each { |y| add.call(:right, [2, y], [3, y]) }
          # 7. Top: right -> left (rows 2,3).
          7.downto(0).each { |x| add.call(:top, [x, 2], [x, 3]) }
          # 8. Left: top -> bottom, then disappears (columns 4,5 by continuity).
          7.downto(0).each { |y| add.call(:left, [4, y], [5, y]) }

          t
        end

        TRACK        = build_track
        MIN_DURATION = (TRACK.size + BODY) / SPEED   # plays the whole path
        DURATION     = MIN_DURATION                  # lifetime (read by the preview)

        def render(t, panel)
          panel.clear
          head = t * SPEED
          BODY.times do |i|
            pos = (head - i).floor
            next if pos.negative? || pos >= TRACK.size

            f   = BODY == 1 ? 0.0 : i.to_f / (BODY - 1) # 0 head ... 1 tail
            rgb = mix(HEAD, TAIL, f)
            TRACK[pos].each { |(face, x, y)| px(panel, face, x, y, rgb) }
          end
        end

        private

        # Linear interpolation between two colors (f: 0 -> a, 1 -> b).
        def mix(a, b, f)
          a.zip(b).map { |ca, cb| (ca + ((cb - ca) * f)).round.clamp(0, 255) }
        end
      end
    end
  end
end
