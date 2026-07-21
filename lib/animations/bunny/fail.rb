require_relative 'retry'

module Claudine
  module Animations
    module Bunny
      # End of turn on failure: same animation as post_tool_fail -- the angry
      # bunny (fists on hips) shaking in red.
      class Fail < Retry
      end
    end
  end
end
