require_relative '_base'

module Claudine
  module Animations
    module Bunny
      # Avant un outil : un lapin joue sur les 4 faces latérales. Avant (1) : il
      # traverse en sautant (gauche → droite → gauche) puis danse sur place
      # (léger écrasement penché gauche / centre / droite / centre). Arrière (3) :
      # idem en miroir (symétrie). Droite (2) + gauche (4) : la même animation
      # inversée dans le temps (danse puis sauts), 4 en miroir de 2.
      # Blanc bleuté (event de début → couleur claire). Overlay court.
      # Signature : lapins qui sautent puis dansent tout autour de la façade.
      class PreTool < BunnyBase
        COLOR  = [210, 232, 255]   # blanc bleuté (début)
        T1     = 0.60              # fin du saut gauche → droite
        T2     = 1.20              # fin du saut droite → gauche
        DUR    = 2.30              # fin de la danse
        MIN_DURATION = DUR
        HOP_H    = 3.0             # hauteur des sauts (px)
        CENTER_X = 2.0             # bord gauche du sprite quand centré
        SHEAR    = 2.0             # amplitude du penché (px en haut du sprite)
        SQUASH   = 0.15            # écrasement vertical max pendant la danse (léger)
        BLINK    = 0.25            # demi-période du clignotement du dessus (s)

        # Dessus : 8 pixels (ligne×colonne → x,y), 2 le long de la diagonale de
        # chaque coin, qui clignotent en rythme.
        TOP_DOTS = [
          [1, 1], [2, 2], [5, 5], [6, 6],   # diagonale principale
          [6, 1], [5, 2], [2, 5], [1, 6],   # anti-diagonale
        ].freeze

        # Sprite lapin (dx, dy ; 0 = pattes). Forme fournie par l'utilisateur.
        #   # . . #
        #   # . . #
        #   # # # #
        #   # . # #
        #   # # # #
        BODY = [
          [0, 4],                 [3, 4],   # oreilles
          [0, 3],                 [3, 3],
          [0, 2], [1, 2], [2, 2], [3, 2],   # tête
          [0, 1],         [2, 1], [3, 1],   # corps (patte repliée)
          [0, 0], [1, 0], [2, 0], [3, 0],   # corps / pattes
        ].freeze

        def render(t, panel)
          panel.clear
          draw_on(panel, :front, t,       false)   # 1 : sauts → danse
          draw_on(panel, :back,  t,       true)    # 3 : symétrie miroir
          draw_on(panel, :right, DUR - t, false)   # 2 : inversé (danse → sauts)
          draw_on(panel, :left,  DUR - t, true)    # 4 : inversé + miroir
          # Dessus : 8 pixels de coin qui clignotent en rythme.
          if (t / BLINK).floor.even?
            TOP_DOTS.each { |x, y| px(panel, :top, x, y, COLOR) }
          end
        end

        private

        # Dessine le lapin sur une face à l'instant tt (miroir horizontal option.).
        def draw_on(panel, face, tt, mirror)
          bx, by, lean = pose(tt.clamp(0.0, DUR))
          sy = 1.0 - SQUASH * lean.abs          # écrasement vertical quand penché
          BODY.each do |dx, dy|
            x = bx + dx + lean * SHEAR * (dy / 4.0)   # penché : le haut décale plus
            y = by + dy * sy
            x = 7 - x if mirror
            px(panel, face, x, y, COLOR)
          end
        end

        # Renvoie [base_x, base_y, lean] à l'instant t.
        #  - t < T1 : saut gauche → droite (2 arcs)
        #  - t < T2 : saut droite → gauche (2 arcs)
        #  - sinon  : danse centrée, penché -1 (gauche) … +1 (droite)
        def pose(t)
          if t < T1
            p = t / T1
            [4.0 * p, HOP_H * Math.sin(Math::PI * 2 * p).abs, 0.0]
          elsif t < T2
            p = (t - T1) / (T2 - T1)
            [4.0 * (1 - p), HOP_H * Math.sin(Math::PI * 2 * p).abs, 0.0]
          else
            p = [(t - T2) / (DUR - T2), 1.0].min
            [CENTER_X, 0.0, -Math.sin(2 * Math::PI * p)]
          end
        end
      end
    end
  end
end
