require_relative '_base'

module Claudine
  module Animations
    module Bunny
      # Nouvelle tâche : un lapin en gros plan (de profil) marche tranquillement
      # autour du cube, le long de l'anneau des 4 faces latérales, avec un cycle
      # de pattes. Traverse les arêtes sans couture (ring_px). Bleu clair (event
      # de début → couleur claire). Overlay.
      # Signature : un grand lapin qui fait le tour du cube au pas.
      class TaskNew < BunnyBase
        MIN_DURATION = 3.6
        DURATION     = 4.5        # durée complète (lue par l'aperçu)
        COLOR = [120, 200, 255]   # bleu clair (début)
        SPEED = 7.0               # colonnes/seconde (marche tranquille)
        STEP  = 4                 # colonnes par pas (alternance des pattes)

        # Lapin de profil, tourné vers la marche (dx croissant = avant). dy=0=bas.
        # Œil = creux en (5,4). Grand plan (7 px de large, 7 de haut).
        #   . . . # # . .   oreille
        #   . . . . # # .
        #   . . # # # . #   tête (œil en creux) + dos
        #   . # # # # # #   corps
        #   # # # # # # .
        #   . # # # # # .
        BODY = [
                          [3, 6], [4, 6],
                                  [4, 5], [5, 5],
                  [2, 4], [3, 4], [4, 4],         [6, 4],
          [1, 3], [2, 3], [3, 3], [4, 3], [5, 3], [6, 3],
          [0, 2], [1, 2], [2, 2], [3, 2], [4, 2], [5, 2],
                  [1, 1], [2, 1], [3, 1], [4, 1], [5, 1],
        ].freeze
        LEGS_A = [[1, 0], [4, 0]].freeze   # pas 1
        LEGS_B = [[2, 0], [5, 0]].freeze   # pas 2 (alternance)

        def render(t, panel)
          panel.clear
          col  = t * SPEED
          legs = (col / STEP).floor.even? ? LEGS_A : LEGS_B
          (BODY + legs).each { |dx, dy| ring_px(panel, col + dx, dy, COLOR) }
        end
      end
    end
  end
end
