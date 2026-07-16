# Diagnostic : remplit TOUT le cube d'une seule couleur uniforme.
#
# But : discriminer la cause du mélange de couleurs observé sur test_cube_faces.
#   - Si le cube entier est UNIFORME et propre (les 320 LEDs de la couleur
#     demandée) → le flux série se désynchronise seulement sur les données
#     multicolores (décalage d'octets / parser). Le mapping est bon.
#   - Si le cube reste MÉLANGÉ / avec des LEDs fausses même en couleur unique
#     → corruption matérielle du buffer LED (driver FastLED RMT5 / DMA sur
#     l'ESP32-S3, cf. erreur esp_cache_msync). Rien à voir avec le mapping.
#
# Usage : ruby test/test_cube_solid.rb [couleur]
#   couleur ∈ red green blue white  (défaut : green)
#
# Fermer le moniteur série de l'IDE Arduino avant de lancer (« port busy »).
require 'logger'
require_relative '../lib/panel'

Claudine.logger.level = ::Logger::DEBUG

COLORS = {
  'red'   => [80,  0,  0],
  'green' => [ 0, 80,  0],
  'blue'  => [ 0,  0, 80],
  'white' => [60, 60, 60],
}
name = ARGV[0] || 'green'
r, g, b = COLORS.fetch(name) { COLORS['green'] }

panel = Claudine::Panel.new
panel.fill(r, g, b)
panel.show

puts "\nTout le cube devrait être #{name.upcase} uniforme, sur les 5 faces."
puts "  - uniforme et propre  -> désync du flux multicolore (mapping OK)"
puts "  - encore mélangé      -> corruption driver LED (FastLED RMT5 / DMA, S3)"

panel.close
