import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../models/history_entry.dart';

class HistoryProvider extends ChangeNotifier {
  final List<HistoryEntry> _history = [];

  List<HistoryEntry> get history => List.unmodifiable(_history);

  void addEntry(Uint8List image, String text) {
    _history.insert(0, HistoryEntry.fromSolari(text, image));
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }
}
