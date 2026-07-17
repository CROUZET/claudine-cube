require_relative 'task_new'

module Claudine
  module Animations
    module Cube
      # Tâche terminée : même clignotement concentrique alterné que task_new
      # (anneaux dedans / dehors sur les 5 faces), mais en jaune. task_new et
      # task_done partagent le geste ; seule la couleur les distingue.
      class TaskDone < TaskNew
        COLOR = [235, 200, 0]   # jaune (vert pour task_new)
      end
    end
  end
end
