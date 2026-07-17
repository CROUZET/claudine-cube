require_relative '_base'

module Claudine
  module Animations
    module Cube
      # Notification (variante complémentaire de Notification) : n'allume que le
      # 2e anneau (d=1) et le 4e anneau central (d=3) de chaque face — le négatif
      # exact de Notification (d=0 + d=2), soit deux cadres concentriques
      # imbriqués dans les vides de l'originale.
      # Signature : clignotement carré rapide et net (cible « en creux »).
      class Notification4 < CubeBase
        MIN_DURATION = 0.9
        RATE  = 3.0             # clignotements par seconde (approx)
        COLOR = [255, 130, 0]
        RINGS = [1, 3]          # 2e anneau + 4e anneau (central)

        def render(t, panel)
          panel.clear
          on = (t * RATE).to_i.even?
          rgb = on ? COLOR : dim(COLOR, 0.08)
          ALL_FACES.each do |face|
            RINGS.each { |d| face_ring(panel, face, d, rgb) }
          end
        end
      end
    end
  end
end
