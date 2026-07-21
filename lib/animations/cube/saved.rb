require_relative 'save'

module Claudine
  module Animations
    module Cube
      # After compaction: same blinking 2x2 checkerboard as pre_compact, but in
      # yellow. pre_compact and post_compact share the gesture; only the color
      # distinguishes them (gray before, yellow after).
      class Saved < Save
        COLOR = [235, 200, 0]   # yellow
      end
    end
  end
end
