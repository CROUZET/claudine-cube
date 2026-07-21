require_relative '../cube/_base'

module Claudine
  module Animations
    # "bunny" set. Same physical cube as the `cube` set, so we reuse its
    # geometry and its rendering helpers (px, ring_px, face_ring, top_ring,
    # ring_row, wave, dim, ...) via Cube::CubeBase, plus the face references.
    # The bunny animations inherit from BunnyBase.
    #
    # Color chart (cf. project memory): start = light (white / light blue),
    # end = yellow, error = red.
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
