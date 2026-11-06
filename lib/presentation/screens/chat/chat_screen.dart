import 'package:flutter/material.dart';

import '../../../core/i18n/strings.dart';
import '../../../data/app_state.dart';
import '../../../data/models/barber.dart';
import '../../../data/models/barbershop.dart';
import '../../widgets/conversation_view.dart';

/// A 1:1 conversation with a barber. The layout and every chat feature
/// (replies, ticks, typing, pinned visit, quick replies) live in
/// [ConversationView], shared with the barber's side.
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key, required this.shop, required this.barber});

  final Barbershop shop;
  final Barber barber;

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    return ConversationView(
      name: barber.name,
      threadKey: barber.id,
      messages: () => s.chatWith(barber.id),
      send: (text, {isSticker = false, replyTo}) =>
          s.sendChat(barber.id, text, isSticker: isSticker, replyTo: replyTo),
      delete: (id) => s.deleteChatMessage(barber.id, id),
      quickReplies: L.chatQuickClient,
      idleSubtitle: shop.name,
      nextVisit: () => s.nextVisitWithBarber(barber.id),
    );
  }
}
