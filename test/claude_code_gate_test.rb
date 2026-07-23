# frozen_string_literal: true

require_relative "test_helper"
require "net/http"
require "tmpdir"
require "fileutils"
require_relative "../lib/event"
require_relative "../lib/event_bus"
require_relative "../lib/config"
require_relative "../lib/connectors/claude_code"

# The ClaudeCode connector honors the integration gate: when the source is off
# in Config, POSTs still get a 204 but are dropped instead of pushed. No hardware.
class ClaudeCodeGateTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
    @cfg = Claudine::Config.new(path: File.join(@dir, ".claudine"))
    @bus = Claudine::EventBus.new
    @port = free_port
    @srv = Claudine::Connectors::ClaudeCode.new(bus: @bus, port: @port, config: @cfg)
    @srv.start
    30.times do
      post("warmup")
      break
    rescue Errno::ECONNREFUSED
      sleep 0.05
    end
    @bus.drain # discard the warm-up event
  end

  def teardown
    @srv&.stop
    FileUtils.remove_entry(@dir) if @dir && File.exist?(@dir)
  end

  def post(type) = Net::HTTP.new("127.0.0.1", @port).post("/event/#{type}", "")

  def test_enabled_pushes_event
    assert_equal "204", post("user_prompt").code
    assert_includes @bus.drain.map(&:type), :user_prompt
  end

  def test_disabled_drops_but_still_answers_204 # rubocop:disable Naming/VariableNumber
    @cfg.set_integration("claude_code", false)

    assert_equal "204", post("user_prompt").code
    assert_empty @bus.drain
  end

  def test_reenabled_pushes_again
    @cfg.set_integration("claude_code", false)
    @cfg.set_integration("claude_code", true)
    post("stop")

    assert_includes @bus.drain.map(&:type), :stop
  end
end
