#include <ESP_I2S.h>
#include <SD.h>
#include <SPI.h>

// --- Pin Definitions ---
#define SD_CS_PIN 21        // SD card CS pin (change if needed)
#define I2S_BCLK   D1       // I2S BCLK
#define I2S_LRC    D0       // I2S LRC / WS
#define I2S_DOUT   D2       // I2S Data Out
#define WAV_FILE   "/fixed_done.wav"

I2SClass I2S;

void playWav() {
  File wavFile = SD.open(WAV_FILE);
  if (!wavFile) {
    Serial.println("Failed to open WAV file!");
    return;
  }

  wavFile.seek(44); // Skip header
  const size_t BUFFER_SIZE = 512;
  uint8_t buffer[BUFFER_SIZE];

  while (wavFile.available()) {
    size_t bytesRead = wavFile.read(buffer, BUFFER_SIZE);
    I2S.write(buffer, bytesRead);
  }

  Serial.print("CLICK");

  // 🔇 Send 50 ms of silence to avoid click
  int silenceSamples = 110025 / 20; // 50ms of silence
  for (int i = 0; i < silenceSamples; i++) {
    int16_t silence = 0;
    I2S.write((uint8_t *)&silence, sizeof(silence));
  }

  wavFile.close();
  Serial.println("Done!");
}


void setup() {
  Serial.begin(115200);
  Serial.println("\nSimple WAV Player with Command");

  if (!SD.begin(SD_CS_PIN)) {
    Serial.println("SD card mount failed!");
    while (true);
  }

  I2S.setPins(I2S_BCLK, I2S_LRC, I2S_DOUT);
  if (!I2S.begin(I2S_MODE_STD, 11025, I2S_DATA_BIT_WIDTH_16BIT, I2S_SLOT_MODE_MONO)) {
    Serial.println("I2S init failed!");
    while (true);
  }

  Serial.println("Type 'play' and press Enter to start.");
}

void loop() {
  if (Serial.available()) {
    String cmd = Serial.readStringUntil('\n');
    cmd.trim();
    if (cmd.equalsIgnoreCase("play")) {
      playWav();
    } else {
      Serial.println("Unknown command. Type 'play'.");
    }
  }
}
