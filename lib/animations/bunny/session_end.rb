require_relative 'session_start'

module Claudine
  module Animations
    module Bunny
      # Fin de session : les lapins s'endorment. Ils partent allumés (oreilles
      # dressées) puis les oreilles s'abaissent, les yeux se ferment, et tout le
      # cube (lapins + cadre du dessus) s'éteint en fondu progressif du début à
      # la fin. Arc-en-ciel FROID. Miroir « sommeil » de l'éveil (session_start).
      class SessionEnd < SessionStart
        HUE0 = 0.25               # froid : vert-jaune → … → violet
        HUE1 = 0.85
        DUR  = 2.6                # endormissement complet (fondu jusqu'au noir)
        SINK = 0.8                # descente des oreilles (s)
        MIN_DURATION = DUR
        DURATION     = DUR        # durée montrée par l'aperçu

        EYES = [[2, 3], [5, 3]].freeze   # creux des yeux (mêmes positions A et B)

        def render(t, panel)
          panel.clear
          fade = [1.0 - t / DUR, 0.0].max        # fondu progressif tout du long
          return if fade <= 0.0                  # endormi : cube éteint
          ear_top = 7 - ([t / SINK, 1.0].min * 3).round   # oreilles 7 → 4
          asleep  = t >= SINK                    # yeux fermés une fois assoupi

          # Modèle A : avant + arrière (miroir). Pas de clin d'œil (il dort).
          draw_a(panel, :front, fade, ear_top, false, false)
          draw_a(panel, :back,  fade, ear_top, false, true)
          # Modèle B : droite + gauche (miroir).
          blit(panel, :right, B_BODY, fade, false)
          blit(panel, :left,  B_BODY, fade, true)
          # Yeux fermés (creux remplis) sur les 4 lapins une fois endormis.
          close_eyes(panel, fade) if asleep
          # Dessus : le cadre plein s'éteint en fondu avec le reste.
          TOP_PATH.each { |x, y| px(panel, :top, x, y, warm(:top, x, y, fade)) }
        end

        private

        def close_eyes(panel, fade)
          %i[front back right left].each do |face|
            EYES.each { |x, y| px(panel, face, x, y, warm(face, x, y, fade)) }
          end
        end
      end
    end
  end
end
