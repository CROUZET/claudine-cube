# frozen_string_literal: true

require_relative "fork"

module Claudine
  module Animations
    module Bunny
      # Subagent stop: same gesture as subagent_start but in yellow and in
      # reverse order -- the 4 bunnies start by going around the cube
      # jumping (4 jumps to the right), then dive into their burrow (pop
      # downward). Yellow (end event -> yellow). Overlay.
      # Signature: the bunnies turn jumping then vanish underground.
      class Join < Fork
        COLOR = [255, 200, 0].freeze # yellow (end)

        private

        # First the jumps, then the dive into the burrow.
        def pose(t, base)
          jt = JUMPS * JUMP_T
          if t < jt                                  # around the cube jumping
            total = t / JUMP_T
            p = total - total.floor
            [base + (total * SIDE), Math.sin(Math::PI * p) * HOP_H]
          elsif t < jt + POP                         # dive into the burrow (0 -> -5)
            p = (t - jt) / POP
            off = (-5 * (1.0 - ease_out_back(1.0 - p))).round
            [base + (JUMPS * SIDE), off]
          else
            [base + (JUMPS * SIDE), -5] # underground
          end
        end
      end
    end
  end
end
