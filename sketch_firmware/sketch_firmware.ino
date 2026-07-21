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
// The Adalight protocol and the rest of the setup are unchanged.
#include <Adafruit_NeoPixel.h>

#define NUM_LEDS   320   // 5 faces x 8x8 (cube)
#define DATA_PIN   1     // D0 on the Seeed XIAO ESP32-S3
#define WIDTH      8
#define HEIGHT     8
#define BAUD       921600

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
}

void loop() {
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
            state = WAIT_A;
          }
        }
        break;
      }
    }
  }
}
