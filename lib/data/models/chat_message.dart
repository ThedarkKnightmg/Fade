/// One message in a barber conversation.
class ChatMessage {
  ChatMessage({
    required this.text,
    required this.mine,
    required this.at,
    this.isSticker = false,
    this.replyTo,
    String? id,
  }) : id = id ?? 'm${at.microsecondsSinceEpoch}_${_seq++}';

  static int _seq = 0;

  /// Stable identity, so a reply or a delete targets THIS message even when
  /// two messages share a text and a minute.
  final String id;

  final String text;

  /// True if the user sent it; false for the barber.
  final bool mine;

  final DateTime at;

  /// A sticker renders large and bubble-less (Telegram-style) instead of as a
  /// text bubble; [text] then holds the sticker's glyph.
  final bool isSticker;

  /// The message this one answers, shown as a quote above the text.
  final ChatMessage? replyTo;
}
