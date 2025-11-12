import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tts_service.dart';
import 'vibration_service.dart';
import 'select_to_speak_service.dart';

/// Service that provides in-app screen reader functionality similar to TalkBack
/// Allows navigation through focusable elements and reads them aloud
class ScreenReaderService extends ChangeNotifier {
  static final ScreenReaderService _instance = ScreenReaderService._internal();
  factory ScreenReaderService() => _instance;
  ScreenReaderService._internal();

  final TtsService _ttsService = TtsService();
  final SelectToSpeakService _selectToSpeakService = SelectToSpeakService();
  bool _isEnabled = false;
  FocusNode? _currentFocusNode;
  final List<FocusNode> _focusableNodes = [];
  final Map<FocusNode, VoidCallback?> _focusCallbacks = {};
  final Map<FocusNode, String> _nodeContexts = {}; // Maps focus nodes to their page context
  String? _activeContext; // Currently active page/bottom sheet context
  int _currentIndex = -1;

  /// Get whether screen reader is currently enabled
  bool get isEnabled => _isEnabled;

  /// Get current focus node
  FocusNode? get currentFocusNode => _currentFocusNode;

  /// Get current focus index
  int get currentIndex => _currentIndex;

  /// Initialize the service
  Future<void> initialize() async {
    await _loadPreferences();
    await _ttsService.initialize();
  }

  /// Load saved preferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('screenReaderEnabled') ?? false;
    debugPrint('Screen reader loaded: enabled=$_isEnabled');
  }

  /// Save preferences
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('screenReaderEnabled', _isEnabled);
    debugPrint('Screen reader saved: enabled=$_isEnabled');
  }

  /// Enable or disable screen reader
  Future<void> setEnabled(bool enabled) async {
    if (_isEnabled == enabled) return;
    
    _isEnabled = enabled;
    await _savePreferences();
    
    if (enabled) {
      // Apply current speech settings from SelectToSpeakService
      _ttsService.setSpeechSpeed(_selectToSpeakService.speechRate);
      
      // Apply output device preference from SelectToSpeakService
      if (_selectToSpeakService.outputToSolari) {
        _ttsService.setBleTransmission(true);
      } else {
        _ttsService.setLocalPlayback(true);
      }
      
      VibrationService.mediumFeedback();
      await _speakText('Screen reader enabled');
      
      // Don't auto-focus - let user navigate manually
      // This prevents interrupting the announcement
    } else {
      await _speakText('Screen reader disabled');
      VibrationService.mediumFeedback();
      _currentFocusNode?.unfocus();
      _currentFocusNode = null;
      _currentIndex = -1;
    }
    
    notifyListeners();
  }

  /// Set the active context (page/screen that should have focus)
  void setActiveContext(String context) {
    if (_activeContext != context) {
      debugPrint('Screen reader: Switching context from "$_activeContext" to "$context"');
      _activeContext = context;
      _currentFocusNode?.unfocus();
      _currentFocusNode = null;
      _currentIndex = -1;
      notifyListeners();
    }
  }

  /// Get the current active context
  String? get activeContext => _activeContext;

  /// Register a focusable element with context
  void registerFocusNode(FocusNode node, {VoidCallback? onTap, String? context}) {
    if (!_focusableNodes.contains(node)) {
      _focusableNodes.add(node);
      _focusCallbacks[node] = onTap;
      if (context != null) {
        _nodeContexts[node] = context;
      }
      debugPrint('Screen reader: Registered focus node for context "${context ?? 'default'}" (total: ${_focusableNodes.length})');
    }
  }

  /// Unregister a focusable element
  void unregisterFocusNode(FocusNode node) {
    _focusableNodes.remove(node);
    _focusCallbacks.remove(node);
    _nodeContexts.remove(node);
    if (_currentFocusNode == node) {
      _currentFocusNode = null;
      _currentIndex = -1;
    }
    // Only log if we still have nodes (reduces noise during bulk cleanup)
    if (_focusableNodes.isNotEmpty) {
      debugPrint('Screen reader: Unregistered focus node (total: ${_focusableNodes.length})');
    }
  }

  /// Get focusable nodes for the active context only
  List<FocusNode> get _activeNodes {
    if (_activeContext == null) {
      return _focusableNodes; // If no context set, return all nodes
    }
    return _focusableNodes.where((node) {
      final nodeContext = _nodeContexts[node];
      return nodeContext == null || nodeContext == _activeContext;
    }).toList();
  }

  /// Move focus to next element (only within active context)
  Future<void> focusNext() async {
    if (!_isEnabled) {
      return; // Silently return if disabled
    }
    
    final activeNodes = _activeNodes;
    if (activeNodes.isEmpty) {
      // Only log if this is unexpected (not during cleanup)
      if (_isEnabled) {
        debugPrint('Screen reader: No focusable nodes available for context "$_activeContext"');
      }
      return;
    }

    // Find current index in active nodes
    int activeIndex = _currentFocusNode != null ? activeNodes.indexOf(_currentFocusNode!) : -1;
    activeIndex = (activeIndex + 1) % activeNodes.length;
    
    _currentIndex = _focusableNodes.indexOf(activeNodes[activeIndex]);
    debugPrint('Screen reader: Moving to next element (${activeIndex + 1} of ${activeNodes.length} in context "$_activeContext")');
    await _setFocusAt(_currentIndex);
  }

  /// Move focus to previous element (only within active context)
  Future<void> focusPrevious() async {
    if (!_isEnabled) {
      return; // Silently return if disabled
    }
    
    final activeNodes = _activeNodes;
    if (activeNodes.isEmpty) {
      // Only log if this is unexpected (not during cleanup)
      if (_isEnabled) {
        debugPrint('Screen reader: No focusable nodes available for context "$_activeContext"');
      }
      return;
    }

    // Find current index in active nodes
    int activeIndex = _currentFocusNode != null ? activeNodes.indexOf(_currentFocusNode!) : -1;
    activeIndex = (activeIndex - 1 + activeNodes.length) % activeNodes.length;
    
    _currentIndex = _focusableNodes.indexOf(activeNodes[activeIndex]);
    debugPrint('Screen reader: Moving to previous element (${activeIndex + 1} of ${activeNodes.length} in context "$_activeContext")');
    await _setFocusAt(_currentIndex);
  }

  /// Set focus at specific index
  Future<void> _setFocusAt(int index) async {
    if (index < 0 || index >= _focusableNodes.length) return;

    _currentFocusNode?.unfocus();
    _currentFocusNode = _focusableNodes[index];
    _currentFocusNode?.requestFocus();
    
    VibrationService.lightFeedback();
    notifyListeners();
  }

  /// Focus on a specific node (useful after enabling screen reader on current element)
  Future<void> focusOnNode(FocusNode node) async {
    if (!_isEnabled) return;
    
    final index = _focusableNodes.indexOf(node);
    if (index >= 0) {
      _currentIndex = index;
      await _setFocusAt(index);
    }
  }

  /// Announce text using TTS
  Future<void> announceText(String text, {String? hint}) async {
    if (!_isEnabled) return;
    
    String announcement = text;
    if (hint != null && hint.isNotEmpty) {
      announcement += '. $hint';
    }
    
    await _speakText(announcement);
  }

  /// Internal speak method
  Future<void> _speakText(String text) async {
    try {
      // Use the same output device preference as SelectToSpeakService
      if (_selectToSpeakService.outputToSolari) {
        _ttsService.setBleTransmission(true);
      } else {
        _ttsService.setLocalPlayback(true);
      }
      
      await _ttsService.speakText(
        text,
        onStart: () => debugPrint('Screen reader speaking: "$text" via ${_selectToSpeakService.outputToSolari ? "Solari device" : "Phone"}'),
        onComplete: () => debugPrint('Screen reader finished speaking'),
        onError: (error) => debugPrint('Screen reader error: $error'),
      );
    } catch (e) {
      debugPrint('Error in screen reader: $e');
    }
  }

  /// Stop any currently playing speech
  Future<void> stopSpeaking() async {
    await _ttsService.stopSpeaking();
  }

  /// Activate currently focused element (simulate tap)
  void activateFocusedElement() {
    if (_currentFocusNode == null || !_isEnabled) return;
    
    VibrationService.mediumFeedback();
    // Call the registered callback for the focused node
    final callback = _focusCallbacks[_currentFocusNode];
    if (callback != null) {
      callback();
    }
  }

  /// Clear focus nodes for a specific context (call when leaving a page/screen)
  void clearContextNodes(String context) {
    final nodesToRemove = <FocusNode>[];
    
    for (final node in _focusableNodes) {
      if (_nodeContexts[node] == context) {
        nodesToRemove.add(node);
      }
    }
    
    if (nodesToRemove.isNotEmpty) {
      debugPrint('Screen reader: Clearing ${nodesToRemove.length} nodes for context "$context"');
      
      for (final node in nodesToRemove) {
        if (_currentFocusNode == node) {
          _currentFocusNode?.unfocus();
          _currentFocusNode = null;
          _currentIndex = -1;
        }
        _focusableNodes.remove(node);
        _focusCallbacks.remove(node);
        _nodeContexts.remove(node);
      }
      
      notifyListeners();
    }
  }
  
  /// Clear all registered focus nodes (call when completely resetting)
  void clearAllFocusNodes() {
    if (_focusableNodes.isNotEmpty) {
      debugPrint('Screen reader: Clearing all ${_focusableNodes.length} focus nodes');
    }
    
    stopSpeaking();
    
    _focusableNodes.clear();
    _focusCallbacks.clear();
    _nodeContexts.clear();
    _currentFocusNode?.unfocus();
    _currentFocusNode = null;
    _currentIndex = -1;
    notifyListeners();
  }

  /// Dispose resources
  @override
  void dispose() {
    _focusableNodes.clear();
    _focusCallbacks.clear();
    _currentFocusNode = null;
    super.dispose();
  }
}
