require_relative '_base'

module Claudine
  module Animations
    module Cube
      # Avant compaction : un damier de carrés 2×2 sur les 5 faces, qui s'inverse
      # à intervalle régulier (les carrés allumés et éteints échangent leur
      # place). Signature : damier clignotant qui alterne sur tout le cube.
      class PreCompact < CubeBase
        MIN_DURATION = 1.0
        PHASE  = 0.3             # durée d'une phase avant inversion du damier
        SQUARE = 2               # côté d'un carré (px)
        COLOR  = [210, 210, 210] # gris neutre

        def render(t, panel)
          panel.clear
          lit = (t / PHASE).to_i.even? ? 0 : 1   # quelle parité est allumée
          ALL_FACES.each do |face|
            SIDE.times do |x|
              SIDE.times do |y|
                next unless (x / SQUARE + y / SQUARE) % 2 == lit
                px(panel, face, x, y, self.class::COLOR)
              end
            end
          end
        end
      end
    end
  end
end
