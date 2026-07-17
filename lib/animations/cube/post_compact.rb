require_relative 'pre_compact'

module Claudine
  module Animations
    module Cube
      # Après compaction : même damier 2×2 clignotant que pre_compact, mais en
      # jaune. pre_compact et post_compact partagent le geste ; seule la couleur
      # les distingue (gris avant, jaune après).
      class PostCompact < PreCompact
        COLOR = [235, 200, 0]   # jaune
      end
    end
  end
end
