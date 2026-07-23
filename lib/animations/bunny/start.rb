# frozen_string_literal: true

require_relative "_base"

module Claudine
  module Animations
    module Bunny
      # Before a tool: a bunny plays on the 4 lateral faces. Front (1): it
      # crosses by jumping (left -> right -> left) then dances in place
      # (slight leaning squash left / center / right / center). Back (3):
      # same, mirrored (symmetry). Right (2) + left (4): the same animation
      # reversed in time (dance then jumps), 4 mirroring 2.
      # Bluish white (start event -> light color). Short overlay.
      # Signature: bunnies jumping then dancing all around the facade.
      class Start < BunnyBase
        COLOR = [210, 232, 255].freeze # bluish white (start)
        T1 = 0.60 # end of the left -> right jump
        T2 = 1.20 # end of the right -> left jump
        DUR = 2.30 # end of the dance
        MIN_DURATION = DUR
        HOP_H = 3.0 # height of the jumps (px)
        CENTER_X = 2.0 # left edge of the sprite when centered
        SHEAR = 2.0 # amplitude of the lean (px at the top of the sprite)
        SQUASH = 0.15 # max vertical squash during the dance (slight)
        BLINK = 0.25 # half-period of the top blinking (s)

        # Top: 8 pixels (row x column -> x,y), 2 along the diagonal of
        # each corner, that blink in rhythm.
        TOP_DOTS = [
          [1, 1], [2, 2], [5, 5], [6, 6],   # main diagonal
          [6, 1], [5, 2], [2, 5], [1, 6],   # anti-diagonal
        ].freeze

        # Bunny sprite (dx, dy ; 0 = paws). Shape provided by the user.
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
          draw_on(panel, :front, t,       false)   # 1 : jumps -> dance
          draw_on(panel, :back,  t,       true)    # 3 : mirror symmetry
          draw_on(panel, :right, DUR - t, false)   # 2 : reversed (dance -> jumps)
          draw_on(panel, :left,  DUR - t, true)    # 4 : reversed + mirror
          # Top: 8 corner pixels that blink in rhythm.
          TOP_DOTS.each { |x, y| px(panel, :top, x, y, COLOR) } if (t / BLINK).floor.even?
        end

        private

        # Draws the bunny on a face at time tt (optional horizontal mirror).
        def draw_on(panel, face, tt, mirror)
          bx, by, lean = pose(tt.clamp(0.0, DUR))
          sy = 1.0 - (SQUASH * lean.abs) # vertical squash when leaning
          BODY.each do |dx, dy|
            x = bx + dx + (lean * SHEAR * (dy / 4.0)) # lean: the top shifts more
            y = by + (dy * sy)
            x = 7 - x if mirror
            px(panel, face, x, y, COLOR)
          end
        end

        # Returns [base_x, base_y, lean] at time t.
        #  - t < T1 : left -> right jump (2 arcs)
        #  - t < T2 : right -> left jump (2 arcs)
        #  - otherwise : centered dance, lean -1 (left) ... +1 (right)
        def pose(t)
          if t < T1
            p = t / T1
            [4.0 * p, HOP_H * Math.sin(Math::PI * 2 * p).abs, 0.0]
          elsif t < T2
            p = (t - T1) / (T2 - T1)
            [4.0 * (1 - p), HOP_H * Math.sin(Math::PI * 2 * p).abs, 0.0]
          else
            p = [(t - T2) / (DUR - T2), 1.0].min
            [CENTER_X, 0.0, -Math.sin(2 * Math::PI * p)]
          end
        end
      end
    end
  end
end
