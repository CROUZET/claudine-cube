# Calage de la rotation de la face du DESSUS (CLAUDE.md §4, point ouvert).
#
# Le mapping des faces latérales est relevé et sûr. L'orientation LOGIQUE de la
# face du dessus (comment ses x/y se raccordent aux faces latérales) n'a pas
# encore été calée visuellement. Ce test rend le raccord visible.
#
# Ce qu'on affiche :
#   - Face AVANT : sa rangée du HAUT (y=7) en ROUGE vif = l'arête partagée avec
#     le dessus, vue depuis l'avant. Un point BLANC marque le coin avant
#     HAUT-GAUCHE (front x=0, y=7) comme repère.
#   - Face DESSUS : chacune de ses 4 arêtes logiques dans une couleur distincte,
#     plus un point BLANC au coin logique (x=0, y=0) du dessus.
#
#       arête y=7 du dessus (rangée logique du HAUT)  -> VERT
#       arête y=0 du dessus (rangée logique du BAS)   -> BLEU
#       arête x=0 du dessus (colonne logique GAUCHE)  -> JAUNE
#       arête x=7 du dessus (colonne logique DROITE)  -> MAGENTA
#       coin  (x=0, y=0)                              -> BLANC
#
# LECTURE :
#   Regarder quelle arête COLORÉE du dessus touche physiquement l'arête ROUGE
#   de l'avant, et de quel côté tombe le point BLANC.
#     -> on en déduit l'orientation réelle du dessus.
#   Continuité idéale attendue : monter la colonne x de l'avant doit se
#   prolonger sur la même colonne x du dessus, sans miroir.
#   Si l'arête qui touche l'avant n'est pas celle attendue, ou si le blanc est
#   du mauvais côté, ajuster l'UNIQUE ligne `top_local` de lib/cube_mapping.rb
#   (offset / échange x<->y / inversion) puis relancer ce test.
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
WHITE   = [90, 90, 90]

panel = Claudine::Panel.new

# --- Face avant : arête haute (repère) ---
8.times { |x| panel.set(face: :front, x: x, y: 7, r: RED[0], g: RED[1], b: RED[2]) }
panel.set(face: :front, x: 0, y: 7, r: WHITE[0], g: WHITE[1], b: WHITE[2])

# --- Face dessus : 4 arêtes logiques + coin (0,0) ---
8.times do |i|
  panel.set(face: :top, x: i, y: 7, r: GREEN[0],   g: GREEN[1],   b: GREEN[2])    # haut
  panel.set(face: :top, x: i, y: 0, r: BLUE[0],    g: BLUE[1],    b: BLUE[2])     # bas
  panel.set(face: :top, x: 0, y: i, r: YELLOW[0],  g: YELLOW[1],  b: YELLOW[2])   # gauche
  panel.set(face: :top, x: 7, y: i, r: MAGENTA[0], g: MAGENTA[1], b: MAGENTA[2])  # droite
end
panel.set(face: :top, x: 0, y: 0, r: WHITE[0], g: WHITE[1], b: WHITE[2])

panel.show

puts <<~MSG

  Calage du DESSUS :
    Face AVANT  : rangée du haut ROUGE (+ coin haut-gauche BLANC) = arête partagée.
    Face DESSUS : VERT=haut(y=7)  BLEU=bas(y=0)  JAUNE=gauche(x=0)  MAGENTA=droite(x=7)
                  BLANC = coin logique (0,0).

  Reporter :
    1) quelle arête colorée du DESSUS touche l'arête ROUGE de l'AVANT ?
    2) de quel côté (gauche/droite) se trouve le point BLANC du dessus par
       rapport au point BLANC de l'avant ?
  -> j'en déduis l'offset de rotation à appliquer dans top_local.
MSG

panel.close
