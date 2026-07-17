require_relative '_base'

module Claudine
  module Animations
    module Bunny
      # Après un outil : un lapin sur chacune des 4 faces latérales fait une
      # petite danse (déhanché gauche/droite), et le dessus reprend les 8 pixels
      # de coin clignotants de pre_tool. Le tout s'éteint en fondu du début à la
      # fin. Jaune (event de fin → jaune). Overlay court.
      # Signature : lapins qui dansent, coins du dessus qui clignotent, puis tout
      # s'estompe.
      class PostTool < BunnyBase
        COLOR  = [255, 200, 0]     # jaune (fin)
        DUR    = 1.6               # durée de la danse + fondu
        MIN_DURATION = DUR
        SWAYS  = 3                 # nombre de déhanchés pendant la danse
        BASE_X = 2                 # bord gauche du sprite (centré, 4 px de large)
        SHEAR  = 1.0               # amplitude du penché (px en haut du sprite)
        SQUASH = 0                 # écrasement vertical max (léger)
        BLINK  = 0.25              # demi-période du clignotement du dessus (s)

        # Décalage de phase de la danse par face latérale (danses staggerées).
        FACE_PHASE = { front: 0.0, right: 0.2, back: 0.4, left: 0.6 }.freeze

        # Dessus : 8 pixels de coin qui clignotent (mêmes qu'en pre_tool).
        TOP_DOTS = [
          [1, 1], [2, 2], [5, 5], [6, 6],   # diagonale principale
          [6, 1], [5, 2], [2, 5], [1, 6],   # anti-diagonale
        ].freeze

        # Sprite lapin (dx, dy ; 0 = pattes).
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
          p    = [t / DUR, 1.0].min
          fade = 1.0 - p                     # fondu progressif tout du long
          return if fade <= 0.0
          FACE_PHASE.each do |face, off|
            lean = -Math.sin(2 * Math::PI * (SWAYS * p + off))
            draw(panel, face, lean, fade)
          end
          # Dessus : 8 pixels de coin qui clignotent en rythme, en fondu.
          if (t / BLINK).floor.even?
            c = dim(COLOR, fade)
            TOP_DOTS.each { |x, y| px(panel, :top, x, y, c) }
          end
        end

        private

        def draw(panel, face, lean, fade)
          sy    = 1.0 - SQUASH * lean.abs    # écrasement vertical quand penché
          color = dim(COLOR, fade)
          BODY.each do |dx, dy|
            x = BASE_X + dx + lean * SHEAR * (dy / 4.0)
            y = dy * sy
            px(panel, face, x, y, color)
          end
        end
      end
    end
  end
end
