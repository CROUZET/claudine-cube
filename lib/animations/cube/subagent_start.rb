require_relative '_base'

module Claudine
  module Animations
    module Cube
      # A subagent starts: a violet dot orbits fast around the cube
      # (central band), with a trail. Signature: a dot turning (orbit).
      class SubagentStart < CubeBase
        MIN_DURATION = 0.6     # short lock (= default, made explicit)
        SPEED        = 30.0    # columns per second
        COLOR        = [160, 0, 220]

        def render(t, panel)
          panel.clear
          head = t * SPEED
          5.times do |trail|
            k = 1.0 - trail * 0.2
            next if k <= 0
            c = dim(COLOR, k)
            ring_px(panel, head - trail, 3, c)
            ring_px(panel, head - trail, 4, c)
          end
        end
      end
    end
  end
end
