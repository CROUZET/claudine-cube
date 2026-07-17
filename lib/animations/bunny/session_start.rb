require_relative '_base'

module Claudine
  module Animations
    module Bunny
      # Éveil : des lapins apparaissent sur 4 faces, colorés par l'arc-en-ciel
      # CHAUD du session_start cube (teinte selon la diagonale d=X+Y+Z du cube).
      #  - avant (1) + arrière (3) : modèle A (oreilles droites), en symétrie
      #    miroir ; les oreilles se dressent puis un clin d'œil (œil gauche).
      #  - droite (2) + gauche (4) : modèle B (oreilles écartées), en symétrie.
      # (Le dessus reste vide pour l'instant.)
      # Signature : lapins qui se réveillent tout autour de la façade.
      class SessionStart < BunnyBase
        RISE     = 0.7            # apparition + montée des oreilles (s)
        TOP_FILL = 2.0            # remplissage du loader sur le dessus (s)
        MIN_DURATION = 1.4
        DURATION     = 4.0        # durée montrée par l'aperçu (voir 2 clignements)

        # Palette chaude, identique au session_start cube : teinte le long de la
        # diagonale d=0..DMAX (jaune-orangé → rouge → magenta).
        DMAX = 21
        HUE0 = 0.15
        HUE1 = -0.18

        BLINK_PERIOD = 2.6        # temps entre deux clignements (s)
        BLINK_DUR    = 0.14       # durée paupière fermée (s)
        BLINK_OFFSET = 1.3        # cale le 1er clignement peu après l'éveil

        # --- Modèle A : lapin frontal, oreilles droites, pleine largeur. ---
        # Corps + tête (sans oreilles). Yeux (x=2,5 en y=3) laissés éteints.
        A_BODY = [
          [0, 4], [1, 4], [2, 4], [3, 4], [4, 4], [5, 4], [6, 4], [7, 4],
          [0, 3], [1, 3],         [3, 3], [4, 3],         [6, 3], [7, 3],
          [0, 2], [1, 2], [2, 2], [3, 2], [4, 2], [5, 2], [6, 2], [7, 2],
                  [1, 1], [2, 1], [3, 1], [4, 1], [5, 1], [6, 1],
                          [2, 0], [3, 0], [4, 0], [5, 0],
        ].freeze
        A_EARS = [1, 2, 5, 6].freeze  # oreilles droites (montent de y=5 à y=7)
        A_WINK = [2, 3].freeze        # œil qui cligne (gauche)

        # --- Modèle B : lapin aux oreilles écartées (en V). ---
        B_BODY = [
          [0, 7],                                                 [7, 7],
          [0, 6], [1, 6],                                 [6, 6], [7, 6],
                  [1, 5], [2, 5],                 [5, 5], [6, 5],
                  [1, 4], [2, 4], [3, 4], [4, 4], [5, 4], [6, 4],
                  [1, 3],         [3, 3], [4, 3],         [6, 3],
                  [1, 2], [2, 2], [3, 2], [4, 2], [5, 2], [6, 2],
                          [2, 1], [3, 1], [4, 1], [5, 1],
                          [2, 0], [3, 0], [4, 0], [5, 0],
        ].freeze

        # --- Dessus : chemin du loader sur les 2 anneaux extérieurs. ---
        # Un anneau carré d parcouru dans le sens horaire (boucle fermée).
        def self.ring_path(d)
          lo = d
          hi = 7 - d
          path = []
          (lo..hi).each        { |x| path << [x, lo] }   # bas : gauche → droite
          ((lo + 1)..hi).each  { |y| path << [hi, y] }   # droite : bas → haut
          (hi - 1).downto(lo).each     { |x| path << [x, hi] }  # haut : droite → gauche
          (hi - 1).downto(lo + 1).each { |y| path << [lo, y] }  # gauche : haut → bas
          path
        end

        # Spirale : tour extérieur (d=0) puis tour intérieur (d=1).
        TOP_PATH = (ring_path(0) + ring_path(1)).freeze

        def render(t, panel)
          panel.clear
          k       = [t / RISE, 1.0].min      # fondu d'apparition 0 → 1
          ear_top = 4 + (k * 3).round
          wink    = t >= RISE && blinking?(t)

          # Modèle A : avant (1) + arrière (3), symétrie miroir.
          draw_a(panel, :front, k, ear_top, wink, false)
          draw_a(panel, :back,  k, ear_top, wink, true)
          # Modèle B : droite (2) + gauche (4), symétrie miroir.
          blit(panel, :right, B_BODY, k, false)
          blit(panel, :left,  B_BODY, k, true)
          # Dessus : loader cumulatif sur le pourtour (2 anneaux extérieurs).
          draw_top_loader(panel, t)
        end

        private

        def blinking?(t)
          ((t + BLINK_OFFSET) % BLINK_PERIOD) < BLINK_DUR
        end

        # Dessine le modèle A (corps + oreilles montantes + éventuel clin d'œil).
        def draw_a(panel, face, k, ear_top, wink, mirror)
          blit(panel, face, A_BODY, k, mirror)
          A_EARS.each { |x| (5..ear_top).each { |y| put(panel, face, x, y, k, mirror) } }
          put(panel, face, A_WINK[0], A_WINK[1], k, mirror) if wink
        end

        # Dessine une liste de pixels sur une face, en miroir horizontal si demandé.
        def blit(panel, face, pixels, k, mirror)
          pixels.each { |x, y| put(panel, face, x, y, k, mirror) }
        end

        # Allume un pixel avec la teinte chaude correspondant à sa position 3D,
        # atténuée par k (fondu). Le miroir s'applique sur la colonne.
        def put(panel, face, x, y, k, mirror)
          dx = mirror ? 7 - x : x
          px(panel, face, dx, y, warm(face, dx, y, k))
        end

        # Loader : remplit cumulativement le chemin du dessus jusqu'à la tête,
        # qui avance sur TOP_FILL secondes (puis reste plein).
        def draw_top_loader(panel, t)
          path = top_path
          n    = ((t / TOP_FILL).clamp(0.0, 1.0) * path.size).floor
          path.first(n).each { |x, y| px(panel, :top, x, y, warm(:top, x, y, 1.0)) }
        end

        # Ordre de parcours du loader (surchargé par SessionEnd pour l'inverser).
        def top_path
          TOP_PATH
        end

        # Teinte selon la position 3D et la palette (HUE0..HUE1 de la classe),
        # atténuée par k. Chaude par défaut ; froide pour SessionEnd.
        def warm(face, x, y, k)
          wx, wy, wz = world(face, x, y)
          d   = wx + wy + wz
          hue = (self.class::HUE0 + (d.to_f / DMAX) * (self.class::HUE1 - self.class::HUE0)) % 1.0
          dim(hsv(hue), k)
        end

        # Coordonnées monde (X gauche→droite, Y avant→arrière, Z bas→haut).
        def world(face, x, y)
          case face
          when :front then [x,     0,     y]
          when :right then [7,     x,     y]
          when :back  then [7 - x, 7,     y]
          when :left  then [0,     7 - x, y]
          when :top   then [x,     y,     7]
          end
        end

        # HSV (h 0..1, s=v=1) -> [r, g, b] plein (0..255).
        def hsv(h)
          i = (h * 6.0).floor
          f = h * 6.0 - i
          q = 1.0 - f
          r, g, b = case i % 6
                    when 0 then [1.0, f,   0.0]
                    when 1 then [q,   1.0, 0.0]
                    when 2 then [0.0, 1.0, f]
                    when 3 then [0.0, q,   1.0]
                    when 4 then [f,   0.0, 1.0]
                    else        [1.0, 0.0, q]
                    end
          [(r * 255).round, (g * 255).round, (b * 255).round]
        end
      end
    end
  end
end
