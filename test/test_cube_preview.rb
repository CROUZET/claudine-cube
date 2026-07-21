# Preview on HARDWARE of all animations in the 'cube' set.
# Plays each hook ~2.5 s in sequence, at 30 fps, on the real cube.
# Handy to judge the rendering without triggering the real Claude Code hooks.
#
#   ruby test/test_cube_preview.rb
#   ruby test/test_cube_preview.rb post_tool user_prompt   # only those
#
# Close the serial monitor of the Arduino IDE before launching ("port busy").
require 'logger'
require_relative '../lib/panel'
require_relative '../lib/animation_manager'

Claudine.logger.level = ::Logger::WARN

# Reading order (plausible life cycle); completed by any missing hook.
ORDER = %i[
  session_start user_prompt pre_tool post_tool post_tool_fail
  subagent_start subagent_stop task_new task_done
  pre_compact post_compact notification stop stop_failure
  system_idle session_end
]

ENV['CLAUDINE_ANIMATION_SET'] ||= 'cube'   # overridable: CLAUDINE_ANIMATION_SET=bunny ruby ...
manager  = Claudine::AnimationManager.new
registry = manager.instance_variable_get(:@registry)

wanted = ARGV.map(&:to_sym)
hooks  = (ORDER + registry.keys).uniq
hooks &= wanted unless wanted.empty?

FPS = 30
DT  = 1.0 / FPS
DUR = 2.5

panel = Claudine::Panel.new
begin
  hooks.each do |hook|
    variants = registry[hook]
    next if variants.nil? || variants.empty?
    # Plays ALL the variants of the hook (not just the first), so
    # they can be compared. In operation, the manager picks one at random.
    variants.each do |klass|
      # An animation that declares its own lifetime (e.g. system_idle) is played
      # in full, otherwise we loop it over DUR seconds for the preview.
      dur = klass.const_defined?(:DURATION) ? [DUR, klass::DURATION].max : DUR
      label = variants.size > 1 ? "#{hook} (#{klass.name.split('::').last})" : hook.to_s
      puts format('▶  %-28s %.1fs', label, dur)
      anim = klass.new({})
      t = 0.0
      while t < dur
        anim.render(t, panel)
        panel.show
        sleep DT
        t += DT
      end
    end
  end
  puts "\nPreview done."
rescue Interrupt
  puts "\nInterrupted."
ensure
  panel.clear
  panel.show
  panel.close
end
