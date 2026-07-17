require_relative '_base'

module Claudine
  module Animations
    module Cube
      # Après un outil (succès) : une couronne de créneaux (merlons de rempart)
      # à la base des 4 faces latérales, qui tourne tout le long du cube. Une
      # ligne de base continue (y=0) avec des dents qui montent (jusqu'à
      # HEIGHT), motif qui défile autour du cube. Même orange/ambré que le
      # serpent (pre_tool). Signature : couronne crénelée qui tourne à la base.
      class PostTool < CubeBase
        MIN_DURATION = 0.8           # tourne un court instant puis rend la main
        HEIGHT       = 2             # hauteur d'un merlon (px du bas : y = 0,1)
        MERLON       = 3             # largeur d'un merlon (partie haute)
        PERIOD       = 4             # merlon + créneau (3 + 1 colonnes)
        SPEED        = 4.0           # colonnes par seconde (rotation)
        COLOR        = [190, 80, 0]  # = PreTool::HEAD (orange/ambré du serpent)

        def render(t, panel)
          panel.clear
          shift = (t * SPEED).floor
          RING.times do |col|
            merlon = ((col + shift) % PERIOD) < MERLON
            h      = merlon ? HEIGHT : 1     # dent (HEIGHT px) ou base (1 px)
            h.times { |y| ring_px(panel, col, y, COLOR) }
          end
        end
      end
    end
  end
end
