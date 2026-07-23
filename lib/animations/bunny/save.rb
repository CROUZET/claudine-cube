# frozen_string_literal: true

require_relative "_base"
require_relative "think"

module Claudine
  module Animations
    module Bunny
      # Before compaction: a bunny head on each of the 4 lateral faces
      # rises, passes onto the top, converges toward the center and the 4 merge
      # into a new bunny (hatching). Light blue (start event -> light).
      # Signature: 4 heads rising and merging into one bunny on the top.
      class Save < BunnyBase
        T1 = 0.6 # rise on the lateral faces
        T2 = 1.5 # convergence on the top
        DUR = 2.3 # hatching of the merged bunny
        MIN_DURATION = DUR
        DURATION = DUR
        COLOR = [120, 200, 255].freeze # light blue (start)

        # Bunny head (4x5, dx/dy ; 0 = bottom).
        #   # . . #   ears
        #   # . . #
        #   # # # #   head
        #   # # # #
        #   # # # #
        HEAD = [
          [0, 4],                 [3, 4],
          [0, 3],                 [3, 3],
          [0, 2], [1, 2], [2, 2], [3, 2],
          [0, 1], [1, 1], [2, 1], [3, 1],
          [0, 0], [1, 0], [2, 0], [3, 0],
        ].freeze

        # Entry positions on the top (sprite origin), per edge.
        EDGES = [[2, 0], [4, 3], [2, 3], [0, 3]].freeze # front, right, back, left
        CENTER = [2, 2].freeze # merge point

        # Merged bunny = the nice bunny (profile) from user_prompt, centered.
        NEW = Think::RABBIT
        NEW_X = 2 # offset to center (5 px wide)
        NEW_Y = 1

        def render(t, panel)
          panel.clear
          if t < T1 # rise on the 4 faces
            yb = (3 * (t / T1)).round
            LATERAL.each do |face|
              HEAD.each { |dx, dy| px(panel, face, 2 + dx, yb + dy, COLOR) }
            end
          elsif t < T2 # convergence on the top
            cp = (t - T1) / (T2 - T1)
            EDGES.each do |sx, sy|
              ox = (sx + (cp * (CENTER[0] - sx))).round
              oy = (sy + (cp * (CENTER[1] - sy))).round
              HEAD.each { |dx, dy| px(panel, :top, ox + dx, oy + dy, COLOR) }
            end
          else # hatching of the merged bunny
            a = 1.0 - ((1.0 - [(t - T2) / (DUR - T2), 1.0].min)**2)
            NEW.each { |dx, dy| px(panel, :top, NEW_X + dx, NEW_Y + dy, dim(COLOR, a)) }
          end
        end
      end
    end
  end
end
