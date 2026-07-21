# Test de limite d'affichage — les 320 LEDs allumées, montée en luminosité.
#
# But : trouver la limite réelle du cube (alim 5 V / 10 A + thermique + intégrité
# du flux série sur une trame « pleine ») en poussant TOUTES les LEDs à fond.
# C'est volontairement le pire cas : blanc plein sur les 320 LEDs.
#
# ⚠️ SÉCURITÉ — à lire avant de lancer :
#   - Le blanc plein (255,255,255) à brightness 1.0 sur 320 LEDs demande
#     ~19 A en théorie (320 × 60 mA). L'alim ne fait que 10 A : elle va limiter
#     (chute de tension → LEDs qui virent, brownout de l'ESP → reset). C'est
#     précisément ce qu'on veut observer.
#   - GARDER LE JACK DC BRANCHÉ. L'USB seul ne tient pas le blanc plein.
#   - Ça CHAUFFE. Le test monte par PALIERS et attend une touche entre chaque
#     pour pouvoir s'arrêter (Ctrl-C) dès que l'affichage déraille ou chauffe.
#   - Ne pas laisser au max sans surveillance.
#
# Le test contourne le scaling du Panel (@brightness) et pousse les octets bruts
# vers le firmware : le palier affiché EST la valeur envoyée aux LEDs.
#
# RÉSULTATS MESURÉS (2026-07, cf. docs/HARDWARE.md « Hardware lessons ») :
#   - Jack DC branché : blanc plein 100% sur les 320 LEDs → RAS, aucun artefact
#     (pas de virage de teinte, pas de scintillement, pas de brownout ESP).
#     Le ~19 A théorique est très pessimiste ; l'alim 10 A encaisse proprement.
#   - USB seul (sans jack) : OK à ~8%, mais l'ESP brownout (LEDs qui clignotent)
#     ENTRE 20% et 25% de blanc plein (source USB écrête ~4 A théo. pire-cas).
#   → La limite pratique est thermique (usage prolongé), pas l'affichage.
#
# Fermer le moniteur série de l'IDE Arduino avant de lancer (« port busy »).
#
# Options (env) :
#   COLOR=white|red|green|blue    couleur du remplissage (défaut white)
#   STEPS=0.08,0.25,0.5,0.75,1.0  paliers de luminosité (défaut ci-dessous)
#   AUTO=1                        enchaîne les paliers sans attendre (3 s chacun)
require 'logger'
require_relative '../lib/panel'

Claudine.logger.level = ::Logger::INFO

COLORS = {
  'white' => [255, 255, 255],
  'red'   => [255,   0,   0],
  'green' => [  0, 255,   0],
  'blue'  => [  0,   0, 255],
}
color_name = (ENV['COLOR'] || 'white').downcase
base = COLORS[color_name] or abort "COLOR inconnue: #{color_name} (choix: #{COLORS.keys.join(', ')})"

steps = (ENV['STEPS'] || '0.08,0.25,0.5,0.75,1.0').split(',').map(&:to_f)
auto  = ENV['AUTO'] == '1'

# Courant approx. par LED à blanc plein ≈ 60 mA ; on pondère par la fraction
# de canaux allumés et par la luminosité du palier.
channels_on = base.count(&:positive?) / 3.0
def est_current(brightness, channels_on)
  Claudine::Panel::NUM_LEDS * 0.060 * channels_on * brightness
end

panel = Claudine::Panel.new
panel.brightness = 1.0   # on gère la luminosité nous-mêmes, palier par palier

puts <<~MSG

  === TEST DE LIMITE D'AFFICHAGE ===
  Couleur : #{color_name} #{base.inspect}   |   320 LEDs allumées
  Paliers : #{steps.map { |s| (s * 100).round }.join('%, ')}%
  Alim : 5 V / 10 A — au-delà de ~10 A l'alim limite (chute de tension attendue).
  Ctrl-C pour couper à tout moment.

MSG

begin
  steps.each_with_index do |b, i|
    val = base.map { |c| (c * b).round.clamp(0, 255) }
    panel.fill(*val)
    panel.show

    amps = est_current(b, channels_on)
    warn_flag = amps > 10 ? '  ⚠️ >10 A : au-delà de la capacité alim' : ''
    puts format('Palier %d/%d — luminosité %3d%% → octets %-15s ~%.1f A%s',
                i + 1, steps.size, (b * 100).round, val.inspect, amps, warn_flag)

    if auto
      sleep 3
    else
      print '  [Entrée] palier suivant, [Ctrl-C] arrêter… '
      $stdin.gets
    end
  end

  puts "\nMax atteint. Observer : blanc uniforme ? teinte qui vire ? scintillement ?"
  puts "reset de l'ESP (brownout) ? LEDs de fin de chaîne qui décrochent ?"
  unless auto
    print 'Laisser allumé, [Entrée] pour éteindre… '
    $stdin.gets
  else
    sleep 3
  end
rescue Interrupt
  puts "\nInterrompu."
ensure
  panel.clear
  panel.show
  panel.close
end
