
import 'dart:typed_data';

/// Model class for representing a history entry (image + message)
class HistoryEntry {
  /// The sender of the message (e.g., "Solari")
  final String sender;

  /// The content/description of the message
  final String text;

  /// When the message was created
  final DateTime time;

  /// The image associated with the entry
  final Uint8List image;

  HistoryEntry({
    required this.sender,
    required this.text,
    required this.time,
    required this.image,
  });

  /// Create a history entry from Solari (the AI)
  factory HistoryEntry.fromSolari(String text, Uint8List image) {
    return HistoryEntry(
      sender: 'Solari',
      text: text,
      time: DateTime.now(),
      image: image,
    );
  }
}