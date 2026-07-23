# frozen_string_literal: true

require_relative "retry"

module Claudine
  module Animations
    module Bunny
      # fail (turn ended on error): the same angry red shake as `retry`, but
      # SUSTAINED much longer -- rarer and graver than a recoverable retry, so
      # it lingers instead of being a brief blip.
      class Fail < Retry
        MIN_DURATION = 1.5
      end
    end
  end
end
