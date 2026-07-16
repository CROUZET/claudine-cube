require_relative '_base'

module Claudine
  module Animations
    module Cube
      # Extinction : le cube s'éteint en fondu du blanc vers le noir.
      # Signature : fondu descendant monotone (pas de rebond).
      class SessionEnd < CubeBase
        MIN_DURATION = 1.6
        DUR  = 1.5
        BASE = [140, 140, 140]

        def render(t, panel)
          k = [1.0 - t / DUR, 0.0].max
          fill(panel, dim(BASE, k))
        end
      end
    end
  end
end
