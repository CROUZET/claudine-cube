require_relative 'task_new'

module Claudine
  module Animations
    module Bunny
      # Tâche terminée : le même lapin que task_new (gros plan de profil) marche,
      # mais en jaune, sur un demi-tour du cube seulement, en laissant un petit
      # caca (brun) à sa position de départ ; puis tout s'éteint en fondu.
      # Signature : le lapin fait demi-tour et laisse une crotte, puis s'estompe.
      class TaskDone < TaskNew
        COLOR  = [255, 200, 0]     # jaune (fin)
        CACA_C = [110, 55, 0]      # petit caca (brun)
        HALF   = 16                # demi-tour (16 colonnes sur 32)
        T_WALK = 2.5               # marche jusqu'au demi-tour puis s'arrête
        T_FADE = 1.2               # extinction
        MIN_DURATION = T_WALK + T_FADE
        DURATION     = T_WALK + T_FADE

        # Petit caca à la position de départ (face avant, révélé quand le lapin
        # s'éloigne).
        CACA = [[1, 0], [2, 0], [3, 0], [2, 1]].freeze

        def render(t, panel)
          panel.clear
          fade = t < T_WALK ? 1.0 : (1.0 - (t - T_WALK) / T_FADE).clamp(0.0, 1.0)
          return if fade <= 0.0
          col  = [t * SPEED, HALF].min                       # avance puis s'arrête à mi-tour
          legs = (col / STEP).floor.even? ? LEGS_A : LEGS_B

          CACA.each { |x, y| px(panel, :front, x, y, dim(CACA_C, fade)) }   # crotte au départ
          (BODY + legs).each { |dx, dy| ring_px(panel, col + dx, dy, dim(COLOR, fade)) }
        end
      end
    end
  end
end
