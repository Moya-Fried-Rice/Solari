import 'package:flutter_test/flutter_test.dart';
import 'package:solari/utils/punctuation_helper.dart';

void main() {
  group('PunctuationHelper Tests', () {
    test('should add question mark to questions starting with question words', () {
      expect(PunctuationHelper.addPunctuation('what is this'), equals('what is this?'));
      expect(PunctuationHelper.addPunctuation('where is the person'), equals('where is the person?'));
      expect(PunctuationHelper.addPunctuation('how many people are there'), equals('how many people are there?'));
      expect(PunctuationHelper.addPunctuation('is there a person present in this image'), equals('is there a person present in this image?'));
    });

    test('should add question mark to yes/no questions with auxiliary verbs', () {
      expect(PunctuationHelper.addPunctuation('are you ready'), equals('are you ready?'));
      expect(PunctuationHelper.addPunctuation('can you see this'), equals('can you see this?'));
      expect(PunctuationHelper.addPunctuation('do you understand'), equals('do you understand?'));
    });

    test('should add period to statements', () {
      expect(PunctuationHelper.addPunctuation('this is a person'), equals('this is a person.'));
      expect(PunctuationHelper.addPunctuation('there are three people'), equals('there are three people.'));
      expect(PunctuationHelper.addPunctuation('describe this image'), equals('describe this image.'));
    });

    test('should not modify text that already has punctuation', () {
      expect(PunctuationHelper.addPunctuation('what is this?'), equals('what is this?'));
      expect(PunctuationHelper.addPunctuation('this is a test.'), equals('this is a test.'));
    });

    test('advanced punctuation should handle commands with exclamation', () {
      expect(PunctuationHelper.addPunctuationAdvanced('stop'), equals('stop!'));
      expect(PunctuationHelper.addPunctuationAdvanced('help me'), equals('help me!'));
      expect(PunctuationHelper.addPunctuationAdvanced('look at this'), equals('look at this!'));
    });

    test('should handle edge cases', () {
      expect(PunctuationHelper.addPunctuation(''), equals(''));
      expect(PunctuationHelper.addPunctuation('   '), equals('.'));
      expect(PunctuationHelper.addPunctuation('yes'), equals('yes.'));
    });

    test('real-world VLM prompt examples', () {
      // These are the types of prompts that would improve VLM responses
      expect(
        PunctuationHelper.addPunctuationAdvanced('is there a person present in this image'),
        equals('is there a person present in this image?')
      );
      
      expect(
        PunctuationHelper.addPunctuationAdvanced('describe what you see'),
        equals('describe what you see.')
      );
      
      expect(
        PunctuationHelper.addPunctuationAdvanced('how many objects are visible'),
        equals('how many objects are visible?')
      );
      
      expect(
        PunctuationHelper.addPunctuationAdvanced('tell me about this scene'),
        equals('tell me about this scene?')
      );
    });

    test('enhanced VLM-specific patterns', () {
      // VLM vision questions
      expect(
        PunctuationHelper.addPunctuationAdvanced('do you see any animals'),
        equals('do you see any animals?')
      );
      expect(
        PunctuationHelper.addPunctuationAdvanced('what color is the car'),
        equals('what color is the car?')
      );
      
      // VLM vision commands
      expect(
        PunctuationHelper.addPunctuationAdvanced('detect faces in this image'),
        equals('detect faces in this image.')
      );
      expect(
        PunctuationHelper.addPunctuationAdvanced('recognize the objects'),
        equals('recognize the objects.')
      );
    });

    test('punctuation analysis method', () {
      final analysis = PunctuationHelper.analyzePunctuation('is there a person');
      expect(analysis['type'], equals('question'));
      expect(analysis['punctuation'], equals('?'));
      
      final commandAnalysis = PunctuationHelper.analyzePunctuation('detect people');
      expect(commandAnalysis['type'], equals('command'));
      expect(commandAnalysis['punctuation'], equals('.'));
      
      final exclamationAnalysis = PunctuationHelper.analyzePunctuation('help me');
      expect(exclamationAnalysis['type'], equals('exclamation'));
      expect(exclamationAnalysis['punctuation'], equals('!'));
    });
  });
}