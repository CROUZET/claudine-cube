require_relative '_base'

module Claudine
  module Animations
    module Cube
      # Entrée utilisateur / « en attente » : une vague cyan MONTE le long des 4
      # faces latérales, puis se referme en anneaux concentriques vers le centre
      # du dessus. La vague se REJOUE EN BOUCLE (courte pause sombre entre deux
      # passages) tant qu'aucun autre event n'arrive — sert d'indicateur « ça
      # réfléchit » pendant le thinking, au lieu de laisser le cube éteint.
      # Signature : crête montante bas→haut, en anneaux vers l'intérieur, répétée.
      class UserPrompt < CubeBase
        MIN_DURATION = 0.6
        SPEED  = 16.0           # lignes/anneaux par seconde
        SPREAD = 2.0            # épaisseur de la crête
        PAUSE  = 0.5            # temps sombre entre deux vagues (secondes)
        COLOR  = [0, 180, 220]

        # Durée d'un passage complet : montée (SIDE lignes) + anneaux du dessus
        # (jusqu'à d=3) + l'épaisseur de crête, le tout converti en secondes.
        CYCLE = (SIDE + 3 + SPREAD) / SPEED + PAUSE

        def render(t, panel)
          panel.clear
          head = (t % CYCLE) * SPEED
          # Montée sur les 4 faces latérales (y = 0 bas .. 7 haut).
          SIDE.times do |y|
            k = 1.0 - (head - y).abs / SPREAD
            ring_row(panel, y, dim(COLOR, [k, 1.0].min)) if k > 0
          end
          # Arrivée sur le dessus : anneaux concentriques (d = 0 bord .. 3 centre)
          # qui se referment. Le bord (d=0) s'allume juste après la rangée haute.
          crest = head - SIDE
          4.times do |d|
            k = 1.0 - (crest - d).abs / SPREAD
            top_ring(panel, d, dim(COLOR, [k, 1.0].min)) if k > 0
          end
        end
      end
    end
  end
end
