require_relative '_base'

module Claudine
  module Animations
    module Cube
      # Tâche terminée : une vague verte monte tout autour du cube puis se referme
      # en anneaux concentriques sur le dessus (accomplissement qui s'élève et se
      # boucle). Signature : montée pleine (traînée de comète) + anneaux vers le
      # centre du dessus.
      class TaskDone < CubeBase
        MIN_DURATION = 0.6
        SPEED = 18.0
        COLOR = [0, 220, 90]

        def render(t, panel)
          panel.clear
          head = t * SPEED
          # Montée pleine sur les 4 faces latérales (crête vive + traînée).
          SIDE.times do |y|
            next if y > head
            k = [1.0 - (head - y) / SIDE, 0.2].max
            ring_row(panel, y, dim(COLOR, k))
          end
          # Sur le dessus : anneaux concentriques qui se remplissent vers le centre.
          crest = head - SIDE
          4.times do |d|
            next if d > crest
            k = [1.0 - (crest - d) / SIDE, 0.2].max
            top_ring(panel, d, dim(COLOR, k))
          end
        end
      end
    end
  end
end
