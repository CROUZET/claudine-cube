require_relative '_base'

module Claudine
  module Animations
    module Cube
      # Repos (aucun event depuis IDLE_TIMEOUT) : un chevron « > » de 3 LED
      # (pointe dans le sens de la marche) tourne autour du BAS du cube, sur les
      # 4 faces latérales, faisant TOURS tours complets (écran 1 → 4). Signature :
      # petit motif net qui file lentement au ras du socle.
      #
      # Jouée UNE SEULE FOIS : les tours se font à pleine luminosité, puis un
      # court fondu (FADE) et le manager éteint le cube (à DURATION).
      class SystemIdle < CubeBase
        TOURS    = 2                        # tours complets de l'anneau (≥ 1)
        SPEED    = 7.0                      # colonnes/seconde (lent, « en veille »)
        Y        = 1                        # hauteur du chevron (bas du cube : rangées 0..2)
        FADE     = 1.0                      # fondu de sortie, APRÈS les tours
        TRAVEL   = TOURS * RING / SPEED     # temps des tours à pleine luminosité
        DURATION = TRAVEL + FADE            # durée de vie totale (lue par le manager)
        COLOR    = [0, 120, 200]            # bleu doux
        ARM      = 0.5                      # luminosité relative des bras
        CHEVRONS = 6                        # nb de chevrons dans la comète (tête incluse)
        STEP     = 2                        # espacement entre chevrons (2 = le plus serré qui garde la forme « > » ; 1 fusionne les bras en lignes pleines)
        FALLOFF  = 0.55                     # décroissance de luminosité par chevron (<1 = dégradé marqué)

        def render(t, panel)
          panel.clear
          out = fade_out(t)
          col = t * SPEED                          # avance continue autour de l'anneau

          # Comète : la MÊME forme « > » répétée derrière la tête (>>>>>>),
          # chaque chevron plus faible que le précédent (dégradé exponentiel).
          # Dessinés du plus lointain (faible) au plus proche pour que la tête
          # reste nette au-dessus.
          (CHEVRONS - 1).downto(0) do |i|
            chevron(panel, col - i * STEP, out * (FALLOFF**i))
          end
        end

        # Un chevron « > » à la colonne `c` : pointe devant, deux bras en retrait.
        def chevron(panel, c, k)
          ring_px(panel, c,     Y,     dim(COLOR, k))
          ring_px(panel, c - 1, Y + 1, dim(COLOR, k * ARM))
          ring_px(panel, c - 1, Y - 1, dim(COLOR, k * ARM))
        end

        private

        # Pleine luminosité pendant les tours, puis fondu 1→0 sur les FADE
        # dernières secondes (garantit au moins TOURS tours complets visibles).
        def fade_out(t)
          return 1.0 if t < TRAVEL
          (1.0 - (t - TRAVEL) / FADE).clamp(0.0, 1.0)
        end
      end
    end
  end
end
