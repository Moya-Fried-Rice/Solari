/// Utility class for adding punctuation to STT transcriptions
/// This helps improve VLM prompt quality when STT doesn't include punctuation
/// 
/// The Sherpa ONNX GigaSpeech model has limited punctuation support.
/// This class intelligently adds punctuation to improve VLM response quality.
class PunctuationHelper {
  
  /// Add appropriate punctuation to a transcribed text
  /// This is particularly important for VLM prompts where punctuation affects meaning
  static String addPunctuation(String text) {
    if (text.isEmpty) return text;
    
    // Trim and convert to lowercase for analysis (but preserve original case in output)
    final trimmed = text.trim();
    final lowerText = trimmed.toLowerCase();
    
    // Question patterns - these typically need question marks
    final questionWords = [
      'what', 'where', 'when', 'why', 'who', 'how', 'which',
      'is there', 'are there', 'can you', 'could you', 'would you',
      'do you', 'does', 'did', 'will', 'should', 'could', 'can',
      'am i', 'are you', 'is this', 'is that', 'are these', 'are those'
    ];
    
    // Check if it's likely a question
    bool isQuestion = false;
    
    // Check for question word at the beginning
    for (final questionWord in questionWords) {
      if (lowerText.startsWith(questionWord)) {
        isQuestion = true;
        break;
      }
    }
    
    // Check for inverted sentence structure (auxiliary verb + subject)
    final auxiliaryVerbs = ['is', 'are', 'was', 'were', 'do', 'does', 'did', 'can', 'could', 'will', 'would', 'should'];
    final words = lowerText.split(' ');
    if (words.isNotEmpty && auxiliaryVerbs.contains(words[0])) {
      isQuestion = true;
    }
    
    // Add appropriate punctuation
    if (isQuestion) {
      return trimmed.endsWith('?') ? trimmed : '$trimmed?';
    } else {
      // Default to period for statements
      return trimmed.endsWith('.') ? trimmed : '$trimmed.';
    }
  }
  
  /// Enhanced version with more sophisticated rules
  static String addPunctuationAdvanced(String text) {
    if (text.isEmpty) return text;
    
    final trimmed = text.trim();
    final lowerText = trimmed.toLowerCase();
    
    // Already has punctuation
    if (trimmed.endsWith('.') || trimmed.endsWith('?') || trimmed.endsWith('!')) {
      return trimmed;
    }
    
    // Exclamations - commands or strong statements
    final exclamationPatterns = [
      'stop', 'wait', 'look', 'help', 'no', 'yes', 'wow', 'oh', 'ah',
      'listen', 'watch', 'be careful', 'attention', 'alert'
    ];
    
    for (final pattern in exclamationPatterns) {
      if (lowerText.startsWith(pattern) && lowerText.split(' ').length <= 3) {
        return '$trimmed!';
      }
    }
    
    // Questions (comprehensive check)
    if (_isQuestion(lowerText)) {
      return '$trimmed?';
    }
    
    // Commands/imperatives
    if (_isCommand(lowerText)) {
      return '$trimmed.';
    }
    
    // Default to period
    return '$trimmed.';
  }
  
  static bool _isQuestion(String lowerText) {
    // Question words
    final questionWords = [
      'what', 'where', 'when', 'why', 'who', 'how', 'which', 'whose'
    ];
    
    // Question phrases - enhanced for VLM vision queries
    final questionPhrases = [
      'is there', 'are there', 'can you', 'could you', 'would you',
      'do you', 'does', 'did', 'will you', 'should', 'could', 'can',
      'am i', 'are you', 'is this', 'is that', 'are these', 'are those',
      'tell me', 'show me',
      // VLM-specific vision question patterns
      'do you see', 'can you see', 'is anyone', 'are people', 'how many',
      'what color', 'what type', 'what kind', 'can you identify',
      'is the person', 'are the people'
    ];
    
    // Check question words at start
    for (final word in questionWords) {
      if (lowerText.startsWith(word)) return true;
    }
    
    // Check question phrases
    for (final phrase in questionPhrases) {
      if (lowerText.startsWith(phrase)) return true;
    }
    
    // Check auxiliary verb inversion
    final words = lowerText.split(' ');
    if (words.isNotEmpty) {
      final firstWord = words[0];
      final auxiliaryVerbs = ['is', 'are', 'was', 'were', 'do', 'does', 'did', 
                            'can', 'could', 'will', 'would', 'should', 'have', 'has', 'had'];
      return auxiliaryVerbs.contains(firstWord);
    }
    
    return false;
  }
  
  static bool _isCommand(String lowerText) {
    final commandWords = [
      'tell', 'show', 'describe', 'explain', 'find', 'look', 'see',
      'identify', 'count', 'list', 'read', 'check', 'analyze',
      // VLM-specific vision commands
      'detect', 'recognize', 'examine', 'observe', 'inspect',
      'compare', 'measure', 'estimate', 'locate', 'point'
    ];
    
    for (final word in commandWords) {
      if (lowerText.startsWith(word)) return true;
    }
    
    return false;
  }
  
  /// Get detailed analysis of punctuation decision (useful for debugging)
  static Map<String, dynamic> analyzePunctuation(String text) {
    if (text.isEmpty) return {'type': 'empty', 'punctuation': '', 'reason': 'Empty text'};
    
    final trimmed = text.trim();
    final lowerText = trimmed.toLowerCase();
    
    // Already has punctuation
    if (trimmed.endsWith('.') || trimmed.endsWith('?') || trimmed.endsWith('!')) {
      return {
        'type': 'already_punctuated',
        'punctuation': trimmed.substring(trimmed.length - 1),
        'reason': 'Text already has punctuation'
      };
    }
    
    // Check exclamations
    final exclamationPatterns = [
      'stop', 'wait', 'look', 'help', 'no', 'yes', 'wow', 'oh', 'ah',
      'listen', 'watch', 'be careful', 'attention', 'alert'
    ];
    
    for (final pattern in exclamationPatterns) {
      if (lowerText.startsWith(pattern) && lowerText.split(' ').length <= 3) {
        return {
          'type': 'exclamation',
          'punctuation': '!',
          'reason': 'Short exclamatory phrase detected: "$pattern"'
        };
      }
    }
    
    // Check questions
    if (_isQuestion(lowerText)) {
      return {
        'type': 'question',
        'punctuation': '?',
        'reason': 'Question pattern detected'
      };
    }
    
    // Check commands
    if (_isCommand(lowerText)) {
      return {
        'type': 'command',
        'punctuation': '.',
        'reason': 'Imperative/command detected'
      };
    }
    
    // Default
    return {
      'type': 'statement',
      'punctuation': '.',
      'reason': 'Default declarative statement'
    };
  }
}