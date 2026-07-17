# CLAUDE.md — Cube LED (évolution de Claudine)

Ce document est le point d'entrée pour travailler sur le **cube LED**, portage de
Claudine (panneau 16×16 plat) vers un cube de 5 faces 8×8. Il complète — sans le
remplacer — l'architecture logicielle héritée de Claudine (daemon, EventBus,
Runner, connectors, protocole Adalight), décrite dans `docs/SOFTWARE.md`.

**Le portage est terminé : matériel monté/testé, logiciel porté, géométrie
validée sur le cube réel, et un set d'animations « cube » par défaut est en
place.** Ce doc décrit le résultat et les pièges rencontrés (dont un non-évident
qui a coûté cher : voir §3).

---

## 1. Ce qu'est le projet

Claudine à l'origine : un panneau **16×16 plat** (256 LEDs WS2812B) piloté par un
ESP32, qui réagit visuellement aux hooks de cycle de vie de Claude Code. Le Mac
fait tout le calcul (daemon Ruby, boucle 30 fps, protocole Adalight sur USB
série), l'ESP32 est « bête » et pousse des frames de pixels sur la matrice.

Le cube : **5 faces LED 8×8** (320 LEDs) assemblées en cube posé sur une table,
électronique dans un PCB central et connecteurs déportés dans un socle. Le
principe logiciel est **strictement le même** que Claudine — seuls la géométrie
(plat → cube) et le microcontrôleur (DevKit → XIAO) changent.

---

## 2. Matériel (terminé, testé, fonctionnel)

### Différences clés avec Claudine

| Aspect | Claudine (origine) | Cube (ce projet) |
|---|---|---|
| Matrice | 1 × 16×16 plate (256) | 5 × 8×8 en cube (320) |
| Microcontrôleur | ESP32-S3-DevKitC-1 | **Seeed XIAO ESP32-S3** |
| Pin data | GPIO 16 | **D0 = GPIO 1** |
| Alimentation | 5V/10A, jack | 5V/10A, jack **dans le socle** |
| Level shifter | 74AHCT125 | 74AHCT125 (identique) |
| Structure | panneau nu | cube bois + socle + fond amovible |

Détails complets (composants, câblage, topologie d'alim en étoile, thermique,
leçons apprises) dans **`docs/HARDWARE.md`**. Rappels essentiels :

- **XIAO ESP32-S3**, data sur **D0 (GPIO 1)**, USB-C pour data/reflash seulement.
- **74AHCT125** (3,3 V → 5 V), **330 Ω** en série, réservoir **1000 µF**,
  découplage **100 nF**.
- **5 × WS2812B 8×8 GRB**, chaînées DOUT→DIN. Alim **5 V / 10 A** par jack dans le
  socle, **topologie en étoile** (chaque face tire son 5V/GND du PCB).
- Brightness de travail ~0,08 (≈20/255), ~1,5 A total → convection naturelle
  suffit. Garder le jack DC branché pour tout usage réel (l'USB seul ne tient pas
  le blanc plein).

---

## 3. Firmware (XIAO) — ⚠️ points non-évidents

Le firmware reste un décodeur Adalight minimal, mais **deux choses diffèrent de
Claudine et sont critiques** (elles ont été trouvées à la dure) :

### a) Sortie LED : Adafruit NeoPixel, PAS FastLED

Sur ce couple **FastLED 3.10 / ESP-IDF 5.x**, aucun backend FastLED n'est fiable
pour 320 WS2812B sur le S3 :

- **RMT5** (défaut) : plante sa synchro DMA (`esp_cache_msync(113): invalid addr`)
  et corrompt la chaîne au-delà des premières LEDs.
- **RMT4 legacy** : ne compile pas sur IDF5 (conflit `neopixelWrite`).
- **I2S** : le driver « classic ESP32 » n'a pas d'implémentation S3 → erreurs de
  link.
- **SPI clockless** : met les trames en file sans les transmettre.

→ Le firmware utilise **Adafruit NeoPixel** (`strip.setPixelColor` / `strip.show`),
qui s'appuie sur le driver RMT natif du core Arduino (celui de la LED RGB
intégrée), éprouvé sur le XIAO S3. Installer la lib « Adafruit NeoPixel ».

### b) Buffer série RX à agrandir (cause racine du bug d'affichage)

Symptôme initial : les couleurs partaient « en vrac » au-delà d'une frontière
**mouvante** (≈ LED 85-128). Ce **n'était ni le mapping ni le matériel** (matériel
sain, confirmé par un sketch d'animation autonome). Cause : pendant `strip.show()`
(~10 ms, boucle bloquée), le Mac envoie déjà la trame suivante ; le buffer RX
USB-CDC par défaut (**256 o ≈ 85 LEDs**) déborde → fin de trame perdue/corrompue à
position variable.

→ Correctif : **`Serial.setRxBufferSize(4096)` avant `Serial.begin()`** (une trame
= 6 + 320×3 = **966 o**, tient largement).

### Constantes

```cpp
#define DATA_PIN   1     // D0 sur le XIAO (était 16 sur le DevKit)
#define NUM_LEDS   320   // 5 × 64 (était 256)
// + Serial.setRxBufferSize(4096) dans setup(), avant Serial.begin(BAUD)
```

Baud 921600, ordre GRB (`NEO_GRB + NEO_KHZ800`), luminosité pleine côté firmware
(le Mac scale). Carte IDE : **XIAO_ESP32S3**. Reflash : USB seul, jack débranché.
Fermer le moniteur série avant de lancer le daemon (« port busy »).

Le dossier `sketch_firmware/testing/` contient des sketches autonomes de
diagnostic matériel (ex. `flashing_colors.ino`, qui fait défiler des couleurs sur
les 320 LEDs sans flux série — utile pour confirmer que le matériel est sain).

---

## 4. Mapping des LEDs (relevé, validé et calé visuellement)

Le parcours physique a été relevé LED par LED et implémenté dans
`lib/cube_mapping.rb` (module `CubeMapping`, auto-test OK : `ruby lib/cube_mapping.rb`).

### Ordre des faces dans la chaîne

```
0 = avant (front)   → index 0..63
1 = droite (right)  → index 64..127
2 = arrière (back)  → index 128..191
3 = gauche (left)   → index 192..255
4 = dessus (top)    → index 256..319
```

Face F occupe `64*F .. 64*F+63`.

### Coordonnées logiques (unifiées pour toutes les faces)

- **x = colonne**, 0 = gauche … 7 = droite
- **y = ligne**, 0 = bas … 7 = haut

Toute animation raisonne en `(face, x, y)` ; `CubeMapping.index(face, x, y)` absorbe
le sens physique du câblage.

### Parcours physique

- **Faces latérales (0..3)** : origine bas-gauche, la chaîne monte une colonne
  entière (bas→haut) puis passe à la colonne suivante → `index_local = x*8 + y`.
- **Face dessus (4)** : origine haut-gauche, la chaîne parcourt une ligne vers la
  droite puis descend → `index_local = (7 - y)*8 + x`.

### ✅ Rotation du dessus — calée

Le point autrefois ouvert est **résolu**. La continuité avant→dessus a été validée
sur matériel (`test/test_cube_edge.rb`) : le coin avant-haut-gauche coïncide avec
le coin proche-gauche du dessus, `x` aligné, sans miroir, et monter sur l'avant
(`y`→7) se prolonge sur le dessus en `y` croissant (proche→fond). **`top_local`
est correct tel quel, aucun offset.**

**Les 8 arêtes sont désormais validées sur matériel** (`test/test_cube_edge.rb`,
qui allume les 8 arêtes partagées, pixels 2→6 des deux côtés) : les 3 arêtes
dessus↔latérales restantes (droite/arrière/gauche→dessus) sont **continues et
alignées telles quelles, aucun offset à appliquer**. Les effets qui traversent
ces arêtes (cf. `top_edge_px` et le serpent de `pre_tool`) sont donc corrects.

---

## 5. Logiciel — état livré

Tout le découplage source ↔ rendu de Claudine est conservé. Ce qui a changé :

1. **`Panel` orienté face** (`lib/panel.rb`) : le mapping serpentin plat +
   `FLIP_X/FLIP_Y` est remplacé par `CubeMapping`. API :
   `panel.set(face:, x:, y:, r:, g:, b:)` et `panel.fill_face(face, r, g, b)`
   (plus `fill`, `clear`, `set_raw`, `show`, `close`).
2. **`Settings`** (`config/settings.rb`) : `WIDTH=8`, `HEIGHT=8`, `FACES=5`,
   `NUM_LEDS=320`, `PORT='/dev/cu.usbmodem11201'` (XIAO). `FLIP_X/FLIP_Y` supprimés.
3. **Set d'animations `cube`** (par défaut, `lib/animations/cube/`) : les sets
   plats de Claudine (`default`/`fancy`/`abstract`/`bunny`) et `EventLabel` ont
   été **supprimés** (texte 3×5 inadapté au cube). Le nouveau set est **sans
   texte**, pensé volume : 16 hooks + `_base.rb` (helpers `ring_px`/`ring_row`
   autour des 4 faces latérales, `face_ring`/`top_ring` anneaux concentriques,
   `top_edge_px` pour le pourtour du dessus).
   ⚠️ **L'utilisateur est légèrement daltonien** : chaque event est distinguable
   par le **mouvement/forme/luminosité**, pas seulement la couleur.
4. **Modèle deux couches dans `AnimationManager`** : un event de **fond**
   (`user_prompt`) démarre une boucle « au travail » qui persiste (indicateur de
   thinking) ; les events **ponctuels** (`pre_tool`, `post_tool`, …) sont des
   **overlays** qui jouent une fois (leur `MIN_DURATION`) puis rendent la main au
   fond ; les events **terminaux** (`stop`, `stop_failure`, `session_end`,
   `session_start`) coupent le fond. Le fond boucle jusqu'au terminal ou l'idle.
   Vérifié par `test/test_manager_states.rb`.
5. **Inchangé** : EventBus, Runner (30 fps), connector Claude Code
   (HTTP 127.0.0.1:9292, 15 hooks + `system_idle`), display lock (0,6 s,
   latest-wins), idle (`system_idle` après 90 s), protocole Adalight.

Le dossier `lib/text/` (font 3×5, renderer) est conservé de Claudine mais **non
utilisé** par le set cube (le renderer emploie l'ancien `set` positionnel ; il
faudrait le porter à l'API par face pour dessiner du texte sur une face 8×8).

### Tests (`test/`, sans les anciens tests plats)

| Fichier | Rôle | Matériel |
|---|---|---|
| `test_cube_faces.rb` | 1 couleur/face (ordre + mapping) | oui |
| `test_cube_edge.rb` | calage/vérif des 8 arêtes (pixels 2→6 des 2 côtés) | oui |
| `test_cube_preview.rb [hooks…]` | aperçu des animations sur le cube | oui |
| `test_cube_animations.rb` | dry-run de toutes les anims (panel factice) | non |
| `test_manager_states.rb` | modèle deux couches (fond/overlay) du manager | non |

### Lancer

```bash
bundle install
ruby claudine.rb                 # set 'cube' par défaut
ruby test/test_cube_preview.rb   # regarder les animations tourner
```

---

## 6. Fichiers de référence

- `lib/cube_mapping.rb` — `CubeMapping.index(face, x, y)` + auto-test. Fondation.
- `lib/animations/cube/` — set par défaut (16 hooks + `_base.rb`).
- `docs/HARDWARE.md` — matériel complet.
- `docs/SOFTWARE.md` — architecture daemon + firmware (référence logicielle,
  mise à jour pour le cube).
- `docs/cube_animation_snippets.md` — effets mis de côté, réutilisables.
- `sketch_firmware/sketch_firmware.ino` — firmware NeoPixel.
- `sketch_firmware/testing/` — sketches de diagnostic matériel autonomes
  (`flashing_colors.ino`).

---

## 7. Rappels de conventions (hérités de Claudine)

- Le Mac pense, le microcontrôleur est bête (frames Adalight sur USB série).
- Découplage source ↔ rendu : ajouter une source ne touche jamais le rendu.
- Ruby 4.0.5 (rbenv, `.ruby-version`), `bundle install`, `ruby claudine.rb`.
- Fermer le moniteur série de l'IDE Arduino avant de lancer (« port busy »).
- `CLAUDINE_ANIMATION_SET` choisit le set ; `CLAUDINE_LOG_LEVEL=DEBUG` pour les
  logs verbeux.
