import 'package:flutter/material.dart';

import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../../data/models/barber.dart';
import '../../../data/models/barbershop.dart';
import 'package:intl/intl.dart';

import '../../widgets/chat_kit.dart';
import '../../widgets/message_composer.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/sticker_picker.dart';

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

  Future<void> _sendSticker() async {
    final s = await pickSticker(context);
    if (s == null || !mounted) return;
    AppState.instance.sendChat(widget.barber.id, s, isSticker: true);
    _toBottom();
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _soon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(L.comingSoon),
        behavior: SnackBarBehavior.floating,
      ));
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.h4(context)),
                        // Telegram's presence line sits where the shop name was.
                        Text(L.lastSeenRecently,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption(context)),
                      ],
                    ),
                  ),
                  // Overflow only — no call button, since Fade doesn't place
                  // calls and a dead phone icon is worse than none.
                  _HeaderAction(
                    icon: Icons.more_vert_rounded,
                    onTap: () => _soon(context),
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
                    // Flatten to rows so date pills and same-sender grouping
                    // are decided once, not re-derived per build.
                    final rows = <Widget>[];
                    for (var i = 0; i < msgs.length; i++) {
                      final m = msgs[i];
                      final prev = i == 0 ? null : msgs[i - 1];
                      final next =
                          i == msgs.length - 1 ? null : msgs[i + 1];
                      // A new day starts a separator.
                      if (prev == null || !_sameDay(prev.at, m.at)) {
                        rows.add(ChatDateSeparator(day: m.at));
                      }
                      // Tail only on the last bubble of a same-sender run, or
                      // when the next message is on another day.
                      final lastOfRun = next == null ||
                          next.mine != m.mine ||
                          !_sameDay(next.at, m.at);
                      rows.add(m.isSticker
                          ? StickerMessage(
                              sticker: m.text,
                              mine: m.mine,
                              time: DateFormat('HH:mm').format(m.at),
                            )
                          : ChatBubble(
                              text: m.text,
                              mine: m.mine,
                              at: m.at,
                              showTail: lastOfRun,
                            ));
                    }
                    return ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                      itemCount: rows.length,
                      itemBuilder: (_, i) => rows[i],
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
              onSticker: _sendSticker,
            ),
          ],
        ),
      ),
    );
  }
}

/// A quiet round icon button for the chat header (call / overflow), matching
/// Telegram's flat header actions.
class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 42,
        height: 42,
        child: Icon(icon, size: 22, color: p.textSecondary),
      ),
    );
  }
}

