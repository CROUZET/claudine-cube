# CLAUDE.md — Cube LED (evolution of Claudine)

This document is the entry point for working on the **LED cube**, a port of
Claudine (flat 16×16 panel) to a cube of 5 faces of 8×8. It complements — without
replacing — the software architecture inherited from Claudine (daemon, EventBus,
Runner, connectors, Adalight protocol), described in `docs/SOFTWARE.md`.

**The port is complete: hardware assembled/tested, software ported, geometry
validated on the real cube, and a default "cube" animation set is in
place.** This doc describes the result and the pitfalls encountered (including a
non-obvious one that was costly: see §3).

---

## 1. What the project is

Claudine originally: a **flat 16×16** panel (256 WS2812B LEDs) driven by an
ESP32, which reacts visually to Claude Code lifecycle hooks. The Mac
does all the computation (Ruby daemon, 30 fps loop, Adalight protocol over USB
serial); the ESP32 is "dumb" and pushes frames of pixels onto the matrix.

The cube: **5 LED faces of 8×8** (320 LEDs) assembled into a cube sitting on a table,
electronics in a central PCB and remote connectors in a base. The
software principle is **strictly the same** as Claudine — only the geometry
(flat → cube) and the microcontroller (DevKit → XIAO) change.

---

## 2. Hardware (complete, tested, functional)

### Key differences from Claudine

| Aspect | Claudine (original) | Cube (this project) |
|---|---|---|
| Matrix | 1 × 16×16 flat (256) | 5 × 8×8 as a cube (320) |
| Microcontroller | ESP32-S3-DevKitC-1 | **Seeed XIAO ESP32-S3** |
| Data pin | GPIO 16 | **D0 = GPIO 1** |
| Power | 5V/10A, jack | 5V/10A, jack **in the base** |
| Level shifter | 74AHCT125 | 74AHCT125 (identical) |
| Structure | bare panel | wooden cube + base + removable bottom |

Full details (components, wiring, star power topology, thermal,
lessons learned) in **`docs/HARDWARE.md`**. Essential reminders:

- **XIAO ESP32-S3**, data on **D0 (GPIO 1)**, USB-C for data/reflash only.
- **74AHCT125** (3.3 V → 5 V), **330 Ω** in series, **1000 µF** reservoir,
  **100 nF** decoupling.
- **5 × WS2812B 8×8 GRB**, chained DOUT→DIN. Power **5 V / 10 A** via a jack in the
  base, **star topology** (each face draws its 5V/GND from the PCB).
- Working brightness ~0.08 (≈20/255), ~1.5 A total → natural convection
  is enough. Keep the DC jack plugged in for any real use (USB alone can't hold
  full white).

---

## 3. Firmware (XIAO) — ⚠️ non-obvious points

The firmware remains a minimal Adalight decoder, but **two things differ from
Claudine and are critical** (they were found the hard way):

### a) LED output: Adafruit NeoPixel, NOT FastLED

On this **FastLED 3.10 / ESP-IDF 5.x** pairing, no FastLED backend is reliable
for 320 WS2812B on the S3:

- **RMT5** (default): its DMA sync crashes (`esp_cache_msync(113): invalid addr`)
  and corrupts the chain beyond the first few LEDs.
- **RMT4 legacy**: doesn't compile on IDF5 (`neopixelWrite` conflict).
- **I2S**: the "classic ESP32" driver has no S3 implementation → link
  errors.
- **SPI clockless**: queues frames without transmitting them.

→ The firmware uses **Adafruit NeoPixel** (`strip.setPixelColor` / `strip.show`),
which relies on the native RMT driver of the Arduino core (the one for the built-in
RGB LED), proven on the XIAO S3. Install the "Adafruit NeoPixel" library.

### b) RX serial buffer to enlarge (root cause of the display bug)

Initial symptom: colors went "haywire" beyond a **moving**
boundary (≈ LED 85-128). This was **neither the mapping nor the hardware** (hardware
sound, confirmed by a standalone animation sketch). Cause: during `strip.show()`
(~10 ms, loop blocked), the Mac is already sending the next frame; the default
USB-CDC RX buffer (**256 B ≈ 85 LEDs**) overflows → end of frame lost/corrupted at a
variable position.

→ Fix: **`Serial.setRxBufferSize(4096)` before `Serial.begin()`** (one frame
= 6 + 320×3 = **966 B**, fits with plenty of room).

### Constants

```cpp
#define DATA_PIN   1     // D0 on the XIAO (was 16 on the DevKit)
#define NUM_LEDS   320   // 5 × 64 (was 256)
// + Serial.setRxBufferSize(4096) in setup(), before Serial.begin(BAUD)
```

Baud 921600, GRB order (`NEO_GRB + NEO_KHZ800`), full brightness on the firmware side
(the Mac scales). IDE board: **XIAO_ESP32S3**. Reflash: USB only, jack unplugged.
Close the serial monitor before starting the daemon ("port busy").

The `sketch_firmware/testing/` folder contains standalone hardware
diagnostic sketches (e.g. `flashing_colors.ino`, which scrolls colors across
the 320 LEDs with no serial stream — useful to confirm the hardware is sound).

---

## 4. LED mapping (surveyed, validated, and visually calibrated)

The physical path was mapped LED by LED and implemented in
`lib/cube_mapping.rb` (module `CubeMapping`, self-test OK: `ruby lib/cube_mapping.rb`).

### Order of faces in the chain

```
0 = front   → index 0..63
1 = right   → index 64..127
2 = back    → index 128..191
3 = left    → index 192..255
4 = top     → index 256..319
```

Face F occupies `64*F .. 64*F+63`.

### Logical coordinates (unified for all faces)

- **x = column**, 0 = left … 7 = right
- **y = row**, 0 = bottom … 7 = top

Every animation reasons in `(face, x, y)`; `CubeMapping.index(face, x, y)` absorbs
the physical wiring direction.

### Physical path

- **Side faces (0..3)**: origin bottom-left, the chain climbs an entire column
  (bottom→top) then moves to the next column → `index_local = x*8 + y`.
- **Top face (4)**: origin top-left, the chain runs along a row to the
  right then descends → `index_local = (7 - y)*8 + x`.

### ✅ Top rotation — calibrated

The previously open point is **resolved**. The front→top continuity was validated
on hardware (`test/test_cube_edge.rb`): the front-top-left corner coincides with
the near-left corner of the top, `x` aligned, no mirror, and climbing on the front
(`y`→7) continues onto the top with increasing `y` (near→far). **`top_local`
is correct as-is, no offset.**

**The 8 edges are now validated on hardware** (`test/test_cube_edge.rb`,
which lights the 8 shared edges, pixels 2→6 on both sides): the 3 remaining
top↔side edges (right/back/left→top) are **continuous and
aligned as-is, no offset to apply**. The effects that cross
these edges (cf. `top_edge_px` and the snake in `pre_tool`) are therefore correct.

---

## 5. Software — delivered state

All of Claudine's source ↔ rendering decoupling is preserved. What changed:

1. **Face-oriented `Panel`** (`lib/panel.rb`): the flat serpentine mapping +
   `FLIP_X/FLIP_Y` is replaced by `CubeMapping`. API:
   `panel.set(face:, x:, y:, r:, g:, b:)` and `panel.fill_face(face, r, g, b)`
   (plus `fill`, `clear`, `set_raw`, `show`, `close`).
2. **`Settings`** (`config/settings.rb`): `WIDTH=8`, `HEIGHT=8`, `FACES=5`,
   `NUM_LEDS=320`, `PORT='/dev/cu.usbmodem11201'` (XIAO). `FLIP_X/FLIP_Y` removed.
3. **Intention layer** (`lib/intentions.rb` + `lib/profiles/claude_code.rb`):
   animations are indexed by **intention** (neutral state verbs: `think`,
   `start`, `fork`…), not by hook. A **profile** (data) maps Claude Code hooks
   onto the 16 intentions; the manager translates. This decouples the cube from
   Claude Code (any source is just a new profile) and moves the temporal role
   out of the manager. Frozen V1 spec + rationale: `docs/INTENTIONS.md`.
4. **`cube` animation set** (default, `lib/animations/cube/`): Claudine's flat
   sets (`default`/`fancy`/`abstract`/`bunny`) and `EventLabel` have
   been **removed** (3×5 text unsuitable for the cube). The new set is **without
   text**, designed for volume: 16 intentions + `_base.rb` (helpers
   `ring_px`/`ring_row` around the 4 side faces, `face_ring`/`top_ring`
   concentric rings, `top_edge_px` for the perimeter of the top). Files are named
   by intention (`think.rb`, `start.rb`, …).
   ⚠️ **The user is slightly colorblind**: each state is distinguishable
   by **motion/shape/brightness**, not by color alone.
   A second set, **`bunny`** (bunnies, `lib/animations/bunny/`), is **complete**
   (all 16 intentions): it reuses the cube geometry (`Cube::CubeBase`, via
   `bunny/_base.rb`) and stages bunnies (rainbow wake-up, jumps
   around the ring, dances, peekaboo, angry bunny, falling asleep, merging
   heads, etc.). Selected via `CLAUDINE_ANIMATION_SET=bunny`. Color scheme of the
   set: start = light (white/light blue), end = yellow, error = red.
5. **Intention-driven `AnimationManager`**: the temporal role comes from the
   intention's `kind` (`Intentions.kind`). An **ambient** intention (`think`)
   starts a "working" loop that persists (thinking indicator); **pulse**
   intentions (`start`, `finish`, `fork`, …) are **overlays** that play once
   (their `MIN_DURATION`) then hand back to the background; **boundary**
   intentions (`welcome`, `stop`, `fail`, `bye`) cut the background; the
   **dormant** intention (`sleep`) is the idle animation. If the set lacks a
   resolved intention, the manager walks the vocabulary fallback chain. The
   background loops until a boundary or idle. Verified by
   `test/test_manager_states.rb`.
6. **Unchanged**: EventBus, Runner (30 fps), Claude Code connector
   (HTTP 127.0.0.1:9292, pushes raw hooks — the profile translates), display
   lock (0.6 s, latest-wins), idle (`sleep` intention after 90 s), Adalight
   protocol.

The `lib/text/` folder (3×5 font, renderer) is kept from Claudine but **not
used** by the cube set (the renderer uses the old positional `set`; it
would need to be ported to the per-face API to draw text on an 8×8 face).

### Tests (`test/`, without the old flat tests)

| File | Role | Hardware |
|---|---|---|
| `test_cube_faces.rb` | 1 color/face (order + mapping) | yes |
| `test_cube_edge.rb` | calibration/check of the 8 edges (pixels 2→6 on both sides) | yes |
| `test_cube_preview.rb [intentions…]` | preview of the animations on the cube | yes |
| `test_cube_animations.rb` | dry-run of all the animations (fake panel) | no |
| `test_manager_states.rb` | two-layer model (background/overlay) of the manager | no |

### Running

```bash
bundle install
ruby claudine.rb                 # default 'cube' set
ruby test/test_cube_preview.rb   # watch the animations run
```

---

## 6. Reference files

- `lib/cube_mapping.rb` — `CubeMapping.index(face, x, y)` + self-test. Foundation.
- `lib/animations/cube/` — default set (16 hooks + `_base.rb`).
- `lib/animations/bunny/` — complete "bunnies" set (16 hooks; reuses `Cube::CubeBase`).
- `docs/HARDWARE.md` — full hardware.
- `docs/SOFTWARE.md` — daemon + firmware architecture (software reference,
  updated for the cube).
- `docs/cube_animation_snippets.md` — effects set aside, reusable.
- `docs/IDEAS.md` — **single index of evolutions** (nothing built), organized
  by maturity; the big work items are linked (marketplace) and the small ideas
  inline. Every evolution idea goes here, not in the README nor `SOFTWARE.md`.
- `docs/INTENTIONS.md` — intention vocabulary (V1, **implemented**): the
  source ↔ rendering contract that decouples the cube from Claude Code (the
  animations target states "think/start/fork…", a profile maps the hooks onto
  them). See `lib/intentions.rb`, `lib/profiles/claude_code.rb`.
- `docs/MARKETPLACE.md` — vision of a marketplace of shareable animations
  (design exploration): third-party code execution security, compilation
  to WASM, creator journey.
- `sketch_firmware/sketch_firmware.ino` — NeoPixel firmware.
- `sketch_firmware/testing/` — standalone hardware diagnostic sketches
  (`flashing_colors.ino`).

---

## 7. Convention reminders (inherited from Claudine)

- The Mac thinks, the microcontroller is dumb (Adalight frames over USB serial).
- Source ↔ rendering decoupling: adding a source never touches the render path.
- Ruby 4.0.5 (rbenv, `.ruby-version`), `bundle install`, `ruby claudine.rb`.
- Close the Arduino IDE serial monitor before starting ("port busy").
- `CLAUDINE_ANIMATION_SET` chooses the set (`cube` by default, `bunny` complete) —
  also overridable in `test/test_cube_preview.rb` and `test_cube_animations.rb`.
- `CLAUDINE_BRIGHTNESS` overrides the global brightness (default 0.08; raising it
  increases current/heat, keep the DC jack plugged in).
- `CLAUDINE_LOG_LEVEL=DEBUG` for verbose logs.
