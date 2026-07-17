require_relative 'session_start'

module Claudine
  module Animations
    module Cube
      # Fin de session : même vague diagonale que l'ouverture (montée puis
      # reflux jusqu'à extinction), mais en couleurs froides. Ouverture et
      # fermeture partagent le geste ; la température de la palette les oppose
      # (chaud à l'éveil, froid à la fin).
      class SessionEnd < SessionStart
        # Froid, plage large pour plus de variété : vert-jaune (0.25) → vert →
        # cyan → bleu → indigo → violet (0.85).
        HUE0 = 0.25
        HUE1 = 0.85
      end
    end
  end
end
