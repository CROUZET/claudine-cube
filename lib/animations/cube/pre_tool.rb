require_relative '_base'

module Claudine
  module Animations
    module Cube
      # Avant un outil : un serpent jaune de 2 px de large traverse le cube.
      # Parcours (numérotation faces : 1 avant, 2 droite, 3 arrière, 4 gauche,
      # 5 dessus) : part du bas-milieu de l'avant, monte, passe par le dessus,
      # descend sur l'arrière jusqu'au milieu, vire à droite pour rejoindre la
      # face droite, la traverse jusqu'à son milieu, vire encore à droite et
      # remonte, repasse par le dessus, arrive sur la gauche et s'y éteint.
      # Signature : serpent lumineux unique qui « navigue » à travers le volume.
      class PreTool < CubeBase
        BODY  = 18             # longueur du serpent (en « rungs » de 2 px)
        SPEED = 30.0           # rungs par seconde
        HEAD  = [190, 80, 0]   # orange/ambré (tête)
        TAIL  = [28, 8, 0]     # ambré très sombre (queue)

        # Piste : liste ordonnée de « rungs », chaque rung = les 2 pixels
        # (largeur du serpent) allumés à une étape du parcours. Deux rungs
        # consécutifs sont adjacents sur le cube (traversées d'arêtes validées
        # par la géométrie de CubeMapping).
        def self.build_track
          t = []
          add = ->(face, a, b) { t << [[face, a[0], a[1]], [face, b[0], b[1]]] }

          # Trajet décalé d'1 px à gauche (colonnes 2,3 au lieu du centre 3,4) ;
          # les virages se font 1 px après le milieu (lignes/colonnes 2,3). Les
          # colonnes « miroir » (4,5) sur arrière/gauche découlent de la
          # continuité des arêtes dessus↔faces (voir CubeMapping).
          # 1. Avant : bas → haut (colonnes 2,3, décalées à gauche).
          (0..7).each { |y| add.call(:front, [2, y], [3, y]) }
          # 2. Dessus : proche → fond.
          (0..7).each { |y| add.call(:top, [2, y], [3, y]) }
          # 3. Arrière : haut → 1 px sous le milieu (colonnes 4,5 par continuité).
          [7, 6, 5, 4, 3].each { |y| add.call(:back, [4, y], [5, y]) }
          # 4. Arrière : virage, vers la face droite (lignes 2,3).
          [4, 3, 2, 1, 0].each { |x| add.call(:back, [x, 2], [x, 3]) }
          # 5. Droite : bord arrière → 1 px avant le milieu (lignes 2,3).
          [7, 6, 5, 4, 3].each { |x| add.call(:right, [x, 2], [x, 3]) }
          # 6. Droite : virage, remonte (colonnes 2,3).
          [3, 4, 5, 6, 7].each { |y| add.call(:right, [2, y], [3, y]) }
          # 7. Dessus : droite → gauche (lignes 2,3).
          7.downto(0).each { |x| add.call(:top, [x, 2], [x, 3]) }
          # 8. Gauche : haut → bas, puis disparaît (colonnes 4,5 par continuité).
          7.downto(0).each { |y| add.call(:left, [4, y], [5, y]) }

          t
        end

        TRACK        = build_track
        MIN_DURATION = (TRACK.size + BODY) / SPEED   # joue tout le parcours
        DURATION     = MIN_DURATION                  # durée de vie (lue par l'aperçu)

        def render(t, panel)
          panel.clear
          head = t * SPEED
          BODY.times do |i|
            pos = (head - i).floor
            next if pos < 0 || pos >= TRACK.size
            f   = BODY == 1 ? 0.0 : i.to_f / (BODY - 1)   # 0 tête … 1 queue
            rgb = mix(HEAD, TAIL, f)
            TRACK[pos].each { |(face, x, y)| px(panel, face, x, y, rgb) }
          end
        end

        private

        # Interpolation linéaire entre deux couleurs (f : 0 → a, 1 → b).
        def mix(a, b, f)
          a.zip(b).map { |ca, cb| (ca + (cb - ca) * f).round.clamp(0, 255) }
        end
      end
    end
  end
end
