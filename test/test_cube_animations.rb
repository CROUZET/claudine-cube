# Dry-run de toutes les animations du set 'cube' SANS matériel.
#
# Charge le set via l'AnimationManager, instancie chaque hook et appelle
# render(t, panel) sur un panel factice à plusieurs instants. Vérifie qu'aucune
# animation ne lève d'exception et n'écrit hors bornes. Utile en CI / avant flash.
#
#   ruby test/test_cube_animations.rb
require 'logger'
require_relative '../lib/animation_manager'

Claudine.logger.level = ::Logger::WARN

# Panel factice : valide les bornes comme le vrai Panel/CubeMapping.
class FakePanel
  FACES = %i[front right back left top]
  def initialize; @writes = 0; end
  attr_reader :writes
  def clear; end
  def fill(_r, _g, _b); end
  def fill_face(face, _r, _g, _b)
    raise "face invalide: #{face.inspect}" unless FACES.include?(face)
  end
  def set(face:, x:, y:, r:, g:, b:)
    raise "face invalide: #{face.inspect}" unless FACES.include?(face)
    raise "x hors bornes: #{x.inspect}" unless x.is_a?(Integer) && (0..7).include?(x)
    raise "y hors bornes: #{y.inspect}" unless y.is_a?(Integer) && (0..7).include?(y)
    [r, g, b].each { |c| raise "couleur invalide: #{c.inspect}" unless c.is_a?(Integer) && (0..255).include?(c) }
    @writes += 1
  end
end

ENV['CLAUDINE_ANIMATION_SET'] = 'cube'
manager  = Claudine::AnimationManager.new
registry = manager.instance_variable_get(:@registry)

TIMES = [0.0, 0.05, 0.2, 0.5, 1.0, 2.0, 5.0, 12.0]
ok = true

registry.sort_by { |hook, _| hook.to_s }.each do |hook, variants|
  variants.each do |klass|
    begin
      anim = klass.new({})
      panel = FakePanel.new
      TIMES.each { |t| anim.render(t, panel) }
      puts format('ok  %-16s %-28s (%d écritures)', hook, klass.name.split('::').last, panel.writes)
    rescue => e
      ok = false
      puts format('XX  %-16s %-28s -> %s', hook, klass.name.split('::').last, e.message)
    end
  end
end

puts "\n#{registry.size} hook(s) chargé(s)."
puts ok ? "TOUTES LES ANIMATIONS PASSENT ✅" : "ÉCHEC : voir ci-dessus ❌"
exit(ok ? 0 : 1)
