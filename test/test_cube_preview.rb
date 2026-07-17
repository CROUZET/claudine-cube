# Aperçu sur MATÉRIEL de toutes les animations du set 'cube'.
# Joue chaque hook ~2,5 s à la suite, à 30 fps, sur le cube réel.
# Pratique pour juger le rendu sans déclencher les vrais hooks Claude Code.
#
#   ruby test/test_cube_preview.rb
#   ruby test/test_cube_preview.rb post_tool user_prompt   # seulement ceux-là
#
# Fermer le moniteur série de l'IDE Arduino avant de lancer (« port busy »).
require 'logger'
require_relative '../lib/panel'
require_relative '../lib/animation_manager'

Claudine.logger.level = ::Logger::WARN

# Ordre de lecture (cycle de vie plausible) ; complété par tout hook manquant.
ORDER = %i[
  session_start user_prompt pre_tool post_tool post_tool_fail
  subagent_start subagent_stop task_new task_done
  pre_compact post_compact notification stop stop_failure
  system_idle session_end
]

ENV['CLAUDINE_ANIMATION_SET'] = 'cube'
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
    # Joue TOUTES les variantes du hook (pas seulement la première), pour
    # pouvoir les comparer. En fonctionnement, le manager en tire une au hasard.
    variants.each do |klass|
      label = variants.size > 1 ? "#{hook} (#{klass.name.split('::').last})" : hook.to_s
      puts format('▶  %-28s', label)
      anim = klass.new({})
      t = 0.0
      while t < DUR
        anim.render(t, panel)
        panel.show
        sleep DT
        t += DT
      end
    end
  end
  puts "\nAperçu terminé."
rescue Interrupt
  puts "\nInterrompu."
ensure
  panel.clear
  panel.show
  panel.close
end
