require_relative '_base'

module Claudine
  module Animations
    module Bunny
      # Démarrage d'un sous-agent : un petit lapin surgit du bas (effet ressort)
      # sur chacune des 4 faces latérales, puis les 4 lapins font le tour du cube
      # en sautant vers la droite, chacun à la place du suivant, 4 fois (tour
      # complet). Bleu clair (event de début → couleur claire). Overlay.
      # Signature : les lapins jaillissent puis tournent autour du cube en sautant.
      class SubagentStart < BunnyBase
        COLOR  = [120, 200, 255]   # bleu clair (début)
        POP    = 0.45              # durée du jaillissement (s)
        JUMPS  = 4                 # nombre de sauts (tour complet)
        JUMP_T = 1.0               # durée d'un saut (s)
        HOP_H  = 3.0               # hauteur d'un saut (px)
        BASE_X = 2                 # position du lapin dans sa face (centré, 4 px)
        MIN_DURATION = POP + JUMPS * JUMP_T
        DURATION     = MIN_DURATION

        # Petit lapin (dx, dy ; 0 = pattes).
        #   # . . #   oreilles
        #   # . . #
        #   # # # #   corps
        #   # # # #
        #   # # # #
        BODY = [
          [0, 4],                 [3, 4],
          [0, 3],                 [3, 3],
          [0, 2], [1, 2], [2, 2], [3, 2],
          [0, 1], [1, 1], [2, 1], [3, 1],
          [0, 0], [1, 0], [2, 0], [3, 0],
        ].freeze

        def render(t, panel)
          panel.clear
          4.times do |i|
            base = i * SIDE + BASE_X          # colonne de départ du lapin i
            col, by = pose(t, base)
            BODY.each { |dx, dy| plot(panel, col + dx, by + dy, COLOR) }
          end
        end

        private

        # Renvoie [colonne, décalage_vertical] du lapin à l'instant t.
        def pose(t, base)
          if t < POP                          # jaillissement vertical, sur place
            off = (-5 * (1.0 - ease_out_back(t / POP))).round
            [base, off]
          else
            total = (t - POP) / JUMP_T         # progression en "sauts" (0..JUMPS)
            if total >= JUMPS
              [base + JUMPS * SIDE, 0]         # posé (= maison, modulo l'anneau)
            else
              p = total - total.floor          # phase du saut courant
              [base + total * SIDE, Math.sin(Math::PI * p) * HOP_H]
            end
          end
        end

        # Ease-out « back » : dépasse 1 puis revient (effet ressort visible ~1 px).
        def ease_out_back(p)
          c1 = 3.2
          c3 = c1 + 1
          1 + c3 * (p - 1)**3 + c1 * (p - 1)**2
        end

        # Pixel sur l'anneau ; débord sur le dessus si y ≥ 8 (cf. user_prompt).
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
