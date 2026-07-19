import 'package:flutter/material.dart';

import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../../data/models/barber.dart';
import '../../../data/models/barbershop.dart';
import '../../widgets/chat_kit.dart';
import '../../widgets/message_composer.dart';
import '../../widgets/paper_kit.dart';

/// A 1:1 conversation with a barber — bubbles + a text input. Messages live in
/// [AppState]; the barber sends a short canned reply after you write.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.shop, required this.barber});

  final Barbershop shop;
  final Barber barber;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  void _send() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    AppState.instance.sendChat(widget.barber.id, t);
    _ctrl.clear();
    _toBottom();
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header.
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 16, 8),
              child: Row(
                children: [
                  CircleBtn(
                    icon: Icons.arrow_back_rounded,
                    size: 42,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 10),
                  InitialAvatar(name: widget.barber.name, size: 42, index: 1),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.barber.name,
                            style: AppTypography.h4(context)),
                        Text(widget.shop.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall(context)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: p.border),
            // Messages — on a Telegram-style wallpaper.
            Expanded(
              child: ChatWallpaper(
                child: AnimatedBuilder(
                  animation: AppState.instance,
                  builder: (context, _) {
                    final msgs = AppState.instance.chatWith(widget.barber.id);
                    _toBottom();
                    if (msgs.isEmpty) {
                      return Center(
                        child: Text(L.sayHiTo(widget.barber.name),
                            style: AppTypography.bodySmall(context)),
                      );
                    }
                    return ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
                      itemCount: msgs.length,
                      itemBuilder: (_, i) => ChatBubble(
                        text: msgs[i].text,
                        mine: msgs[i].mine,
                        at: msgs[i].at,
                      ),
                    );
                  },
                ),
              ),
            ),
            // Input bar.
            MessageComposer(
              controller: _ctrl,
              onSend: _send,
              hintText: L.messageHint,
            ),
          ],
        ),
      ),
    );
  }
}

