require_relative '_base'

module Claudine
  module Animations
    module Bunny
      # "Thinking" (looping background): bunnies hop in a line around the
      # cube, along the ring of the 4 lateral faces, at different jump
      # heights. On the highest jumps, their head overflows onto the top
      # along the edge they cross. Solid light blue (working state). Loops
      # seamlessly.
      # Signature: small light-blue bunnies hopping around the cube.
      class Think < BunnyBase
        MIN_DURATION = 0.6
        COLOR   = [140, 200, 255]         # light blue
        SPEED   = 12.0                    # columns/second (around the cube)
        HOP_LEN = 8                       # length of one jump (columns) -- 32 = 4 jumps/turn
        HOP_H   = [3.0, 5.0, 4.0].freeze  # jump height per bunny (the top can go out)
        NB      = HOP_H.size              # number of staggered bunnies around the cube

        # Profile bunny sprite (increasing dx = walk direction). dy = row,
        # 0 = paws. Shape provided by the user.
        #   . . # . .
        #   . . . # .
        #   . . . # #
        #   . # # # #
        #   # # # # .
        #   # # # # .
        #   . # # . .
        RABBIT = [
                          [2, 6],                   # ear tip
                                  [3, 5],           # ear
                                  [3, 4], [4, 4],   # ear / head
                  [1, 3], [2, 3], [3, 3], [4, 3],   # head
          [0, 2], [1, 2], [2, 2], [3, 2],           # body
          [0, 1], [1, 1], [2, 1], [3, 1],           # body
                  [1, 0], [2, 0],                   # paws
        ].freeze

        def render(t, panel)
          panel.clear
          head = t * SPEED
          NB.times do |i|
            col    = head + i * (RING.to_f / NB)
            hop    = Math.sin(Math::PI * ((col % HOP_LEN) / HOP_LEN))  # arc 0..1
            base_y = hop * HOP_H[i]                                    # height specific to the bunny
            RABBIT.each { |dx, dy| plot(panel, col + dx, base_y + dy, COLOR) }
          end
        end

        private

        # Places a pixel on the lateral ring; if it goes past the top (y >= 8),
        # it overflows onto the top along the edge (top_edge_px), the overflow
        # row giving the perimeter ring (8 -> edge, 9+ -> interior).
        def plot(panel, col, yy, rgb)
          yi = yy.to_i
          if yi <= 7
            ring_px(panel, col, yy, rgb)
          else
            c    = col.to_i % RING
            face = LATERAL[c / SIDE]
            lx   = c % SIDE
            tx, ty = top_edge_px(face, lx, yi - 8)
            px(panel, :top, tx, ty, rgb) if tx
          end
        end
      end
    end
  end
end
