require_relative '_base'

module Claudine
  module Animations
    module Bunny
      # « Thinking » (fond qui boucle) : des lapins sautillent en file autour du
      # cube, le long de l'anneau des 4 faces latérales, à des hauteurs de saut
      # différentes. Aux sauts les plus hauts, leur tête déborde sur le dessus le
      # long de l'arête franchie. Bleu clair uni (état de travail). Boucle sans
      # raccord.
      # Signature : petits lapins bleu clair qui font le tour du cube en sautillant.
      class UserPrompt < BunnyBase
        MIN_DURATION = 0.6
        COLOR   = [140, 200, 255]         # bleu clair
        SPEED   = 12.0                    # colonnes/seconde (tour du cube)
        HOP_LEN = 8                       # longueur d'un saut (colonnes) — 32 = 4 sauts/tour
        HOP_H   = [3.0, 5.0, 4.0].freeze  # hauteur de saut par lapin (le haut peut sortir)
        NB      = HOP_H.size              # nombre de lapins échelonnés autour du cube

        # Sprite lapin de profil (dx croissant = sens de la marche). dy = ligne,
        # 0 = pattes. Forme fournie par l'utilisateur.
        #   . . # . .
        #   . . . # .
        #   . . . # #
        #   . # # # #
        #   # # # # .
        #   # # # # .
        #   . # # . .
        RABBIT = [
                          [2, 6],                   # pointe d'oreille
                                  [3, 5],           # oreille
                                  [3, 4], [4, 4],   # oreille / tête
                  [1, 3], [2, 3], [3, 3], [4, 3],   # tête
          [0, 2], [1, 2], [2, 2], [3, 2],           # corps
          [0, 1], [1, 1], [2, 1], [3, 1],           # corps
                  [1, 0], [2, 0],                   # pattes
        ].freeze

        def render(t, panel)
          panel.clear
          head = t * SPEED
          NB.times do |i|
            col    = head + i * (RING.to_f / NB)
            hop    = Math.sin(Math::PI * ((col % HOP_LEN) / HOP_LEN))  # arc 0..1
            base_y = hop * HOP_H[i]                                    # hauteur propre au lapin
            RABBIT.each { |dx, dy| plot(panel, col + dx, base_y + dy, COLOR) }
          end
        end

        private

        # Place un pixel sur l'anneau latéral ; s'il dépasse le haut (y ≥ 8),
        # il déborde sur le dessus le long de l'arête (top_edge_px), la rangée
        # de dépassement donnant l'anneau du pourtour (8 → bord, 9+ → intérieur).
        def plot(panel, col, yy, rgb)
          yi = yy.to_i
          if yi <= 7
            ring_px(panel, col, yy, rgb)
          else
            c    = col.to_i % RING
            face = LATERAL[c / SIDE]
            lx   = c % SIDE
            tx, ty = top_edge_px(face, lx, yi - 8)
            px(panel, :top, tx, ty, rgb) if tx
          end
        end
      end
    end
  end
end
