# frozen_string_literal: true

require_relative "test_helper"
require "tmpdir"
require "fileutils"
require_relative "../lib/event"
require_relative "../lib/event_bus"
require_relative "../lib/config"
require_relative "../lib/status"
require_relative "../lib/animation_manager"
require_relative "../lib/runner"

# Runner: the per-frame `drive` decision — what plays when a source is active vs. off.
# The key contract: manual admin triggers still play one-shot with every integration off; ordinary source events don't.
# No hardware (drive never touches the serial Panel — a stub stands in).
class RunnerTest < Minitest::Test
  def setup
    ENV["CLAUDINE_ANIMATION_SET"] = "cube"
    @dir = Dir.mktmpdir
    @cfg = Claudine::Config.new(path: File.join(@dir, ".claudine"))
    @bus = Claudine::EventBus.new
    @mgr = Claudine::AnimationManager.new
    @runner = Claudine::Runner.new(manager: @mgr, bus: @bus, config: @cfg, status: Claudine::Status.new)
  end

  def teardown
    FileUtils.remove_entry(@dir) if @dir && File.exist?(@dir)
  end

  def drive(panel, t, active) = @runner.send(:drive, panel, t, active)
  def push(type, payload) = @bus.push(Claudine::Event.new(type:, payload:))

  def test_manual_trigger_plays_while_sources_off
    push(:think, { once: true })
    drive(TestPanels::Stub.new, 0.0, false)

    assert_predicate @mgr, :rendering? # the trigger's one-shot is up despite every source being off
  end

  def test_source_event_dropped_while_sources_off
    push(:pre_tool, {}) # an ordinary source event (no `once`)
    spy = TestPanels::ClearSpy.new
    drive(spy, 0.0, false)

    refute_predicate @mgr, :rendering? # dropped — nothing plays
    assert_predicate spy, :cleared? # cube kept dark
  end

  def test_one_shot_trigger_blanks_when_it_ends
    push(:think, { once: true, duration: 2.0 })
    drive(TestPanels::Stub.new, 0.0, false)

    assert_predicate @mgr, :rendering?

    spy = TestPanels::ClearSpy.new
    drive(spy, 5.0, false) # past the 2s custom duration, no new event

    refute_predicate @mgr, :rendering? # reverted to off
    assert_predicate spy, :cleared?
  end

  def test_source_event_plays_when_active
    push(:user_prompt, {})
    drive(TestPanels::Stub.new, 0.0, true)

    assert_predicate @mgr, :rendering? # ambient background is up
  end
end
