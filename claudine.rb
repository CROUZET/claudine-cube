require_relative 'lib/event'
require_relative 'lib/event_bus'
require_relative 'lib/animation_manager'
require_relative 'lib/config'
require_relative 'lib/runner'
require_relative 'lib/connectors/claude_code'
require_relative 'lib/connectors/admin_server'

config  = Claudine::Config.new
manager = Claudine::AnimationManager.new
runner  = Claudine::Runner.new(manager: manager, config: config)

claude_code = Claudine::Connectors::ClaudeCode.new(bus: runner.bus, config: config)
admin       = Claudine::Connectors::AdminServer.new(config: config)

begin
  claude_code.start
  admin.start
  runner.start
ensure
  admin.stop
  claude_code.stop
end
