require_relative '_base'

module Claudine
  module Animations
    module Cube
      # After a tool (success): a crown of crenellations (rampart merlons) at
      # the base of the 4 side faces, rotating all the way around the cube. A
      # continuous base row (y=0) with teeth that rise (up to HEIGHT), a
      # pattern that scrolls around the cube. Same orange/amber as the snake
      # (pre_tool). Signature: a crenellated crown rotating at the base.
      class Finish < CubeBase
        MIN_DURATION = 0.8           # rotates for a short moment then hands back
        HEIGHT       = 2             # height of a merlon (px from bottom: y = 0,1)
        MERLON       = 3             # width of a merlon (upper part)
        PERIOD       = 4             # merlon + crenel (3 + 1 columns)
        SPEED        = 4.0           # columns per second (rotation)
        COLOR        = [190, 80, 0]  # = Start::HEAD (orange/amber of the snake)

        def render(t, panel)
          panel.clear
          shift = (t * SPEED).floor
          RING.times do |col|
            merlon = ((col + shift) % PERIOD) < MERLON
            h      = merlon ? HEIGHT : 1     # tooth (HEIGHT px) or base (1 px)
            h.times { |y| ring_px(panel, col, y, COLOR) }
          end
        end
      end
    end
  end
end
