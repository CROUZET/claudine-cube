require_relative '_base'

module Claudine
  module Animations
    module Cube
      # Un sous-agent se termine : l'anneau central violet complet s'illumine puis
      # s'éteint en fondu (l'orbite se referme). Signature : anneau plein qui fade.
      class SubagentStop < CubeBase
        MIN_DURATION = 0.7
        DUR   = 0.7
        COLOR = [160, 0, 220]

        def render(t, panel)
          panel.clear
          c = dim(COLOR, [1.0 - t / DUR, 0.0].max)
          ring_row(panel, 3, c)
          ring_row(panel, 4, c)
        end
      end
    end
  end
end
