require_relative '_base'
require_relative 'user_prompt'

module Claudine
  module Animations
    module Bunny
      # Après compaction : le lapin fusionné de pre_compact (le profil de
      # user_prompt) apparaît, identique, sur les 5 faces, clignote en jaune,
      # puis s'éteint en fondu. Jaune (event de fin → jaune). Overlay court.
      # Signature : le lapin fusionné qui clignote et s'estompe sur tout le cube.
      class PostCompact < BunnyBase
        DUR   = 1.6                 # durée du clignotement + fondu
        MIN_DURATION = DUR
        DURATION     = DUR
        COLOR = [255, 200, 0]       # jaune (fin)
        BLINK = 0.25                # demi-période du clignotement (s)

        RABBIT = UserPrompt::RABBIT  # lapin fusionné (profil)
        X = 2                        # centrage (5 px de large)
        Y = 1

        def render(t, panel)
          panel.clear
          fade = (1.0 - t / DUR).clamp(0.0, 1.0)         # fondu progressif
          return if fade <= 0.0
          return unless (t / BLINK).floor.even?          # clignotement (éteint 1 phase / 2)
          c = dim(COLOR, fade)
          ALL_FACES.each do |face|
            RABBIT.each { |dx, dy| px(panel, face, X + dx, Y + dy, c) }
          end
        end
      end
    end
  end
end
