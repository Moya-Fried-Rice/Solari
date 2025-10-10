# Solari

**Solari** is an AI-powered smart glasses system designed to assist visually impaired individuals by providing real-time visual descriptions of their surroundings.  

The system integrates advanced computer vision and natural language technologies to translate visual input into spoken feedback, helping users navigate daily life with greater independence and confidence.  

With Solari, the goal is to bridge accessibility gaps by making the world more understandable through seamless, wearable technology.

## Recent Updates

### STT Punctuation Enhancement (Latest)
- **Improved VLM Response Quality**: Added automatic punctuation restoration to speech-to-text output
- **Smart Question Detection**: Automatically adds question marks to interrogative sentences ("Is there a person present in this image?")
- **Context-Aware Punctuation**: Distinguishes between questions, statements, and commands
- **Better VLM Prompts**: Enhances visual language model responses by providing properly punctuated prompts

The GigaSpeech-trained Sherpa ONNX model has limited punctuation support. Our new `PunctuationHelper` class intelligently adds appropriate punctuation marks to improve VLM prompt quality and response accuracy.