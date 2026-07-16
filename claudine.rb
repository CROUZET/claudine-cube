require_relative 'lib/event'
require_relative 'lib/event_bus'
require_relative 'lib/animation_manager'
require_relative 'lib/runner'
require_relative 'lib/connectors/claude_code'

manager = Claudine::AnimationManager.new
runner  = Claudine::Runner.new(manager: manager)

claude_code = Claudine::Connectors::ClaudeCode.new(bus: runner.bus)
claude_code.start
begin
  runner.start
ensure
  claude_code.stop
end
