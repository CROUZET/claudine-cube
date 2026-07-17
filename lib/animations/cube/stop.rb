require_relative '_base'

module Claudine
  module Animations
    module Cube
      # Fin de tour (succès) : le cube s'affiche d'abord moucheté de SHADES
      # teintes de jaune (du clair au foncé, réparties aléatoirement), puis
      # s'éteint par teinte — tous les pixels d'une même teinte disparaissent
      # ensemble, à intervalle régulier (STEP), de la plus claire à la plus
      # foncée, jusqu'à extinction complète.
      # Signature : dissolution jaune par paliers, du clair vers le foncé.
      class Stop < CubeBase
        SHADES = 8                 # nombre de teintes (n), du clair au foncé
        STEP   = 0.3               # intervalle entre deux extinctions (s)
        LIGHT  = [255, 225, 70]    # jaune clair (première teinte, éteinte en 1er)
        DARK   = [90, 55, 0]       # jaune foncé (dernière teinte, éteinte en dernier)

        MIN_DURATION = SHADES * STEP   # joue jusqu'à extinction complète

        def initialize(_payload = {})
          # Palette clair → foncé, et affectation figée d'une teinte par pixel
          # (une seule fois : sinon le moucheté scintillerait à chaque frame).
          @palette = (0...SHADES).map { |i| mix(LIGHT, DARK, i.to_f / (SHADES - 1)) }
          @tint    = {}
          ALL_FACES.each do |face|
            SIDE.times do |x|
              SIDE.times { |y| @tint[[face, x, y]] = rand(SHADES) }
            end
          end
        end

        def render(t, panel)
          panel.clear
          gone = (t / STEP).floor   # teintes déjà éteintes (les plus claires d'abord)
          @tint.each do |(face, x, y), i|
            next if i < gone        # cette teinte a disparu
            rgb = @palette[i]
            px(panel, face, x, y, rgb)
          end
        end

        private

        # Interpolation linéaire entre deux couleurs (f : 0 → a, 1 → b).
        def mix(a, b, f)
          a.zip(b).map { |ca, cb| (ca + (cb - ca) * f).round.clamp(0, 255) }
        end
      end
    end
  end
end
