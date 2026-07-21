require_relative '_base'
require_relative 'user_prompt'

module Claudine
  module Animations
    module Bunny
      # After compaction: the merged bunny from pre_compact (the user_prompt
      # profile) appears, identical, on the 5 faces, blinks in yellow, then
      # fades out. Yellow (end event -> yellow). Short overlay.
      # Signature: the merged bunny blinking and fading out over the whole cube.
      class PostCompact < BunnyBase
        DUR   = 1.6                 # duration of the blinking + fade
        MIN_DURATION = DUR
        DURATION     = DUR
        COLOR = [255, 200, 0]       # yellow (end)
        BLINK = 0.25                # half-period of the blinking (s)

        RABBIT = UserPrompt::RABBIT  # merged bunny (profile)
        X = 2                        # centering (5 px wide)
        Y = 1

        def render(t, panel)
          panel.clear
          fade = (1.0 - t / DUR).clamp(0.0, 1.0)         # progressive fade
          return if fade <= 0.0
          return unless (t / BLINK).floor.even?          # blinking (off 1 phase out of 2)
          c = dim(COLOR, fade)
          ALL_FACES.each do |face|
            RABBIT.each { |dx, dy| px(panel, face, X + dx, Y + dy, c) }
          end
        end
      end
    end
  end
end
