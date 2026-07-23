# frozen_string_literal: true

require_relative "_base"

module Claudine
  module Animations
    module Bunny
      # After a tool: a bunny on each of the 4 lateral faces does a
      # little dance (left/right hip sway), and the top reuses the 8 blinking
      # corner pixels of pre_tool. All of it fades out from start to
      # finish. Yellow (end event -> yellow). Short overlay.
      # Signature: bunnies dancing, top corners blinking, then everything
      # fades out.
      class Finish < BunnyBase
        COLOR = [255, 200, 0].freeze # yellow (end)
        DUR = 1.6               # duration of the dance + fade
        MIN_DURATION = DUR
        SWAYS = 3                 # number of hip sways during the dance
        BASE_X = 2                 # left edge of the sprite (centered, 4 px wide)
        SHEAR = 1.0               # amplitude of the lean (px at the top of the sprite)
        SQUASH = 0                 # max vertical squash (slight)
        BLINK = 0.25              # half-period of the top blinking (s)

        # Phase offset of the dance per lateral face (staggered dances).
        FACE_PHASE = { front: 0.0, right: 0.2, back: 0.4, left: 0.6 }.freeze

        # Top: 8 corner pixels that blink (same as in pre_tool).
        TOP_DOTS = [
          [1, 1], [2, 2], [5, 5], [6, 6],   # main diagonal
          [6, 1], [5, 2], [2, 5], [1, 6],   # anti-diagonal
        ].freeze

        # Bunny sprite (dx, dy ; 0 = paws).
        #   # . . #
        #   # . . #
        #   # # # #
        #   # . # #
        #   # # # #
        BODY = [
          [0, 4],                 [3, 4],   # ears
          [0, 3],                 [3, 3],
          [0, 2], [1, 2], [2, 2], [3, 2],   # head
          [0, 1],         [2, 1], [3, 1],   # body (folded paw)
          [0, 0], [1, 0], [2, 0], [3, 0],   # body / paws
        ].freeze

        def render(t, panel)
          panel.clear
          p = [t / DUR, 1.0].min
          fade = 1.0 - p # progressive fade all along
          return if fade <= 0.0

          FACE_PHASE.each do |face, off|
            lean = -Math.sin(2 * Math::PI * ((SWAYS * p) + off))
            draw(panel, face, lean, fade)
          end
          # Top: 8 corner pixels that blink in rhythm, fading out.
          return unless (t / BLINK).floor.even?

          c = dim(COLOR, fade)
          TOP_DOTS.each { |x, y| px(panel, :top, x, y, c) }
        end

        private

        def draw(panel, face, lean, fade)
          sy = 1.0 - (SQUASH * lean.abs) # vertical squash when leaning
          color = dim(COLOR, fade)
          BODY.each do |dx, dy|
            x = BASE_X + dx + (lean * SHEAR * (dy / 4.0))
            y = dy * sy
            px(panel, face, x, y, color)
          end
        end
      end
    end
  end
end
