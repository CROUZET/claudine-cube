# frozen_string_literal: true

require_relative "handle"

module Claudine
  module Animations
    module Bunny
      # Task done: the same bunny as task_new (close-up profile) walks,
      # but in yellow, over only a half-turn of the cube, leaving a little
      # dropping (brown) at its starting position; then everything fades out.
      # Signature: the bunny does an about-turn and leaves a dropping, then fades away.
      class Handled < Handle
        COLOR = [255, 200, 0].freeze # yellow (end)
        CACA_C = [110, 55, 0].freeze # little dropping (brown)
        HALF = 16 # half-turn (16 columns out of 32)
        T_WALK = 2.5 # walks up to the half-turn then stops
        T_FADE = 1.2 # extinction
        MIN_DURATION = T_WALK + T_FADE
        DURATION = T_WALK + T_FADE

        # Little dropping at the starting position (front face, revealed when the
        # bunny moves away).
        CACA = [[1, 0], [2, 0], [3, 0], [2, 1]].freeze

        def render(t, panel)
          panel.clear
          fade = t < T_WALK ? 1.0 : (1.0 - ((t - T_WALK) / T_FADE)).clamp(0.0, 1.0)
          return if fade <= 0.0

          col = [t * SPEED, HALF].min # advances then stops at half-turn
          legs = (col / STEP).floor.even? ? LEGS_A : LEGS_B

          CACA.each { |x, y| px(panel, :front, x, y, dim(CACA_C, fade)) } # dropping at the start
          (BODY + legs).each { |dx, dy| ring_px(panel, col + dx, dy, dim(COLOR, fade)) }
        end
      end
    end
  end
end
