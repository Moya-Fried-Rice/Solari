import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'A-Law WAV Generator',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FlutterTts flutterTts = FlutterTts();
  final AudioPlayer audioPlayer = AudioPlayer();

  String filePath = "";
  String status = "Ready";
  String duration = "";

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    // Configure TTS for lower quality output to reduce processing
    await flutterTts.setSpeechRate(0.5); // Slower speech rate
    await flutterTts.setVolume(0.8);
    await flutterTts.setPitch(1.0);

    // Set language to English
    await flutterTts.setLanguage("en-US");

    setState(() {
      status = "TTS initialized";
    });
  }

  String _calculateDuration(
    int fileSize,
    int sampleRate,
    int channels,
    int bytesPerSample,
  ) {
    // For A-Law: 1 byte per sample, mono channel
    int totalSamples = fileSize - 44; // Subtract WAV header size
    double durationSeconds = totalSamples / (sampleRate * channels);

    int minutes = (durationSeconds / 60).floor();
    int seconds = (durationSeconds % 60).floor();
    int milliseconds = ((durationSeconds % 1) * 1000).floor();

    if (minutes > 0) {
      return "${minutes}m ${seconds}s";
    } else if (seconds > 0) {
      return "${seconds}.${milliseconds.toString().padLeft(3, '0').substring(0, 1)}s";
    } else {
      return "${milliseconds}ms";
    }
  }

  Future<void> _convertWithRetry(
    String tempPath,
    String finalPath, {
    int maxRetries = 3,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      setState(() {
        status = "Converting to A-Law (attempt $attempt/$maxRetries)...";
      });

      String ffmpegCommand =
          '-i $tempPath -ar 8000 -ac 1 -acodec pcm_alaw -y $finalPath';
      print('FFmpeg attempt $attempt: $ffmpegCommand');

      final session = await FFmpegKit.execute(ffmpegCommand);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        setState(() {
          filePath = finalPath;
          status = "Success! 8kHz A-Law WAV created";
        });

        // Get file size for info
        File finalFile = File(finalPath);
        int fileSize = await finalFile.length();

        // Calculate duration for A-Law format (8kHz, mono, 1 byte per sample)
        String audioDuration = _calculateDuration(fileSize, 8000, 1, 1);
        setState(() {
          duration = audioDuration;
        });

        print('A-Law compressed WAV saved at: $finalPath');
        print(
          'File size: ${fileSize} bytes (${(fileSize / 1024).toStringAsFixed(1)} KB)',
        );
        print('Duration: $audioDuration');
        print(
          'Format: 8kHz, A-Law compression, mono - optimized for smart glasses',
        );
        return; // Success!
      } else {
        // Get detailed error information
        final logs = await session.getAllLogs();
        String errorDetails = logs.map((log) => log.getMessage()).join('\n');

        print('FFmpeg attempt $attempt failed with return code: $returnCode');
        print('FFmpeg error details: $errorDetails');

        if (attempt < maxRetries) {
          print('Retrying in ${attempt * 500}ms...');
          await Future.delayed(Duration(milliseconds: attempt * 500));
        } else {
          setState(() {
            status = "Conversion failed after $maxRetries attempts";
          });
          throw Exception(
            'FFmpeg conversion failed after $maxRetries attempts',
          );
        }
      }
    }
  }

  Future<void> synthesizeTextToFile(String text, String fileName) async {
    setState(() {
      status = "Synthesizing...";
      duration = ""; // Clear previous duration
    });

    try {
      // Only Android supported
      if (!Platform.isAndroid) {
        throw UnsupportedError("Only Android is supported in this version.");
      }

      // Use temporary directory
      Directory tempDir = await getTemporaryDirectory();
      String tempPath = "${tempDir.path}/${fileName}_temp.wav";
      String finalPath = "${tempDir.path}/${fileName}_alaw.wav";

      // Synthesize to temporary file first
      await flutterTts.synthesizeToFile(text, tempPath, true);

      // Wait a bit to ensure TTS file is fully written and closed
      await Future.delayed(const Duration(milliseconds: 500));

      // Verify the temp file exists and has content
      File tempFile = File(tempPath);
      if (!await tempFile.exists()) {
        throw Exception("TTS file was not created: $tempPath");
      }

      int tempFileSize = await tempFile.length();
      if (tempFileSize == 0) {
        throw Exception("TTS file is empty: $tempPath");
      }

      print('TTS file created: ${tempFileSize} bytes');

      // Use retry mechanism for more reliable conversion
      await _convertWithRetry(tempPath, finalPath);

      // Clean up temporary file on success
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (e) {
      setState(() {
        status = "Error: $e";
      });
      print('Error in synthesizeTextToFile: $e');
    }
  }

  Future<void> playAudio() async {
    if (filePath.isEmpty) return;
    await audioPlayer.play(DeviceFileSource(filePath));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('A-Law WAV Generator (Smart Glasses)')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                await synthesizeTextToFile(
                  "Peter Piper picked a peck of pickled peppers. A peck of pickled peppers Peter Piper picked. If Peter Piper picked a peck of pickled peppers, Where’s the peck of pickled peppers Peter Piper picked?",
                  "tts_file",
                );
              },
              child: const Text("Synthesize to A-Law WAV"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: playAudio,
              child: const Text("Play A-Law Audio"),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    "Status: $status",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    filePath.isEmpty
                        ? "No file yet"
                        : "8kHz A-Law WAV saved at:\n$filePath",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (filePath.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    if (duration.isNotEmpty)
                      Text(
                        "🎵 Duration: $duration",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    const SizedBox(height: 4),
                    const Text(
                      "✅ Optimized for smart glasses\n📱 8kHz sample rate, A-Law compression, mono",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.green),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
