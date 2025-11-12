import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../models/history_entry.dart';

/// Provider for managing history state throughout the app
class HistoryProvider extends ChangeNotifier {
  final List<HistoryEntry> _history = [];

  List<HistoryEntry> get history => List.unmodifiable(_history);

  void addEntry(Uint8List image, String response, {String? question, Uint8List? rawAudio}) {
    _history.insert(0, HistoryEntry.fromSolari(response, image, question: question, rawAudio: rawAudio));
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }
}
