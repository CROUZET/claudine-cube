require_relative '_base'

module Claudine
  module Animations
    module Cube
      # Après compaction : sur chaque face, deux fines lignes partent du centre et
      # S'ÉCARTENT vers les bords (haut et bas), sans trace derrière elles ; bref
      # fondu quand elles atteignent les bords.
      # Signature : expansion éphémère depuis le centre (inverse de pre_compact).
      class PostCompact < CubeBase
        MIN_DURATION = 1.0
        DUR    = 0.8            # durée de l'expansion
        FADE   = 0.3            # fondu final
        SPREAD = 1.3            # épaisseur des lignes
        COLOR  = [180, 180, 180]

        def render(t, panel)
          panel.clear
          return if t > DUR + FADE
          prog = [t / DUR, 1.0].min
          pos  = prog * 3.5                       # centre (0) -> bords (3.5)
          tail = t > DUR ? [1.0 - (t - DUR) / FADE, 0.0].max : 1.0
          ALL_FACES.each do |f|
            SIDE.times do |y|
              d = [(y - (3.5 - pos)).abs, (y - (3.5 + pos)).abs].min
              k = (1.0 - d / SPREAD) * tail
              next if k <= 0
              c = dim(COLOR, k)
              SIDE.times { |x| px(panel, f, x, y, c) }
            end
          end
        end
      end
    end
  end
end
