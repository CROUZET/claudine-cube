require_relative '_base'

module Claudine
  module Animations
    module Cube
      # Variant of Think, played in REVERSE: the cyan wave is born at
      # the CENTER of the top, opens into concentric rings toward the border, then
      # DESCENDS along the 4 side faces (top->bottom). Like the original, it
      # replays in a loop (short dark pause) as long as no other event
      # arrives -- same "thinking" indicator role.
      #
      # The manager draws at random between Think and Think2 on each
      # user_prompt event (variant convention `_<digits>`), to avoid
      # repetition. Signature: descending crest center->border then top->bottom.
      class Think2 < CubeBase
        MIN_DURATION = 0.6
        SPEED  = 16.0           # rows/rings per second
        SPREAD = 2.0            # thickness of the crest
        PAUSE  = 0.5            # dark time between two waves (seconds)
        COLOR  = [0, 180, 220]

        # Duration of a full pass: top rings (center d=3 -> border d=0)
        # + descent (SIDE rows) + the crest thickness, converted to seconds.
        CYCLE = (3 + SIDE + SPREAD) / SPEED + PAUSE

        def render(t, panel)
          panel.clear
          head = (t % CYCLE) * SPEED
          # Opening on the top: rings from the center (d=3) toward the border (d=0).
          4.times do |d|
            k = 1.0 - (head - (3 - d)).abs / SPREAD
            top_ring(panel, d, dim(COLOR, [k, 1.0].min)) if k > 0
          end
          # Descent on the 4 side faces (y = 7 top .. 0 bottom), after
          # the crest has reached the border of the top.
          crest = head - 3
          SIDE.times do |y|
            k = 1.0 - (crest - (7 - y)).abs / SPREAD
            ring_row(panel, y, dim(COLOR, [k, 1.0].min)) if k > 0
          end
        end
      end
    end
  end
end
