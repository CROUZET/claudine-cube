require_relative '_base'

module Claudine
  module Animations
    module Cube
      # Fin de tour (échec) : pulsation rouge lente et insistante (alerte posée).
      # Signature : pulsation ample et régulière (distinct du double-flash sec de
      # post_tool_fail) — le rythme, pas la couleur, porte l'info.
      class StopFailure < CubeBase
        MIN_DURATION = 1.0
        PERIOD = 1.2
        COLOR  = [255, 0, 0]

        def render(t, panel)
          fill(panel, dim(COLOR, 0.15 + 0.85 * wave(t, PERIOD)))
        end
      end
    end
  end
end
