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
  good = expected.is_a?(Array) ? expected.include?(got) : (got == expected)
  puts format('%s %-52s got=%s', good ? 'ok ' : 'XX ', label, got.inspect)
  good
end

# La famille user_prompt a plusieurs variantes tirées au hasard par le manager.
USER_PROMPT = %w[UserPrompt UserPrompt2].freeze

# Durées réelles des overlays, lues sur les classes (les instants du scénario
# en sont dérivés avec marge, pour rester valides si on retouche une anim).
PRE  = Claudine::Animations::Cube::PreTool::MIN_DURATION
POST = Claudine::Animations::Cube::PostTool::MIN_DURATION

# Scénario : prompt → thinking → outil → thinking → outil → stop → nouveau prompt
t_pre         = 1.0
t_pre_revert  = t_pre + PRE + 0.3          # après expiration de l'overlay pre_tool
t_post        = t_pre_revert + 0.5
t_post_revert = t_post + POST + 0.3
t_stop        = t_post_revert + 0.5

ok &= check('user_prompt active la boucle de fond',
            step(mgr, panel, 0.0, :user_prompt), USER_PROMPT)
ok &= check('fond persiste pendant le thinking',
            step(mgr, panel, 0.3), USER_PROMPT)
ok &= check('pre_tool = overlay ponctuel',
            step(mgr, panel, t_pre, :pre_tool), 'PreTool')
ok &= check('overlay pre_tool encore visible avant expiration',
            step(mgr, panel, t_pre + PRE * 0.5), 'PreTool')
ok &= check('après le pre_tool, retour au fond user_prompt',
            step(mgr, panel, t_pre_revert), USER_PROMPT)
ok &= check('post_tool = overlay ponctuel',
            step(mgr, panel, t_post, :post_tool), 'PostTool')
ok &= check('après le post_tool, retour au fond user_prompt',
            step(mgr, panel, t_post_revert), USER_PROMPT)
ok &= check('stop coupe le fond et s\'affiche',
            step(mgr, panel, t_stop, :stop), 'Stop')
ok &= check('stop persiste (fond coupé, pas d\'overlay)',
            step(mgr, panel, t_stop + 2.0), 'Stop')
ok &= check('nouveau user_prompt relance la boucle de fond',
            step(mgr, panel, t_stop + 3.0, :user_prompt), USER_PROMPT)

# Le fond doit bien être nul après stop, et rétabli après le nouveau prompt.
bg = mgr.instance_variable_get(:@background)
ok &= check('un fond est actif après le nouveau prompt', !bg.nil?, true)

puts ok ? "\nMODÈLE DE COUCHES OK ✅" : "\nÉCHEC ❌"
exit(ok ? 0 : 1)
