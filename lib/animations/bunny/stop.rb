require_relative '_base'
require_relative 'user_prompt'

module Claudine
  module Animations
    module Bunny
      # Fin de tour (succès) : les lapins courent autour du cube (façon
      # user_prompt) puis s'arrêtent et se tournent de face (un lapin frontal
      # centré sur chaque face latérale), avant de s'éteindre en fondu. Jaune
      # (event de fin → jaune).
      # Signature : la course s'arrête, les lapins regardent, puis s'estompent.
      class Stop < BunnyBase
        COLOR   = [255, 200, 0]           # jaune (fin)
        SPEED   = 16.0                    # colonnes/seconde (course)
        HOP_LEN = UserPrompt::HOP_LEN     # même saut que user_prompt
        HOP_H   = [3.0, 5.0, 4.0].freeze  # hauteurs de saut variées
        NB      = HOP_H.size
        RUN     = UserPrompt::RABBIT       # sprite courant (profil) de user_prompt

        T_RUN  = 2.0                       # durée de la course
        T_FADE = 2.0                       # durée du fondu (après l'arrêt)
        DUR    = T_RUN + T_FADE
        MIN_DURATION = DUR
        DURATION     = DUR                 # durée complète (lue par l'aperçu)

        # Petit lapin frontal (corps entier), 4 px de large ; centré via FRONT_X.
        #   # . . #   oreilles
        #   # . . #
        #   # # # #   corps
        #   # # # #
        #   # # # #
        FRONT = [
          [0, 4],                 [3, 4],
          [0, 3],                 [3, 3],
          [0, 2], [1, 2], [2, 2], [3, 2],
          [0, 1], [1, 1], [2, 1], [3, 1],
          [0, 0], [1, 0], [2, 0], [3, 0],
        ].freeze
        FRONT_X = 2                        # centre le sprite (4 px) sur la face
        FRONT_FACES = %i[front right back left].freeze

        def render(t, panel)
          panel.clear
          if t < T_RUN
            draw_run(panel, t)
          else
            fade = 1.0 - (t - T_RUN) / T_FADE
            return if fade <= 0.0
            c = dim(COLOR, fade)
            FRONT_FACES.each { |face| FRONT.each { |x, y| px(panel, face, FRONT_X + x, y, c) } }
          end
        end

        private

        # Course : lapins qui sautent autour de l'anneau (comme user_prompt).
        def draw_run(panel, t)
          head = t * SPEED
          NB.times do |i|
            col    = head + i * (RING.to_f / NB)
            hop    = Math.sin(Math::PI * ((col % HOP_LEN) / HOP_LEN))
            base_y = hop * HOP_H[i]
            RUN.each { |dx, dy| plot(panel, col + dx, base_y + dy, COLOR) }
          end
        end

        # Pixel sur l'anneau ; débordement sur le dessus si y ≥ 8 (cf. user_prompt).
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
