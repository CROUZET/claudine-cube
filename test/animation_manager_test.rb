# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/event"
require_relative "../lib/animation_manager"

# The two-layer model (background loop + one-shot overlays), the status snapshot, hot theme swap, direct-intention triggers, and one-shot play-once.
# No hardware.
class AnimationManagerTest < Minitest::Test
  THINK = %w[Think Think2].freeze # :think has random variants

  def setup
    ENV["CLAUDINE_ANIMATION_SET"] = "cube"
    @mgr = Claudine::AnimationManager.new
    @panel = TestPanels::Stub.new
  end

  # Emits an optional event then renders; returns the current animation's short name.
  def step(t, event = nil)
    @mgr.handle(Claudine::Event.new(type: event, payload: {}), t) if event
    @mgr.render(t, @panel)
    cur = @mgr.instance_variable_get(:@current)
    cur && cur.class.name.split("::").last
  end

  def test_working_state_model
    # read the real overlay durations off the (now-loaded) cube set
    pre = Claudine::Animations::Cube::Start::MIN_DURATION
    post = Claudine::Animations::Cube::Finish::MIN_DURATION
    t_pre = 1.0
    t_pre_revert = t_pre + pre + 0.3
    t_post = t_pre_revert + 0.5
    t_post_revert = t_post + post + 0.3
    t_stop = t_post_revert + 0.5

    assert_includes THINK, step(0.0, :user_prompt) # ambient background starts
    assert_includes THINK, step(0.3) # persists while thinking
    assert_equal "Start", step(t_pre, :pre_tool) # pulse overlay
    assert_equal "Start", step(t_pre + (pre * 0.5)) # still visible before expiry
    assert_includes THINK, step(t_pre_revert) # reverts to background
    assert_equal "Finish", step(t_post, :post_tool)
    assert_includes THINK, step(t_post_revert)
    assert_equal "Stop", step(t_stop, :stop) # boundary cuts the background
    assert_equal "Stop", step(t_stop + 2.0)
    assert_includes THINK, step(t_stop + 3.0, :user_prompt)
    refute_nil @mgr.instance_variable_get(:@background)
  end

  def test_status_snapshot
    step(0.0, :user_prompt)
    s = @mgr.status(0.5)

    assert_equal :working, s[:state]
    assert_includes THINK, s[:animation]
  end

  def test_reset_blanks_state
    step(0.0, :user_prompt)
    @mgr.reset

    assert_nil @mgr.instance_variable_get(:@current)
    assert_nil @mgr.instance_variable_get(:@background)
    assert_equal :blank, @mgr.status(100.0)[:state]
    assert_nil @mgr.status(100.0)[:animation]
  end

  def test_available_sets
    sets = Claudine::AnimationManager.available_sets

    assert_includes sets, "cube"
    assert_includes sets, "bunny"
  end

  def test_switch_set
    assert @mgr.switch_set("bunny")
    assert_equal "bunny", @mgr.set
    refute @mgr.switch_set("nope") # unknown ignored
    assert_equal "bunny", @mgr.set
  end

  def test_direct_intention_resolves_bypassing_profile
    assert_equal "Fork", step(0.0, :fork)
  end

  def test_trigger_plays_once_and_blanks
    @mgr.handle(Claudine::Event.new(type: :think, payload: { once: true }), 0.0)

    assert_nil @mgr.instance_variable_get(:@background) # never becomes a background
    assert_predicate @mgr, :rendering? # something is on screen
    spy = TestPanels::ClearSpy.new
    @mgr.render(5.0, spy) # well past the one-shot duration

    assert_nil @mgr.instance_variable_get(:@current) # blanked
    refute_predicate @mgr, :rendering?
    assert_predicate spy, :cleared? # buffer cleared, not left lit
  end

  def test_trigger_honors_custom_duration
    # A caller-supplied duration keeps the one-shot up for that long, overriding the animation's own.
    @mgr.handle(Claudine::Event.new(type: :fork, payload: { once: true, duration: 30.0 }), 0.0)
    @mgr.render(10.0, @panel) # long past Fork's natural duration, well before 30s

    assert_predicate @mgr, :rendering? # still up thanks to the custom duration

    @mgr.render(31.0, TestPanels::Stub.new)

    refute_predicate @mgr, :rendering? # blanked once the custom duration elapses
  end
end
