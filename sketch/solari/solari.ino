  // ============================================================================
  // SOLARI Smart Glasses - VQA (Visual Question Answering)
  // ============================================================================
  // Visual Question Answering functionality with camera and microphone
  // ============================================================================
  
  #include <BLEDevice.h>
  #include <BLEUtils.h>
  #include <BLEServer.h>
  #include "esp_camera.h"
  #include "ESP_I2S.h"
  #include "esp_adc_cal.h"
  #include <BLE2902.h>

  #define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
  #define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"
  #define SPEAKER_CHARACTERISTIC_UUID "12345678-1234-1234-1234-123456789abc"
  #define TEMP_CHARACTERISTIC_UUID "00002A6E-0000-1000-8000-00805F9B34FB"

  #define CAPTURE_DEBOUNCE_MS 500
  #define SEND_DELAY_BETWEEN_CHUNKS_MS 50

  #define VQA_STREAM_CHUNK_DURATION_MS 150  // 500ms chunks for VQA streaming
  #define VQA_STREAM_BUFFER_COUNT 4         // Number of buffers for smooth streaming

  #define BUTTON_PIN D4

// I2S Speaker Pin Definitions
#define I2S_BCLK   D1       // I2S BCLK
#define I2S_LRC    D0       // I2S LRC / WS  
#define I2S_DOUT   D2       // I2S Data Out

  // ============================================================================
  // LED and Button Globals
  // ============================================================================
  const int led_pin = LED_BUILTIN; // On-board LED

  bool ledState = false;     // indicator LED state (mirrors vqa running)
  bool lastButtonState = HIGH; // Previous button state (HIGH = not pressed due to pullup)
  unsigned long lastButtonMillis = 0;
  const unsigned long BUTTON_DEBOUNCE_MS = 200; // Button debounce time



  // ============================================================================
  // Temperature Globals
  // ============================================================================
  float tempThreshold = 55.0; // °C limit before shutdown
  TaskHandle_t tempTaskHandle;
  bool tempMonitoringEnabled = false; // Enable/disable temperature monitoring



  // ============================================================================
  // BLE Globals
  // ============================================================================
  bool deviceConnected = false;
  bool systemInitialized = false;
  BLECharacteristic* pCharacteristic;
  BLECharacteristic* pSpeakerCharacteristic;
  BLECharacteristic* pTempCharacteristic;
  int negotiatedChunkSize = 23;
  I2SClass i2s;
  I2SClass i2s_speaker; // Separate I2S instance for speaker output



  // ============================================================================
  // Audio Playback Globals
  // ============================================================================
  
  // Audio buffer for incoming BLE audio data
  #define AUDIO_BUFFER_SIZE 8192  // 8KB buffer for audio chunks
  uint8_t audioBuffer[AUDIO_BUFFER_SIZE];
  size_t audioBufferIndex = 0;
  bool audioReceiving = false;
  size_t expectedAudioSize = 0;
  
  // Audio format constants (matching Flutter app output)
  const int SPEAKER_SAMPLE_RATE = 11025;
  const int SPEAKER_BIT_DEPTH = 16;
  const int SPEAKER_CHANNELS = 1; // Mono



  // ============================================================================
  // VQA Globals
  // ============================================================================
  struct VQAState {
    bool isRunning = false;
    bool stopRequested = false;
    bool imageTransmissionComplete = false;
    bool audioRecordingInProgress = false;
    bool audioRecordingComplete = false;
    unsigned long audioRecordingStartTime = 0;
    TaskHandle_t vqaTaskHandle = nullptr;
    
    // Streaming audio state
    bool audioStreamingActive = false;
    size_t totalAudioStreamed = 0;
    unsigned long streamStartTime = 0;
  };
  VQAState vqaState;

  // Microphone configuration (for VQA recording)
  const int MIC_SAMPLE_RATE = 8000;           // Keep lower for VQA transmission efficiency
  const int MIC_BIT_DEPTH = 16;



  // ============================================================================
  // Enhanced Logging System
  // ============================================================================

  // Log levels
  enum LogLevel {
    LOG_DEBUG = 0,
    LOG_INFO = 1,
    LOG_WARN = 2,
    LOG_ERROR = 3
  };

  // Current log level (change to LOG_DEBUG for more verbose output)
  LogLevel currentLogLevel = LOG_DEBUG;

  // Log level strings
  const char* logLevelStr[] = {"DEBUG", "INFO", "WARN", "ERROR"};

  // Enhanced logging function
  void log(LogLevel level, const String &component, const String &msg) {
    if (level >= currentLogLevel) {
      Serial.printf("[%8lu] [%s] [%s] %s\n", 
                    millis(), 
                    logLevelStr[level], 
                    component.c_str(), 
                    msg.c_str());
    }
  }

  // Convenience functions for different log levels
  void logInfo(const String &component, const String &msg) {
    log(LOG_INFO, component, msg);
  }

  void logWarn(const String &component, const String &msg) {
    log(LOG_WARN, component, msg);
  }

  void logError(const String &component, const String &msg) {
    log(LOG_ERROR, component, msg);
  }

  void logDebug(const String &component, const String &msg) {
    log(LOG_DEBUG, component, msg);
  }

  // Memory info helper
  void logMemory(const String &component) {
    if (currentLogLevel <= LOG_DEBUG) {
      log(LOG_DEBUG, component, "Free heap: " + String(ESP.getFreeHeap()) + 
          " bytes, PSRAM: " + String(ESP.getFreePsram()) + " bytes");
    }
  }

  // Enhanced progress logger with transfer rate
  void logProgressRate(const String &component, size_t current, size_t total, unsigned long startTime) {
    if (currentLogLevel <= LOG_INFO) {
      int percent = (current * 100) / total;
      unsigned long elapsed = millis() - startTime;
      float rate = 0;
      if (elapsed > 0) {
        rate = (current / 1024.0) / (elapsed / 1000.0); // KB/s
      }
      
      // Create progress bar
      const int barWidth = 20;
      int filled = (percent * barWidth) / 100;
      String progressBar = "[";
      
      for (int i = 0; i < barWidth; i++) {
        if (i < filled) {
          progressBar += "█";
        } else {
          progressBar += "░";
        }
      }
      progressBar += "]";
      
      log(LOG_INFO, component, progressBar + " (" + String(percent) + "%) " + 
          String(current) + "/" + String(total) + " bytes - " + String(rate, 1) + " KB/s");
    }
  }

  // Streaming audio logger
  void logStreamingProgress(const String &component, size_t chunkSize, size_t totalStreamed, unsigned long startTime, int chunkNumber) {
    if (currentLogLevel <= LOG_INFO) {
      unsigned long elapsed = millis() - startTime;
      float rate = 0;
      if (elapsed > 0) {
        rate = (totalStreamed / 1024.0) / (elapsed / 1000.0); // KB/s
      }
      
      log(LOG_INFO, component, "Chunk #" + String(chunkNumber) + " (" + String(chunkSize) + " bytes) - " + 
          "Total: " + String(totalStreamed/1024.0, 1) + " KB @ " + String(rate, 1) + " KB/s");
    }
  }



  // ============================================================================
  // BLE Server Callbacks
  // ============================================================================

  class MyServerCallbacks : public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) override {
      Serial.println();
      logInfo("BLE", "!! Client connected !!");
      deviceConnected = true;
      logMemory("BLE");
      
      // Initialize system components when connected
      if (!systemInitialized) {
        initializeSystem();
      }
    }
    void onDisconnect(BLEServer* pServer) override {
      Serial.println();
      logWarn("BLE", "!! Client disconnected !!");
      deviceConnected = false;
      
      // Clean up system components when disconnected
      if (systemInitialized) {
        cleanupSystem();
      }
      
      BLEDevice::startAdvertising();
      logInfo("BLE", "Advertising restarted");
    }
    void onMtuChanged(BLEServer* pServer, esp_ble_gatts_cb_param_t* param) override {
      int mtu = param->mtu.mtu;
      negotiatedChunkSize = max(20, mtu - 3); // 3 bytes for ATT header
      logInfo("BLE", "MTU changed: " + String(mtu) + " bytes, "
                    "chunk size set to: " + String(negotiatedChunkSize) + " bytes");
    }
  };

  // VQA Characteristic Callback - Handles VQA commands and data
  class VQACharacteristicCallbacks : public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic* pCharacteristic) override {
      String value = pCharacteristic->getValue().c_str();
      uint8_t* data = pCharacteristic->getData();
      size_t length = pCharacteristic->getLength();
      
      logDebug("VQA-BLE", "Data received: \"" + value + "\" (" + String(length) + " bytes)");
      
      // Handle VQA commands
      if (value == "VQA_START") {
        logInfo("VQA", "Start command received");
        if (!vqaState.isRunning) {
          startVqaStreaming();
        } else {
          logWarn("VQA", "VQA already running");
        }
      } else if (value == "VQA_STOP") {
        logInfo("VQA", "Stop command received");
        if (vqaState.isRunning) {
          vqaState.stopRequested = true;
        } else {
          logWarn("VQA", "No VQA session to stop");
        }
      } else {
        // Log other VQA data for debugging
        logDebug("VQA-BLE", "Unknown VQA command: \"" + value + "\"");
      }
    }
  };

  // Speaker Characteristic Callback - Handles audio data for playback
  class SpeakerCharacteristicCallbacks : public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic* pCharacteristic) override {
      String value = pCharacteristic->getValue().c_str();
      uint8_t* data = pCharacteristic->getData();
      size_t length = pCharacteristic->getLength();
      
      // Check if this is an audio transmission start
      if (value.startsWith("S_START:")) {
        // Audio start header - extract expected size
        String sizeStr = value.substring(8); // Remove "S_START:" prefix
        expectedAudioSize = sizeStr.toInt();
        audioBufferIndex = 0;
        audioReceiving = true;
        logInfo("AUDIO", "Started receiving audio data, expected size: " + String(expectedAudioSize) + " bytes");
        return;
      }
      
      // Check if this is an audio transmission end
      if (value == "S_END") {
        // Audio end header - play the received audio
        audioReceiving = false;
        logInfo("AUDIO", "Finished receiving audio data, total received: " + String(audioBufferIndex) + " bytes");
        
        if (audioBufferIndex > 0) {
          playReceivedAudio();
        } else {
          logWarn("AUDIO", "No audio data received to play");
        }
        return;
      }
      
      // Handle audio data chunks
      if (audioReceiving && length > 0) {
        // Ensure we don't overflow the buffer
        size_t bytesToCopy = min(length, AUDIO_BUFFER_SIZE - audioBufferIndex);
        if (bytesToCopy > 0) {
          memcpy(audioBuffer + audioBufferIndex, data, bytesToCopy);
          audioBufferIndex += bytesToCopy;
          
          // Log progress occasionally
          static unsigned long lastProgressLog = 0;
          if (millis() - lastProgressLog > 500) { // Log every 500ms
            int percent = expectedAudioSize > 0 ? (audioBufferIndex * 100) / expectedAudioSize : 0;
            logDebug("AUDIO", "Audio progress: " + String(percent) + "% (" + String(audioBufferIndex) + "/" + String(expectedAudioSize) + " bytes)");
            lastProgressLog = millis();
          }
        } else {
          logWarn("AUDIO", "Audio buffer overflow - chunk ignored");
        }
        return;
      }
      
      // Handle non-audio data (for debugging)
      if (!audioReceiving) {
        logDebug("SPEAKER-BLE", "Non-audio data received: \"" + value + "\" (" + String(length) + " bytes)");
      }
    }
  };





  // ============================================================================
  // System Initialization and Cleanup
  // ============================================================================

  // Initialize and setup all components
  void initializeSystem() {
    Serial.println();
    logInfo("SYS", "========================== Initializing system components ==========================");
    
    // Initialize Camera
    initCamera();

    // Initialize Microphone
    initMicrophone();
    
    // Initialize Speaker
    initSpeaker();

    systemInitialized = true;
    logInfo("SYS", "========================== System initialization complete ==========================");
    Serial.println();
    logMemory("SYS");
  }



  // Cleanup and free all resources
  void cleanupSystem() {
    Serial.println();
    logInfo("SYS", "========================== Cleaning up system components ==========================");
    
    // Clean up VQA background task if running
    if (vqaState.vqaTaskHandle) {
      vqaState.stopRequested = true;
      vTaskDelay(pdMS_TO_TICKS(100)); // Give time for graceful stop
      if (vqaState.vqaTaskHandle) {
        vTaskDelete(vqaState.vqaTaskHandle);
        vqaState.vqaTaskHandle = nullptr;
      }
      vqaState.isRunning = false;
      logInfo("SYS", "VQA streaming task deleted");
    }
    
    // Reset VQA state
    vqaState.isRunning = false;
    vqaState.stopRequested = false;
    vqaState.imageTransmissionComplete = false;
    vqaState.audioRecordingInProgress = false;
    vqaState.audioRecordingComplete = false;
    vqaState.audioStreamingActive = false;
    vqaState.totalAudioStreamed = 0;
    vqaState.audioRecordingStartTime = 0;
    
    // Deinitialize camera
    esp_camera_deinit();
    logInfo("SYS", "Camera deinitialized");
    
    // Stop I2S (microphone only)
    i2s.end();
    logInfo("SYS", "Microphone deinitialized");
    
    // Deinitialize speaker
    deinitSpeaker();
    
    systemInitialized = false;
    logInfo("SYS", "========================== System cleanup complete ==========================");
    Serial.println();
    logMemory("SYS");
  }



  // ============================================================================
  // Setup Camera
  // ============================================================================

  #include "camera_pins.h"
  void initCamera() {
    logInfo("CAM", "Initializing camera...");
    
    camera_config_t config = {};
    config.ledc_channel = LEDC_CHANNEL_0;
    config.ledc_timer = LEDC_TIMER_0;
    config.pin_d0 = Y2_GPIO_NUM;
    config.pin_d1 = Y3_GPIO_NUM;
    config.pin_d2 = Y4_GPIO_NUM;
    config.pin_d3 = Y5_GPIO_NUM;
    config.pin_d4 = Y6_GPIO_NUM;
    config.pin_d5 = Y7_GPIO_NUM;
    config.pin_d6 = Y8_GPIO_NUM;
    config.pin_d7 = Y9_GPIO_NUM;
    config.pin_xclk = XCLK_GPIO_NUM;
    config.pin_pclk = PCLK_GPIO_NUM;
    config.pin_vsync = VSYNC_GPIO_NUM;
    config.pin_href = HREF_GPIO_NUM;
    config.pin_sscb_sda = SIOD_GPIO_NUM;
    config.pin_sscb_scl = SIOC_GPIO_NUM;
    config.pin_pwdn = PWDN_GPIO_NUM;
    config.pin_reset = RESET_GPIO_NUM;
    config.xclk_freq_hz = 20000000;
    
    // ------------------------------------------ 
    // Image Resolution 
    // ------------------------------------------ 
    // FRAMESIZE_QVGA - 320x240 
    // FRAMESIZE_CIF - 400x296 
    // FRAMESIZE_VGA - 640x480 
    // FRAMESIZE_SVGA - 800x600 
    // FRAMESIZE_XGA - 1024x768 
    // FRAMESIZE_HD - 1280x720 
    // FRAMESIZE_UXGA - 1600x1200
    // FRAMESIZE_QSXGA - 2592x1944
    config.frame_size = FRAMESIZE_XGA; 
    // ------------------------------------------

    config.pixel_format = PIXFORMAT_JPEG;
    config.grab_mode = CAMERA_GRAB_LATEST;
    config.fb_location = CAMERA_FB_IN_PSRAM;
    config.jpeg_quality = psramFound() ? 10 : 12;
    config.fb_count = psramFound() ? 2 : 1;

    logDebug("CAM", "PSRAM found: " + String(psramFound() ? "Yes" : "No"));

    if (esp_camera_init(&config) != ESP_OK) {
      logError("CAM", "Camera initialization failed!");
      while (true) delay(100);
    }
    
    logInfo("CAM", "Camera ready");
    logMemory("CAM");
  }



  // ============================================================================
  // Setup Microphone / I2S
  // ============================================================================

  void initMicrophone() {
      logInfo("MIC", "Initializing microphone...");
      
      // Set the RX pins for PDM microphone
      i2s.setPinsPdmRx(42, 41);
      logDebug("MIC", "PDM pins configured: CLK=42, DATA=41");

      // Begin I2S in PDM RX mode for microphone (VQA recording)
      if (!i2s.begin(I2S_MODE_PDM_RX, MIC_SAMPLE_RATE, I2S_DATA_BIT_WIDTH_16BIT, I2S_SLOT_MODE_MONO)) {
          logError("MIC", "I2S initialization failed!");
          while (true) delay(100);
      }
      
      logInfo("MIC", "Microphone ready");
      logMemory("MIC");
  }





  // ============================================================================
  // Setup BLE
  // ============================================================================

  void initBLE() {
      Serial.println();
      logInfo("SYS", "========================== Initializing Bluetooth Connection ==========================");

      logInfo("BLE", "Initializing Bluetooth LE...");
      
      BLEDevice::init("XIAO_ESP32S3");
      BLEDevice::setMTU(515);
      BLEServer *pServer = BLEDevice::createServer();
      pServer->setCallbacks(new MyServerCallbacks());

      BLEService *pService = pServer->createService(SERVICE_UUID);

      // VQA Service Characteristic
      pCharacteristic = pService->createCharacteristic(
          CHARACTERISTIC_UUID,
          BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_NOTIFY
      );
      pCharacteristic->addDescriptor(new BLE2902());

      // Speaker Characteristic for audio playback
      pSpeakerCharacteristic = pService->createCharacteristic(
          SPEAKER_CHARACTERISTIC_UUID,
          BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR
      );
      pSpeakerCharacteristic->addDescriptor(new BLE2902());

      // Temperature Characteristic
      pTempCharacteristic = pService->createCharacteristic(
          TEMP_CHARACTERISTIC_UUID,
          BLECharacteristic::PROPERTY_NOTIFY
      );
      pTempCharacteristic->addDescriptor(new BLE2902());

      pCharacteristic->setCallbacks(new VQACharacteristicCallbacks());
      pSpeakerCharacteristic->setCallbacks(new SpeakerCharacteristicCallbacks());
      pService->start();

      BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
      pAdvertising->addServiceUUID(SERVICE_UUID);
      pAdvertising->setScanResponse(true);
      BLEDevice::startAdvertising();

      logInfo("BLE", "Ready and advertising as 'XIAO_ESP32S3'");
      logDebug("BLE", "Service UUID: " + String(SERVICE_UUID));
      logMemory("BLE");

      logInfo("SYS", "========================== BLE initialization complete - waiting for connections ==========================");
      Serial.println();
  }



  // ============================================================================
  // Audio Playback Functions
  // ============================================================================
  
  /// Initialize the I2S speaker output
  void initSpeaker() {
    logInfo("SPEAKER", "Initializing I2S speaker...");
    
    // Configure I2S pins for speaker output
    i2s_speaker.setPins(I2S_BCLK, I2S_LRC, I2S_DOUT);
    
    // Initialize I2S in standard mode for speaker output
    if (!i2s_speaker.begin(I2S_MODE_STD, SPEAKER_SAMPLE_RATE, I2S_DATA_BIT_WIDTH_16BIT, I2S_SLOT_MODE_MONO)) {
      logError("SPEAKER", "I2S speaker initialization failed!");
      return;
    }
    
    logInfo("SPEAKER", "I2S speaker initialized successfully");
    logDebug("SPEAKER", "Sample rate: " + String(SPEAKER_SAMPLE_RATE) + " Hz, 16-bit, mono");
    logMemory("SPEAKER");
  }
  
  /// Play received audio data through the speaker
  void playReceivedAudio() {
    if (audioBufferIndex == 0) {
      logWarn("AUDIO", "No audio data to play");
      return;
    }
    
    logInfo("AUDIO", "Starting audio playback: " + String(audioBufferIndex) + " bytes");
    
    // Play the raw audio data in chunks
    const size_t PLAY_BUFFER_SIZE = 512;
    size_t bytesPlayed = 0;
    
    while (bytesPlayed < audioBufferIndex) {
      size_t bytesToPlay = min(PLAY_BUFFER_SIZE, audioBufferIndex - bytesPlayed);
      
      // Write audio data to I2S speaker
      size_t bytesWritten = i2s_speaker.write(audioBuffer + bytesPlayed, bytesToPlay);
      bytesPlayed += bytesWritten;
      
      // Small delay to prevent overwhelming the I2S buffer
      vTaskDelay(pdMS_TO_TICKS(1));
    }
    
    // Add silence at the end to avoid clicking (50ms of silence)
    int silenceSamples = SPEAKER_SAMPLE_RATE / 20; // 50ms of silence
    for (int i = 0; i < silenceSamples; i++) {
      int16_t silence = 0;
      i2s_speaker.write((uint8_t *)&silence, sizeof(silence));
    }
    
    logInfo("AUDIO", "Audio playback completed: " + String(bytesPlayed) + " bytes played");
    
    // Reset audio buffer
    audioBufferIndex = 0;
    expectedAudioSize = 0;
  }
  
  /// Clean up speaker resources
  void deinitSpeaker() {
    logInfo("SPEAKER", "Deinitializing I2S speaker...");
    i2s_speaker.end();
    logInfo("SPEAKER", "I2S speaker deinitialized");
  }
  
  /// Start VQA streaming (referenced in BLE callback)
  void startVqaStreaming() {
    if (vqaState.isRunning) {
      logWarn("VQA", "VQA already running");
      return;
    }
    
    logInfo("VQA", "Starting VQA streaming task...");
    
    // Create VQA streaming task
    xTaskCreatePinnedToCore(
      vqaStreamTask,
      "vqaStreamTask",
      8192,  // Stack size
      NULL,  // Parameters
      2,     // Priority
      &vqaState.vqaTaskHandle,
      1      // Core
    );
  }



  // ============================================================================
  // FreeRTOS Tasks
  // ============================================================================

  // VQA Streaming Task - Audio First, Then Image After Stop
  void vqaStreamTask(void *param) {
    logInfo("VQA-STREAM", "VQA streaming task started (audio first, then image after stop)");
    
    // Ensure LED reflects streaming state
    digitalWrite(led_pin, HIGH);
    ledState = true;

    // Initialize VQA streaming state
    vqaState.isRunning = true;
    vqaState.stopRequested = false;
    vqaState.audioRecordingInProgress = false;
    vqaState.audioRecordingComplete = false;
    vqaState.imageTransmissionComplete = false;
    vqaState.audioStreamingActive = false;
    vqaState.totalAudioStreamed = 0;
    
    // Calculate streaming parameters for continuous audio (VQA uses lower quality for efficiency)
    const int sampleRate = MIC_SAMPLE_RATE;
    const int bytesPerSample = MIC_BIT_DEPTH / 8;
    const int bytesPerSecond = sampleRate * bytesPerSample;
    const int chunkDuration = VQA_STREAM_CHUNK_DURATION_MS;
    const int chunkSizeBytes = (bytesPerSecond * chunkDuration) / 1000;
    
    logDebug("VQA-STREAM", "Stream config: " + String(chunkSizeBytes) + " bytes/chunk, " + 
            String(chunkDuration) + "ms/chunk, image after audio stops");

    // Send VQA start header
    String header = "VQA_START";
    pCharacteristic->setValue((uint8_t*)header.c_str(), header.length());
    pCharacteristic->notify();
    vTaskDelay(pdMS_TO_TICKS(20));
    logDebug("VQA-STREAM", "Start header sent");

    // Initialize streaming state
    vqaState.audioStreamingActive = true;
    vqaState.streamStartTime = millis();
    int chunkNumber = 0;
    bool streamingSuccess = true;

    // ============================================================================
    // STEP 1: Stream Audio Continuously Until Stop Requested
    // ============================================================================
    logInfo("VQA-STREAM", "Starting continuous audio streaming...");
    
    // Audio header
    String audioHeader = "A_START";  // Audio stream start marker
    pCharacteristic->setValue((uint8_t*)audioHeader.c_str(), audioHeader.length());
    pCharacteristic->notify();
    vTaskDelay(pdMS_TO_TICKS(20));
    logDebug("VQA-STREAM", "Audio header sent");

    while (!vqaState.stopRequested && streamingSuccess && deviceConnected) {
      chunkNumber++;
      
      // Allocate buffer for this chunk
      uint8_t* chunkBuffer = new uint8_t[chunkSizeBytes];
      if (!chunkBuffer) {
        logError("VQA-STREAM", "Failed to allocate chunk buffer");
        streamingSuccess = false;
        break;
      }

      // Record audio chunk
      size_t bytesRead = 0;
      unsigned long recordStart = millis();
      
      while (bytesRead < chunkSizeBytes && (millis() - recordStart) < (chunkDuration + 100)) {
        size_t bytesToRead = min((size_t)negotiatedChunkSize, chunkSizeBytes - bytesRead);
        size_t actuallyRead = i2s.readBytes((char*)(chunkBuffer + bytesRead), bytesToRead);
        bytesRead += actuallyRead;
        
        if (actuallyRead == 0) {
          vTaskDelay(pdMS_TO_TICKS(1)); // Small delay if no data available
        }
        
        // Check for stop request during recording
        if (vqaState.stopRequested) {
          break;
        }
      }
      
      if (bytesRead < chunkSizeBytes && !vqaState.stopRequested) {
        logWarn("VQA-STREAM", "Chunk " + String(chunkNumber) + " incomplete: " + 
                String(bytesRead) + "/" + String(chunkSizeBytes) + " bytes");
      }

      // Only send if we have data and not stopping
      if (bytesRead > 0 && !vqaState.stopRequested) {
        // Send chunk data directly in BLE-sized packets (no header needed)
        for (size_t i = 0; i < bytesRead && !vqaState.stopRequested; i += negotiatedChunkSize) {
          size_t packetSize = min((size_t)negotiatedChunkSize, bytesRead - i);
          pCharacteristic->setValue(chunkBuffer + i, packetSize);
          pCharacteristic->notify();
          vTaskDelay(pdMS_TO_TICKS(SEND_DELAY_BETWEEN_CHUNKS_MS));
          
          // Check if client disconnected during streaming
          if (!deviceConnected) {
            logWarn("VQA-STREAM", "Client disconnected during streaming");
            streamingSuccess = false;
            break;
          }
        }

        vqaState.totalAudioStreamed += bytesRead;
        logStreamingProgress("VQA-STREAM", bytesRead, vqaState.totalAudioStreamed, vqaState.streamStartTime, chunkNumber);
      }

      // Clean up chunk buffer
      delete[] chunkBuffer;

      if (!streamingSuccess) break;
    }

    // Finalize audio streaming
    vqaState.audioStreamingActive = false;
    vqaState.audioRecordingComplete = true;

    // Send audio end signal
    String audioEndHeader = "A_END";
    pCharacteristic->setValue((uint8_t*)audioEndHeader.c_str(), audioEndHeader.length());
    pCharacteristic->notify();
    vTaskDelay(pdMS_TO_TICKS(20));
    logDebug("VQA-STREAM", "Audio end sent");

    unsigned long audioTime = millis() - vqaState.streamStartTime;
    float avgRate = (vqaState.totalAudioStreamed / 1024.0) / (audioTime / 1000.0);
    
    logInfo("VQA-STREAM", "Audio streaming complete: " + String(vqaState.totalAudioStreamed) + " bytes (" + 
            String(vqaState.totalAudioStreamed/1024.0, 1) + " KB) in " + String(audioTime) + 
            "ms (" + String(avgRate, 1) + " KB/s avg)");

    // ============================================================================
    // STEP 2: Capture and Send Image (only after audio streaming stops)
    // ============================================================================
    if (streamingSuccess && deviceConnected) {
      logInfo("VQA-STREAM", "Starting image capture after audio streaming stopped...");
      
      // Take picture
      camera_fb_t *fb = esp_camera_fb_get();
      
      // Retry once if first capture fails
      if (!fb) {
        logWarn("VQA-STREAM", "First capture failed, retrying...");
        vTaskDelay(pdMS_TO_TICKS(50));
        fb = esp_camera_fb_get();
        if (!fb) {
          logError("VQA-STREAM", "Camera capture failed after retry");
          streamingSuccess = false;
        }
      }

      if (fb && streamingSuccess) {
        size_t imageSize = fb->len;
        uint8_t *imageBuffer = fb->buf;
        logInfo("VQA-STREAM", "Captured " + String(imageSize) + " bytes (" + 
                String(imageSize/1024) + " KB)");

        // Send image data via BLE
        logInfo("VQA-STREAM", "Starting image transmission...");
        
        // Image header
        String imageHeader = "I:" + String(imageSize);
        pCharacteristic->setValue((uint8_t*)imageHeader.c_str(), imageHeader.length());
        pCharacteristic->notify();
        vTaskDelay(pdMS_TO_TICKS(20));
        logDebug("VQA-STREAM", "Image header sent");

        // Send image chunks
        size_t sentBytes = 0;
        unsigned long transferStart = millis();
        
        for (size_t i = 0; i < imageSize && deviceConnected; i += negotiatedChunkSize) {
          int len = (i + negotiatedChunkSize > imageSize) ? (imageSize - i) : negotiatedChunkSize;
          pCharacteristic->setValue(imageBuffer + i, len);
          pCharacteristic->notify();
          sentBytes += len;
          vTaskDelay(pdMS_TO_TICKS(SEND_DELAY_BETWEEN_CHUNKS_MS));
            
          logProgressRate("VQA-IMG", sentBytes, imageSize, transferStart);
          
          // Check if client disconnected during image transfer
          if (!deviceConnected) {
            logWarn("VQA-STREAM", "Client disconnected during image transfer");
            streamingSuccess = false;
            break;
          }
        }

        if (streamingSuccess && deviceConnected) {
          unsigned long imageTransferTime = millis() - transferStart;
          float imageTransferRate = (imageSize / 1024.0) / (imageTransferTime / 1000.0);
          
          // Image footer
          String imageFooter = "I_END";
          pCharacteristic->setValue((uint8_t*)imageFooter.c_str(), imageFooter.length());
          pCharacteristic->notify();
          vTaskDelay(pdMS_TO_TICKS(20));
          logDebug("VQA-STREAM", "Image footer sent");

          logInfo("VQA-STREAM", "Image transfer complete in " + String(imageTransferTime) + 
                  "ms (" + String(imageTransferRate, 1) + " KB/s)");
          
          vqaState.imageTransmissionComplete = true;
        }

        // Release camera frame buffer
        esp_camera_fb_return(fb);
      }
    }

    // ============================================================================
    // STEP 3: Finalize VQA Operation
    // ============================================================================
    
    // Determine completion status
    String stopReason;
    if (vqaState.stopRequested) {
      stopReason = "User requested stop";
    } else if (!deviceConnected) {
      stopReason = "Client disconnected";
    } else {
      stopReason = "Stream error";
    }

    // Send completion footer
    if (streamingSuccess || vqaState.stopRequested) {
      String footer = "VQA_END";
      pCharacteristic->setValue((uint8_t*)footer.c_str(), footer.length());
      pCharacteristic->notify();
      logDebug("VQA-STREAM", "VQA footer sent");

      unsigned long totalTime = millis() - vqaState.streamStartTime;
      
      logInfo("VQA-STREAM", "VQA operation completed: " + stopReason);
      logInfo("VQA-STREAM", "Total duration: " + String(totalTime) + "ms");
      logInfo("VQA-STREAM", "Audio streamed: " + String(vqaState.totalAudioStreamed/1024.0, 1) + " KB");
      logInfo("VQA-STREAM", "Image captured: " + String(vqaState.imageTransmissionComplete ? "Yes" : "No"));
    } else {
      String errorFooter = "VQA_ERR";
      pCharacteristic->setValue((uint8_t*)errorFooter.c_str(), errorFooter.length());
      pCharacteristic->notify();
      logError("VQA-STREAM", "VQA streaming failed: " + stopReason);
    }

    // Reset VQA state
    vqaState.isRunning = false;
    vqaState.stopRequested = false;
    vqaState.vqaTaskHandle = nullptr;

    // Turn off indicator LED
    digitalWrite(led_pin, LOW);
    ledState = false;
    
    // Task auto-cleanup
    vTaskDelete(NULL);
  }



  // Temperature Task
  void temperatureTask(void *param) {
    while (true) {
      float currentTemp = temperatureRead();

      // Safety shutdown
      if (currentTemp > tempThreshold) {
        logError("TEMP", "Overheat detected! Turning off Device");
        esp_deep_sleep_start();
      }

      // Always send to Flutter when connected
      if (deviceConnected) {
        char buffer[16]; // Enough for header + float
        snprintf(buffer, sizeof(buffer), "T:%.2f", currentTemp);
        pTempCharacteristic->setValue((uint8_t*)buffer, strlen(buffer));
        pTempCharacteristic->notify();
      }

      if (tempMonitoringEnabled) {
        logDebug("TEMP", "Current temperature: " + String(currentTemp, 1) + " °C");
      }

      vTaskDelay(pdMS_TO_TICKS(10000)); // every 1 sec
    }
  }



  // ============================================================================
  // Setup
  // ============================================================================

  void setup() {
      Serial.begin(115200);
      delay(1000);
      
      // Welcome
      printWelcomeArt();
      logInfo("SYS", "Compile time: " + String(__DATE__) + " " + String(__TIME__));
      logMemory("SYS");

      // Setup LED and button pins
      pinMode(led_pin, OUTPUT);
      digitalWrite(led_pin, LOW);
      pinMode(BUTTON_PIN, INPUT_PULLUP); // Button input with pullup

      // Initialize BLE only
      initBLE();

      // Create task to monitor temperature (always active for overheat protection)
      xTaskCreatePinnedToCore(temperatureTask, "temperatureTask", 4096, NULL, 1, &tempTaskHandle, 1);
      logInfo("SYS", "Temperature monitoring task created (overheat protection always active)");

      logInfo("SYS", "System components will be initialized when a client connects");
      logMemory("SYS");
  }



  // ============================================================================
  // Main Loop
  // ============================================================================

  void loop() {
    // -----------------------------
    // Button handling (press to start, release to stop VQA)
    // -----------------------------
    int buttonState = digitalRead(BUTTON_PIN);
    
    // Optional: debug button values occasionally
    static unsigned long lastButtonDebug = 0;
    if (millis() - lastButtonDebug > 2000) {
      lastButtonDebug = millis();
    }

    // Detect state changes with debounce
    if (buttonState != lastButtonState && (millis() - lastButtonMillis) > BUTTON_DEBOUNCE_MS) {
      lastButtonMillis = millis();

      if (buttonState == LOW) {
        // Button pressed - start VQA
        if (!deviceConnected) {
          logWarn("BUTTON", "Button press ignored - BLE not connected");
        } else if (!systemInitialized) {
          logWarn("BUTTON", "Button press ignored - system not initialized");
        } else if (!vqaState.isRunning) {
          // Start VQA streaming
          vqaState.stopRequested = false;
          BaseType_t result = xTaskCreatePinnedToCore(
            vqaStreamTask, 
            "VQAStreamTask", 
            20480, 
            nullptr, 
            1, // Normal priority
            &vqaState.vqaTaskHandle, 
            1  // Core 1
          );
          if (result == pdPASS) {
            logInfo("BUTTON", "VQA streaming started - button pressed");
            digitalWrite(led_pin, HIGH);
            ledState = true;
          } else {
            logError("BUTTON", "Failed to start VQA streaming task");
          }
        } else {
          logWarn("BUTTON", "VQA already running");
        }
      } else {
        // Button released - stop VQA
        if (vqaState.isRunning) {
          vqaState.stopRequested = true;
          logInfo("BUTTON", "VQA streaming stop requested - button released");
        } else {
          logDebug("BUTTON", "Button released - no VQA to stop");
        }
      }
    }

    lastButtonState = buttonState;

    // -----------------------------
    // Serial Commands for testing - VQA only
    // -----------------------------
    if (Serial.available()) {
      String cmd = Serial.readStringUntil('\n');
      cmd.trim();
      cmd.toUpperCase();

      if (cmd == "VQA_START") {
        if (!deviceConnected) {
          logWarn("CMD", "VQA streaming ignored - BLE not connected");
        } else if (systemInitialized) {
          if (!vqaState.isRunning) {
            // Start VQA streaming
            vqaState.stopRequested = false;
            BaseType_t result = xTaskCreatePinnedToCore(
              vqaStreamTask, 
              "VQAStreamTask", 
              20480, 
              nullptr, 
              1, // Normal priority
              &vqaState.vqaTaskHandle, 
              1  // Core 1
            );
            if (result == pdPASS) {
              logInfo("CMD", "VQA streaming started via serial");
              digitalWrite(led_pin, HIGH);
              ledState = true;
            } else {
              logError("CMD", "Failed to start VQA streaming task via serial");
            }
          } else {
            logWarn("CMD", "VQA streaming already active");
          }
        } else {
          logWarn("CMD", "VQA streaming ignored - system not initialized");
        }
      }
      else if (cmd == "VQA_STOP") {
        if (vqaState.isRunning) {
          vqaState.stopRequested = true;
          logInfo("CMD", "VQA streaming stop requested via serial");
        } else {
          logWarn("CMD", "No VQA streaming active to stop");
        }
      }
      else if (cmd == "STATUS") {
        logInfo("SYS", "=== System Status ===");
        logInfo("SYS", "BLE connected: " + String(deviceConnected ? "Yes" : "No"));
        logInfo("SYS", "System initialized: " + String(systemInitialized ? "Yes" : "No"));
        logInfo("SYS", "VQA running: " + String(vqaState.isRunning ? "Yes" : "No"));
        logInfo("SYS", "Temperature monitoring: " + String(tempMonitoringEnabled ? "Enabled" : "Disabled"));
        logInfo("SYS", "Chunk size: " + String(negotiatedChunkSize) + " bytes");
        logMemory("SYS");
      }
      else if (cmd == "DEBUG") {
        currentLogLevel = (currentLogLevel == LOG_DEBUG) ? LOG_INFO : LOG_DEBUG;
        logInfo("SYS", "Debug logging " + String(currentLogLevel == LOG_DEBUG ? "enabled" : "disabled"));
      }
      else if (cmd == "TEMP") {
        tempMonitoringEnabled = !tempMonitoringEnabled;
        logInfo("CMD", "Temperature monitoring " + String(tempMonitoringEnabled ? "enabled" : "disabled") + " via serial (overheat protection always active)");
      }
      else if (cmd.length() > 0) {
        logWarn("CMD", "Unknown serial command: '" + cmd + "'");
        logInfo("CMD", "Available commands: VQA_START, VQA_STOP, STATUS, DEBUG, TEMP");
      }
    }

    delay(10);
  }



  // ============================================================================
  // Welcome Art
  // ============================================================================
  void printWelcomeArt() {
    static const char* art[] = {
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⠿⠿⣷⣦⣀⠀⢀⣀⣀⣤⣤⣤⣤⣤⣄⣀⡀⢀⣤⣶⠿⠿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⡟⢸⠀⠀⠉⠻⠿⠛⠛⠋⠉⠉⠉⠉⠉⠙⠛⠻⠿⠋⠁⠀⠀⢻⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⡇⠘⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡀⠀⢸⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⡿⠛⠀⠀⠐⢠⣦⣦⣦⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣄⠀⠀⠙⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⡟⠀⠀⠀⠀⠀⠸⣿⣿⣿⣿⣿⣿⣿⣿⠀⠸⣿⣿⣿⣿⣿⣿⣿⡇⡄⠀⠀⠈⢿⣆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⠇⠀⠀⠀⠀⠀⠀⢻⣿⣿⣿⣿⣿⡿⠁⣼⣄⠙⠿⣿⣿⣿⡿⠟⠀⠀⠀⠀⠀⢸⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⡆⠀⠀⠀⠀⠀⣴⡿⠛⢿⡏⠉⠈⠰⡿⠛⠻⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⣿⡀⢀⠀⠀⣸⣿⠁⠀⢸⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢙⣿⣶⡄⡾⠟⠃⠀⠀⣾⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠿⣯⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⠃⠀⠀⠀⠀⠀⠀⣴⡿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⠀⠀⠀⠘⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      "⢀⡀⡀⣀⣀⣀⠀⠀⠀⠀⣿⡇⠀⠀⠀⠀⠀⠀⠀⠊⠀⠀⠀⠀⠀⢀⣀⠀⠀⠀⠀⠀⠀⣤⣾⠿⠛⠃⠀⠀⠀⣸⣷⠀⠀⠀⠀⣀⣀⡀⡀⠀",
      "⠺⠿⠛⠛⠛⠛⠿⠿⠿⠿⠿⠿⠿⠿⠿⠷⣶⢶⡶⡶⠶⠿⠿⠿⠿⠟⠛⠛⠻⠿⠿⠿⢿⣿⣀⣠⣤⣤⣤⣤⣶⠿⠛⠛⠛⠛⠛⠛⠛⠛⠻⠃",
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠉⠉⠉⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
    };

    for (const char* line : art) {
      Serial.println(line);
      delay(200);  // shorter, faster but still gives dramatic effect
    }
    
    logInfo("SYS", "Welcome, Cj");
  }
