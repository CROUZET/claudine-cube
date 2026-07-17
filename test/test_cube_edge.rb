# Calage / vérification des ARÊTES du cube (CLAUDE.md §4).
#
# Chaque arête partagée par 2 faces est allumée SUR SES DEUX FACES, pixels 2→6
# (les 5 du milieu, on laisse les coins pour éviter la confusion là où 3 faces
# se rejoignent), dans une couleur propre à chaque arête. Les deux pixels de
# même indice de part et d'autre d'une arête sont physiquement le MÊME point du
# cube.
#
# LECTURE, cube posé sur la table :
#   - Sur chaque arête, les deux faces doivent montrer une SEULE bande continue
#     de la bonne couleur, alignée pixel à pixel au passage de la couture.
#   - Si, sur une arête, la bande d'une face est décalée / inversée / sur la
#     mauvaise rangée par rapport à l'autre face → le mapping de cette arête est
#     à corriger.
#
# Les 4 arêtes latérales↔latérales sont sûres (mapping relevé). L'arête
# avant→dessus est calée. Les 3 autres arêtes dessus↔latérales (droite/arrière/
# gauche) sont à vérifier ici ; si l'une décale, ajuster `top_local` dans
# lib/cube_mapping.rb puis relancer.
#
# Fermer le moniteur série de l'IDE Arduino avant de lancer (« port busy »).
require 'logger'
require_relative '../lib/panel'

Claudine.logger.level = ::Logger::DEBUG

RED     = [90,  0,  0]
GREEN   = [ 0, 90,  0]
BLUE    = [ 0,  0, 90]
YELLOW  = [90, 90,  0]
MAGENTA = [90,  0, 90]
CYAN    = [ 0, 90, 90]
ORANGE  = [90, 40,  0]
WHITE   = [90, 90, 90]

E = (2..6).to_a   # pixels 2 à 6 le long de l'arête

# [nom, couleur, pixels face A, pixels face B] — A[i] et B[i] = même point.
EDGES = [
  ['avant→droite',  RED,     E.map { |i| [:front, 7, i] }, E.map { |i| [:right, 0, i] }],
  ['droite→arrière', GREEN,  E.map { |i| [:right, 7, i] }, E.map { |i| [:back,  0, i] }],
  ['arrière→gauche', BLUE,   E.map { |i| [:back,  7, i] }, E.map { |i| [:left,  0, i] }],
  ['gauche→avant',  YELLOW,  E.map { |i| [:left,  7, i] }, E.map { |i| [:front, 0, i] }],
  ['avant→dessus',  MAGENTA, E.map { |i| [:front, i, 7] }, E.map { |i| [:top,   i,     0] }],
  ['droite→dessus', CYAN,    E.map { |i| [:right, i, 7] }, E.map { |i| [:top,   7,     i] }],
  ['arrière→dessus', ORANGE, E.map { |i| [:back,  i, 7] }, E.map { |i| [:top,   7 - i, 7] }],
  ['gauche→dessus', WHITE,   E.map { |i| [:left,  i, 7] }, E.map { |i| [:top,   0,     7 - i] }],
].freeze

panel = Claudine::Panel.new
EDGES.each do |_name, col, a, b|
  (a + b).each { |face, x, y| panel.set(face: face, x: x, y: y, r: col[0], g: col[1], b: col[2]) }
end
panel.show

puts "\nArêtes (pixels 2→6 des deux côtés, une couleur par arête) :"
NAMES = { RED => 'ROUGE', GREEN => 'VERT', BLUE => 'BLEU', YELLOW => 'JAUNE',
          MAGENTA => 'MAGENTA', CYAN => 'CYAN', ORANGE => 'ORANGE', WHITE => 'BLANC' }.freeze
EDGES.each { |name, col, _a, _b| puts format('  %-16s -> %s', name, NAMES[col]) }
puts <<~MSG

  À confirmer sur le cube :
    - chaque arête = UNE bande continue, alignée pixel à pixel au passage ;
    - en particulier droite/arrière/gauche → dessus (non encore calées).
  Si une bande décale au passage du DESSUS -> ajuster top_local (cube_mapping.rb).
MSG

panel.close
