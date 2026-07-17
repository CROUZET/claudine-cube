require_relative '../cube/_base'

module Claudine
  module Animations
    # Set « bunny » (lapins). Même cube physique que le set `cube`, donc on
    # réutilise sa géométrie et ses helpers de rendu (px, ring_px, face_ring,
    # top_ring, ring_row, wave, dim, …) via Cube::CubeBase, plus les repères de
    # faces. Les animations bunny héritent de BunnyBase.
    #
    # Charte couleur (cf. mémoire projet) : début = clair (blanc / bleu clair),
    # fin = jaune, erreur = rouge.
    module Bunny
      ALL_FACES = Cube::ALL_FACES
      LATERAL   = Cube::LATERAL
      SIDE      = Cube::SIDE
      RING      = Cube::RING

      class BunnyBase < Cube::CubeBase
      end
    end
  end
end
