require_relative '_base'

module Claudine
  module Animations
    module Cube
      # Un sous-agent démarre : un point violet orbite vite autour du cube
      # (bande centrale), avec traînée. Signature : point qui tourne (orbite).
      class SubagentStart < CubeBase
        MIN_DURATION = 0.6     # lock court (= défaut, explicité)
        SPEED        = 30.0    # colonnes par seconde
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
