#include <ESP_I2S.h>
#include "done.h"
#include "processing.h"

// --- Pin Definitions ---
#define I2S_BCLK   D1       // I2S BCLK
#define I2S_LRC    D0       // I2S LRC / WS
#define I2S_DOUT   D2       // I2S Data Out

I2SClass I2S;

void playAudio(const unsigned char* audioData, unsigned int audioLength, const char* audioName) {
  Serial.print("Playing ");
  Serial.print(audioName);
  Serial.println("...");

  // Play the raw audio data
  const size_t BUFFER_SIZE = 512;
  unsigned int bytesPlayed = 0;

  while (bytesPlayed < audioLength) {
    size_t bytesToPlay = min(BUFFER_SIZE, audioLength - bytesPlayed);
    I2S.write(audioData + bytesPlayed, bytesToPlay);
    bytesPlayed += bytesToPlay;
  }

  // 🔇 Send 50 ms of silence to avoid click
  int silenceSamples = 11025 / 20; // 50ms of silence for 11025 Hz
  for (int i = 0; i < silenceSamples; i++) {
    int16_t silence = 0;
    I2S.write((uint8_t *)&silence, sizeof(silence));
  }

  Serial.print(audioName);
  Serial.println(" playback completed!");
}

void playDone() {
  playAudio(done_audio_data, done_audio_length, "Done");
}

void playProcessing() {
  playAudio(processing_audio_data, processing_audio_length, "Processing");
}


void setup() {
  Serial.begin(115200);
  Serial.println("\nRAW Audio Player with Command");

  I2S.setPins(I2S_BCLK, I2S_LRC, I2S_DOUT);
  if (!I2S.begin(I2S_MODE_STD, 11025, I2S_DATA_BIT_WIDTH_16BIT, I2S_SLOT_MODE_MONO)) {
    Serial.println("I2S init failed!");
    while (true);
  }

  Serial.println("Audio system initialized!");
  Serial.println("Available commands:");
  Serial.println("  'done' - Play done audio");
  Serial.println("  'processing' - Play processing audio");
  Serial.println("  'play' - Play done audio (for compatibility)");
}

void loop() {
  if (Serial.available()) {
    String cmd = Serial.readStringUntil('\n');
    cmd.trim();
    
    if (cmd.equalsIgnoreCase("done") || cmd.equalsIgnoreCase("play")) {
      playDone();
    } else if (cmd.equalsIgnoreCase("processing")) {
      playProcessing();
    } else {
      Serial.println("Unknown command. Available commands: 'done', 'processing', 'play'");
    }
  }
}
