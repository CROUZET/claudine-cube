# frozen_string_literal: true

module Claudine
  module Profiles
    # Maps Claude Code hook events (the raw <type> the connector POSTs) onto
    # intentions (see docs/INTENTIONS.md and lib/intentions.rb). This is *data*,
    # not code: adding another source (CI, a build tool, …) means writing a
    # profile like this one — the render path never changes.
    #
    # The 16 hooks map 1:1 onto the 16 intentions.
    CLAUDE_CODE = {
      session_start: :welcome,
      user_prompt: :think,
      pre_tool: :start,
      post_tool: :finish,
      task_new: :handle,
      task_done: :handled,
      subagent_start: :fork,
      subagent_stop: :join,
      notification: :wait,
      post_tool_fail: :retry,
      pre_compact: :save,
      post_compact: :saved,
      stop: :stop,
      stop_failure: :fail,
      session_end: :bye,
      system_idle: :sleep,
    }.freeze
  end
end
