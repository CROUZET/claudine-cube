require_relative '_base'

module Claudine
  module Animations
    module Cube
      # Nouvelle tâche : sur les 5 faces, les 2 anneaux extérieurs et les 2
      # anneaux intérieurs s'allument en alternance régulière (respiration
      # « dedans / dehors » synchronisée sur tout le cube).
      # Signature : clignotement concentrique alterné, identique sur chaque face.
      class TaskNew < CubeBase
        MIN_DURATION = 0.6
        PHASE = 0.4             # durée d'une phase (secondes) avant de basculer
        COLOR = [0, 180, 120]

        def render(t, panel)
          panel.clear
          outer = (t / PHASE).to_i.even?     # true : anneaux extérieurs ; false : intérieurs
          rings = outer ? [0, 1] : [2, 3]
          ALL_FACES.each do |face|
            rings.each { |d| face_ring(panel, face, d, COLOR) }
          end
        end
      end
    end
  end
end
