require_relative '_base'

module Claudine
  module Animations
    module Cube
      # Rest (no event since IDLE_TIMEOUT): a 2 px ring at the equator
      # of the cube (rows 3,4 of the 4 side faces) blinks gently, then
      # gradually turns off until fully off.
      #
      # Played ONCE ONLY: gentle blinking during HOLD, then monotone
      # extinction (FADE) with no residual pulsing. The manager turns the cube
      # off at DURATION.
      class SystemIdle < CubeBase
        ROWS     = [3, 4]                   # 2 px ring in the middle of the cube
        PERIOD   = 1.6                      # slow, gentle blinking
        BLINKS   = 1                        # pulses at full intensity
        HOLD     = BLINKS * PERIOD          # duration of the full blinking
        FADE     = 2.0                      # gradual extinction, after HOLD
        DURATION = HOLD + FADE              # total lifetime (read by the manager)
        COLOR    = [0, 120, 200]            # soft blue (standby)
        LOW      = 0.1                      # trough of the blink (glow, not quite off)

        def render(t, panel)
          panel.clear
          rgb = dim(COLOR, brightness(t))
          ROWS.each { |y| ring_row(panel, y, rgb) }
        end

        private

        # Two phases chained without a break:
        #  - HOLD: gentle cosine blinking (full at multiples of PERIOD,
        #    trough at LOW in the middle) -> HOLD lands exactly on a peak (=1).
        #  - FADE: monotone extinction 1 -> 0, cosine ease (zero derivative at
        #    both ends), so no residual pulsing and no jump.
        def brightness(t)
          if t < HOLD
            LOW + (1.0 - LOW) * (0.5 + 0.5 * Math.cos(2 * Math::PI * t / PERIOD))
          else
            p = ((t - HOLD) / FADE).clamp(0.0, 1.0)
            0.5 + 0.5 * Math.cos(Math::PI * p)
          end
        end
      end
    end
  end
end
