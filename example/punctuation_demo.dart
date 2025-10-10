/// Example demonstrating the punctuation enhancement feature
/// 
/// This shows how the STT service now automatically adds punctuation
/// to improve VLM prompt quality and response accuracy.

import '../lib/utils/punctuation_helper.dart';

void main() {
  // Examples of STT output without punctuation
  final sttOutputs = [
    'is there a person present in this image',
    'what do you see in this picture',
    'describe the scene',
    'how many people are visible',
    'tell me about the objects',
    'can you identify any animals',
    'show me what is happening',
    'look at this carefully',
    'stop analyzing',
    'help me understand',
    // New VLM-specific examples
    'do you see any faces',
    'what color is the car',
    'detect people in this photo',
    'recognize the objects here',
  ];

  print('=== STT Punctuation Enhancement Demo ===\n');
  
  for (final text in sttOutputs) {
    final enhanced = PunctuationHelper.addPunctuationAdvanced(text);
    final analysis = PunctuationHelper.analyzePunctuation(text);
    
    print('Original:  "$text"');
    print('Enhanced:  "$enhanced"');
    print('Type:      ${analysis['type']} (${analysis['reason']})');
    print('Impact:    ${_analyzeImpact(text, enhanced)}');
    print('---');
  }
}

String _analyzeImpact(String original, String enhanced) {
  if (enhanced.endsWith('?')) {
    return 'Question format - VLM will provide more specific answers';
  } else if (enhanced.endsWith('!')) {
    return 'Exclamation - VLM will understand urgency/emphasis';
  } else if (enhanced.endsWith('.')) {
    return 'Statement - VLM will provide descriptive response';
  }
  return 'No change needed';
}