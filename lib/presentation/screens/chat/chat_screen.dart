import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../../data/models/barber.dart';
import '../../../data/models/barbershop.dart';
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
            // Messages.
            Expanded(
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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: msgs.length,
                    itemBuilder: (_, i) => _Bubble(msg: msgs[i]),
                  );
                },
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

class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg});
  final dynamic msg;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final mine = msg.mine as bool;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: mine ? AppColors.accent : p.card,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(mine ? 18 : 4),
                  bottomRight: Radius.circular(mine ? 4 : 18),
                ),
                border: mine ? null : Border.all(color: p.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text as String,
                    style: GoogleFonts.nunito(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: mine ? Colors.white : p.text,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('HH:mm').format(msg.at as DateTime),
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: mine
                          ? Colors.white.withValues(alpha: 0.7)
                          : p.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
