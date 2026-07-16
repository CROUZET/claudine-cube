// Firmware Adalight — cube LED (5 × 8×8 = 320 WS2812B) sur Seeed XIAO ESP32-S3.
//
// Sortie LED : Adafruit NeoPixel (et non FastLED).
//   Sur ce couple FastLED 3.10 / ESP-IDF 5.x, aucun backend FastLED n'est
//   fiable pour 320 WS2812B sur le S3 :
//     - RMT5 (défaut) : plante sa synchro DMA (« esp_cache_msync invalid addr »)
//       et corrompt la chaîne au-delà des ~128 premières LEDs ;
//     - RMT4 legacy    : ne compile pas sur IDF5 (conflit neopixelWrite) ;
//     - I2S            : driver « classic ESP32 » sans implémentation S3 (link) ;
//     - SPI clockless  : met les trames en file sans les transmettre.
//   Adafruit NeoPixel s'appuie sur le driver RMT natif du core Arduino-ESP32
//   (celui de la LED RGB intégrée), éprouvé sur le XIAO S3.
//
// Nécessite la bibliothèque « Adafruit NeoPixel » (Library Manager de l'IDE).
// Le protocole Adalight et le reste du montage sont inchangés.
#include <Adafruit_NeoPixel.h>

#define NUM_LEDS   320   // 5 faces × 8×8 (cube)
#define DATA_PIN   1     // D0 on the Seeed XIAO ESP32-S3
#define WIDTH      8
#define HEIGHT     8
#define BAUD       921600

// NEO_GRB : les WS2812B attendent l'ordre GRB. Le Mac envoie des triplets R,G,B
// et gère la luminosité ; on transmet donc à pleine échelle.
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
  // Pendant strip.show() (~10 ms pour 320 LEDs) la boucle ne lit pas le port :
  // le Mac envoie déjà la trame suivante. Le buffer RX USB-CDC par défaut
  // (256 o ≈ 85 LEDs) déborde alors et corrompt la fin de trame à une position
  // variable. On l'agrandit pour contenir une trame entière (6 + 320×3 = 966 o).
  // DOIT être appelé AVANT begin().
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
