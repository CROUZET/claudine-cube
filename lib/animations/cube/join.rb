# frozen_string_literal: true

require_relative "_base"

module Claudine
  module Animations
    module Cube
      # A subagent finishes: the full central violet ring lights up then
      # fades off (the orbit closes). Signature: a full ring that fades.
      class Join < CubeBase
        MIN_DURATION = 0.7
        DUR   = 0.7
        COLOR = [160, 0, 220].freeze

        def render(t, panel)
          panel.clear
          c = dim(COLOR, [1.0 - (t / DUR), 0.0].max)
          ring_row(panel, 3, c)
          ring_row(panel, 4, c)
        end
      end
    end
  end
end
