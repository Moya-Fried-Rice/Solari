import 'package:flutter/material.dart';

/// Service to manage screen magnification functionality
class MagnificationService extends ChangeNotifier {
  static final MagnificationService _instance = MagnificationService._internal();
  factory MagnificationService() => _instance;
  MagnificationService._internal();

  bool _isEnabled = false;

  bool get isEnabled => _isEnabled;

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    notifyListeners();
  }
}
