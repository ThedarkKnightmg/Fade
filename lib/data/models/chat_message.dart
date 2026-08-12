/// One message in a barber conversation.
class ChatMessage {
  ChatMessage({
    required this.text,
    required this.mine,
    required this.at,
    this.isSticker = false,
  });

  final String text;

  /// True if the user sent it; false for the barber.
  final bool mine;

  final DateTime at;

  /// A sticker renders large and bubble-less (Telegram-style) instead of as a
  /// text bubble; [text] then holds the sticker's glyph.
  final bool isSticker;
}
