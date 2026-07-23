# frozen_string_literal: true

require_relative "../base"

module Claudine
  module Animations
    module Cube
      # Shared faces and geometric landmarks.
      ALL_FACES = %i[front right back left top].freeze
      LATERAL = %i[front right back left].freeze # the 4 side faces
      SIDE = 8 # side of a face
      RING = LATERAL.size * SIDE # 32 columns around the cube

      # Common base for the cube animations. Provides "volumetric" rendering
      # helpers: ring around the 4 side faces, pulsing, per-face fill. Each
      # animation reasons in (face, x, y) via the Panel (the physical mapping
      # is absorbed by CubeMapping).
      #
      # Convention: x = column (0 left), y = row (0 bottom). The :top face
      # connects to the front in increasing y (validated on hardware).
      class CubeBase < Base
        def initialize(_payload = {}); end

        private

        # Sine wave 0..1 with period `period` seconds.
        def wave(t, period)
          (Math.sin(2 * Math::PI * t / period) * 0.5) + 0.5
        end

        # Multiplies a color by a factor 0..1 (rounded, clamped).
        def dim(rgb, k)
          rgb.map { |c| (c * k).round.clamp(0, 255) }
        end

        def fill(panel, rgb)
          panel.fill(rgb[0], rgb[1], rgb[2])
        end

        def face_fill(panel, face, rgb)
          panel.fill_face(face, rgb[0], rgb[1], rgb[2])
        end

        # A logical pixel on a face (coordinates coerced to integers).
        def px(panel, face, x, y, rgb)
          xi = x.to_i
          yi = y.to_i
          return if xi.negative? || xi >= SIDE || yi.negative? || yi >= SIDE

          panel.set(face: face, x: xi, y: yi, r: rgb[0], g: rgb[1], b: rgb[2])
        end

        # Pixel on the "ring" of the 4 side faces: col 0..31 goes around
        # (front 0..7, right 8..15, back 16..23, left 24..31) and loops.
        def ring_px(panel, col, y, rgb)
          c = col.to_i % RING
          px(panel, LATERAL[c / SIDE], c % SIDE, y, rgb)
        end

        # Fills an entire row y of the ring (the 4 side faces).
        def ring_row(panel, y, rgb)
          RING.times { |col| ring_px(panel, col, y, rgb) }
        end

        # Mapping from a side column -> pixel on the top border.
        # For a side face and its local column x (0..7), returns [tx, ty]
        # on the top's `ring` (0 = border, 1 = inner ring).
        # Traversing the 4 faces traces a full loop around the top's perimeter.
        def top_edge_px(face, x, ring)
          i = x.to_i
          if ring <= 0
            case face
            when :front then [i,     0]
            when :right then [7,     i]
            when :back  then [7 - i, 7]
            when :left  then [0,     7 - i]
            end
          else
            j = i.clamp(1, 6)
            k = (7 - i).clamp(1, 6)
            case face
            when :front then [j, 1]
            when :right then [6, j]
            when :back  then [k, 6]
            when :left  then [1, k]
            end
          end
        end

        # Concentric square ring on a face: d = distance to the border
        # (0 = outer border ... 3 = central 2x2 square).
        def face_ring(panel, face, d, rgb)
          SIDE.times do |x|
            SIDE.times do |y|
              next unless [x, y, SIDE - 1 - x, SIDE - 1 - y].min == d

              px(panel, face, x, y, rgb)
            end
          end
        end

        # Same on the top face (shortcut).
        def top_ring(panel, d, rgb)
          face_ring(panel, :top, d, rgb)
        end
      end
    end
  end
end
