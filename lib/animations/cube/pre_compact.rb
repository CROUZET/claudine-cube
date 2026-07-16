require_relative '_base'

module Claudine
  module Animations
    module Cube
      # Avant compaction : sur chaque face, deux fines lignes partent des bords
      # (haut et bas) et CONVERGENT vers le centre, sans laisser de trace derrière
      # elles ; brève disparition en fondu quand elles se rejoignent.
      # Signature : convergence éphémère vers le centre.
      class PreCompact < CubeBase
        MIN_DURATION = 1.0
        DUR    = 0.8            # durée de la convergence
        FADE   = 0.3            # fondu final
        SPREAD = 1.3            # épaisseur des lignes
        COLOR  = [210, 210, 210]

        def render(t, panel)
          panel.clear
          return if t > DUR + FADE
          prog = [t / DUR, 1.0].min
          pos  = prog * 3.5                       # bords (0) -> centre (3.5)
          tail = t > DUR ? [1.0 - (t - DUR) / FADE, 0.0].max : 1.0
          ALL_FACES.each do |f|
            SIDE.times do |y|
              d = [(y - pos).abs, (y - (7 - pos)).abs].min
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
