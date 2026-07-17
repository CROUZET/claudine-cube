require_relative '_base'

module Claudine
  module Animations
    module Cube
      # Notification (variante inverse de Notification2) : seuls les DEUX anneaux
      # carrés EXTÉRIEURS de chaque face clignotent (le cadre : d=0 et d=1), le
      # cœur 4×4 restant éteint.
      # Signature : clignotement carré rapide et net d'un cadre lumineux en
      # bordure de chaque face. Le manager tire au sort entre Notification,
      # Notification2 (cœur) et Notification3 (cadre).
      class Notification3 < CubeBase
        MIN_DURATION = 0.9
        RATE  = 3.0             # clignotements par seconde (approx)
        COLOR = [255, 130, 0]
        OUTER = [0, 1]          # les 2 anneaux concentriques extérieurs

        def render(t, panel)
          panel.clear
          on = (t * RATE).to_i.even?
          rgb = on ? COLOR : dim(COLOR, 0.08)
          ALL_FACES.each do |face|
            OUTER.each { |d| face_ring(panel, face, d, rgb) }
          end
        end
      end
    end
  end
end
