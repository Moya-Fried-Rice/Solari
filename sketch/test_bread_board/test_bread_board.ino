#include "ESP_I2S.h"
#include <SD.h>
#include <SPI.h>

/*
 * SIMPLE 8-BIT WAV PLAYER FOR SMART GLASSES
 * 
 * SUPPORTS ONLY:
 * - 8kHz, 8-bit, mono PCM WAV files
 * - Optimized for BLE streaming (~8KB/second)
 */

// Xiao ESP32-S3 pin names (works fine)
#define I2S_BCLK D1  // BCLK
#define I2S_LRC  D0  // LRC / WS
#define I2S_DOUT D2  // DIN

// SD Card pins for Xiao ESP32-S3 (using pin 21 like in camera example)
#define SD_CS_PIN 21

#define WAV_FILE_NAME "/test.wav"

int16_t amplitude = 20000;  // Default amplitude (can be changed via Serial)

// Simplified WAV header for 8-bit files
struct WAVHeader {
  uint32_t sampleRate;
  uint32_t dataSize;
};

// Create I2S instance
I2SClass i2s;

// Function declarations
void setupI2S(uint32_t sampleRate);
bool readWAVHeader(File &file, WAVHeader &header);
void playWAVFile();
void handleSerialInput();

void setup() {
  Serial.begin(115200);
  Serial.println("\n8-BIT WAV PLAYER FOR SMART GLASSES");
  
  // Initialize SD card
  if (!SD.begin(SD_CS_PIN)) {
    Serial.println("[ERROR] SD card failed!");
    return;
  }
  
  // Check if WAV file exists
  if (!SD.exists(WAV_FILE_NAME)) {
    Serial.println("[ERROR] test.wav not found!");
    return;
  }
  
  setupI2S(8000);  // Fixed 8kHz
  Serial.println("Ready! Commands: 'p' = play, number = volume");
}

void loop() {
  handleSerialInput();
  delay(100);  // Small delay to prevent excessive loop iterations
}

void setupI2S(uint32_t sampleRate) {
  // Set the pins for I2S TX (output to MAX98357A)
  i2s.setPins(I2S_BCLK, I2S_LRC, I2S_DOUT);
  
  // Begin I2S in TX mode, mono, 16-bit, at the specified sample rate
  if (!i2s.begin(I2S_MODE_STD, sampleRate, I2S_DATA_BIT_WIDTH_16BIT, I2S_SLOT_MODE_MONO)) {
    Serial.println("[ERROR] Failed to initialize I2S!");
    while (true) delay(1000);
  }
  
  Serial.println("[DEBUG] ESP_I2S initialized successfully");
  Serial.printf("[DEBUG] I2S configured for %d Hz, 16-bit, mono\n", sampleRate);
}

bool readWAVHeader(File &file, WAVHeader &header) {
  // Based on hexdump: sample rate at offset 24 (0x18), data size at offset 40 (0x28)
  file.seek(0);
  
  // Read sample rate from offset 24
  file.seek(24);
  file.read((uint8_t*)&header.sampleRate, 4);
  
  // Read data size from offset 40 (after "data" chunk header)
  file.seek(40);
  file.read((uint8_t*)&header.dataSize, 4);
  
  Serial.printf("[INFO] WAV: %d Hz, %d bytes\n", header.sampleRate, header.dataSize);
  return true;
}

void playWAVFile() {
  File wavFile = SD.open(WAV_FILE_NAME);
  if (!wavFile) {
    Serial.println("[ERROR] Failed to open WAV file");
    return;
  }
  
  WAVHeader header;
  if (!readWAVHeader(wavFile, header)) {
    wavFile.close();
    return;
  }
  
  // Always use 8kHz (our target format)
  if (header.sampleRate != 8000) {
    Serial.printf("[WARN] Expected 8kHz, got %d Hz - playing anyway\n", header.sampleRate);
  }
  
  float duration = (float)header.dataSize / 8000.0;
  Serial.printf("[INFO] Playing: %.1f seconds, %d bytes\n", duration, header.dataSize);
  
  // Audio data starts at offset 44 (0x2C) - after all headers
  wavFile.seek(44);
  
  const size_t chunkSize = 128;
  uint8_t audioData[chunkSize];
  uint32_t totalBytesRead = 0;
  
  while (totalBytesRead < header.dataSize) {
    size_t bytesToRead = min(chunkSize, (size_t)(header.dataSize - totalBytesRead));
    size_t bytesRead = wavFile.read(audioData, bytesToRead);
    
    if (bytesRead == 0) break;
    
    // Convert 8-bit unsigned to 16-bit signed and send to I2S
    for (size_t i = 0; i < bytesRead; i++) {
      // Convert: 8-bit unsigned (0-255) to 16-bit signed (-32768 to 32767)
      // More precise conversion to reduce quantization noise
      int16_t sample = (int16_t)((audioData[i] - 128) * 257);
      
      // Apply volume with better precision
      sample = (int16_t)((int32_t)sample * amplitude / 32767);
      
      // Send to I2S
      i2s.write((uint8_t*)&sample, sizeof(int16_t));
    }
    
    totalBytesRead += bytesRead;
  }
  
  wavFile.close();
  Serial.println("[INFO] Playback complete");
}

// Listen for serial input and handle commands
void handleSerialInput() {
  if (Serial.available()) {
    String input = Serial.readStringUntil('\n');
    input.trim();
    
    if (input.equalsIgnoreCase("p") || input.equalsIgnoreCase("play")) {
      Serial.println("[INFO] Playing 8-bit WAV file...");
      playWAVFile();
    } else {
      int newAmp = input.toInt();
      if (newAmp >= 0 && newAmp <= 32767) {
        amplitude = newAmp;
        Serial.printf("[INFO] Volume set to %d\n", amplitude);
      } else {
        Serial.println("[INFO] Commands: 'p' = play, number = volume (0-32767)");
      }
    }
  }
}


