require_relative '_base'

module Claudine
  module Animations
    module Bunny
      # Échec (outil en erreur) : un lapin tremble de colère sur les 4 faces
      # latérales, en rouge. Animation partagée avec stop_failure (fin de tour
      # en échec).
      # Signature : lapin qui tremble, rouge.
      class PostToolFail < BunnyBase
        MIN_DURATION = 1.0
        COLOR = [255, 0, 0]        # rouge (erreur)
        SHAKE = 1.0                # amplitude du tremblement (px)
        FREQ  = 5.0                # fréquence du tremblement (Hz) — colère
        BLINK = 0.2                # demi-période du clignotement du X (s)

        # Dessus : gros X épais (2 px) — les 2 diagonales élargies.
        X_TOP = (0..7).to_a.product((0..7).to_a)
                      .select { |x, y| (x - y).abs <= 1 || (x + y - 7).abs <= 1 }
                      .freeze

        # Tête de lapin classique (dx, dy ; 0 = bas). Oreilles de 2 px, tête,
        # yeux, corps simple. Occupe les colonnes 1..6, laissant 0 et 7 pour le
        # tremblement.
        #   . # # . . # # .   oreilles (2 px)
        #   . # # . . # # .
        #   . # # # # # # .   tête
        #   . # . # # . # .   yeux (creux en 2,5)
        #   . # # # # # # .
        #   . . # # # # . .   corps
        #   . . . . . . . .
        #   . . . # # . . .   pattes
        BODY = [
          [1, 7], [2, 7],                         [5, 7], [6, 7],
          [1, 6], [2, 6],                         [5, 6], [6, 6],
          [1, 5], [2, 5], [3, 5], [4, 5], [5, 5], [6, 5],
          [1, 4],         [3, 4], [4, 4],         [6, 4],
          [1, 3], [2, 3], [3, 3], [4, 3], [5, 3], [6, 3],
                  [2, 2], [3, 2], [4, 2], [5, 2],
                          [3, 0], [4, 0],
        ].freeze

        FACES = %i[front right back left].freeze

        def render(t, panel)
          panel.clear
          shake = SHAKE * Math.sin(2 * Math::PI * FREQ * t)
          FACES.each do |face|
            BODY.each { |dx, dy| px(panel, face, dx + shake, dy, COLOR) }
          end
          # Dessus : gros X rouge qui clignote.
          if (t / BLINK).floor.even?
            X_TOP.each { |x, y| px(panel, :top, x, y, COLOR) }
          end
        end
      end
    end
  end
end
