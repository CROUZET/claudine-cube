# ============================================================
#  cube_mapping.rb  —  mapping logique du cube LED 5 x 8x8
# ============================================================
#
#  Chaîne physique relevée sur le montage :
#
#  Ordre des faces dans la chaîne :
#     0 = avant, 1 = droite, 2 = arrière, 3 = gauche, 4 = dessus
#  (64 LEDs par face : face F occupe les index 64*F .. 64*F+63)
#
#  Parcours DANS chaque face latérale (faces 0..3), identique :
#     origine coin BAS-GAUCHE, on monte une colonne entière
#     (row 0 -> 7), puis colonne suivante à droite.
#       index_local = col * 8 + row
#     avec row = 0 en bas, col = 0 à gauche.
#
#  Parcours de la face du DESSUS (face 4) :
#     origine coin HAUT-GAUCHE, on parcourt une ligne entière
#     vers la droite (col 0 -> 7), puis ligne en dessous.
#       index_local = (7 - row) * 8 + col
#     avec row = 0 en bas, col = 0 à gauche (même repère logique).
#
#  CONVENTION DE COORDONNÉES LOGIQUES (identique pour toutes les faces) :
#     - x = colonne, 0 = gauche  .. 7 = droite
#     - y = ligne,   0 = bas     .. 7 = haut
#   Ainsi une animation peut raisonner en (face, x, y) sans se
#   soucier du sens physique du câblage : tout est absorbé ici.
# ============================================================

module CubeMapping
  WIDTH       = 8
  HEIGHT      = 8
  PER_FACE    = WIDTH * HEIGHT      # 64
  FACES       = 5
  NUM_LEDS    = PER_FACE * FACES    # 320

  # Noms de faces -> numéro dans la chaîne
  FACE = {
    front: 0,   # avant
    right: 1,   # droite
    back:  2,   # arrière
    left:  3,   # gauche
    top:   4,   # dessus
  }.freeze

  # Index local (0..63) dans une face latérale (faces 0..3).
  # Colonne par colonne, chaque colonne de bas en haut.
  #   x = colonne (0 gauche), y = ligne (0 bas)
  def self.side_local(x, y)
    x * HEIGHT + y
  end

  # Index local (0..63) dans la face du dessus (face 4).
  # Ligne par ligne du haut vers le bas, chaque ligne de gauche à droite.
  #   x = colonne (0 gauche), y = ligne (0 bas)
  # La chaîne commence en HAUT (y = 7), d'où (7 - y).
  def self.top_local(x, y)
    (HEIGHT - 1 - y) * WIDTH + x
  end

  # Point d'entrée : (face, x, y) -> index global 0..319
  #   face : symbole (:front, :right, :back, :left, :top) ou entier 0..4
  #   x    : colonne 0..7 (0 = gauche)
  #   y    : ligne   0..7 (0 = bas)
  def self.index(face, x, y)
    f = face.is_a?(Symbol) ? FACE.fetch(face) : face
    raise ArgumentError, "face #{face} invalide"        unless (0..4).include?(f)
    raise ArgumentError, "x=#{x} hors bornes"           unless (0...WIDTH).include?(x)
    raise ArgumentError, "y=#{y} hors bornes"           unless (0...HEIGHT).include?(y)

    local = (f == FACE[:top]) ? top_local(x, y) : side_local(x, y)
    f * PER_FACE + local
  end
end

# ------------------------------------------------------------
#  Auto-test rapide : ruby cube_mapping.rb
#  Vérifie la cohérence avec le relevé physique.
# ------------------------------------------------------------
if __FILE__ == $PROGRAM_NAME
  m = CubeMapping

  checks = [
    # face avant : bas-gauche = 0, monte la 1re colonne, puis colonne suivante
    [:front, 0, 0,   0],
    [:front, 0, 1,   1],
    [:front, 0, 7,   7],
    [:front, 1, 0,   8],
    [:front, 7, 7,  63],
    # face droite : décalée de 64
    [:right, 0, 0,  64],
    [:right, 7, 7, 127],
    # face arrière
    [:back,  0, 0, 128],
    # face gauche
    [:left,  0, 0, 192],
    # face dessus : haut-gauche = premier index de la face (256)
    [:top,   0, 7, 256],   # coin haut-gauche
    [:top,   7, 7, 263],   # fin de la 1re ligne (haut-droite)
    [:top,   0, 6, 264],   # ligne en dessous, à gauche
    [:top,   7, 0, 319],   # coin bas-droite = dernière LED
  ]

  ok = true
  checks.each do |face, x, y, expected|
    got = m.index(face, x, y)
    status = (got == expected) ? "ok " : "XX "
    ok &&= (got == expected)
    puts "#{status} (#{face}, x=#{x}, y=#{y}) -> #{got}  (attendu #{expected})"
  end

  puts ok ? "\nTOUS LES TESTS PASSENT ✅" : "\nECHEC : revoir le mapping ❌"
end
