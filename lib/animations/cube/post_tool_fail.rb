require_relative '_base'

module Claudine
  module Animations
    module Cube
      # Après un outil (échec) : DOUBLE clignotement rouge sec du cube entier.
      # Signature : deux flashs brefs (distinct du flash unique de post_tool),
      # lisible même sans percevoir la couleur.
      class PostToolFail < CubeBase
        MIN_DURATION = 0.8
        COLOR = [255, 0, 0]

        def render(t, panel)
          on = (t < 0.12) || (t >= 0.26 && t < 0.38)
          fill(panel, on ? COLOR : [0, 0, 0])
        end
      end
    end
  end
end
