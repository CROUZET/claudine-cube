require_relative '_base'

module Claudine
  module Animations
    module Bunny
      # Notification : avant (1) + arrière (3) → gros plan d'une tête de lapin
      # (avec l'œil et une oreille) qui fait coucou de la patte (jaune) ;
      # droite (2) + gauche (4) → gros plan d'une carotte (corps rouge + fanes
      # vertes) qui rebondit ; dessus (5) → anneau extérieur jaune qui tourne.
      # Overlay court.
      # Signature : lapin qui salue + carotte qui saute.
      class Notification < BunnyBase
        MIN_DURATION = 1.5
        COLOR  = [255, 200, 0]   # jaune (lapin)
        BODY_C = [255, 0, 0]     # corps de la carotte (rouge)
        LEAF   = [0, 170, 0]     # fanes
        FREQ   = 2.5             # fréquence (Hz)
        SPIN     = 0.15          # tours/seconde de l'anneau du dessus
        SEGMENTS = 8             # nb de segments (arcs jaunes / trous) de l'anneau

        # Tête en gros plan (fixe). dx, dy ; 0 = bas. Œil = creux en (2,2).
        #   . # # . . . . .   oreille
        #   . # # . . . . .
        #   . # # . . . . .
        #   # # # . . . . .
        #   # # # # . . . .
        #   # # . # # . . .   œil (creux en 2)
        #   # # # # # . . .
        #   # # # # . . . .
        HEAD = [
                  [1, 7], [2, 7],
                  [1, 6], [2, 6],
                  [1, 5], [2, 5],
          [0, 4], [1, 4], [2, 4],
          [0, 3], [1, 3], [2, 3], [3, 3],
          [0, 2], [1, 2],         [3, 2], [4, 2],
          [0, 1], [1, 1], [2, 1], [3, 1], [4, 1],
          [0, 0], [1, 0], [2, 0], [3, 0],
        ].freeze

        # Patte levée (colonnes 6,7 ; se décale horizontalement pour saluer).
        PAW = [
          [6, 4], [7, 4],
          [6, 3], [7, 3],
          [6, 2], [7, 2],
          [6, 1], [7, 1],
          [6, 0], [7, 0],
        ].freeze

        # Carotte, gros plan sur le HAUT : grandes fanes vertes + corps rouge
        # large qui remplit la face et sort par le bas (pas de pointe).
        #   # . # . # .   fanes
        #   # # # # # #
        #   . # # # . .   base des fanes
        #   # # # # # # #  corps (rouge), large
        #   # # # # # # #
        #   # # # # # # #
        #   . # # # # .
        #   . # # # # .
        LEAVES = [
          [1, 7],         [3, 7],         [5, 7],
          [1, 6], [2, 6], [3, 6], [4, 6], [5, 6],
                  [2, 5], [3, 5], [4, 5],
        ].freeze
        CARROT = [
          [1, 4], [2, 4], [3, 4], [4, 4], [5, 4], [6, 4],
          [1, 3], [2, 3], [3, 3], [4, 3], [5, 3], [6, 3],
          [1, 2], [2, 2], [3, 2], [4, 2], [5, 2], [6, 2],
                  [2, 1], [3, 1], [4, 1], [5, 1],
                  [2, 0], [3, 0], [4, 0], [5, 0],
        ].freeze

        def render(t, panel)
          panel.clear
          w   = Math.sin(2 * Math::PI * FREQ * t).round   # -1..1 (coucou)
          bob = Math.sin(2 * Math::PI * FREQ * t).round   # -1..1 (rebond carotte)
          draw_bunny(panel, :front, w)    # 1 : lapin
          draw_bunny(panel, :back,  w)    # 3 : lapin
          draw_carrot(panel, :right, bob) # 2 : carotte
          draw_carrot(panel, :left,  bob) # 4 : carotte
          draw_top_ring(panel, t)         # 5 : anneau jaune tournant
        end

        private

        # Dessus : anneau extérieur de 2 px, arcs jaunes qui tournent.
        def draw_top_ring(panel, t)
          rot = t * SPIN
          SIDE.times do |x|
            SIDE.times do |y|
              next unless [x, y, SIDE - 1 - x, SIDE - 1 - y].min <= 1  # 2 anneaux ext.
              u   = Math.atan2(y - 3.5, x - 3.5) / (2 * Math::PI) + 0.5 # 0..1 (angle)
              seg = ((u + rot) * SEGMENTS).floor
              px(panel, :top, x, y, COLOR) if seg.even?   # arcs jaunes (trous sinon)
            end
          end
        end

        def draw_bunny(panel, face, w)
          HEAD.each { |x, y| px(panel, face, x,     y, COLOR) }
          PAW.each  { |x, y| px(panel, face, x + w, y, COLOR) }
        end

        def draw_carrot(panel, face, bob)
          LEAVES.each { |x, y| px(panel, face, x, y + bob, LEAF) }
          CARROT.each { |x, y| px(panel, face, x, y + bob, BODY_C) }
        end
      end
    end
  end
end
