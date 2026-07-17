require_relative '_base'

module Claudine
  module Animations
    module Cube
      # Notification (variante) : au lieu de faire clignoter tout le cube en
      # ambre, seuls les DEUX anneaux carrés intérieurs de chaque face clignotent
      # (le cœur 4×4 : d=2 et d=3), le pourtour restant éteint.
      # Signature : clignotement carré rapide et net d'un noyau lumineux au
      # centre de chaque face — même urgence que l'originale, empreinte plus
      # ramassée. Le manager tire au sort entre Notification et Notification2.
      class Notification2 < CubeBase
        MIN_DURATION = 0.9
        RATE  = 3.0             # clignotements par seconde (approx)
        COLOR = [255, 130, 0]
        INNER = [2, 3]          # les 2 anneaux concentriques intérieurs

        def render(t, panel)
          panel.clear
          on = (t * RATE).to_i.even?
          rgb = on ? COLOR : dim(COLOR, 0.08)
          ALL_FACES.each do |face|
            INNER.each { |d| face_ring(panel, face, d, rgb) }
          end
        end
      end
    end
  end
end
