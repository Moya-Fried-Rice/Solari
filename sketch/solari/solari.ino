// ============================================================================
// SOLARI Smart Glasses - High-Quality Audio & Visual Processing System
// ============================================================================
// Configurable audio quality system for smart glasses
// Features: BLE communication, camera capture, audio streaming, temperature monitoring
// ============================================================================

#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include "esp_camera.h"
#include "ESP_I2S.h"
#include "esp_adc_cal.h"
#include <BLE2902.h>
#include <vector>
#include "done.h"
#include "processing.h"
#include "start.h"

// ============================================================================
// BLE Service and Characteristic UUIDs
// ============================================================================
#define BLE_SERVICE_UUID                    "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define VQA_CHARACTERISTIC_UUID             "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define TEMPERATURE_CHARACTERISTIC_UUID     "00002A6E-0000-1000-8000-00805F9B34FB"
#define AUDIO_PLAYBACK_CHARACTERISTIC_UUID  "12345678-1234-1234-1234-123456789abc"

// ============================================================================
// Timing and Control Constants
// ============================================================================
#define IMAGE_CAPTURE_DEBOUNCE_MS           500
#define BLE_CHUNK_SEND_DELAY_MS             8
#define VQA_AUDIO_CHUNK_DURATION_MS         150  // Audio chunk duration for VQA streaming
#define VQA_STREAMING_BUFFER_COUNT          4    // Number of buffers for smooth streaming
#define BUTTON_DEBOUNCE_MS                  200  // Button debounce time

// ============================================================================
// Hardware Pin Definitions
// ============================================================================
#define USER_BUTTON_PIN                     D4



// ============================================================================
// LED and Button State Management
// ============================================================================
const int STATUS_LED_PIN = LED_BUILTIN;        // On-board status LED

// Button and LED state variables
bool isStatusLedOn = false;                     // Current LED state (mirrors VQA running)
bool previousButtonState = HIGH;                // Previous button state (HIGH = not pressed due to pullup)
unsigned long lastButtonPressTime = 0;         // Timestamp of last button state change



// ============================================================================
// Temperature Monitoring Configuration
// ============================================================================
const float TEMPERATURE_SHUTDOWN_THRESHOLD = 55.0;  // °C limit before emergency shutdown
TaskHandle_t temperatureMonitoringTaskHandle;
bool isTemperatureLoggingEnabled = false;           // Enable/disable temperature logging (overheat protection always active)



// ============================================================================
// BLE Connection and System State
// ============================================================================
bool isBleClientConnected = false;
bool isSystemInitialized = false;

// BLE Characteristic pointers
BLECharacteristic* vqaDataCharacteristic;
BLECharacteristic* temperatureDataCharacteristic;
BLECharacteristic* audioPlaybackCharacteristic;

// BLE communication settings
int negotiatedBleChunkSize = 23;                     // Default BLE MTU chunk size

// I2S instances
I2SClass microphoneI2S;                              // Microphone input I2S



// ============================================================================
// Visual Question Answering (VQA) System State
// ============================================================================
struct VisualQuestionAnsweringState {
    // Main operation state
    bool isOperationActive = false;
    bool isStopRequested = false;
    TaskHandle_t vqaTaskHandle = nullptr;
    
    // Image processing state
    bool isImageTransmissionComplete = false;
    
    // Audio recording state
    bool isAudioRecordingInProgress = false;
    bool isAudioRecordingComplete = false;
    unsigned long audioRecordingStartTime = 0;
    
    // Audio streaming state
    bool isAudioStreamingActive = false;
    size_t totalAudioBytesStreamed = 0;
    unsigned long streamingStartTime = 0;
};
VisualQuestionAnsweringState vqaSystemState;

// ============================================================================
// Audio Configuration - Modify these values to test different audio formats
// ============================================================================

// Speaker Audio Output Configuration
const int SPEAKER_SAMPLE_RATE = 11025;              // Sample rate for audio playback
const int SPEAKER_BIT_DEPTH = 16;                   // Bit depth for audio samples
const int SPEAKER_BYTES_PER_SAMPLE = 2;             // Bytes per audio sample (16-bit = 2 bytes)
const char* SPEAKER_AUDIO_QUALITY_NAME = "Low Quality";
const int SPEAKER_AUDIO_CHUNK_SIZE = 512;           // Chunk size for audio processing
const int SPEAKER_PLAYBACK_DELAY_MS = 16;           // Target delay between audio chunks

// Microphone Input Configuration (for VQA recording)
const int MICROPHONE_SAMPLE_RATE = 8000;            // Lower sample rate for efficient VQA transmission
const int MICROPHONE_BIT_DEPTH = 16;                // Microphone bit depth
const i2s_data_bit_width_t I2S_SPEAKER_BIT_WIDTH = I2S_DATA_BIT_WIDTH_16BIT;
  
// ============================================================================
// Audio Playback System State
// ============================================================================
struct AudioPlaybackSystemState {
    // Reception state
    bool isReceivingAudioData = false;
    bool isAudioLoadingComplete = false;
    size_t expectedTotalAudioSize = 0;
    size_t receivedAudioDataSize = 0;
    unsigned long audioReceptionStartTime = 0;
    
    // Playback state
    bool isCurrentlyPlaying = false;
    bool isRealTimeStreamingEnabled = false;        // Enable real-time streaming during reception
    size_t currentPlaybackPosition = 0;
    size_t streamingStartThreshold = 88200;         // Buffer 2 seconds of audio (extra buffer for smooth playback)
    unsigned long lastAudioSampleTime = 0;
    
    // Audio data and processing
    std::vector<uint8_t> audioDataBuffer;
    TaskHandle_t audioPlaybackTaskHandle = nullptr;
    int16_t volumeAmplitude = 32767;                // Volume control (0-32767, where 32767 is max)
};
AudioPlaybackSystemState audioPlaybackSystem;

// I2S instance for speaker output (separate from microphone I2S)
I2SClass speakerI2S;

// ============================================================================
// Sound Effect Global Variables
// ============================================================================

// Global variables for looping sound effects
volatile bool isProcessingSoundLooping = false;
volatile bool isSoundEffectPlaying = false;
TaskHandle_t processingSoundTaskHandle = nullptr;
unsigned long processingStartTime = 0;
const unsigned long PROCESSING_TIMEOUT_MS = 30000; // 30 second timeout

// ============================================================================
// Enhanced Logging System
// ============================================================================

// Logging severity levels
enum LoggingSeverityLevel {
    LOG_LEVEL_DEBUG = 0,
    LOG_LEVEL_INFO = 1,
    LOG_LEVEL_WARNING = 2,
    LOG_LEVEL_ERROR = 3
};

// Current active logging level (change to LOG_LEVEL_DEBUG for verbose output)
LoggingSeverityLevel activeLoggingLevel = LOG_LEVEL_DEBUG;

// Logging level display strings
const char* loggingLevelNames[] = {"DEBUG", "INFO", "WARN", "ERROR"};

// ============================================================================
// Function Forward Declarations
// ============================================================================
void displayWelcomeArt();
void stopProcessingSoundLoop();
void playDoneSoundWhenReady();
void playStartSound();

// Main logging function with timestamp and component tagging
void writeLogMessage(LoggingSeverityLevel severity, const String &componentName, const String &message) {
    if (severity >= activeLoggingLevel) {
        Serial.printf("[%8lu] [%s] [%s] %s\n", 
                      millis(), 
                      loggingLevelNames[severity], 
                      componentName.c_str(), 
                      message.c_str());
    }
}

// Convenience logging functions for different severity levels
void logInfoMessage(const String &componentName, const String &message) {
    writeLogMessage(LOG_LEVEL_INFO, componentName, message);
}

void logWarningMessage(const String &componentName, const String &message) {
    writeLogMessage(LOG_LEVEL_WARNING, componentName, message);
}

void logErrorMessage(const String &componentName, const String &message) {
    writeLogMessage(LOG_LEVEL_ERROR, componentName, message);
}

void logDebugMessage(const String &componentName, const String &message) {
    writeLogMessage(LOG_LEVEL_DEBUG, componentName, message);
}

// Memory usage logging helper
void logSystemMemoryUsage(const String &componentName) {
    if (activeLoggingLevel <= LOG_LEVEL_DEBUG) {
        writeLogMessage(LOG_LEVEL_DEBUG, componentName, 
                       "Free heap: " + String(ESP.getFreeHeap()) + 
                       " bytes, PSRAM: " + String(ESP.getFreePsram()) + " bytes");
    }
}

// Enhanced progress logger with visual progress bar and transfer rate
void logDataTransferProgress(const String &componentName, size_t bytesProcessed, size_t totalBytes, unsigned long operationStartTime) {
    if (activeLoggingLevel <= LOG_LEVEL_INFO) {
        int completionPercentage = (bytesProcessed * 100) / totalBytes;
        unsigned long elapsedTime = millis() - operationStartTime;
        float transferRateKBps = 0;
        if (elapsedTime > 0) {
            transferRateKBps = (bytesProcessed / 1024.0) / (elapsedTime / 1000.0); // KB/s
        }
        
        // Create visual progress bar
        const int progressBarWidth = 20;
        int filledBlocks = (completionPercentage * progressBarWidth) / 100;
        String visualProgressBar = "[";
        
        for (int i = 0; i < progressBarWidth; i++) {
            if (i < filledBlocks) {
                visualProgressBar += "█";
            } else {
                visualProgressBar += "░";
            }
        }
        visualProgressBar += "]";
        
        writeLogMessage(LOG_LEVEL_INFO, componentName, 
                       visualProgressBar + " (" + String(completionPercentage) + "%) " + 
                       String(bytesProcessed) + "/" + String(totalBytes) + " bytes - " + 
                       String(transferRateKBps, 1) + " KB/s");
    }
}

// Audio streaming progress logger with chunk-based metrics
void logAudioStreamingProgress(const String &componentName, size_t chunkSizeBytes, size_t totalBytesStreamed, unsigned long streamStartTime, int chunkSequenceNumber) {
    if (activeLoggingLevel <= LOG_LEVEL_INFO) {
        unsigned long elapsedStreamingTime = millis() - streamStartTime;
        float streamingRateKBps = 0;
        if (elapsedStreamingTime > 0) {
            streamingRateKBps = (totalBytesStreamed / 1024.0) / (elapsedStreamingTime / 1000.0); // KB/s
        }
        
        writeLogMessage(LOG_LEVEL_INFO, componentName, 
                       "Chunk #" + String(chunkSequenceNumber) + " (" + String(chunkSizeBytes) + " bytes) - " + 
                       "Total: " + String(totalBytesStreamed/1024.0, 1) + " KB @ " + String(streamingRateKBps, 1) + " KB/s");
    }
}



// ============================================================================
// BLE Server Event Callbacks
// ============================================================================

class BleServerEventCallbacks : public BLEServerCallbacks {
    void onConnect(BLEServer* bleServer) override {
        Serial.println();
        logInfoMessage("BLE", "!! Client connected !!");
        isBleClientConnected = true;
        logSystemMemoryUsage("BLE");
        
        // Initialize system components when BLE client connects
        if (!isSystemInitialized) {
            initializeSystemComponents();
        }
    }
    
    void onDisconnect(BLEServer* bleServer) override {
        Serial.println();
        logWarningMessage("BLE", "!! Client disconnected !!");
        isBleClientConnected = false;
        
        // Clean up system components when client disconnects
        if (isSystemInitialized) {
            cleanupSystemComponents();
        }
        
        BLEDevice::startAdvertising();
        logInfoMessage("BLE", "Advertising restarted");
    }
    
    void onMtuChanged(BLEServer* bleServer, esp_ble_gatts_cb_param_t* mtuChangeParams) override {
        int negotiatedMtu = mtuChangeParams->mtu.mtu;
        negotiatedBleChunkSize = max(20, negotiatedMtu - 3); // Reserve 3 bytes for ATT header
        logInfoMessage("BLE", "MTU negotiated: " + String(negotiatedMtu) + " bytes, "
                              "effective chunk size: " + String(negotiatedBleChunkSize) + " bytes");
    }
};

class VqaCharacteristicEventCallbacks : public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic* vqaCharacteristic) override {
        String receivedStringValue = vqaCharacteristic->getValue().c_str();
        uint8_t* receivedBinaryData = vqaCharacteristic->getData();
        size_t receivedDataLength = vqaCharacteristic->getLength();
        
        // Output raw binary data to serial for VQA command debugging
        Serial.print("VQA BLE Data Received: ");
        for (size_t i = 0; i < receivedDataLength; i++) {
            Serial.print("0x");
            if (receivedBinaryData[i] < 16) Serial.print("0");
            Serial.print(receivedBinaryData[i], HEX);
            Serial.print(" ");
        }
        Serial.print("| String: \"");
        Serial.print(receivedStringValue);
        Serial.print("\" | Length: ");
        Serial.println(receivedDataLength);
    }
};

class AudioPlaybackCharacteristicEventCallbacks : public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic* audioPlaybackCharacteristic) override {
        String receivedStringValue = audioPlaybackCharacteristic->getValue().c_str();
        uint8_t* receivedBinaryData = audioPlaybackCharacteristic->getData();
        size_t receivedDataLength = audioPlaybackCharacteristic->getLength();
        
        // Handle audio streaming start command
        if (receivedStringValue.startsWith("S_START:")) {
            // This is a server response - stop processing sound and play done sound
            if (isProcessingSoundLooping) {
                logInfoMessage("AUDIO-RESPONSE", "Server response received (S_START) - stopping processing sound and playing done sound");
                stopProcessingSoundLoop();
                playDoneSoundWhenReady();
            }
            
            audioPlaybackSystem.expectedTotalAudioSize = receivedStringValue.substring(8).toInt();
            audioPlaybackSystem.isReceivingAudioData = true;
            audioPlaybackSystem.isAudioLoadingComplete = false;
            audioPlaybackSystem.isRealTimeStreamingEnabled = false;
            audioPlaybackSystem.receivedAudioDataSize = 0;
            audioPlaybackSystem.currentPlaybackPosition = 0;
            audioPlaybackSystem.isCurrentlyPlaying = false;
            audioPlaybackSystem.audioReceptionStartTime = millis();
            audioPlaybackSystem.audioDataBuffer.clear();
            audioPlaybackSystem.audioDataBuffer.reserve(audioPlaybackSystem.expectedTotalAudioSize);
            
            // Clean up any existing audio playback task
            if (audioPlaybackSystem.audioPlaybackTaskHandle != nullptr) {
                vTaskDelete(audioPlaybackSystem.audioPlaybackTaskHandle);
                audioPlaybackSystem.audioPlaybackTaskHandle = nullptr;
            }
            
            logInfoMessage("AUDIO-PLAYBACK", "Real-time audio streaming started - Expected size: " + 
                          String(audioPlaybackSystem.expectedTotalAudioSize) + " bytes");
            
            // Turn on status LED to indicate audio loading
            digitalWrite(STATUS_LED_PIN, HIGH);
            isStatusLedOn = true;
            return;
        }
        
        // Handle audio streaming end command
        if (receivedStringValue.startsWith("S_END")) {
            // This is also a server response - stop processing sound if still running
            if (isProcessingSoundLooping) {
                logInfoMessage("AUDIO-RESPONSE", "Server response received (S_END) - stopping processing sound");
                stopProcessingSoundLoop();
                // Don't play done sound here since audio will start playing
            }
            
            audioPlaybackSystem.isReceivingAudioData = false;
            audioPlaybackSystem.isAudioLoadingComplete = true;
            
            unsigned long totalLoadingTime = millis() - audioPlaybackSystem.audioReceptionStartTime;
            float audioLoadingRateKBps = (audioPlaybackSystem.receivedAudioDataSize / 1024.0) / (totalLoadingTime / 1000.0);
            
            logInfoMessage("AUDIO-PLAYBACK", "Audio reception complete - " + 
                          String(audioPlaybackSystem.receivedAudioDataSize/1024.0, 1) + 
                          "KB in " + String(totalLoadingTime) + "ms (" + String(audioLoadingRateKBps, 1) + "KB/s)");
            
            if (!audioPlaybackSystem.isCurrentlyPlaying) {
                // If streaming didn't start (very small audio file), play normally
                logInfoMessage("AUDIO-PLAYBACK", "Playing small audio file immediately...");
                playCompleteAudioBuffer();
                
                // Turn off status LED after playback completes
                digitalWrite(STATUS_LED_PIN, LOW);
                isStatusLedOn = false;
                
                logInfoMessage("AUDIO-PLAYBACK", "Small audio file playback complete");
            } else {
                logInfoMessage("AUDIO-PLAYBACK", "Audio transmission complete, real-time streaming continues...");
            }
            return;
        }
        
        // Handle binary audio data reception
        if (audioPlaybackSystem.isReceivingAudioData) {
            // Append received binary data to audio buffer
            for (size_t i = 0; i < receivedDataLength; i++) {
                audioPlaybackSystem.audioDataBuffer.push_back(receivedBinaryData[i]);
            }
            audioPlaybackSystem.receivedAudioDataSize += receivedDataLength;
            
            // Start real-time streaming playback once we have enough buffered data
            if (!audioPlaybackSystem.isCurrentlyPlaying && 
                audioPlaybackSystem.receivedAudioDataSize >= audioPlaybackSystem.streamingStartThreshold) {
                logInfoMessage("AUDIO-PLAYBACK", "Real-time streaming started with 2s audio buffered (" + 
                              String(audioPlaybackSystem.receivedAudioDataSize/1024.0, 1) + "KB)");
                audioPlaybackSystem.isRealTimeStreamingEnabled = true;
                audioPlaybackSystem.isCurrentlyPlaying = true;
                
                // Create real-time audio streaming playback task
                xTaskCreate(realTimeAudioStreamingTask, "RealTimeAudioStream", 8192, NULL, 1, 
                           &audioPlaybackSystem.audioPlaybackTaskHandle);
            }
            
            // Combined progress logging: show both receiving and streaming status
            if (audioPlaybackSystem.receivedAudioDataSize % 1024 == 0) { // Log every 1KB received
                unsigned long elapsedReceptionTime = millis() - audioPlaybackSystem.audioReceptionStartTime;
                float audioReceptionRateKBps = (audioPlaybackSystem.receivedAudioDataSize / 1024.0) / (elapsedReceptionTime / 1000.0);
                int receptionPercentage = (audioPlaybackSystem.receivedAudioDataSize * 100) / audioPlaybackSystem.expectedTotalAudioSize;
                
                // Create unified visual progress bar
                const int progressBarWidth = 20;
                int filledProgressBlocks = (receptionPercentage * progressBarWidth) / 100;
                String unifiedProgressBar = "[";
                
                for (int i = 0; i < progressBarWidth; i++) {
                    if (i < filledProgressBlocks) {
                        unifiedProgressBar += "█";
                    } else {
                        unifiedProgressBar += "░";
                    }
                }
                unifiedProgressBar += "]";
                
                String currentOperationStatus = audioPlaybackSystem.isCurrentlyPlaying ? "STREAMING" : "RECEIVING";
                float playbackTimeSeconds = audioPlaybackSystem.isCurrentlyPlaying ? 
                                          (float)(audioPlaybackSystem.currentPlaybackPosition / SPEAKER_BYTES_PER_SAMPLE) / (float)SPEAKER_SAMPLE_RATE : 0;
                
                logInfoMessage("AUDIO-STREAM", currentOperationStatus + " " + unifiedProgressBar + " " + String(receptionPercentage) + "% | " + 
                              String(audioPlaybackSystem.receivedAudioDataSize/1024.0, 1) + "KB @ " + 
                              String(audioReceptionRateKBps, 1) + "KB/s" + 
                              (audioPlaybackSystem.isCurrentlyPlaying ? " | " + String(playbackTimeSeconds, 1) + "s played" : ""));
            }
            return;
        }
        
        // Output raw binary data to serial for debugging purposes
        Serial.print("Audio Playback BLE Data Received: ");
        for (size_t i = 0; i < receivedDataLength; i++) {
            Serial.print("0x");
            if (receivedBinaryData[i] < 16) Serial.print("0");
            Serial.print(receivedBinaryData[i], HEX);
            Serial.print(" ");
        }
        Serial.print("| String: \"");
        Serial.print(receivedStringValue);
        Serial.print("\" | Length: ");
        Serial.println(receivedDataLength);
    }
};



// ============================================================================
// System Component Initialization and Cleanup
// ============================================================================

// Initialize and setup all hardware components
void initializeSystemComponents() {
    Serial.println();
    logInfoMessage("SYSTEM", "========================== Initializing system components ==========================");
    
    // Initialize camera subsystem
    initializeCameraSubsystem();

    // Initialize microphone input subsystem
    initializeMicrophoneSubsystem();

    // Initialize speaker output subsystem
    initializeSpeakerSubsystem();

    isSystemInitialized = true;
    logInfoMessage("SYSTEM", "========================== System initialization complete ==========================");
    Serial.println();
    logSystemMemoryUsage("SYSTEM");
}



// Cleanup and free all system resources
void cleanupSystemComponents() {
    Serial.println();
    logInfoMessage("SYSTEM", "========================== Cleaning up system components ==========================");
    
    // Clean up VQA background task if currently running
    if (vqaSystemState.vqaTaskHandle) {
        vqaSystemState.isStopRequested = true;
        
        // Stop processing sound loop
        stopProcessingSoundLoop();
        
        vTaskDelay(pdMS_TO_TICKS(100)); // Allow time for graceful task termination
        if (vqaSystemState.vqaTaskHandle) {
            vTaskDelete(vqaSystemState.vqaTaskHandle);
            vqaSystemState.vqaTaskHandle = nullptr;
        }
        vqaSystemState.isOperationActive = false;
        logInfoMessage("SYSTEM", "VQA streaming task terminated");
    }
    
    // Reset VQA system state to initial values
    vqaSystemState.isOperationActive = false;
    vqaSystemState.isStopRequested = false;
    vqaSystemState.isImageTransmissionComplete = false;
    vqaSystemState.isAudioRecordingInProgress = false;
    vqaSystemState.isAudioRecordingComplete = false;
    vqaSystemState.isAudioStreamingActive = false;
    vqaSystemState.totalAudioBytesStreamed = 0;
    vqaSystemState.audioRecordingStartTime = 0;
    
    // Deinitialize camera subsystem
    esp_camera_deinit();
    logInfoMessage("SYSTEM", "Camera subsystem deinitialized");
    
    // Reset audio playback system state
    audioPlaybackSystem.isReceivingAudioData = false;
    audioPlaybackSystem.isAudioLoadingComplete = false;
    audioPlaybackSystem.isCurrentlyPlaying = false;
    audioPlaybackSystem.currentPlaybackPosition = 0;
    audioPlaybackSystem.audioDataBuffer.clear();
    
    // Stop I2S interfaces (microphone and speaker)
    microphoneI2S.end();
    speakerI2S.end();
    logInfoMessage("SYSTEM", "Microphone and speaker I2S interfaces deinitialized");
    
    isSystemInitialized = false;
    logInfoMessage("SYSTEM", "========================== System cleanup complete ==========================");
    Serial.println();
    logSystemMemoryUsage("SYSTEM");
}



// ============================================================================
// Camera Subsystem Initialization
// ============================================================================

#include "camera_pins.h"
void initializeCameraSubsystem() {
    logInfoMessage("CAMERA", "Initializing camera subsystem...");
    
    camera_config_t cameraConfiguration = {};
    cameraConfiguration.ledc_channel = LEDC_CHANNEL_0;
    cameraConfiguration.ledc_timer = LEDC_TIMER_0;
    cameraConfiguration.pin_d0 = Y2_GPIO_NUM;
    cameraConfiguration.pin_d1 = Y3_GPIO_NUM;
    cameraConfiguration.pin_d2 = Y4_GPIO_NUM;
    cameraConfiguration.pin_d3 = Y5_GPIO_NUM;
    cameraConfiguration.pin_d4 = Y6_GPIO_NUM;
    cameraConfiguration.pin_d5 = Y7_GPIO_NUM;
    cameraConfiguration.pin_d6 = Y8_GPIO_NUM;
    cameraConfiguration.pin_d7 = Y9_GPIO_NUM;
    cameraConfiguration.pin_xclk = XCLK_GPIO_NUM;
    cameraConfiguration.pin_pclk = PCLK_GPIO_NUM;
    cameraConfiguration.pin_vsync = VSYNC_GPIO_NUM;
    cameraConfiguration.pin_href = HREF_GPIO_NUM;
    cameraConfiguration.pin_sscb_sda = SIOD_GPIO_NUM;
    cameraConfiguration.pin_sscb_scl = SIOC_GPIO_NUM;
    cameraConfiguration.pin_pwdn = PWDN_GPIO_NUM;
    cameraConfiguration.pin_reset = RESET_GPIO_NUM;
    cameraConfiguration.xclk_freq_hz = 20000000;
    
    // ============================================================================
    // Image Resolution Configuration Options
    // ============================================================================
    // FRAMESIZE_QVGA - 320x240    (Low quality, fast)
    // FRAMESIZE_CIF - 400x296     (Low-medium quality)
    // FRAMESIZE_VGA - 640x480     (Medium quality)
    // FRAMESIZE_SVGA - 800x600    (Medium-high quality)
    // FRAMESIZE_XGA - 1024x768    (High quality) - CURRENT SETTING
    // FRAMESIZE_HD - 1280x720     (HD quality)
    // FRAMESIZE_UXGA - 1600x1200  (Very high quality)
    // FRAMESIZE_QSXGA - 2592x1944 (Maximum quality, slow)
    cameraConfiguration.frame_size = FRAMESIZE_XGA;
    // ============================================================================

    cameraConfiguration.pixel_format = PIXFORMAT_JPEG;
    cameraConfiguration.grab_mode = CAMERA_GRAB_LATEST;
    cameraConfiguration.fb_location = CAMERA_FB_IN_PSRAM;
    cameraConfiguration.jpeg_quality = psramFound() ? 10 : 12;
    cameraConfiguration.fb_count = psramFound() ? 2 : 1;

    logDebugMessage("CAMERA", "PSRAM availability: " + String(psramFound() ? "Available" : "Not available"));

    if (esp_camera_init(&cameraConfiguration) != ESP_OK) {
        logErrorMessage("CAMERA", "Camera subsystem initialization failed!");
        while (true) delay(100);
    }
    
    logInfoMessage("CAMERA", "Camera subsystem ready");
    logSystemMemoryUsage("CAMERA");
}



// ============================================================================
// Microphone Input Subsystem Initialization
// ============================================================================

void initializeMicrophoneSubsystem() {
    logInfoMessage("MICROPHONE", "Initializing microphone input subsystem...");
    
    // Configure PDM microphone input pins
    microphoneI2S.setPinsPdmRx(42, 41);
    logDebugMessage("MICROPHONE", "PDM pins configured: CLK=42, DATA=41");

    // Initialize I2S in PDM RX mode for microphone recording (VQA audio capture)
    if (!microphoneI2S.begin(I2S_MODE_PDM_RX, MICROPHONE_SAMPLE_RATE, I2S_DATA_BIT_WIDTH_16BIT, I2S_SLOT_MODE_MONO)) {
        logErrorMessage("MICROPHONE", "Microphone I2S initialization failed!");
        while (true) delay(100);
    }
    
    logInfoMessage("MICROPHONE", "Microphone input subsystem ready");
    logSystemMemoryUsage("MICROPHONE");
}

// ============================================================================
// Speaker Output Subsystem Initialization
// ============================================================================

void initializeSpeakerSubsystem() {
    logInfoMessage("SPEAKER", "Initializing speaker output subsystem...");
    
    // Configure I2S TX pins for speaker output (separate from microphone to avoid conflicts)
    speakerI2S.setPins(D1, D0, D2);  // BCLK=D1, LRC=D0, DOUT=D2
    logDebugMessage("SPEAKER", "I2S TX pins configured: BCLK=D1, LRC=D0, DOUT=D2");

    // Initialize I2S in TX mode with configurable audio format
    if (!speakerI2S.begin(I2S_MODE_STD, SPEAKER_SAMPLE_RATE, I2S_SPEAKER_BIT_WIDTH, I2S_SLOT_MODE_MONO)) {
        logErrorMessage("SPEAKER", "Speaker I2S initialization failed!");
        while (true) delay(100);
    }
    
    logInfoMessage("SPEAKER", String("Speaker output subsystem ready - ") + String(SPEAKER_SAMPLE_RATE) + "Hz, " + 
                              String(SPEAKER_BIT_DEPTH) + "-bit, mono (" + String(SPEAKER_AUDIO_QUALITY_NAME) + ")");
    logSystemMemoryUsage("SPEAKER");
}



// ============================================================================
// Bluetooth Low Energy (BLE) Subsystem Initialization
// ============================================================================

void initializeBluetoothSubsystem() {
    Serial.println();
    logInfoMessage("SYSTEM", "========================== Initializing Bluetooth Connection ==========================");

    logInfoMessage("BLUETOOTH", "Initializing Bluetooth Low Energy subsystem...");
    
    BLEDevice::init("XIAO_ESP32S3");
    BLEDevice::setMTU(515);
    BLEServer *bleServer = BLEDevice::createServer();
    bleServer->setCallbacks(new BleServerEventCallbacks());

    BLEService *solariService = bleServer->createService(BLE_SERVICE_UUID);

    // VQA Data Communication Characteristic
    vqaDataCharacteristic = solariService->createCharacteristic(
        VQA_CHARACTERISTIC_UUID,
        BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_NOTIFY
    );
    vqaDataCharacteristic->addDescriptor(new BLE2902());

    // Audio Playback Data Characteristic
    audioPlaybackCharacteristic = solariService->createCharacteristic(
        AUDIO_PLAYBACK_CHARACTERISTIC_UUID,
        BLECharacteristic::PROPERTY_WRITE_NR
    );

    // Temperature Monitoring Characteristic
    temperatureDataCharacteristic = solariService->createCharacteristic(
        TEMPERATURE_CHARACTERISTIC_UUID,
        BLECharacteristic::PROPERTY_NOTIFY
    );
    temperatureDataCharacteristic->addDescriptor(new BLE2902());

    vqaDataCharacteristic->setCallbacks(new VqaCharacteristicEventCallbacks());
    audioPlaybackCharacteristic->setCallbacks(new AudioPlaybackCharacteristicEventCallbacks());
    solariService->start();

    BLEAdvertising *bleAdvertising = BLEDevice::getAdvertising();
    bleAdvertising->addServiceUUID(BLE_SERVICE_UUID);
    bleAdvertising->setScanResponse(true);
    BLEDevice::startAdvertising();

    logInfoMessage("BLUETOOTH", "Ready and advertising as 'XIAO_ESP32S3'");
    logDebugMessage("BLUETOOTH", "Service UUID: " + String(BLE_SERVICE_UUID));
    logSystemMemoryUsage("BLUETOOTH");

    logInfoMessage("SYSTEM", "========================== BLE initialization complete - waiting for connections ==========================");
    Serial.println();
}



  // ============================================================================
  // FreeRTOS Tasks
  // ============================================================================

// Visual Question Answering Streaming Task - Audio First, Then Image After Stop
void visualQuestionAnsweringStreamingTask(void *taskParameters) {
    logInfoMessage("VQA-STREAM", "VQA streaming task started (audio first, then image after stop)");
    
    // Ensure status LED reflects streaming state
    digitalWrite(STATUS_LED_PIN, HIGH);
    isStatusLedOn = true;

    // Initialize VQA streaming state
    vqaSystemState.isOperationActive = true;
    vqaSystemState.isStopRequested = false;
    vqaSystemState.isAudioRecordingInProgress = false;
    vqaSystemState.isAudioRecordingComplete = false;
    vqaSystemState.isImageTransmissionComplete = false;
    vqaSystemState.isAudioStreamingActive = false;
    vqaSystemState.totalAudioBytesStreamed = 0;
    
    // Calculate streaming parameters for continuous audio (VQA uses lower quality for efficiency)
    const int microphoneSampleRate = MICROPHONE_SAMPLE_RATE;
    const int microphoneBytesPerSample = MICROPHONE_BIT_DEPTH / 8;
    const int microphoneBytesPerSecond = microphoneSampleRate * microphoneBytesPerSample;
    const int audioChunkDurationMs = VQA_AUDIO_CHUNK_DURATION_MS;
    const int audioChunkSizeBytes = (microphoneBytesPerSecond * audioChunkDurationMs) / 1000;
    
    logDebugMessage("VQA-STREAM", "Stream configuration: " + String(audioChunkSizeBytes) + " bytes/chunk, " + 
                   String(audioChunkDurationMs) + "ms/chunk, image capture after audio stops");

    // Play start sound to indicate VQA operation beginning
    logInfoMessage("VQA-STREAM", "Playing start sound to indicate VQA operation beginning");
    playStartSound();
    
    // Send VQA operation start header
    String vqaStartHeader = "VQA_START";
    vqaDataCharacteristic->setValue((uint8_t*)vqaStartHeader.c_str(), vqaStartHeader.length());
    vqaDataCharacteristic->notify();
    vTaskDelay(pdMS_TO_TICKS(20));
    logDebugMessage("VQA-STREAM", "VQA start header transmitted");

    // Brief pause after start sound to ensure clean transition
    vTaskDelay(pdMS_TO_TICKS(100));

    // Initialize audio streaming state
    vqaSystemState.isAudioStreamingActive = true;
    vqaSystemState.streamingStartTime = millis();
    int audioChunkSequenceNumber = 0;
    bool isStreamingSuccessful = true;

    // ============================================================================
    // STEP 1: Stream Audio Continuously Until Stop Requested
    // ============================================================================
    logInfoMessage("VQA-STREAM", "Starting continuous audio streaming...");
    
    // Audio streaming start header
    String audioStreamStartHeader = "A_START";  // Audio stream start marker
    vqaDataCharacteristic->setValue((uint8_t*)audioStreamStartHeader.c_str(), audioStreamStartHeader.length());
    vqaDataCharacteristic->notify();
    vTaskDelay(pdMS_TO_TICKS(20));
    logDebugMessage("VQA-STREAM", "Audio stream start header transmitted");

    while (!vqaSystemState.isStopRequested && isStreamingSuccessful && isBleClientConnected) {
        audioChunkSequenceNumber++;
        
        // Allocate memory buffer for this audio chunk
        uint8_t* audioChunkBuffer = new uint8_t[audioChunkSizeBytes];
        if (!audioChunkBuffer) {
            logErrorMessage("VQA-STREAM", "Failed to allocate audio chunk buffer");
            isStreamingSuccessful = false;
            break;
        }

        // Record audio chunk from microphone
        size_t bytesRecordedFromMicrophone = 0;
        unsigned long chunkRecordingStartTime = millis();
        
        while (bytesRecordedFromMicrophone < audioChunkSizeBytes && 
               (millis() - chunkRecordingStartTime) < (audioChunkDurationMs + 100)) {
            size_t bytesToReadFromMicrophone = min((size_t)negotiatedBleChunkSize, audioChunkSizeBytes - bytesRecordedFromMicrophone);
            size_t bytesActuallyRead = microphoneI2S.readBytes((char*)(audioChunkBuffer + bytesRecordedFromMicrophone), bytesToReadFromMicrophone);
            bytesRecordedFromMicrophone += bytesActuallyRead;
            
            if (bytesActuallyRead == 0) {
                vTaskDelay(pdMS_TO_TICKS(1)); // Small delay if no microphone data available
            }
            
            // Check for stop request during audio recording
            if (vqaSystemState.isStopRequested) {
                break;
            }
        }
        
        if (bytesRecordedFromMicrophone < audioChunkSizeBytes && !vqaSystemState.isStopRequested) {
            logWarningMessage("VQA-STREAM", "Audio chunk " + String(audioChunkSequenceNumber) + " incomplete: " + 
                             String(bytesRecordedFromMicrophone) + "/" + String(audioChunkSizeBytes) + " bytes");
        }

        // Only transmit if we have recorded data and not stopping
        if (bytesRecordedFromMicrophone > 0 && !vqaSystemState.isStopRequested) {
            // Transmit audio chunk data in BLE-sized packets (no additional header needed)
            for (size_t i = 0; i < bytesRecordedFromMicrophone && !vqaSystemState.isStopRequested; i += negotiatedBleChunkSize) {
                size_t blePacketSize = min((size_t)negotiatedBleChunkSize, bytesRecordedFromMicrophone - i);
                vqaDataCharacteristic->setValue(audioChunkBuffer + i, blePacketSize);
                vqaDataCharacteristic->notify();
                vTaskDelay(pdMS_TO_TICKS(BLE_CHUNK_SEND_DELAY_MS));
                
                // Check if BLE client disconnected during streaming
                if (!isBleClientConnected) {
                    logWarningMessage("VQA-STREAM", "BLE client disconnected during audio streaming");
                    isStreamingSuccessful = false;
                    break;
                }
            }

            vqaSystemState.totalAudioBytesStreamed += bytesRecordedFromMicrophone;
            logAudioStreamingProgress("VQA-STREAM", bytesRecordedFromMicrophone, vqaSystemState.totalAudioBytesStreamed, 
                                    vqaSystemState.streamingStartTime, audioChunkSequenceNumber);
        }

        // Clean up audio chunk buffer
        delete[] audioChunkBuffer;

        if (!isStreamingSuccessful) break;
    }

    // Finalize audio streaming operation
    vqaSystemState.isAudioStreamingActive = false;
    vqaSystemState.isAudioRecordingComplete = true;

    // Send audio streaming end signal
    String audioStreamEndHeader = "A_END";
    vqaDataCharacteristic->setValue((uint8_t*)audioStreamEndHeader.c_str(), audioStreamEndHeader.length());
    vqaDataCharacteristic->notify();
    vTaskDelay(pdMS_TO_TICKS(20));
    logDebugMessage("VQA-STREAM", "Audio stream end header transmitted");

    unsigned long totalAudioStreamingTime = millis() - vqaSystemState.streamingStartTime;
    float averageAudioStreamingRateKBps = (vqaSystemState.totalAudioBytesStreamed / 1024.0) / (totalAudioStreamingTime / 1000.0);
    
    logInfoMessage("VQA-STREAM", "Audio streaming complete: " + String(vqaSystemState.totalAudioBytesStreamed) + " bytes (" + 
                  String(vqaSystemState.totalAudioBytesStreamed/1024.0, 1) + " KB) in " + String(totalAudioStreamingTime) + 
                  "ms (" + String(averageAudioStreamingRateKBps, 1) + " KB/s average)");

    // ============================================================================
    // STEP 2: Capture and Send Image (only after audio streaming stops)
    // ============================================================================
    if (isStreamingSuccessful && isBleClientConnected) {
        logInfoMessage("VQA-STREAM", "Starting image capture after audio streaming stopped...");
        
        // Take picture
        camera_fb_t *capturedImageFrameBuffer = esp_camera_fb_get();
        
        // Retry once if first capture fails
        if (!capturedImageFrameBuffer) {
            logWarningMessage("VQA-STREAM", "First capture failed, retrying...");
            vTaskDelay(pdMS_TO_TICKS(50));
            capturedImageFrameBuffer = esp_camera_fb_get();
            if (!capturedImageFrameBuffer) {
                logErrorMessage("VQA-STREAM", "Camera capture failed after retry");
                isStreamingSuccessful = false;
            }
        }

        if (capturedImageFrameBuffer && isStreamingSuccessful) {
            size_t capturedImageSize = capturedImageFrameBuffer->len;
            uint8_t *capturedImageDataBuffer = capturedImageFrameBuffer->buf;
            logInfoMessage("VQA-STREAM", "Captured " + String(capturedImageSize) + " bytes (" + 
                          String(capturedImageSize/1024) + " KB)");

            // Send image data via BLE
            logInfoMessage("VQA-STREAM", "Starting image transmission...");
            
            // Image transmission header
            String imageTransmissionHeader = "I:" + String(capturedImageSize);
            vqaDataCharacteristic->setValue((uint8_t*)imageTransmissionHeader.c_str(), imageTransmissionHeader.length());
            vqaDataCharacteristic->notify();
            vTaskDelay(pdMS_TO_TICKS(20));
            logDebugMessage("VQA-STREAM", "Image transmission header sent");

            // Send image data in chunks
            size_t imageBytesSent = 0;
            unsigned long imageTransferStartTime = millis();
            
            for (size_t i = 0; i < capturedImageSize && isBleClientConnected; i += negotiatedBleChunkSize) {
                int currentChunkLength = (i + negotiatedBleChunkSize > capturedImageSize) ? (capturedImageSize - i) : negotiatedBleChunkSize;
                vqaDataCharacteristic->setValue(capturedImageDataBuffer + i, currentChunkLength);
                vqaDataCharacteristic->notify();
                imageBytesSent += currentChunkLength;
                vTaskDelay(pdMS_TO_TICKS(BLE_CHUNK_SEND_DELAY_MS));
                
                logDataTransferProgress("VQA-IMG", imageBytesSent, capturedImageSize, imageTransferStartTime);
                
                // Check if BLE client disconnected during image transfer
                if (!isBleClientConnected) {
                    logWarningMessage("VQA-STREAM", "BLE client disconnected during image transfer");
                    isStreamingSuccessful = false;
                    break;
                }
            }

            if (isStreamingSuccessful && isBleClientConnected) {
                unsigned long totalImageTransferTime = millis() - imageTransferStartTime;
                float imageTransferRateKBps = (capturedImageSize / 1024.0) / (totalImageTransferTime / 1000.0);
                
                // Image transmission footer
                String imageTransmissionFooter = "I_END";
                vqaDataCharacteristic->setValue((uint8_t*)imageTransmissionFooter.c_str(), imageTransmissionFooter.length());
                vqaDataCharacteristic->notify();
                vTaskDelay(pdMS_TO_TICKS(20));
                logDebugMessage("VQA-STREAM", "Image transmission footer sent");

                logInfoMessage("VQA-STREAM", "Image transfer complete in " + String(totalImageTransferTime) + 
                              "ms (" + String(imageTransferRateKBps, 1) + " KB/s)");
                
                vqaSystemState.isImageTransmissionComplete = true;
            }

            // Release camera frame buffer
            esp_camera_fb_return(capturedImageFrameBuffer);
        }
    }

    // ============================================================================
    // STEP 3: Finalize VQA Operation
    // ============================================================================
    
    // Determine completion status reason
    String operationCompletionReason;
    if (vqaSystemState.isStopRequested) {
        operationCompletionReason = "User requested stop";
    } else if (!isBleClientConnected) {
        operationCompletionReason = "BLE client disconnected";
    } else {
        operationCompletionReason = "Streaming error";
    }

    // Send operation completion footer
    if (isStreamingSuccessful || vqaSystemState.isStopRequested) {
        String vqaCompletionFooter = "VQA_END";
        vqaDataCharacteristic->setValue((uint8_t*)vqaCompletionFooter.c_str(), vqaCompletionFooter.length());
        vqaDataCharacteristic->notify();
        logDebugMessage("VQA-STREAM", "VQA completion footer sent");

        // Start processing sound loop now that VQA data has been sent to server
        logInfoMessage("VQA-STREAM", "VQA data transmission complete - starting processing sound while waiting for server response");
        startProcessingSoundLoop();

        unsigned long totalOperationTime = millis() - vqaSystemState.streamingStartTime;
        
        logInfoMessage("VQA-STREAM", "VQA operation completed: " + operationCompletionReason);
        logInfoMessage("VQA-STREAM", "Total duration: " + String(totalOperationTime) + "ms");
        logInfoMessage("VQA-STREAM", "Audio streamed: " + String(vqaSystemState.totalAudioBytesStreamed/1024.0, 1) + " KB");
        logInfoMessage("VQA-STREAM", "Image captured: " + String(vqaSystemState.isImageTransmissionComplete ? "Yes" : "No"));
        
        // Note: Processing sound will continue looping until server response is received
        // The sound will be stopped when response arrives via BLE characteristic callback
    } else {
        String vqaErrorFooter = "VQA_ERR";
        vqaDataCharacteristic->setValue((uint8_t*)vqaErrorFooter.c_str(), vqaErrorFooter.length());
        vqaDataCharacteristic->notify();
        logErrorMessage("VQA-STREAM", "VQA streaming failed: " + operationCompletionReason);
        
        // Stop processing sound loop on error
        stopProcessingSoundLoop();
    }

    // Reset VQA system state
    vqaSystemState.isOperationActive = false;
    vqaSystemState.isStopRequested = false;
    vqaSystemState.vqaTaskHandle = nullptr;

    // Turn off status indicator LED
    digitalWrite(STATUS_LED_PIN, LOW);
    isStatusLedOn = false;
    
    // Task auto-cleanup
    vTaskDelete(NULL);
}

// Real-time Audio Streaming Task for immediate playback
void realTimeAudioStreamingTask(void *taskParameters) {
    logInfoMessage("AUDIO-STREAM", String("Starting real-time audio streaming task (") + 
                                  String(SPEAKER_SAMPLE_RATE) + "Hz, " + String(SPEAKER_BIT_DEPTH) + "-bit, " + 
                                  String(SPEAKER_AUDIO_QUALITY_NAME) + ")");
    
    const size_t audioProcessingChunkSize = SPEAKER_AUDIO_CHUNK_SIZE;  // Configurable chunk size
    const unsigned long targetPlaybackDelayMs = SPEAKER_PLAYBACK_DELAY_MS;  // Configurable delay
    
    // Anti-click: Send silence first to initialize I2S cleanly
    const size_t silenceBufferSize = 64;  // Small silence buffer
    uint8_t silenceInitializationBuffer[silenceBufferSize] = {0};  // Zero-filled silence
    speakerI2S.write(silenceInitializationBuffer, silenceBufferSize);
    vTaskDelay(pdMS_TO_TICKS(10));  // Brief pause
    
    while (true) {
        // Check if we have enough audio data available to play
        size_t availableAudioData = audioPlaybackSystem.receivedAudioDataSize - audioPlaybackSystem.currentPlaybackPosition;
        
        if (availableAudioData >= audioProcessingChunkSize || 
            (audioPlaybackSystem.isAudioLoadingComplete && availableAudioData > 0)) {
            
            size_t bytesToPlayInThisChunk = min(audioProcessingChunkSize, availableAudioData);
            
            // Ensure we don't split samples (align to bytes per sample)
            if (bytesToPlayInThisChunk % SPEAKER_BYTES_PER_SAMPLE != 0) {
                bytesToPlayInThisChunk = (bytesToPlayInThisChunk / SPEAKER_BYTES_PER_SAMPLE) * SPEAKER_BYTES_PER_SAMPLE;
            }
            
            if (bytesToPlayInThisChunk > 0) {
                // Process and play chunk with volume control and filtering
                std::vector<uint8_t> processedAudioChunk(bytesToPlayInThisChunk);
                
                // Anti-click: Volume ramp for first few chunks
                static bool isFirstAudioChunk = true;
                static int volumeRampCounter = 0;
                const int totalVolumeRampChunks = 5;  // Ramp over 5 chunks (~80ms)
                
                for (size_t i = 0; i < bytesToPlayInThisChunk; i += SPEAKER_BYTES_PER_SAMPLE) {
                    size_t audioBufferIndex = audioPlaybackSystem.currentPlaybackPosition + i;
                    
                    // Extract sample based on configured bit depth (currently 16-bit little-endian)
                    int16_t audioSample = audioPlaybackSystem.audioDataBuffer[audioBufferIndex] | 
                                         (audioPlaybackSystem.audioDataBuffer[audioBufferIndex + 1] << 8);
                    
                    // Apply volume control
                    int32_t adjustedVolumeAmplitude = audioPlaybackSystem.volumeAmplitude;
                    
                    // Anti-click: Gradual volume ramp for smooth start
                    if (volumeRampCounter < totalVolumeRampChunks) {
                        adjustedVolumeAmplitude = (adjustedVolumeAmplitude * (volumeRampCounter + 1)) / totalVolumeRampChunks;
                    }
                    
                    audioSample = (int16_t)((int32_t)audioSample * adjustedVolumeAmplitude / 32767);
                    
                    // Apply simple high-pass filter to reduce DC offset and clicks
                    static int16_t previousAudioSample = 0;
                    int16_t filteredAudioSample = audioSample - (previousAudioSample >> 4);  // Simple HPF
                    previousAudioSample = audioSample;
                    
                    // Store back as little-endian
                    processedAudioChunk[i] = filteredAudioSample & 0xFF;
                    processedAudioChunk[i + 1] = (filteredAudioSample >> 8) & 0xFF;
                }
                
                // Increment volume ramp counter
                if (volumeRampCounter < totalVolumeRampChunks) {
                    volumeRampCounter++;
                }
                
                // Send processed audio chunk to I2S speaker
                size_t bytesWrittenToSpeaker = 0;
                while (bytesWrittenToSpeaker < bytesToPlayInThisChunk) {
                    size_t bytesActuallyWritten = speakerI2S.write(processedAudioChunk.data() + bytesWrittenToSpeaker, 
                                                                 bytesToPlayInThisChunk - bytesWrittenToSpeaker);
                    bytesWrittenToSpeaker += bytesActuallyWritten;
                    
                    if (bytesActuallyWritten == 0) {
                        vTaskDelay(pdMS_TO_TICKS(1));
                    }
                }
                
                audioPlaybackSystem.currentPlaybackPosition += bytesToPlayInThisChunk;
            }
        }
        
        // Check if real-time streaming is complete
        if (audioPlaybackSystem.isAudioLoadingComplete && 
            audioPlaybackSystem.currentPlaybackPosition >= audioPlaybackSystem.receivedAudioDataSize) {
            
            float totalPlaybackDurationSeconds = (float)(audioPlaybackSystem.currentPlaybackPosition / SPEAKER_BYTES_PER_SAMPLE) / (float)SPEAKER_SAMPLE_RATE;
            logInfoMessage("AUDIO-STREAM", "Real-time streaming complete - " + String(totalPlaybackDurationSeconds, 1) + 
                          "s played (" + String(audioPlaybackSystem.currentPlaybackPosition/1024.0, 1) + "KB)");
            
            // Turn off status LED and reset playback state
            digitalWrite(STATUS_LED_PIN, LOW);
            isStatusLedOn = false;
            audioPlaybackSystem.isCurrentlyPlaying = false;
            audioPlaybackSystem.isRealTimeStreamingEnabled = false;
            audioPlaybackSystem.currentPlaybackPosition = 0;
            audioPlaybackSystem.audioDataBuffer.clear();
            
            // Delete this task
            audioPlaybackSystem.audioPlaybackTaskHandle = nullptr;
            vTaskDelete(NULL);
            return;
        }
        
        // Wait for next chunk interval
        vTaskDelay(pdMS_TO_TICKS(targetPlaybackDelayMs));
    }
}

// High-Quality Audio Playback Function with 16-bit PCM
void playCompleteAudioBuffer() {
    if (audioPlaybackSystem.audioDataBuffer.size() == 0) {
        logWarningMessage("AUDIO-PLAYBACK", "No audio data available to play");
        return;
    }
    
    size_t totalAudioDataSize = audioPlaybackSystem.audioDataBuffer.size();
    // Each sample is 2 bytes (16-bit) at the configured sample rate
    float audioDurationSeconds = (float)(totalAudioDataSize / 2) / SPEAKER_SAMPLE_RATE;
    logInfoMessage("AUDIO-PLAYBACK", "Playing 16-bit PCM audio: " + String(audioDurationSeconds, 1) + " seconds, " + String(totalAudioDataSize) + " bytes");
    
    // Anti-click: Send silence first to initialize I2S cleanly
    const size_t silenceBufferSize = 64;
    uint8_t silenceInitBuffer[silenceBufferSize] = {0};
    speakerI2S.write(silenceInitBuffer, silenceBufferSize);
    vTaskDelay(pdMS_TO_TICKS(5));
    
    // Use larger chunks for smoother playback at higher quality
    const size_t playbackChunkSize = 512;  // Increased for configured sample rate
    size_t totalBytesPlayed = 0;
    const int volumeRampChunks = 3;  // Ramp over 3 chunks for quick start
    int playbackChunkCounter = 0;
    
    while (totalBytesPlayed < totalAudioDataSize) {
        size_t bytesToPlayInChunk = min(playbackChunkSize, totalAudioDataSize - totalBytesPlayed);
        
        // Ensure we don't split 16-bit samples
        if (bytesToPlayInChunk % 2 == 1) {
            bytesToPlayInChunk--;
        }
        
        if (bytesToPlayInChunk == 0) break;
        
        // Apply volume control and filtering to 16-bit PCM samples
        std::vector<uint8_t> processedPlaybackChunk(bytesToPlayInChunk);
        for (size_t i = 0; i < bytesToPlayInChunk; i += 2) {
            // Extract 16-bit sample (little-endian)
            int16_t audioSample = audioPlaybackSystem.audioDataBuffer[totalBytesPlayed + i] | 
                                 (audioPlaybackSystem.audioDataBuffer[totalBytesPlayed + i + 1] << 8);
            
            // Apply volume control with anti-click ramping
            int32_t adjustedVolumeAmplitude = audioPlaybackSystem.volumeAmplitude;
            if (playbackChunkCounter < volumeRampChunks) {
                adjustedVolumeAmplitude = (adjustedVolumeAmplitude * (playbackChunkCounter + 1)) / volumeRampChunks;
            }
            
            audioSample = (int16_t)((int32_t)audioSample * adjustedVolumeAmplitude / 32767);
            
            // Apply simple high-pass filter to reduce DC offset and clicks
            static int16_t previousSample = 0;
            int16_t filteredSample = audioSample - (previousSample >> 4);  // Simple HPF
            previousSample = audioSample;
            
            // Store back as little-endian
            processedPlaybackChunk[i] = filteredSample & 0xFF;
            processedPlaybackChunk[i + 1] = (filteredSample >> 8) & 0xFF;
        }
        
        playbackChunkCounter++;
        
        // Send entire chunk to I2S at once for smoother playback
        size_t bytesWrittenToSpeaker = 0;
        while (bytesWrittenToSpeaker < bytesToPlayInChunk) {
            size_t bytesActuallyWritten = speakerI2S.write(processedPlaybackChunk.data() + bytesWrittenToSpeaker, 
                                                          bytesToPlayInChunk - bytesWrittenToSpeaker);
            bytesWrittenToSpeaker += bytesActuallyWritten;
            
            // Prevent watchdog timeout on large audio files
            if (bytesActuallyWritten == 0) {
                vTaskDelay(pdMS_TO_TICKS(1));
            }
        }
        
        totalBytesPlayed += bytesToPlayInChunk;
        
        // Yield periodically to prevent watchdog timeout
        if (totalBytesPlayed % 2048 == 0) {
            vTaskDelay(pdMS_TO_TICKS(1));
        }
    }
    
    logInfoMessage("AUDIO-PLAYBACK", "High-quality PCM audio playback finished - played " + String(totalBytesPlayed) + " bytes");
}

// ============================================================================
// Sound Effect Playback Functions
// ============================================================================

void playSoundEffect(const unsigned char* audioData, unsigned int audioLength, const char* audioName) {
    isSoundEffectPlaying = true;
    logInfoMessage("SOUND-EFFECT", String("Playing ") + audioName + " sound effect...");
    
    // Ensure I2S is in a clean state before playing sound effect
    // Flush any pending data and add brief pause for I2S stability
    vTaskDelay(pdMS_TO_TICKS(10));
    
    // Anti-click: Send silence first to initialize cleanly
    const size_t silenceBufferSize = 64;
    uint8_t silenceBuffer[silenceBufferSize] = {0};
    size_t bytesWritten = 0;
    while (bytesWritten < silenceBufferSize) {
        size_t written = speakerI2S.write(silenceBuffer + bytesWritten, silenceBufferSize - bytesWritten);
        if (written == 0) {
            vTaskDelay(pdMS_TO_TICKS(1));
            continue;
        }
        bytesWritten += written;
    }
    vTaskDelay(pdMS_TO_TICKS(10));

    // Play the sound effect in chunks
    const size_t effectChunkSize = 256;
    unsigned int bytesPlayed = 0;

    while (bytesPlayed < audioLength) {
        size_t bytesToPlay = min(effectChunkSize, audioLength - bytesPlayed);
        
        // Apply light volume control to sound effects (reduce to 75% volume)
        std::vector<uint8_t> processedChunk(bytesToPlay);
        for (size_t i = 0; i < bytesToPlay; i += 2) {
            // Extract 16-bit sample (little-endian)
            int16_t sample = audioData[bytesPlayed + i] | (audioData[bytesPlayed + i + 1] << 8);
            
            // Apply volume reduction (75% of original)
            sample = (int16_t)((int32_t)sample * 24576 / 32767);  // 24576/32767 ≈ 0.75
            
            // Store back as little-endian
            processedChunk[i] = sample & 0xFF;
            processedChunk[i + 1] = (sample >> 8) & 0xFF;
        }
        
        // Write chunk with error handling for I2S state issues
        size_t chunkBytesWritten = 0;
        while (chunkBytesWritten < bytesToPlay) {
            size_t written = speakerI2S.write(processedChunk.data() + chunkBytesWritten, 
                                            bytesToPlay - chunkBytesWritten);
            if (written == 0) {
                vTaskDelay(pdMS_TO_TICKS(1));
                continue;
            }
            chunkBytesWritten += written;
        }
        
        bytesPlayed += bytesToPlay;
        
        // Small delay to prevent overwhelming the I2S
        vTaskDelay(pdMS_TO_TICKS(5));
    }

    // Send silence to avoid clicks - with proper error handling
    int silenceSamples = SPEAKER_SAMPLE_RATE / 20; // 50ms of silence
    for (int i = 0; i < silenceSamples; i++) {
        int16_t silence = 0;
        size_t written = 0;
        while (written < sizeof(silence)) {
            size_t result = speakerI2S.write((uint8_t *)&silence + written, sizeof(silence) - written);
            if (result == 0) {
                vTaskDelay(pdMS_TO_TICKS(1));
                continue;
            }
            written += result;
        }
    }

    isSoundEffectPlaying = false;
    logInfoMessage("SOUND-EFFECT", String(audioName) + " sound effect completed");
}

// Task for looping processing sound effect
void loopingProcessingSoundTask(void *taskParameters) {
    logInfoMessage("SOUND-EFFECT", "Starting looping processing sound effect (500ms intervals) - waiting for server response");
    
    int loopCount = 0;
    processingStartTime = millis();
    
    while (isProcessingSoundLooping) {
        // Check for timeout
        if (millis() - processingStartTime > PROCESSING_TIMEOUT_MS) {
            logWarningMessage("SOUND-EFFECT", "Processing sound timeout reached - stopping loop");
            isProcessingSoundLooping = false;
            break;
        }
        
        loopCount++;
        logDebugMessage("SOUND-EFFECT", "Processing sound loop #" + String(loopCount) + " (waiting for server response)");
        
        // Play the processing sound effect (only if still looping)
        if (isProcessingSoundLooping) {
            playSoundEffect(processing_audio_data, processing_audio_length, "Processing");
        }
        
        // Wait 500ms before next loop, checking periodically for stop signal
        for (int i = 0; i < 50 && isProcessingSoundLooping; i++) {
            vTaskDelay(pdMS_TO_TICKS(10)); // 50 * 10ms = 500ms total, but check every 10ms
        }
    }
    
    logInfoMessage("SOUND-EFFECT", "Processing sound loop stopped after " + String(loopCount) + " iterations");
    
    // Ensure sound effect state is cleared when task ends
    if (isSoundEffectPlaying) {
        logDebugMessage("SOUND-EFFECT", "Clearing sound effect state on task exit");
        isSoundEffectPlaying = false;
    }
    
    processingSoundTaskHandle = nullptr;
    vTaskDelete(NULL);
}

void startProcessingSoundLoop() {
    if (!isProcessingSoundLooping) {
        isProcessingSoundLooping = true;
        xTaskCreatePinnedToCore(
            loopingProcessingSoundTask,
            "ProcessingSoundLoop",
            4096,
            nullptr,
            1,  // Normal priority
            &processingSoundTaskHandle,
            0   // Core 0 (different from VQA task which runs on core 1)
        );
        logInfoMessage("SOUND-EFFECT", "Processing sound loop started");
    }
}

void stopProcessingSoundLoop() {
    if (isProcessingSoundLooping) {
        isProcessingSoundLooping = false;
        logInfoMessage("SOUND-EFFECT", "Processing sound loop stop requested");
        
        // Wait for the current sound effect to finish and task to clean up naturally
        unsigned long stopStartTime = millis();
        const unsigned long MAX_STOP_WAIT = 1000; // 1 second max wait
        
        while (processingSoundTaskHandle != nullptr && (millis() - stopStartTime < MAX_STOP_WAIT)) {
            vTaskDelay(pdMS_TO_TICKS(10));
        }
        
        // Force cleanup if task is still running
        if (processingSoundTaskHandle != nullptr) {
            vTaskDelete(processingSoundTaskHandle);
            processingSoundTaskHandle = nullptr;
            logInfoMessage("SOUND-EFFECT", "Processing sound loop task forcibly terminated");
        }
        
        // Ensure any pending sound effect is marked as finished
        if (isSoundEffectPlaying) {
            logInfoMessage("SOUND-EFFECT", "Clearing sound effect state after processing loop stop");
            isSoundEffectPlaying = false;
        }
        
        // Add a brief pause to allow I2S to settle
        vTaskDelay(pdMS_TO_TICKS(50));
    }
}

void playProcessingSound() {
    playSoundEffect(processing_audio_data, processing_audio_length, "Processing");
}

void playDoneSound() {
    playSoundEffect(done_audio_data, done_audio_length, "Done");
}

void playStartSound() {
    playSoundEffect(start_data, start_length, "Start");
}



void playDoneSoundWhenReady() {
    // Wait for any currently playing sound effect to finish
    unsigned long waitStartTime = millis();
    const unsigned long MAX_WAIT_TIME = 2000; // 2 second max wait (longer than any single sound effect)
    
    while (isSoundEffectPlaying && (millis() - waitStartTime < MAX_WAIT_TIME)) {
        vTaskDelay(pdMS_TO_TICKS(10)); // Check every 10ms
    }
    
    if (isSoundEffectPlaying) {
        logWarningMessage("SOUND-EFFECT", "Timeout waiting for sound effect to finish - clearing state and continuing");
        isSoundEffectPlaying = false; // Force clear the state
    }
    
    // Longer pause before playing done sound to ensure clean I2S transition
    vTaskDelay(pdMS_TO_TICKS(100));
    
    logInfoMessage("SOUND-EFFECT", "Processing sound stopped - now playing done sound");
    playDoneSound();
}

// Temperature Monitoring Task
void temperatureMonitoringTask(void *taskParameters) {
    while (true) {
        float currentSystemTemperature = temperatureRead();

        // Emergency safety shutdown if temperature exceeds threshold
        if (currentSystemTemperature > TEMPERATURE_SHUTDOWN_THRESHOLD) {
            logErrorMessage("TEMPERATURE", "Critical overheat detected! Initiating emergency system shutdown");
            esp_deep_sleep_start();
        }

        // Always transmit temperature data to client when BLE is connected
        if (isBleClientConnected) {
            char temperatureDataBuffer[16]; // Sufficient space for header + temperature value
            snprintf(temperatureDataBuffer, sizeof(temperatureDataBuffer), "T:%.2f", currentSystemTemperature);
            temperatureDataCharacteristic->setValue((uint8_t*)temperatureDataBuffer, strlen(temperatureDataBuffer));
            temperatureDataCharacteristic->notify();
        }

        if (isTemperatureLoggingEnabled) {
            logDebugMessage("TEMPERATURE", "Current system temperature: " + String(currentSystemTemperature, 1) + " °C");
        }

        vTaskDelay(pdMS_TO_TICKS(10000)); // Check every 10 seconds
    }
}



  // ============================================================================
  // Setup
  // ============================================================================

void setup() {
    Serial.begin(115200);
    delay(1000);
    
    // Display welcome message and system info
    displayWelcomeArt();
    logInfoMessage("SYSTEM", "Compilation timestamp: " + String(__DATE__) + " " + String(__TIME__));
    logSystemMemoryUsage("SYSTEM");

    // Configure LED and button pins
    pinMode(STATUS_LED_PIN, OUTPUT);
    digitalWrite(STATUS_LED_PIN, LOW);
    pinMode(USER_BUTTON_PIN, INPUT_PULLUP); // Button input with internal pullup resistor

    // Initialize Bluetooth Low Energy subsystem only
    initializeBluetoothSubsystem();

    // Create temperature monitoring task (always active for overheat protection)
    xTaskCreatePinnedToCore(temperatureMonitoringTask, "TemperatureMonitoring", 4096, NULL, 1, &temperatureMonitoringTaskHandle, 1);
    logInfoMessage("SYSTEM", "Temperature monitoring task created (overheat protection always active)");

    logInfoMessage("SYSTEM", "Hardware components will be initialized when a BLE client connects");
    logSystemMemoryUsage("SYSTEM");
}



  // ============================================================================
  // Main Loop
  // ============================================================================

void loop() {
    // ============================================================================
    // User Button Handling (press to start, release to stop VQA)
    // ============================================================================
    int currentButtonState = digitalRead(USER_BUTTON_PIN);
    
    // Optional: debug button values occasionally
    static unsigned long lastButtonDebugTime = 0;
    if (millis() - lastButtonDebugTime > 2000) {
        lastButtonDebugTime = millis();
    }

    // Detect button state changes with debounce protection
    if (currentButtonState != previousButtonState && (millis() - lastButtonPressTime) > BUTTON_DEBOUNCE_MS) {
        lastButtonPressTime = millis();

        if (currentButtonState == LOW) {
            // Button pressed - start VQA operation
            if (!isBleClientConnected) {
                logWarningMessage("USER-INPUT", "Button press ignored - BLE client not connected");
            } else if (!isSystemInitialized) {
                logWarningMessage("USER-INPUT", "Button press ignored - system components not initialized");
            } else if (!vqaSystemState.isOperationActive) {
                // Start VQA streaming operation
                vqaSystemState.isStopRequested = false;
                BaseType_t taskCreationResult = xTaskCreatePinnedToCore(
                    visualQuestionAnsweringStreamingTask, 
                    "VQAStreamingTask", 
                    20480, 
                    nullptr, 
                    1, // Normal priority
                    &vqaSystemState.vqaTaskHandle, 
                    1  // Core 1
                );
                if (taskCreationResult == pdPASS) {
                    logInfoMessage("USER-INPUT", "VQA streaming operation started - button pressed");
                    digitalWrite(STATUS_LED_PIN, HIGH);
                    isStatusLedOn = true;
                } else {
                    logErrorMessage("USER-INPUT", "Failed to create VQA streaming task");
                }
            } else {
                logWarningMessage("USER-INPUT", "VQA operation already active");
            }
        } else {
            // Button released - stop VQA operation
            if (vqaSystemState.isOperationActive) {
                vqaSystemState.isStopRequested = true;
                logInfoMessage("USER-INPUT", "VQA streaming stop requested - button released");
            } else {
                logDebugMessage("USER-INPUT", "Button released - no VQA operation to stop");
            }
        }
    }

    previousButtonState = currentButtonState;

    // ============================================================================
    // Serial Command Interface for Testing and Control
    // ============================================================================
    if (Serial.available()) {
        String serialCommand = Serial.readStringUntil('\n');
        serialCommand.trim();
        serialCommand.toUpperCase();

        if (serialCommand == "VQA_START") {
            if (!isBleClientConnected) {
                logWarningMessage("SERIAL-CMD", "VQA operation ignored - BLE client not connected");
            } else if (isSystemInitialized) {
                if (!vqaSystemState.isOperationActive) {
                    // Start VQA streaming operation via serial command
                    vqaSystemState.isStopRequested = false;
                    BaseType_t taskCreationResult = xTaskCreatePinnedToCore(
                        visualQuestionAnsweringStreamingTask, 
                        "VQAStreamingTask", 
                        20480, 
                        nullptr, 
                        1, // Normal priority
                        &vqaSystemState.vqaTaskHandle, 
                        1  // Core 1
                    );
                    if (taskCreationResult == pdPASS) {
                        logInfoMessage("SERIAL-CMD", "VQA streaming operation started via serial command");
                        digitalWrite(STATUS_LED_PIN, HIGH);
                        isStatusLedOn = true;
                    } else {
                        logErrorMessage("SERIAL-CMD", "Failed to create VQA streaming task via serial command");
                    }
                } else {
                    logWarningMessage("SERIAL-CMD", "VQA operation already active");
                }
            } else {
                logWarningMessage("SERIAL-CMD", "VQA operation ignored - system components not initialized");
            }
        }
        else if (serialCommand == "VQA_STOP") {
            if (vqaSystemState.isOperationActive) {
                vqaSystemState.isStopRequested = true;
                logInfoMessage("SERIAL-CMD", "VQA streaming stop requested via serial command");
            } else {
                logWarningMessage("SERIAL-CMD", "No active VQA operation to stop");
            }
        }
        else if (serialCommand == "STATUS") {
            logInfoMessage("SYSTEM", "=== System Status ===");
            logInfoMessage("SYSTEM", "BLE connected: " + String(isBleClientConnected ? "Yes" : "No"));
            logInfoMessage("SYSTEM", "System initialized: " + String(isSystemInitialized ? "Yes" : "No"));
            logInfoMessage("SYSTEM", "VQA running: " + String(vqaSystemState.isOperationActive ? "Yes" : "No"));
            logInfoMessage("SYSTEM", "Temperature monitoring: " + String(isTemperatureLoggingEnabled ? "Enabled" : "Disabled"));
            logInfoMessage("SYSTEM", "BLE chunk size: " + String(negotiatedBleChunkSize) + " bytes");
            logInfoMessage("AUDIO-PLAYBACK", "Audio receiving: " + String(audioPlaybackSystem.isReceivingAudioData ? "Yes" : "No"));
            logInfoMessage("AUDIO-PLAYBACK", "Audio playing: " + String(audioPlaybackSystem.isCurrentlyPlaying ? "Yes" : "No"));
            logInfoMessage("AUDIO-PLAYBACK", "Audio loaded: " + String(audioPlaybackSystem.isAudioLoadingComplete ? "Yes" : "No"));
            if (audioPlaybackSystem.audioDataBuffer.size() > 0) {
                logInfoMessage("AUDIO-PLAYBACK", "Audio buffer: " + String(audioPlaybackSystem.audioDataBuffer.size()) + " bytes");
                logInfoMessage("AUDIO-PLAYBACK", "Play position: " + String(audioPlaybackSystem.currentPlaybackPosition) + " bytes");
                float playbackProgress = (float)audioPlaybackSystem.currentPlaybackPosition / audioPlaybackSystem.audioDataBuffer.size() * 100;
                logInfoMessage("AUDIO-PLAYBACK", "Playback progress: " + String(playbackProgress, 1) + "%");
            }
            logSystemMemoryUsage("SYSTEM");
        }
        else if (serialCommand == "DEBUG") {
            activeLoggingLevel = (activeLoggingLevel == LOG_LEVEL_DEBUG) ? LOG_LEVEL_INFO : LOG_LEVEL_DEBUG;
            logInfoMessage("SYSTEM", "Debug logging " + String(activeLoggingLevel == LOG_LEVEL_DEBUG ? "enabled" : "disabled"));
        }
        else if (serialCommand == "TEMP") {
            isTemperatureLoggingEnabled = !isTemperatureLoggingEnabled;
            logInfoMessage("SERIAL-CMD", "Temperature monitoring " + String(isTemperatureLoggingEnabled ? "enabled" : "disabled") + " via serial (overheat protection always active)");
        }
        else if (serialCommand.startsWith("VOL")) {
            // Volume control: VOL <number> (0-32767)
            int spaceIndex = serialCommand.indexOf(' ');
            if (spaceIndex > 0) {
                int newVolumeLevel = serialCommand.substring(spaceIndex + 1).toInt();
                if (newVolumeLevel >= 0 && newVolumeLevel <= 32767) {
                    audioPlaybackSystem.volumeAmplitude = newVolumeLevel;
                    logInfoMessage("SERIAL-CMD", "Speaker volume set to " + String(newVolumeLevel));
                } else {
                    logWarningMessage("SERIAL-CMD", "Volume must be between 0-32767");
                }
            } else {
                logInfoMessage("SERIAL-CMD", "Current volume: " + String(audioPlaybackSystem.volumeAmplitude));
            }
        }
        else if (serialCommand == "PROCESSING") {
            if (isSystemInitialized) {
                logInfoMessage("SERIAL-CMD", "Playing processing sound effect via serial command");
                playProcessingSound();
            } else {
                logWarningMessage("SERIAL-CMD", "Sound effect ignored - system not initialized");
            }
        }
        else if (serialCommand == "PROCESSING_LOOP_START") {
            if (isSystemInitialized) {
                logInfoMessage("SERIAL-CMD", "Starting processing sound loop via serial command");
                startProcessingSoundLoop();
            } else {
                logWarningMessage("SERIAL-CMD", "Sound effect ignored - system not initialized");
            }
        }
        else if (serialCommand == "PROCESSING_LOOP_STOP") {
            logInfoMessage("SERIAL-CMD", "Stopping processing sound loop via serial command");
            stopProcessingSoundLoop();
        }
        else if (serialCommand == "SIMULATE_RESPONSE") {
            if (isProcessingSoundLooping) {
                logInfoMessage("SERIAL-CMD", "Simulating server response - stopping processing sound and playing done sound");
                stopProcessingSoundLoop();
                playDoneSoundWhenReady();
            } else {
                logInfoMessage("SERIAL-CMD", "No processing sound currently active");
            }
        }
        else if (serialCommand == "TEST_SEQUENCE") {
            if (isSystemInitialized) {
                logInfoMessage("SERIAL-CMD", "Testing complete sound effect sequence:");
                logInfoMessage("SERIAL-CMD", "1. Starting processing sound loop...");
                startProcessingSoundLoop();
                
                // Create a test task to simulate server response after 5 seconds
                xTaskCreate([](void*) {
                    vTaskDelay(pdMS_TO_TICKS(5000)); // Wait 5 seconds
                    logInfoMessage("TEST", "Simulating server response after 5 seconds");
                    stopProcessingSoundLoop();
                    playDoneSoundWhenReady();
                    vTaskDelete(NULL);
                }, "TestSequence", 2048, NULL, 1, NULL);
            } else {
                logWarningMessage("SERIAL-CMD", "Test sequence ignored - system not initialized");
            }
        }
        else if (serialCommand == "DONE") {
            if (isSystemInitialized) {
                logInfoMessage("SERIAL-CMD", "Playing done sound effect via serial command");
                playDoneSound();
            } else {
                logWarningMessage("SERIAL-CMD", "Sound effect ignored - system not initialized");
            }
        }
        else if (serialCommand.length() > 0) {
            logWarningMessage("SERIAL-CMD", "Unknown serial command: '" + serialCommand + "'");
            logInfoMessage("SERIAL-CMD", "Available commands: VQA_START, VQA_STOP, STATUS, DEBUG, TEMP, VOL <0-32767>");
            logInfoMessage("SERIAL-CMD", "Sound commands: PROCESSING, PROCESSING_LOOP_START, PROCESSING_LOOP_STOP, DONE, SIMULATE_RESPONSE, TEST_SEQUENCE");
        }
    }

    delay(10);
  }



// ============================================================================
// Welcome ASCII Art Display
// ============================================================================
void displayWelcomeArt() {
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
    
    logInfoMessage("SYSTEM", "Welcome, Cj");
  }
