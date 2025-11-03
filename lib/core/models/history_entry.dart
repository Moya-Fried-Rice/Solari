
import 'dart:typed_data';

/// Model class for representing a history entry (image + question + response)
class HistoryEntry {
  /// The sender of the message (e.g., "Solari")
  final String sender;

  /// The user's question (from STT transcription)
  final String? question;

  /// The AI response/description
  final String response;

  /// When the message was created
  final DateTime time;

  /// The image associated with the entry
  final Uint8List image;

  HistoryEntry({
    required this.sender,
    this.question,
    required this.response,
    required this.time,
    required this.image,
  });

  /// Create a history entry from Solari (the AI) with optional question
  factory HistoryEntry.fromSolari(String response, Uint8List image, {String? question}) {
    return HistoryEntry(
      sender: 'Solari',
      question: question,
      response: response,
      time: DateTime.now(),
      image: image,
    );
  }

  /// Legacy getter for backward compatibility
  String get text => response;
}