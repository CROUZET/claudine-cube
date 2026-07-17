require_relative '_base'

module Claudine
  module Animations
    module Cube
      # Variante de UserPrompt, jouée en SENS INVERSE : la vague cyan naît au
      # CENTRE du dessus, s'ouvre en anneaux concentriques vers le bord, puis
      # DESCEND le long des 4 faces latérales (haut→bas). Comme l'originale, elle
      # se rejoue en boucle (courte pause sombre) tant qu'aucun autre event
      # n'arrive — même rôle d'indicateur « ça réfléchit ».
      #
      # Le manager tire au sort entre UserPrompt et UserPrompt2 à chaque event
      # user_prompt (convention de variantes `_<digits>`), pour éviter la
      # répétition. Signature : crête descendante centre→bord puis haut→bas.
      class UserPrompt2 < CubeBase
        MIN_DURATION = 0.6
        SPEED  = 16.0           # lignes/anneaux par seconde
        SPREAD = 2.0            # épaisseur de la crête
        PAUSE  = 0.5            # temps sombre entre deux vagues (secondes)
        COLOR  = [0, 180, 220]

        # Durée d'un passage complet : anneaux du dessus (centre d=3 → bord d=0)
        # + descente (SIDE lignes) + l'épaisseur de crête, converti en secondes.
        CYCLE = (3 + SIDE + SPREAD) / SPEED + PAUSE

        def render(t, panel)
          panel.clear
          head = (t % CYCLE) * SPEED
          # Ouverture sur le dessus : anneaux du centre (d=3) vers le bord (d=0).
          4.times do |d|
            k = 1.0 - (head - (3 - d)).abs / SPREAD
            top_ring(panel, d, dim(COLOR, [k, 1.0].min)) if k > 0
          end
          # Descente sur les 4 faces latérales (y = 7 haut .. 0 bas), après que
          # la crête a atteint le bord du dessus.
          crest = head - 3
          SIDE.times do |y|
            k = 1.0 - (crest - (7 - y)).abs / SPREAD
            ring_row(panel, y, dim(COLOR, [k, 1.0].min)) if k > 0
          end
        end
      end
    end
  end
end
