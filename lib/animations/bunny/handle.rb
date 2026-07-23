# frozen_string_literal: true

require_relative "_base"

module Claudine
  module Animations
    module Bunny
      # New task: a close-up bunny (in profile) walks calmly
      # around the cube, along the ring of the 4 lateral faces, with a
      # paw cycle. Crosses the edges seamlessly (ring_px). Light blue (start
      # event -> light color). Overlay.
      # Signature: a big bunny walking around the cube at a steady pace.
      class Handle < BunnyBase
        MIN_DURATION = 3.6
        DURATION = 4.5 # full duration (read by the preview)
        COLOR = [120, 200, 255].freeze # light blue (start)
        SPEED = 7.0               # columns/second (calm walk)
        STEP = 4                 # columns per step (paw alternation)

        # Profile bunny, turned toward the walk (increasing dx = front). dy=0=bottom.
        # Eye = hollow at (5,4). Close-up (7 px wide, 7 tall).
        #   . . . # # . .   ear
        #   . . . . # # .
        #   . . # # # . #   head (hollow eye) + back
        #   . # # # # # #   body
        #   # # # # # # .
        #   . # # # # # .
        BODY = [
                          [3, 6], [4, 6],
                                  [4, 5], [5, 5],
                  [2, 4], [3, 4], [4, 4],         [6, 4],
          [1, 3], [2, 3], [3, 3], [4, 3], [5, 3], [6, 3],
          [0, 2], [1, 2], [2, 2], [3, 2], [4, 2], [5, 2],
                  [1, 1], [2, 1], [3, 1], [4, 1], [5, 1],
        ].freeze
        LEGS_A = [[1, 0], [4, 0]].freeze   # step 1
        LEGS_B = [[2, 0], [5, 0]].freeze   # step 2 (alternation)

        def render(t, panel)
          panel.clear
          col = t * SPEED
          legs = (col / STEP).floor.even? ? LEGS_A : LEGS_B
          (BODY + legs).each { |dx, dy| ring_px(panel, col + dx, dy, COLOR) }
        end
      end
    end
  end
end
