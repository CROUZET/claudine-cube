# Checks the two-layer model of the AnimationManager (background "working" +
# one-shot overlays), with NO hardware. Simulates the sequence of Claude Code hooks and
# controls which animation is active at each instant.
#
#   ruby test/test_manager_states.rb
require 'logger'
require_relative '../lib/event'
require_relative '../lib/animation_manager'

Claudine.logger.level = ::Logger::WARN

class StubPanel
  def clear; end
  def fill(*); end
  def fill_face(*); end
  def set(**); end
end

ENV['CLAUDINE_ANIMATION_SET'] = 'cube'
mgr   = Claudine::AnimationManager.new
panel = StubPanel.new
ok    = true

# Plays one tick: possibly emits an event then renders. Returns the short name of
# the current animation.
def step(mgr, panel, t, event = nil)
  mgr.handle(Claudine::Event.new(type: event, payload: {}), t) if event
  mgr.render(t, panel)
  cur = mgr.instance_variable_get(:@current)
  cur ? cur.class.name.split('::').last : nil
end

def check(label, got, expected)
  good = expected.is_a?(Array) ? expected.include?(got) : (got == expected)
  puts format('%s %-52s got=%s', good ? 'ok ' : 'XX ', label, got.inspect)
  good
end

# The :think intention (← user_prompt) has several variants picked at random.
THINK = %w[Think Think2].freeze

# Real durations of the overlays, read on the classes (the scenario instants
# are derived from them with margin, to stay valid if an animation is tweaked).
# pre_tool → :start, post_tool → :finish (see lib/profiles/claude_code.rb).
PRE  = Claudine::Animations::Cube::Start::MIN_DURATION
POST = Claudine::Animations::Cube::Finish::MIN_DURATION

# Scenario: prompt → thinking → tool → thinking → tool → stop → new prompt
t_pre         = 1.0
t_pre_revert  = t_pre + PRE + 0.3          # after expiration of the pre_tool overlay
t_post        = t_pre_revert + 0.5
t_post_revert = t_post + POST + 0.3
t_stop        = t_post_revert + 0.5

ok &= check('user_prompt activates the background loop',
            step(mgr, panel, 0.0, :user_prompt), THINK)
ok &= check('background persists during thinking',
            step(mgr, panel, 0.3), THINK)
ok &= check('pre_tool = one-shot overlay',
            step(mgr, panel, t_pre, :pre_tool), 'Start')
ok &= check('pre_tool overlay still visible before expiration',
            step(mgr, panel, t_pre + PRE * 0.5), 'Start')
ok &= check('after the pre_tool, return to the user_prompt background',
            step(mgr, panel, t_pre_revert), THINK)
ok &= check('post_tool = one-shot overlay',
            step(mgr, panel, t_post, :post_tool), 'Finish')
ok &= check('after the post_tool, return to the user_prompt background',
            step(mgr, panel, t_post_revert), THINK)
ok &= check('stop cuts the background and displays itself',
            step(mgr, panel, t_stop, :stop), 'Stop')
ok &= check('stop persists (background cut, no overlay)',
            step(mgr, panel, t_stop + 2.0), 'Stop')
ok &= check('new user_prompt restarts the background loop',
            step(mgr, panel, t_stop + 3.0, :user_prompt), THINK)

# The background must indeed be nil after stop, and restored after the new prompt.
bg = mgr.instance_variable_get(:@background)
ok &= check('a background is active after the new prompt', !bg.nil?, true)

# reset (used by the Runner when all sources are off → the cube is blanked):
# clears current + background so a later resume starts blank, not mid-loop.
mgr.reset
ok &= check('reset clears @current',    mgr.instance_variable_get(:@current).nil?,    true)
ok &= check('reset clears @background', mgr.instance_variable_get(:@background).nil?, true)

puts ok ? "\nLAYER MODEL OK ✅" : "\nFAILURE ❌"
exit(ok ? 0 : 1)
