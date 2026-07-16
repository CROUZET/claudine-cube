require_relative '_base'

module Claudine
  module Animations
    module Cube
      # Le cube s'éveille : respiration verte lente sur tout le volume.
      # Signature : respiration globale (aucune autre anim ne respire tout le cube en vert).
      class SessionStart < CubeBase
        PERIOD = 3.0
        BASE   = [0, 200, 0]

        def render(t, panel)
          fill(panel, dim(BASE, wave(t, PERIOD)))
        end
      end
    end
  end
end
