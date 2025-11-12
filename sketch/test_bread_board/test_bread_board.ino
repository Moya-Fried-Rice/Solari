#include <ESP_I2S.h>
#include "done.h"
#include "processing.h"
#include "harvard.h"
#include "FS.h"
#include "SD.h"
#include "SPI.h"

// --- Pin Definitions ---
#define I2S_BCLK   D1       // I2S BCLK
#define I2S_LRC    D0       // I2S LRC / WS
#define I2S_DOUT   D2       // I2S Data Out
#define SD_CS      21       // SD Card CS pin
#define VBUS_PIN   9        // Pin to monitor USB VBUS voltage (GPIO9 on XIAO ESP32-S3)

// --- Button ---
const int buttonPin = D8;        // Pin where the button is connected
bool lastButtonState = HIGH;     // Previous button state (HIGH when not pressed with pull-up)
bool buttonPressed = false;      // Track button press state

// --- Auto Sleep ---
const unsigned long IDLE_TIMEOUT = 20000;  // 20 seconds in milliseconds
unsigned long lastActivityTime = 0;        // Track last activity time

// --- USB State Tracking ---
bool usbWasConnectedBeforeSleep = false;    // Track USB state before sleep

// --- Processing Loop ---
bool isProcessingLooping = false;           // Track if processing sound is looping
unsigned long lastProcessingPlay = 0;       // Track last time processing sound was played

// --- Auto Sleep Control ---
bool isAutoSleepEnabled = true;             // Track if auto-sleep is enabled

I2SClass I2S;

void playAudio(const unsigned char* audioData, unsigned int audioLength, const char* audioName) {
  Serial.print("Playing ");
  Serial.print(audioName);
  Serial.println("...");

  // Amplification factor (adjust this value to increase/decrease volume)
  // Values: 1.0 = no change, 2.0 = double volume, 0.5 = half volume
  const float amplification = 3.0;

  // Play the raw audio data with amplification
  const size_t BUFFER_SIZE = 512;
  unsigned int bytesPlayed = 0;
  int16_t amplifiedBuffer[BUFFER_SIZE / 2]; // Buffer for amplified samples

  while (bytesPlayed < audioLength) {
    size_t bytesToPlay = min(BUFFER_SIZE, audioLength - bytesPlayed);
    
    // Amplify the audio samples
    for (size_t i = 0; i < bytesToPlay; i += 2) {
      if (bytesPlayed + i + 1 < audioLength) {
        // Convert bytes to 16-bit sample
        int16_t sample = (int16_t)((audioData[bytesPlayed + i + 1] << 8) | audioData[bytesPlayed + i]);
        
        // Apply amplification with clipping protection
        int32_t amplifiedSample = (int32_t)(sample * amplification);
        if (amplifiedSample > 32767) amplifiedSample = 32767;
        if (amplifiedSample < -32768) amplifiedSample = -32768;
        
        amplifiedBuffer[i / 2] = (int16_t)amplifiedSample;
      }
    }
    
    // Write amplified samples to I2S
    I2S.write((uint8_t*)amplifiedBuffer, bytesToPlay);
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

void playHarvard() {
  playAudio(harvard_audio_data, harvard_audio_length, "Harvard");
}

void playAudioFromSD(const char* filename, const char* audioName) {
  Serial.print("Playing ");
  Serial.print(audioName);
  Serial.print(" from SD card: ");
  Serial.println(filename);

  // Check if SD card is still mounted
  if (SD.cardType() == CARD_NONE) {
    Serial.println("SD Card not detected or not mounted");
    return;
  }

  // Check if file exists
  if (!SD.exists(filename)) {
    Serial.print("File does not exist: ");
    Serial.println(filename);
    Serial.println("Listing files on SD card:");
    File root = SD.open("/");
    File file = root.openNextFile();
    while(file) {
      Serial.print("  ");
      Serial.println(file.name());
      file = root.openNextFile();
    }
    root.close();
    return;
  }

  File audioFile = SD.open(filename);
  if (!audioFile) {
    Serial.println("Failed to open audio file from SD card");
    return;
  }

  // Get file size for progress tracking
  size_t fileSize = audioFile.size();
  Serial.print("File size: ");
  Serial.print(fileSize);
  Serial.println(" bytes");

  // Skip WAV header (44 bytes) if it's a WAV file
  if (String(filename).endsWith(".wav") || String(filename).endsWith(".WAV")) {
    audioFile.seek(44);
    Serial.println("Skipped WAV header (44 bytes)");
  }

  // Amplification factor (adjust this value to increase/decrease volume)
  const float amplification = 3.0;

  // Buffer for reading and amplifying audio data
  const size_t BUFFER_SIZE = 512;
  uint8_t buffer[BUFFER_SIZE];
  int16_t amplifiedBuffer[BUFFER_SIZE / 2];
  
  size_t totalBytesRead = 0;
  unsigned long startTime = millis();

  while (audioFile.available()) {
    size_t bytesRead = audioFile.read(buffer, BUFFER_SIZE);
    totalBytesRead += bytesRead;
    
    // Progress indicator every 10KB
    if (totalBytesRead % 10240 == 0) {
      Serial.print("Progress: ");
      Serial.print(totalBytesRead);
      Serial.print(" / ");
      Serial.print(fileSize);
      Serial.println(" bytes");
    }
    
    // Amplify the audio samples
    for (size_t i = 0; i < bytesRead; i += 2) {
      if (i + 1 < bytesRead) {
        // Convert bytes to 16-bit sample
        int16_t sample = (int16_t)((buffer[i + 1] << 8) | buffer[i]);
        
        // Apply amplification with clipping protection
        int32_t amplifiedSample = (int32_t)(sample * amplification);
        if (amplifiedSample > 32767) amplifiedSample = 32767;
        if (amplifiedSample < -32768) amplifiedSample = -32768;
        
        amplifiedBuffer[i / 2] = (int16_t)amplifiedSample;
      }
    }
    
    // Write amplified samples to I2S
    I2S.write((uint8_t*)amplifiedBuffer, bytesRead);
    
    // Add a small delay to prevent watchdog timeout on large files
    if (millis() - startTime > 100) {
      delay(1);
      startTime = millis();
    }
  }

  audioFile.close();

  Serial.print("Total bytes played: ");
  Serial.println(totalBytesRead);

  // Send 50 ms of silence to avoid click
  int silenceSamples = 11025 / 20; // 50ms of silence for 11025 Hz
  for (int i = 0; i < silenceSamples; i++) {
    int16_t silence = 0;
    I2S.write((uint8_t *)&silence, sizeof(silence));
  }

  Serial.print(audioName);
  Serial.println(" playback completed!");
}

void playharvard() {
  playAudioFromSD("/harvard.wav", "harvard from SD");
}

void playsdharvard() {
  playAudioFromSD("/harvard.wav", "harvard from SD");
}

void enterDeepSleep() {
  Serial.println("Entering deep sleep...");
  Serial.println("Device will wake up when USB-C charger is reconnected.");
  
  // Store current USB connection status before sleeping
  usbWasConnectedBeforeSleep = isUSBConnected();
  Serial.print("Current USB status before sleep: ");
  Serial.println(usbWasConnectedBeforeSleep ? "Connected" : "Disconnected");
  
  // Always wake up on USB connection (HIGH), regardless of current state
  // If USB is already connected, user needs to unplug and replug to wake up
  esp_sleep_enable_ext1_wakeup(1ULL << VBUS_PIN, ESP_EXT1_WAKEUP_ANY_HIGH);
  
  delay(100); // Give time for serial message to be sent
  
  // Enter deep sleep
  esp_deep_sleep_start();
}

bool isUSBConnected() {
  // For XIAO ESP32-S3, we can check if USB is connected by reading GPIO9
  // GPIO9 is connected to VBUS through a voltage divider
  int vbusReading = analogRead(VBUS_PIN);
  // The ADC reading will be higher when USB is connected
  // Typical values: ~0 when disconnected, >1000 when connected
  return vbusReading > 500; // Adjust threshold as needed
}

float readTemperature() {
  // Use ESP32's built-in temperature sensor (same as Solari project)
  // This reads the actual internal temperature of the ESP32 chip
  return temperatureRead();
}


void setup() {
  Serial.begin(115200);
  Serial.println("\nRAW Audio Player with Command");

  // Check wake-up reason
  esp_sleep_wakeup_cause_t wakeup_reason = esp_sleep_get_wakeup_cause();
  switch(wakeup_reason) {
    case ESP_SLEEP_WAKEUP_EXT1:
      delay(100); // Small delay to stabilize readings
      
      // Check if this is a valid USB connection wake-up
      if (isUSBConnected()) {
        if (usbWasConnectedBeforeSleep) {
          // USB was connected before sleep, so this must be a reconnection
          Serial.println("Woke up from USB-C charger reconnection!");
        } else {
          // USB was not connected before sleep, so this is a new connection
          Serial.println("Woke up from USB-C charger connection!");
        }
      } else {
        // False wake-up, USB not actually connected
        Serial.println("False wake-up, USB not connected. Going back to sleep...");
        delay(100);
        enterDeepSleep();
      }
      break;
    case ESP_SLEEP_WAKEUP_UNDEFINED:
      Serial.println("Power on or reset wake up");
      break;
    default:
      Serial.printf("Wake up from other source: %d\n", wakeup_reason);
      break;
  }

  // Initialize built-in LED
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);

  // Initialize VBUS monitoring pin
  pinMode(VBUS_PIN, INPUT);

  // Initialize SD card
  if (!SD.begin(SD_CS)) {
    Serial.println("SD Card Mount Failed");
  } else {
    Serial.println("SD Card initialized!");
    uint8_t cardType = SD.cardType();
    if (cardType != CARD_NONE) {
      Serial.print("SD Card Type: ");
      if (cardType == CARD_MMC) {
        Serial.println("MMC");
      } else if (cardType == CARD_SD) {
        Serial.println("SDSC");
      } else if (cardType == CARD_SDHC) {
        Serial.println("SDHC");
      } else {
        Serial.println("UNKNOWN");
      }
    }
  }

  I2S.setPins(I2S_BCLK, I2S_LRC, I2S_DOUT);
  if (!I2S.begin(I2S_MODE_STD, 22050, I2S_DATA_BIT_WIDTH_16BIT, I2S_SLOT_MODE_MONO)) {
    Serial.println("I2S init failed!");
    while (true);
  }

  // Initialize button pin as input with internal pull-up
  pinMode(buttonPin, INPUT_PULLUP);

  Serial.println("Audio system initialized!");
  Serial.println("Button initialized!");
  Serial.println("Available commands:");
  Serial.println("  'done' - Play done audio");
  Serial.println("  'processing' - Play processing audio");
  Serial.println("  'harvard' - Play harvard audio from memory");
  Serial.println("  'sdharvard' - Play harvard audio from SD card");
  Serial.println("  'play' - Play done audio (for compatibility)");
  Serial.println("  'sleep' - Enter deep sleep mode");
  Serial.println("  'usb' - Check USB connection status");
  Serial.println("  'loop' - Start/stop looping processing sound every 5 seconds");
  Serial.println("  'autosleep' - Enable/disable auto-sleep after 20 seconds of inactivity");
  Serial.println("  'ls' - List files on SD card");
  Serial.println("  'lsall' - List all files recursively on SD card");
  Serial.println("Press the button to play processing sound!");
  
  // Display initial USB connection status
  Serial.print("USB connection status: ");
  Serial.println(isUSBConnected() ? "Connected" : "Disconnected");
  
  // Initialize activity timer
  lastActivityTime = millis();
  Serial.print("Auto-sleep ");
  Serial.print(isAutoSleepEnabled ? "enabled" : "disabled");
  Serial.println(": Device will sleep after 20 seconds of inactivity when enabled");
}

void loop() {
  // Check for auto-sleep timeout
  if (isAutoSleepEnabled && millis() - lastActivityTime > IDLE_TIMEOUT) {
    Serial.println("Auto-sleep: 20 seconds of inactivity detected. Entering deep sleep...");
    delay(100); // Give time for serial message
    enterDeepSleep();
  }

  // Blink LED to show device is running
  static unsigned long lastBlink = 0;
  static bool ledState = false;
  if (millis() - lastBlink > 1000) {  // Blink every 1 second
    ledState = !ledState;
    digitalWrite(LED_BUILTIN, ledState ? HIGH : LOW);
    lastBlink = millis();
  }

  // Read and display temperature every 5 seconds
  static unsigned long lastTempRead = 0;
  if (millis() - lastTempRead > 5000) {  // Read temperature every 5 seconds
    float temperature = readTemperature();
    Serial.print("Temperature: ");
    Serial.print(temperature);
    Serial.println(" °C");
    lastTempRead = millis();
  }

  // Monitor USB connection status every 10 seconds
  static unsigned long lastUSBCheck = 0;
  static bool lastUSBState = false;
  if (millis() - lastUSBCheck > 10000) {  // Check USB every 10 seconds
    bool currentUSBState = isUSBConnected();
    if (currentUSBState != lastUSBState) {
      Serial.print("USB status changed: ");
      Serial.println(currentUSBState ? "Connected" : "Disconnected");
      lastUSBState = currentUSBState;
    }
    lastUSBCheck = millis();
  }

  // Handle processing sound looping
  if (isProcessingLooping) {
    if (millis() - lastProcessingPlay >= 5000) {  // Play every 5 seconds
      Serial.println("Loop: Playing processing sound...");
      playProcessing();
      lastProcessingPlay = millis();
      lastActivityTime = millis(); // Reset activity timer when looping
    }
  }

  // Check for button press
  int currentButtonState = digitalRead(buttonPin);
  
  // Detect button press (HIGH to LOW transition with pull-up resistor)
  if (currentButtonState == LOW && lastButtonState == HIGH) {
    Serial.println("Button Pressed - Playing processing sound");
    playProcessing();
    lastActivityTime = millis(); // Reset activity timer on button press
    buttonPressed = true;
  } else if (currentButtonState == HIGH && lastButtonState == LOW) {
    Serial.println("Button Released");
    buttonPressed = false;
  }
  
  lastButtonState = currentButtonState; // Remember state for next loop
  
  // Check for serial commands
  if (Serial.available()) {
    String cmd = Serial.readStringUntil('\n');
    cmd.trim();
    
    // Reset activity timer on any command
    lastActivityTime = millis();
    
    if (cmd.equalsIgnoreCase("done") || cmd.equalsIgnoreCase("play")) {
      playDone();
    } else if (cmd.equalsIgnoreCase("processing")) {
      playProcessing();
    } else if (cmd.equalsIgnoreCase("harvard")) {
      playHarvard();
    } else if (cmd.equalsIgnoreCase("sdharvard")) {
      playsdharvard();
    } else if (cmd.equalsIgnoreCase("sleep")) {
      enterDeepSleep();
    } else if (cmd.equalsIgnoreCase("usb")) {
      Serial.print("USB connection status: ");
      Serial.println(isUSBConnected() ? "Connected" : "Disconnected");
    } else if (cmd.equalsIgnoreCase("loop")) {
      isProcessingLooping = !isProcessingLooping;
      if (isProcessingLooping) {
        Serial.println("Started looping processing sound every 5 seconds");
        lastProcessingPlay = millis(); // Start immediately
        playProcessing();
      } else {
        Serial.println("Stopped looping processing sound");
      }
    } else if (cmd.equalsIgnoreCase("autosleep")) {
      isAutoSleepEnabled = !isAutoSleepEnabled;
      if (isAutoSleepEnabled) {
        Serial.println("Auto-sleep enabled: Device will sleep after 20 seconds of inactivity");
        lastActivityTime = millis(); // Reset timer when enabling
      } else {
        Serial.println("Auto-sleep disabled: Device will not automatically sleep");
      }
    } else if (cmd.equalsIgnoreCase("ls")) {
      Serial.println("Files on SD card:");
      if (SD.cardType() == CARD_NONE) {
        Serial.println("SD Card not detected or not mounted");
      } else {
        File root = SD.open("/");
        File file = root.openNextFile();
        if (!file) {
          Serial.println("  (no files found)");
        }
        while(file) {
          Serial.print("  ");
          Serial.print(file.name());
          Serial.print(" (");
          Serial.print(file.size());
          Serial.println(" bytes)");
          file = root.openNextFile();
        }
        root.close();
      }
    } else {
      Serial.println("Unknown command. Available commands: 'done', 'processing', 'harvard', 'sdharvard', 'play', 'sleep', 'usb', 'loop', 'autosleep', 'ls', 'lsall'");
    }
  }
  
  delay(50); // Small debounce delay for touch sensor
}
