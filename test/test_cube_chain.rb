# Diagnostic CHAÎNE PHYSIQUE — par index brut (set_raw), sans le mapping.
#
# But : localiser au pixel près où la chaîne WS2812 se corrompt. On a établi que
# tout se casse à partir de la LED 128 (entrée du 3e écran). Ce test :
#   - colore les 5 écrans (blocs de 64) de 5 couleurs distinctes, pour voir
#     quels écrans physiques sont propres ;
#   - met un repère BLANC vif sur les 2 LEDs qui encadrent la couture écran2↔écran3
#     (index 127 = dernière LED de l'écran 2, index 128 = 1re LED de l'écran 3).
#
# LECTURE :
#   - Écrans 1 (rouge) et 2 (vert) doivent être propres et uniformes.
#   - Si la LED 127 (blanc) est nette mais que ça part en vrille dès la 128
#     (blanc puis bleu bruité) → défaut PILE à la liaison écran2→écran3 :
#     soit le fil DATA DOUT(écran2)→DIN(écran3), soit la MASSE de l'écran 3.
#   - Note le tout premier pixel franchement faux : c'est le point de panne.
#
# Blocs : 0=rouge 1=vert 2=bleu 3=jaune 4=cyan (par écran dans l'ordre chaîne).
require 'logger'
require_relative '../lib/panel'

Claudine.logger.level = ::Logger::DEBUG

BLOCK_COLORS = [
  [80,  0,  0],  # écran 1 (0..63)     rouge
  [ 0, 80,  0],  # écran 2 (64..127)   vert
  [ 0,  0, 80],  # écran 3 (128..191)  bleu
  [80, 80,  0],  # écran 4 (192..255)  jaune
  [ 0, 80, 80],  # écran 5 (256..319)  cyan
]

panel = Claudine::Panel.new
320.times do |i|
  r, g, b = BLOCK_COLORS[i / 64]
  panel.set_raw(i, r, g, b)
end
# Repères blancs de part et d'autre de la couture écran2↔écran3.
panel.set_raw(127, 90, 90, 90)   # dernière LED de l'écran 2
panel.set_raw(128, 90, 90, 90)   # première LED de l'écran 3
panel.show

puts <<~MSG

  Chaîne par index brut :
    écran 1 (LED   0..63)  = ROUGE
    écran 2 (LED  64..127) = VERT   (LED 127 = BLANC, repère)
    écran 3 (LED 128..191) = BLEU   (LED 128 = BLANC, repère)
    écran 4 (LED 192..255) = JAUNE
    écran 5 (LED 256..319) = CYAN

  À reporter :
    1) écrans 1 et 2 bien propres (rouge / vert uniformes) ?
    2) la LED 127 (blanc) est-elle nette ?
    3) quel est le PREMIER pixel franchement faux (≈ 128 ?) ?
  -> confirme si la panne est pile à la couture écran2→écran3.
MSG

panel.close
