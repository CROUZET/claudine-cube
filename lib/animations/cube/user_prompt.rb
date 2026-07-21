require_relative '_base'

module Claudine
  module Animations
    module Cube
      # User input / "waiting": a cyan wave RISES along the 4
      # side faces, then closes into concentric rings toward the center
      # of the top. The wave REPLAYS IN A LOOP (short dark pause between two
      # passes) as long as no other event arrives -- serves as a "thinking"
      # indicator during thinking, instead of leaving the cube off.
      # Signature: rising crest bottom->top, in rings toward the inside, repeated.
      class UserPrompt < CubeBase
        MIN_DURATION = 0.6
        SPEED  = 16.0           # rows/rings per second
        SPREAD = 2.0            # thickness of the crest
        PAUSE  = 0.5            # dark time between two waves (seconds)
        COLOR  = [0, 180, 220]

        # Duration of a full pass: rise (SIDE rows) + top rings
        # (up to d=3) + the crest thickness, all converted to seconds.
        CYCLE = (SIDE + 3 + SPREAD) / SPEED + PAUSE

        def render(t, panel)
          panel.clear
          head = (t % CYCLE) * SPEED
          # Rise on the 4 side faces (y = 0 bottom .. 7 top).
          SIDE.times do |y|
            k = 1.0 - (head - y).abs / SPREAD
            ring_row(panel, y, dim(COLOR, [k, 1.0].min)) if k > 0
          end
          # Arrival on the top: concentric rings (d = 0 border .. 3 center)
          # that close in. The border (d=0) lights up just after the top row.
          crest = head - SIDE
          4.times do |d|
            k = 1.0 - (crest - d).abs / SPREAD
            top_ring(panel, d, dim(COLOR, [k, 1.0].min)) if k > 0
          end
        end
      end
    end
  end
end
