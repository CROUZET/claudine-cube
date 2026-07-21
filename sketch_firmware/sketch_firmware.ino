// Adalight firmware — LED cube (5 x 8x8 = 320 WS2812B) on Seeed XIAO ESP32-S3.
//
// LED output: Adafruit NeoPixel (not FastLED).
//   On this FastLED 3.10 / ESP-IDF 5.x pairing, no FastLED backend is
//   reliable for 320 WS2812B on the S3:
//     - RMT5 (default): crashes its DMA sync ("esp_cache_msync invalid addr")
//       and corrupts the chain beyond the first ~128 LEDs;
//     - RMT4 legacy    : does not compile on IDF5 (neopixelWrite conflict);
//     - I2S            : "classic ESP32" driver with no S3 implementation (link);
//     - SPI clockless  : queues the frames without transmitting them.
//   Adafruit NeoPixel relies on the native RMT driver of the Arduino-ESP32 core
//   (the one for the built-in RGB LED), proven on the XIAO S3.
//
// Requires the "Adafruit NeoPixel" library (IDE Library Manager).
//
// Boot animation:
//   A SHORT one-shot sweep on power-up — a dim rainbow filling along the chain,
//   then off — just to show the cube is powered and ready (and that every R/G/B
//   channel responds). It plays ONCE, then the cube stays dark until the Mac app
//   drives it (no standby, no loop). If Adalight frames arrive during the sweep,
//   it yields immediately. Deliberately DIM (BOOT_VAL): the app-driven path runs
//   full scale (the Mac dims), but there's no Mac here, so we cap brightness to
//   stay USB-safe.
#include <Adafruit_NeoPixel.h>

#define NUM_LEDS   320   // 5 faces x 8x8 (cube)
#define DATA_PIN   1     // D0 on the Seeed XIAO ESP32-S3
#define WIDTH      8
#define HEIGHT     8
#define BAUD       921600

#define BOOT_FILL_MS 1800  // sweep fill duration (LEDs light up 0..NUM_LEDS)
#define BOOT_HOLD_MS 700   // hold fully lit before going dark
#define BOOT_VAL     10    // boot brightness 0..255 (dim, USB-safe; ~working level)

// NEO_GRB: the WS2812B expect GRB order. The Mac sends R,G,B triplets
// and handles brightness; we therefore transmit at full scale.
Adafruit_NeoPixel strip(NUM_LEDS, DATA_PIN, NEO_GRB + NEO_KHZ800);

// State of the state machine that reads the Adalight header
enum State { WAIT_A, WAIT_D, WAIT_A2, HI, LO, CHK, DATA };
State state = WAIT_A;
uint16_t count = 0;      // announced LED count
uint16_t idx = 0;        // index of the current LED
uint8_t hi, lo;
uint8_t byteInLed = 0;   // 0=R, 1=G, 2=B
uint8_t r, g;

bool bootDone = false;   // true once the boot sweep ended, or the app took over

void setup() {
  // During strip.show() (~10 ms for 320 LEDs) the loop does not read the port:
  // the Mac is already sending the next frame. The default USB-CDC RX buffer
  // (256 bytes ~ 85 LEDs) then overflows and corrupts the end of the frame at a
  // variable position. We enlarge it to hold a full frame (6 + 320x3 = 966 bytes).
  // MUST be called BEFORE begin().
  Serial.setRxBufferSize(4096);
  Serial.begin(BAUD);
  strip.begin();
  strip.clear();
  strip.show();
  // bootDone stays false → the boot sweep plays once, right after power-up.
}

// One-shot "powered & ready" sweep: a dim rainbow filling along the chain, then
// off. Sets bootDone when finished; after that it is never called again.
void renderBoot() {
  uint32_t now = millis();
  if (now >= (uint32_t)BOOT_FILL_MS + BOOT_HOLD_MS) {  // done → go dark, for good
    strip.clear();
    strip.show();
    bootDone = true;
    return;
  }
  static uint32_t lastMs = 0;
  if (now - lastMs < (1000 / 30)) return;              // ~30 fps
  lastMs = now;

  uint16_t lit = (now < BOOT_FILL_MS)
               ? (uint16_t)((uint32_t)NUM_LEDS * now / BOOT_FILL_MS)
               : NUM_LEDS;
  strip.clear();
  for (uint16_t i = 0; i < lit; i++) {
    uint16_t hue = (uint16_t)((uint32_t)i * 65536UL / NUM_LEDS);  // rainbow along the chain
    strip.setPixelColor(i, strip.ColorHSV(hue, 255, BOOT_VAL));
  }
  strip.show();
}

void loop() {
  // Drain any incoming serial through the Adalight decoder.
  while (Serial.available() > 0) {
    uint8_t b = Serial.read();
    switch (state) {
      case WAIT_A:  state = (b == 'A') ? WAIT_D  : WAIT_A; break;
      case WAIT_D:  state = (b == 'd') ? WAIT_A2 : WAIT_A; break;
      case WAIT_A2: state = (b == 'a') ? HI      : WAIT_A; break;
      case HI:  hi = b; state = LO;  break;
      case LO:  lo = b; state = CHK; break;
      case CHK: {
        // verify the checksum: hi ^ lo ^ 0x55
        if (b == (hi ^ lo ^ 0x55)) {
          count = (hi << 8) | lo;          // LED count - 1
          idx = 0; byteInLed = 0;
          state = DATA;
        } else {
          state = WAIT_A;                  // invalid header, resync
        }
        break;
      }
      case DATA: {
        if (byteInLed == 0)      { r = b; byteInLed = 1; }
        else if (byteInLed == 1) { g = b; byteInLed = 2; }
        else {
          if (idx < NUM_LEDS) strip.setPixelColor(idx, r, g, b);
          idx++;
          byteInLed = 0;
          if (idx > count) {                // full frame
            strip.show();
            bootDone = true;                // the app is driving: no more boot anim
            state = WAIT_A;
          }
        }
        break;
      }
    }
  }

  // Boot sweep plays once on power-up; afterwards the cube is dark until the app.
  if (!bootDone) renderBoot();
}
