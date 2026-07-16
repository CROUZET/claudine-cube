# Vérifie le modèle deux couches de l'AnimationManager (fond « au travail » +
# overlays ponctuels), SANS matériel. Simule la séquence de hooks Claude Code et
# contrôle quelle animation est active à chaque instant.
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

# Joue un tick : émet éventuellement un event puis rend. Renvoie le nom court de
# l'animation courante.
def step(mgr, panel, t, event = nil)
  mgr.handle(Claudine::Event.new(type: event, payload: {}), t) if event
  mgr.render(t, panel)
  cur = mgr.instance_variable_get(:@current)
  cur ? cur.class.name.split('::').last : nil
end

def check(label, got, expected)
  good = (got == expected)
  puts format('%s %-52s got=%s', good ? 'ok ' : 'XX ', label, got.inspect)
  good
end

# Scénario : prompt → thinking → outil → thinking → outil → stop → nouveau prompt
ok &= check('user_prompt active la boucle de fond',
            step(mgr, panel, 0.0, :user_prompt), 'UserPrompt')
ok &= check('fond persiste pendant le thinking',
            step(mgr, panel, 0.3), 'UserPrompt')
ok &= check('pre_tool = overlay ponctuel',
            step(mgr, panel, 1.0, :pre_tool), 'PreTool')
ok &= check('overlay pre_tool encore visible avant expiration',
            step(mgr, panel, 1.3), 'PreTool')
ok &= check('après le pre_tool, retour au fond user_prompt',
            step(mgr, panel, 1.7), 'UserPrompt')
ok &= check('post_tool = overlay ponctuel',
            step(mgr, panel, 2.0, :post_tool), 'PostTool')
ok &= check('après le post_tool, retour au fond user_prompt',
            step(mgr, panel, 2.7), 'UserPrompt')
ok &= check('stop coupe le fond et s\'affiche',
            step(mgr, panel, 3.0, :stop), 'Stop')
ok &= check('stop persiste (fond coupé, pas d\'overlay)',
            step(mgr, panel, 5.0), 'Stop')
ok &= check('nouveau user_prompt relance la boucle de fond',
            step(mgr, panel, 6.0, :user_prompt), 'UserPrompt')

# Le fond doit bien être nul après stop, et rétabli après le nouveau prompt.
bg = mgr.instance_variable_get(:@background)
ok &= check('un fond est actif après le nouveau prompt', !bg.nil?, true)

puts ok ? "\nMODÈLE DE COUCHES OK ✅" : "\nÉCHEC ❌"
exit(ok ? 0 : 1)
