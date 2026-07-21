require_relative 'task_new'

module Claudine
  module Animations
    module Cube
      # Task done: same alternating concentric blinking as task_new
      # (inside / outside rings on the 5 faces), but in yellow. task_new and
      # task_done share the gesture; only the color distinguishes them.
      class TaskDone < TaskNew
        COLOR = [235, 200, 0]   # yellow (green for task_new)
      end
    end
  end
end
