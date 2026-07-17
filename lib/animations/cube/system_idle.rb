require_relative '_base'

module Claudine
  module Animations
    module Cube
      # Repos (aucun event depuis IDLE_TIMEOUT) : respiration bleu nuit très
      # douce sur tout le cube, avec un lent point clair qui fait le tour
      # (le cube « s'endort »). Signature : très lent, très sombre.
      #
      # Jouée UNE SEULE FOIS : après DURATION secondes, le manager éteint le
      # cube. L'animation fond au noir sur les FADE dernières secondes pour que
      # l'extinction soit douce (pas de coupure sèche).
      class SystemIdle < CubeBase
        BREATH   = 6.0          # période de respiration (s)
        ORBIT    = 8.0          # période d'un tour complet (s)
        DURATION = 12.0         # durée de vie avant extinction (lue par le manager)
        FADE     = 3.0          # fondu de sortie sur les dernières secondes
        BASE     = [0, 20, 55]
        SPARK    = [40, 80, 140]

        def render(t, panel)
          out = fade_out(t)
          fill(panel, dim(BASE, (0.4 + 0.6 * wave(t, BREATH)) * out))
          col = (t / ORBIT) * RING
          3.times do |trail|
            k = (1.0 - trail * 0.33) * out
            ring_px(panel, col - trail, 4, dim(SPARK, k))
          end
        end

        private

        # Facteur global 1→0 sur les FADE dernières secondes de vie.
        def fade_out(t)
          return 1.0 if t < DURATION - FADE
          (1.0 - (t - (DURATION - FADE)) / FADE).clamp(0.0, 1.0)
        end
      end
    end
  end
end
