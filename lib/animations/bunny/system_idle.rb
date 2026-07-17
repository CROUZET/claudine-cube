require_relative '_base'

module Claudine
  module Animations
    module Bunny
      # Veille (aucun event depuis IDLE_TIMEOUT) : sur les 4 faces latérales, un
      # lapin en « pain » (loaf, oreilles repliées) dort en respirant doucement,
      # avec des petites bulles qui remontent en zigzag et s'estompent au-dessus.
      # Après HOLD, tout s'éteint en fondu ; le manager coupe le cube à DURATION.
      # Signature : lapins endormis qui respirent, avec des bulles de sommeil.
      class SystemIdle < BunnyBase
        PERIOD   = 2.6                  # période de respiration (s)
        HOLD     = 4.0                  # sommeil visible avant le fondu
        FADE     = 2.0                  # extinction
        DURATION = HOLD + FADE          # durée de vie (lue par le manager)
        COLOR    = [80, 150, 220]       # bleu doux (veille)
        FACES    = %i[front right back left].freeze

        # Bulles de sommeil : petits points qui remontent en zigzag et s'estompent.
        NB_BUB = 3                      # nombre de bulles échelonnées
        RISE   = 3.9                    # durée de montée d'une bulle (s)
        AMP    = 1.0                    # amplitude du zigzag (px)
        ZIG    = 2.0                    # nombre d'oscillations pendant la montée
        BUB_X  = 6                      # colonne centrale des bulles (côté droit)

        # Lapin « loaf » (dx, dy ; 0 = bas) : forme ovale, oreilles repliées.
        #   . . # . . # . .   oreilles repliées
        #   . # # # # # # .
        #   # # # # # # # #   corps
        #   # # # # # # # #
        #   . # # # # # # .
        LOAF = [
                  [2, 4],                         [5, 4],
          [1, 3], [2, 3], [3, 3], [4, 3], [5, 3], [6, 3],
          [0, 2], [1, 2], [2, 2], [3, 2], [4, 2], [5, 2], [6, 2], [7, 2],
          [0, 1], [1, 1], [2, 1], [3, 1], [4, 1], [5, 1], [6, 1], [7, 1],
                  [1, 0], [2, 0], [3, 0], [4, 0], [5, 0], [6, 0],
        ].freeze

        def render(t, panel)
          panel.clear
          env    = t < HOLD ? 1.0 : (1.0 - (t - HOLD) / FADE).clamp(0.0, 1.0)
          return if env <= 0.0
          breath = 0.35 + 0.35 * wave(t, PERIOD)     # respiration 0.35..0.70
          loaf_c = dim(COLOR, breath * env)

          FACES.each do |face|
            LOAF.each { |x, y| px(panel, face, x, y, loaf_c) }
            NB_BUB.times do |i|
              ph = ((t / RISE) + i.to_f / NB_BUB) % 1.0        # 0..1 : la bulle monte
              bx = BUB_X + (AMP * Math.sin(ph * ZIG * 2 * Math::PI)).round  # zigzag
              by = (5 + ph * 5).round                          # y de 5 à 10 (déborde sur le dessus)
              bubble(panel, face, bx, by, dim(COLOR, (1.0 - ph) * env))     # s'estompe
            end
          end
        end

        private

        # Bulle : sur la face latérale ; au-delà du haut (y ≥ 8), passe sur le
        # pourtour du dessus le long de l'arête (top_edge_px).
        def bubble(panel, face, x, y, color)
          if y <= 7
            px(panel, face, x, y, color)
          else
            tx, ty = top_edge_px(face, x.clamp(0, 7), y - 8)
            px(panel, :top, tx, ty, color) if tx
          end
        end
      end
    end
  end
end
