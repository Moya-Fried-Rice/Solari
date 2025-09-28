#include "ESP_I2S.h"
#include <SD.h>
#include <SPI.h>

/*
 * 16-BIT PCM WAV PLAYER FOR SMART GLASSES
 * 
 * SUPPORTS:
 * - 16kHz, 16-bit PCM, mono WAV files
 * - High quality audio playback
 * - Optimized for best audio quality
 */

// Xiao ESP32-S3 pin names (works fine)
#define I2S_BCLK D1  // BCLK
#define I2S_LRC  D0  // LRC / WS
#define I2S_DOUT D2  // DIN

// SD Card pins for Xiao ESP32-S3 (using pin 21 like in camera example)
#define SD_CS_PIN 21

#define WAV_FILE_NAME "/processing.wav"

int16_t amplitude = 32767;  // Maximum amplitude for best quality (can be changed via Serial)

// WAV header structure for 16-bit PCM files
struct WAVHeader {
  uint32_t sampleRate;
  uint32_t dataSize;
  uint16_t numChannels;
  uint16_t bitsPerSample;
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
  Serial.println("\n16-BIT PCM WAV PLAYER FOR SMART GLASSES");
  
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
  
  setupI2S(16000);  // Fixed 16kHz for high quality
  Serial.println("Ready! Commands: 'p' = play, number = volume (0-32767)");
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
  file.seek(0);
  
  // Read and verify RIFF header
  char riffHeader[4];
  file.read((uint8_t*)riffHeader, 4);
  if (strncmp(riffHeader, "RIFF", 4) != 0) {
    Serial.println("[ERROR] Not a valid WAV file - missing RIFF header");
    return false;
  }
  
  // Skip file size (4 bytes) and read WAVE header
  file.seek(8);
  char waveHeader[4];
  file.read((uint8_t*)waveHeader, 4);
  if (strncmp(waveHeader, "WAVE", 4) != 0) {
    Serial.println("[ERROR] Not a valid WAV file - missing WAVE header");
    return false;
  }
  
  // Read format code at offset 20 (should be 1 for PCM)
  file.seek(20);
  uint16_t formatCode;
  file.read((uint8_t*)&formatCode, 2);
  
  if (formatCode != 1) {
    Serial.printf("[ERROR] Expected PCM format (1), got format %d\n", formatCode);
    return false;
  }
  
  // Read number of channels at offset 22
  file.seek(22);
  file.read((uint8_t*)&header.numChannels, 2);
  
  // Read sample rate from offset 24
  file.seek(24);
  file.read((uint8_t*)&header.sampleRate, 4);
  
  // Read bits per sample from offset 34
  file.seek(34);
  file.read((uint8_t*)&header.bitsPerSample, 2);
  
  // Find data chunk (it might not always be at offset 40)
  file.seek(36);
  char chunkId[4];
  uint32_t chunkSize;
  
  while (file.available()) {
    file.read((uint8_t*)chunkId, 4);
    file.read((uint8_t*)&chunkSize, 4);
    
    if (strncmp(chunkId, "data", 4) == 0) {
      header.dataSize = chunkSize;
      break;
    }
    
    // Skip this chunk
    file.seek(file.position() + chunkSize);
  }
  
  Serial.printf("[INFO] 16-bit PCM WAV: %d Hz, %d channels, %d bits, %d bytes\n", 
                header.sampleRate, header.numChannels, header.bitsPerSample, header.dataSize);
  
  // Validate format
  if (header.bitsPerSample != 16) {
    Serial.printf("[ERROR] Expected 16-bit, got %d-bit\n", header.bitsPerSample);
    return false;
  }
  
  if (header.numChannels != 1) {
    Serial.printf("[WARN] Expected mono (1 channel), got %d channels - will play first channel only\n", header.numChannels);
  }
  
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
  
  // Dynamically configure I2S for the file's sample rate (prefer 16kHz)
  if (header.sampleRate != 16000) {
    Serial.printf("[WARN] Expected 16kHz, got %d Hz - reconfiguring I2S\n", header.sampleRate);
    setupI2S(header.sampleRate);
  }
  
  // Calculate duration and samples
  uint32_t totalSamples = header.dataSize / (header.bitsPerSample / 8) / header.numChannels;
  float duration = (float)totalSamples / header.sampleRate;
  Serial.printf("[INFO] Playing: %.2f seconds, %d samples at %d Hz\n", duration, totalSamples, header.sampleRate);
  
  const size_t chunkSize = 256;  // Larger chunk for 16-bit samples (128 samples)
  uint8_t audioData[chunkSize];
  uint32_t totalBytesRead = 0;
  
  while (totalBytesRead < header.dataSize) {
    size_t bytesToRead = min(chunkSize, (size_t)(header.dataSize - totalBytesRead));
    size_t bytesRead = wavFile.read(audioData, bytesToRead);
    
    if (bytesRead == 0) break;
    
    // Process 16-bit PCM samples
    for (size_t i = 0; i < bytesRead; i += 2 * header.numChannels) {
      // Read 16-bit sample (little-endian)
      int16_t sample = (int16_t)(audioData[i] | (audioData[i + 1] << 8));
      
      // Apply volume scaling for highest quality
      if (amplitude != 32767) {
        // Use 32-bit arithmetic to prevent overflow
        int32_t scaledSample = ((int32_t)sample * amplitude) / 32767;
        sample = (int16_t)constrain(scaledSample, -32768, 32767);
      }
      
      // Send to I2S (already in correct 16-bit format)
      i2s.write((uint8_t*)&sample, sizeof(int16_t));
      
      // Skip additional channels if stereo (we only play the first channel)
      if (header.numChannels > 1) {
        i += 2 * (header.numChannels - 1);
      }
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
      Serial.println("[INFO] Playing 16-bit PCM WAV file...");
      playWAVFile();
    } else {
      int newAmp = input.toInt();
      if (newAmp >= 0 && newAmp <= 32767) {
        amplitude = newAmp;
        Serial.printf("[INFO] Volume set to %d (%.1f%%)\n", amplitude, (float)amplitude / 327.67);
      } else {
        Serial.println("[INFO] Commands: 'p' = play, number = volume (0-32767)");
        Serial.println("[INFO] Supports 16kHz, 16-bit PCM WAV files for highest quality!");
      }
    }
  }
}


