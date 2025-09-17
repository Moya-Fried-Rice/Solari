/// Model class for representing a chat message
class ChatMessage {
  /// The sender of the message (e.g., "You", "System", or "Solari")
  final String sender;
  
  /// The content of the message
  final String text;
  
  /// When the message was sent
  final DateTime time;

  /// Creates a new chat message
  ChatMessage({
    required this.sender, 
    required this.text, 
    required this.time,
  });
  
  /// Create a message from the user
  factory ChatMessage.fromUser(String text) {
    return ChatMessage(
      sender: 'You', 
      text: text, 
      time: DateTime.now(),
    );
  }
  
  /// Create a message from Solari (the AI)
  factory ChatMessage.fromSolari(String text) {
    return ChatMessage(
      sender: 'Solari', 
      text: text, 
      time: DateTime.now(),
    );
  }
  
  /// Create a message from the system
  factory ChatMessage.fromSystem(String text) {
    return ChatMessage(
      sender: 'System', 
      text: text, 
      time: DateTime.now(),
    );
  }
}
