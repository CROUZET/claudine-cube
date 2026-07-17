require_relative 'subagent_start'

module Claudine
  module Animations
    module Bunny
      # Fin d'un sous-agent : même geste que subagent_start mais en jaune et dans
      # l'ordre inverse — les 4 lapins commencent par faire le tour du cube en
      # sautant (4 sauts vers la droite), puis plongent dans leur terrier (pop
      # vers le bas). Jaune (event de fin → jaune). Overlay.
      # Signature : les lapins tournent en sautant puis disparaissent sous terre.
      class SubagentStop < SubagentStart
        COLOR = [255, 200, 0]   # jaune (fin)

        private

        # D'abord les sauts, puis la plongée dans le terrier.
        def pose(t, base)
          jt = JUMPS * JUMP_T
          if t < jt                                  # tour du cube en sautant
            total = t / JUMP_T
            p = total - total.floor
            [base + total * SIDE, Math.sin(Math::PI * p) * HOP_H]
          elsif t < jt + POP                         # plongée au terrier (0 → -5)
            p = (t - jt) / POP
            off = (-5 * (1.0 - ease_out_back(1.0 - p))).round
            [base + JUMPS * SIDE, off]
          else
            [base + JUMPS * SIDE, -5]                 # sous terre
          end
        end
      end
    end
  end
end
