require_relative '_base'

module Claudine
  module Animations
    module Cube
      # Avant un outil : une colonne ambre balaye le tour du cube. En regard de la
      # colonne, les 2 anneaux extérieurs du dessus s'allument aussi, et s'éteignent
      # derrière elle (marqueur synchronisé, même traînée que la colonne).
      # Signature : colonne verticale qui tourne, prolongée sur le pourtour du dessus.
      class PreTool < CubeBase
        MIN_DURATION = 0.6     # event fréquent : lock court (= défaut, explicité)
        SPEED        = 26.0    # colonnes par seconde
        COLOR        = [220, 120, 0]

        def render(t, panel)
          panel.clear
          head = t * SPEED
          4.times do |trail|
            k = 1.0 - trail * 0.28
            next if k <= 0
            c   = dim(COLOR, k)
            col = head - trail

            # Colonne sur les 4 faces latérales.
            SIDE.times { |y| ring_px(panel, col, y, c) }

            # Pixels correspondants sur les 2 anneaux extérieurs du dessus.
            ci   = col.to_i % RING
            face = LATERAL[ci / SIDE]
            x    = ci % SIDE
            [0, 1].each do |ring|
              tx, ty = top_edge_px(face, x, ring)
              px(panel, :top, tx, ty, c)
            end
          end
        end
      end
    end
  end
end
