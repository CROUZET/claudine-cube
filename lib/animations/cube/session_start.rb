require_relative '_base'

module Claudine
  module Animations
    module Cube
      # Le cube s'éveille : un arc-en-ciel de couleurs chaudes balaie tout le
      # volume en diagonale (coin bas-avant-gauche → coin haut-arrière-droit),
      # atteint le plein, puis reflue et s'éteint depuis le coin opposé. Une
      # vague montante puis descendante, sur les 5 faces.
      #
      # Signature (daltonien-safe) : la vague diagonale qui enveloppe puis vide
      # tout le volume est unique ; la palette chaude (jaune→rouge→magenta) la
      # distingue de session_end (froide) — mouvement ET température, pas la
      # seule teinte.
      class SessionStart < CubeBase
        UP           = 2.4          # durée du remplissage (s)
        DOWN         = 2.0          # durée du reflux (s)
        MIN_DURATION = UP + DOWN    # tenir le lock pendant toute la vague
        DURATION     = UP + DOWN    # durée de vie complète (lue par l'aperçu)
        DMAX         = 21           # d max = (7 + 7 + 7), coin opposé
        EDGE         = 3.5          # épaisseur du front lumineux (en unités de d)
        SPAN         = DMAX + 2 * EDGE

        # Plage de teintes (h 0..1) étalée le long de la diagonale d=0..DMAX.
        # Chaud : jaune-orangé (0.15) → rouge (0.0) → magenta (-0.18 ≡ 0.82).
        # La sous-classe SessionEnd surcharge ces bornes pour une palette froide.
        HUE0 = 0.15
        HUE1 = -0.18

        def render(t, panel)
          panel.clear
          front = front_at(t)

          ALL_FACES.each do |face|
            SIDE.times do |x|
              SIDE.times do |y|
                wx, wy, wz = world(face, x, y)
                d = wx + wy + wz

                # Luminosité : plein derrière le front, fondu sur EDGE au front.
                b = ((front - d) / EDGE).clamp(0.0, 1.0)
                next if b <= 0.0

                hue = (self.class::HUE0 + (d.to_f / DMAX) * (self.class::HUE1 - self.class::HUE0)) % 1.0
                px(panel, face, x, y, dim(hsv(hue), b))
              end
            end
          end
        end

        private

        # Position du front : monte de -EDGE à DMAX+EDGE sur UP (remplissage),
        # puis redescend jusqu'à -EDGE sur DOWN (reflux, coin opposé d'abord).
        def front_at(t)
          if t <= UP
            -EDGE + (t / UP).clamp(0.0, 1.0) * SPAN
          else
            (DMAX + EDGE) - ((t - UP) / DOWN).clamp(0.0, 1.0) * SPAN
          end
        end

        # Coordonnées monde (X gauche→droite, Y avant→arrière, Z bas→haut),
        # 0..7 sur chaque axe, à partir de (face, x=col, y=ligne).
        def world(face, x, y)
          case face
          when :front then [x,     0,     y]
          when :right then [7,     x,     y]
          when :back  then [7 - x, 7,     y]
          when :left  then [0,     7 - x, y]
          when :top   then [x,     y,     7]
          end
        end

        # HSV (h 0..1, s=v=1) -> [r, g, b] plein (0..255). Arc-en-ciel saturé.
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
