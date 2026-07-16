require_relative '../base'

module Claudine
  module Animations
    module Cube
      # Faces et repères géométriques partagés.
      ALL_FACES = %i[front right back left top].freeze
      LATERAL   = %i[front right back left].freeze   # les 4 faces latérales
      SIDE      = 8                                   # côté d'une face
      RING      = LATERAL.size * SIDE                 # 32 colonnes autour du cube

      # Base commune aux animations du cube. Fournit des helpers de rendu
      # « volumétriques » : anneau autour des 4 faces latérales, pulsation,
      # remplissage par face. Chaque animation raisonne en (face, x, y) via le
      # Panel (le mapping physique est absorbé par CubeMapping).
      #
      # Convention : x = colonne (0 gauche), y = ligne (0 bas). La face :top
      # se raccorde à l'avant en y croissant (validé sur matériel).
      class CubeBase < Base
        def initialize(_payload = {})
        end

        private

        # Sinusoïde 0..1 de période `period` secondes.
        def wave(t, period)
          Math.sin(2 * Math::PI * t / period) * 0.5 + 0.5
        end

        # Multiplie une couleur par un facteur 0..1 (arrondi, borné).
        def dim(rgb, k)
          rgb.map { |c| (c * k).round.clamp(0, 255) }
        end

        def fill(panel, rgb)
          panel.fill(rgb[0], rgb[1], rgb[2])
        end

        def face_fill(panel, face, rgb)
          panel.fill_face(face, rgb[0], rgb[1], rgb[2])
        end

        # Un pixel logique sur une face (coordonnées coercées en entiers).
        def px(panel, face, x, y, rgb)
          xi = x.to_i
          yi = y.to_i
          return if xi < 0 || xi >= SIDE || yi < 0 || yi >= SIDE
          panel.set(face: face, x: xi, y: yi, r: rgb[0], g: rgb[1], b: rgb[2])
        end

        # Pixel sur l'« anneau » des 4 faces latérales : col 0..31 fait le tour
        # (front 0..7, right 8..15, back 16..23, left 24..31) et boucle.
        def ring_px(panel, col, y, rgb)
          c = col.to_i % RING
          px(panel, LATERAL[c / SIDE], c % SIDE, y, rgb)
        end

        # Remplit toute une ligne y de l'anneau (les 4 faces latérales).
        def ring_row(panel, y, rgb)
          RING.times { |col| ring_px(panel, col, y, rgb) }
        end

        # Correspondance colonne latérale -> pixel du bord du dessus.
        # Pour une face latérale et sa colonne locale x (0..7), renvoie [tx, ty]
        # sur l'anneau `ring` du dessus (0 = bordure, 1 = anneau intérieur).
        # Le parcours des 4 faces trace un tour complet du périmètre du dessus.
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

        # Anneau carré concentrique sur une face : d = distance au bord
        # (0 = bordure extérieure … 3 = carré central 2×2).
        def face_ring(panel, face, d, rgb)
          SIDE.times do |x|
            SIDE.times do |y|
              next unless [x, y, SIDE - 1 - x, SIDE - 1 - y].min == d
              px(panel, face, x, y, rgb)
            end
          end
        end

        # Idem sur la face du dessus (raccourci).
        def top_ring(panel, d, rgb)
          face_ring(panel, :top, d, rgb)
        end
      end
    end
  end
end
