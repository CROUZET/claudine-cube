require_relative '_base'

module Claudine
  module Animations
    module Cube
      # Après un outil (succès) : bref flash bleu du cube entier qui décroît.
      # Signature : flash global unique, décroissance douce.
      class PostTool < CubeBase
        DUR   = 0.5
        COLOR = [0, 120, 255]

        def render(t, panel)
          fill(panel, dim(COLOR, [1.0 - t / DUR, 0.0].max))
        end
      end
    end
  end
end
