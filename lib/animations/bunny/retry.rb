# frozen_string_literal: true

require_relative "_base"

module Claudine
  module Animations
    module Bunny
      # retry (recoverable tool error): the bunny shakes with anger on the 4
      # lateral faces, in red -- kept SHORT, since a recoverable error is minor.
      # The `fail` intention reuses this shake but sustains it much longer
      # (rarer, graver -- see fail.rb).
      # Signature: bunny shaking red, brief blip.
      class Retry < BunnyBase
        MIN_DURATION = 0.5
        COLOR = [255, 0, 0].freeze # red (error)
        SHAKE = 1.0 # amplitude of the shaking (px)
        FREQ = 5.0 # frequency of the shaking (Hz) -- anger
        BLINK = 0.2 # half-period of the X blinking (s)

        # Top: big thick X (2 px) -- the 2 widened diagonals.
        X_TOP = (0..7).to_a.product((0..7).to_a)
          .select { |x, y| (x - y).abs <= 1 || (x + y - 7).abs <= 1 }
          .freeze

        # Classic bunny head (dx, dy ; 0 = bottom). 2 px ears, head,
        # eyes, simple body. Occupies columns 1..6, leaving 0 and 7 for the
        # shaking.
        #   . # # . . # # .   ears (2 px)
        #   . # # . . # # .
        #   . # # # # # # .   head
        #   . # . # # . # .   eyes (gaps at 2,5)
        #   . # # # # # # .
        #   . . # # # # . .   body
        #   . . . . . . . .
        #   . . . # # . . .   paws
        BODY = [
          [1, 7], [2, 7],                         [5, 7], [6, 7],
          [1, 6], [2, 6],                         [5, 6], [6, 6],
          [1, 5], [2, 5], [3, 5], [4, 5], [5, 5], [6, 5],
          [1, 4],         [3, 4], [4, 4],         [6, 4],
          [1, 3], [2, 3], [3, 3], [4, 3], [5, 3], [6, 3],
                  [2, 2], [3, 2], [4, 2], [5, 2],
                          [3, 0], [4, 0],
        ].freeze

        FACES = %i[front right back left].freeze

        def render(t, panel)
          panel.clear
          shake = SHAKE * Math.sin(2 * Math::PI * FREQ * t)
          FACES.each do |face|
            BODY.each { |dx, dy| px(panel, face, dx + shake, dy, COLOR) }
          end
          # Top: big red X that blinks.
          X_TOP.each { |x, y| px(panel, :top, x, y, COLOR) } if (t / BLINK).floor.even?
        end
      end
    end
  end
end
