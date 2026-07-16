# Validation géométrie du cube (CLAUDE.md §5.3).
#
# Allume chaque face d'une couleur distincte pour confirmer :
#   - l'ordre des faces dans la chaîne (front→right→back→left→top),
#   - l'intégrité du mapping par face.
#
# Attendu, cube posé sur la table, en tournant autour :
#   AVANT   (front) → ROUGE
#   DROITE  (right) → VERT
#   ARRIÈRE (back)  → BLEU
#   GAUCHE  (left)  → JAUNE
#   DESSUS  (top)   → BLANC
#
# Fermer le moniteur série de l'IDE Arduino avant de lancer (« port busy »).
require 'logger'
require_relative '../lib/panel'

Claudine.logger.level = ::Logger::DEBUG

FACES = [
  [:front, [80,  0,  0], 'AVANT',   'ROUGE'],
  [:right, [ 0, 80,  0], 'DROITE',  'VERT'],
  [:back,  [ 0,  0, 80], 'ARRIERE', 'BLEU'],
  [:left,  [80, 80,  0], 'GAUCHE',  'JAUNE'],
  [:top,   [80, 80, 80], 'DESSUS',  'BLANC'],
]

panel = Claudine::Panel.new
FACES.each { |face, (r, g, b), _, _| panel.fill_face(face, r, g, b) }
panel.show

puts "\nUne couleur par face — vérifier autour du cube :"
FACES.each { |_, _, nom, couleur| puts format('  %-8s -> %s', nom, couleur) }
puts <<~MSG

  À confirmer :
    - chaque face est bien d'UNE seule couleur, uniforme (mapping face OK) ;
    - l'ordre correspond (sinon revoir l'ordre des faces dans la chaîne) ;
    - le DESSUS est blanc uniforme (la rotation se cale avec test_cube_edge.rb).
MSG

panel.close
