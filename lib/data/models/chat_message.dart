/// One message in a barber conversation.
class ChatMessage {
  ChatMessage({required this.text, required this.mine, required this.at});

  final String text;

  /// True if the user sent it; false for the barber.
  final bool mine;

  final DateTime at;
}
