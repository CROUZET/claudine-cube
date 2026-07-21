# Dry-run of all animations in the 'cube' set with NO hardware.
#
# Loads the set via the AnimationManager, instantiates each hook and calls
# render(t, panel) on a fake panel at several instants. Checks that no
# animation raises an exception and does not write out of bounds. Useful in CI / before flashing.
#
#   ruby test/test_cube_animations.rb
require 'logger'
require_relative '../lib/animation_manager'

Claudine.logger.level = ::Logger::WARN

# Fake panel: validates bounds like the real Panel/CubeMapping.
class FakePanel
  FACES = %i[front right back left top]
  def initialize; @writes = 0; end
  attr_reader :writes
  def clear; end
  def fill(_r, _g, _b); end
  def fill_face(face, _r, _g, _b)
    raise "invalid face: #{face.inspect}" unless FACES.include?(face)
  end
  def set(face:, x:, y:, r:, g:, b:)
    raise "invalid face: #{face.inspect}" unless FACES.include?(face)
    raise "x out of bounds: #{x.inspect}" unless x.is_a?(Integer) && (0..7).include?(x)
    raise "y out of bounds: #{y.inspect}" unless y.is_a?(Integer) && (0..7).include?(y)
    [r, g, b].each { |c| raise "invalid color: #{c.inspect}" unless c.is_a?(Integer) && (0..255).include?(c) }
    @writes += 1
  end
end

ENV['CLAUDINE_ANIMATION_SET'] ||= 'cube'   # overridable: CLAUDINE_ANIMATION_SET=bunny ruby ...
manager  = Claudine::AnimationManager.new
registry = manager.instance_variable_get(:@registry)

TIMES = [0.0, 0.05, 0.2, 0.5, 1.0, 2.0, 5.0, 12.0]
ok = true

registry.sort_by { |intention, _| intention.to_s }.each do |intention, variants|
  variants.each do |klass|
    begin
      anim = klass.new({})
      panel = FakePanel.new
      TIMES.each { |t| anim.render(t, panel) }
      puts format('ok  %-16s %-28s (%d writes)', intention, klass.name.split('::').last, panel.writes)
    rescue => e
      ok = false
      puts format('XX  %-16s %-28s -> %s', intention, klass.name.split('::').last, e.message)
    end
  end
end

puts "\n#{registry.size} intention(s) loaded."
puts ok ? "ALL ANIMATIONS PASS ✅" : "FAILURE: see above ❌"
exit(ok ? 0 : 1)
