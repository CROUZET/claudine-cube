# frozen_string_literal: true

require_relative "lib/event"
require_relative "lib/event_bus"
require_relative "lib/animation_manager"
require_relative "lib/config"
require_relative "lib/status"
require_relative "lib/runner"
require_relative "lib/connectors/claude_code"
require_relative "lib/connectors/admin_server"

config = Claudine::Config.new
status = Claudine::Status.new

# Boot with the persisted theme, guarding against a hand-edited unknown set.
theme = config.theme
unless Claudine::AnimationManager.available_sets.include?(theme)
  Claudine.logger.warn("claudine: unknown theme '#{theme}' — using '#{Claudine::AnimationManager::DEFAULT_SET}'")
  config.theme = theme = Claudine::AnimationManager::DEFAULT_SET
end

manager = Claudine::AnimationManager.new(set: theme)
runner = Claudine::Runner.new(manager:, config:, status:)

claude_code = Claudine::Connectors::ClaudeCode.new(bus: runner.bus, config:)
admin = Claudine::Connectors::AdminServer.new(config:, status:, bus: runner.bus)

begin
  claude_code.start
  admin.start
  runner.start
ensure
  admin.stop
  claude_code.stop
end
