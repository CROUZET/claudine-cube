require_relative '_base'

module Claudine
  module Animations
    module Cube
      # Repos (aucun event depuis IDLE_TIMEOUT) : un anneau de 2 px à l'équateur
      # du cube (rangées 3,4 des 4 faces latérales) clignote doucement, puis
      # s'éteint progressivement jusqu'à extinction complète.
      #
      # Jouée UNE SEULE FOIS : clignotement doux pendant HOLD, puis extinction
      # monotone (FADE) sans pulsation résiduelle. Le manager éteint le cube à
      # DURATION.
      class SystemIdle < CubeBase
        ROWS     = [3, 4]                   # anneau de 2 px au milieu du cube
        PERIOD   = 1.6                      # clignotement lent et doux
        BLINKS   = 1                        # pulsations à pleine intensité
        HOLD     = BLINKS * PERIOD          # durée du clignotement plein
        FADE     = 2.0                      # extinction progressive, après HOLD
        DURATION = HOLD + FADE              # durée de vie totale (lue par le manager)
        COLOR    = [0, 120, 200]            # bleu doux (veille)
        LOW      = 0.1                      # creux du clignotement (glow, pas tout à fait éteint)

        def render(t, panel)
          panel.clear
          rgb = dim(COLOR, brightness(t))
          ROWS.each { |y| ring_row(panel, y, rgb) }
        end

        private

        # Deux phases enchaînées sans rupture :
        #  - HOLD : clignotement doux en cosinus (plein aux multiples de PERIOD,
        #    creux à LOW au milieu) → HOLD tombe pile sur un sommet (=1).
        #  - FADE : extinction monotone 1 → 0, ease cosinus (dérivée nulle aux
        #    deux bouts), donc pas de pulsation résiduelle ni de sursaut.
        def brightness(t)
          if t < HOLD
            LOW + (1.0 - LOW) * (0.5 + 0.5 * Math.cos(2 * Math::PI * t / PERIOD))
          else
            p = ((t - HOLD) / FADE).clamp(0.0, 1.0)
            0.5 + 0.5 * Math.cos(Math::PI * p)
          end
        end
      end
    end
  end
end
