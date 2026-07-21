require_relative '_base'

module Claudine
  module Animations
    module Cube
      # Notification (complementary variant of Notification): only lights up
      # the 2nd ring (d=1) and the 4th central ring (d=3) of each face -- the
      # exact negative of Notification (d=0 + d=2), i.e. two concentric frames
      # nested in the gaps of the original.
      # Signature: fast, crisp square blinking (a "hollow" target).
      class Notification4 < CubeBase
        MIN_DURATION = 0.9
        RATE  = 3.0             # blinks per second (approx)
        COLOR = [255, 130, 0]
        RINGS = [1, 3]          # 2nd ring + 4th ring (central)

        def render(t, panel)
          panel.clear
          on = (t * RATE).to_i.even?
          rgb = on ? COLOR : dim(COLOR, 0.08)
          ALL_FACES.each do |face|
            RINGS.each { |d| face_ring(panel, face, d, rgb) }
          end
        end
      end
    end
  end
end
