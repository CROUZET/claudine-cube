require_relative 'post_tool_fail'

module Claudine
  module Animations
    module Bunny
      # Fin de tour en échec : même animation que post_tool_fail — le lapin
      # mécontent (poings sur les hanches) qui tremble en rouge.
      class StopFailure < PostToolFail
      end
    end
  end
end
