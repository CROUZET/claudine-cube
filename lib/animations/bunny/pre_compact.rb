require_relative '_base'
require_relative 'user_prompt'

module Claudine
  module Animations
    module Bunny
      # Avant compaction : une tête de lapin sur chacune des 4 faces latérales
      # monte, passe sur le dessus, converge vers le centre et les 4 fusionnent
      # en un nouveau lapin (éclosion). Bleu clair (event de début → clair).
      # Signature : 4 têtes qui remontent et fusionnent en un lapin sur le dessus.
      class PreCompact < BunnyBase
        T1  = 0.6                  # montée sur les faces latérales
        T2  = 1.5                  # convergence sur le dessus
        DUR = 2.3                  # éclosion du lapin fusionné
        MIN_DURATION = DUR
        DURATION     = DUR
        COLOR = [120, 200, 255]    # bleu clair (début)

        # Tête de lapin (4×5, dx/dy ; 0 = bas).
        #   # . . #   oreilles
        #   # . . #
        #   # # # #   tête
        #   # # # #
        #   # # # #
        HEAD = [
          [0, 4],                 [3, 4],
          [0, 3],                 [3, 3],
          [0, 2], [1, 2], [2, 2], [3, 2],
          [0, 1], [1, 1], [2, 1], [3, 1],
          [0, 0], [1, 0], [2, 0], [3, 0],
        ].freeze

        # Positions d'entrée sur le dessus (origine du sprite), par arête.
        EDGES  = [[2, 0], [4, 3], [2, 3], [0, 3]].freeze   # front, right, back, left
        CENTER = [2, 2].freeze                             # point de fusion

        # Lapin fusionné = le joli lapin (profil) de user_prompt, centré.
        NEW   = UserPrompt::RABBIT
        NEW_X = 2                    # décalage pour centrer (5 px de large)
        NEW_Y = 1

        def render(t, panel)
          panel.clear
          if t < T1                                        # montée sur les 4 faces
            yb = (3 * (t / T1)).round
            LATERAL.each do |face|
              HEAD.each { |dx, dy| px(panel, face, 2 + dx, yb + dy, COLOR) }
            end
          elsif t < T2                                     # convergence sur le dessus
            cp = (t - T1) / (T2 - T1)
            EDGES.each do |sx, sy|
              ox = (sx + cp * (CENTER[0] - sx)).round
              oy = (sy + cp * (CENTER[1] - sy)).round
              HEAD.each { |dx, dy| px(panel, :top, ox + dx, oy + dy, COLOR) }
            end
          else                                             # éclosion du lapin fusionné
            a = 1.0 - (1.0 - [(t - T2) / (DUR - T2), 1.0].min)**2
            NEW.each { |dx, dy| px(panel, :top, NEW_X + dx, NEW_Y + dy, dim(COLOR, a)) }
          end
        end
      end
    end
  end
end
