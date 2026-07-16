require_relative '_base'

module Claudine
  module Animations
    module Cube
      # Fin de tour (succès) : respiration bleue calme, posée (Claude a fini, attend).
      # Signature : respiration lente bleue, jamais éteinte complètement.
      class Stop < CubeBase
        PERIOD = 4.0
        COLOR  = [0, 70, 130]

        def render(t, panel)
          fill(panel, dim(COLOR, 0.4 + 0.6 * wave(t, PERIOD)))
        end
      end
    end
  end
end
