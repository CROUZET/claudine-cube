require_relative '_base'

module Claudine
  module Animations
    module Cube
      # Notification : clignotement ambre franc du cube entier (demande d'attention).
      # Signature : clignotement carré rapide (on/off net), très différent des
      # respirations et fondus.
      class Notification < CubeBase
        MIN_DURATION = 0.9
        RATE  = 3.0             # clignotements par seconde (approx)
        COLOR = [255, 130, 0]

        def render(t, panel)
          on = (t * RATE).to_i.even?
          fill(panel, on ? COLOR : dim(COLOR, 0.08))
        end
      end
    end
  end
end
