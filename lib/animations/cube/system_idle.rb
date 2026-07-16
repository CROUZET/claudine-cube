require_relative '_base'

module Claudine
  module Animations
    module Cube
      # Repos (aucun event depuis IDLE_TIMEOUT) : respiration bleu nuit très
      # douce sur tout le cube, avec un lent point clair qui fait le tour
      # (le cube « dort » mais reste vivant). Signature : très lent, très sombre.
      class SystemIdle < CubeBase
        BREATH = 6.0            # période de respiration (s)
        ORBIT  = 8.0            # période d'un tour complet (s)
        BASE   = [0, 20, 55]
        SPARK  = [40, 80, 140]

        def render(t, panel)
          fill(panel, dim(BASE, 0.4 + 0.6 * wave(t, BREATH)))
          col = (t / ORBIT) * RING
          3.times do |trail|
            k = 1.0 - trail * 0.33
            ring_px(panel, col - trail, 4, dim(SPARK, k))
          end
        end
      end
    end
  end
end
