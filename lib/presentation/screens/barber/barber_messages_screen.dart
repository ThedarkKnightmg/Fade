import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/chat_message.dart';
import '../../widgets/paper_kit.dart';

/// The barber side of messaging — conversations with the **clients** who have
/// booked (or requested) a cut. Mirrors the client-side Messages tab, but the
/// threads are keyed by client name (see [AppState.barberChats]).
class BarberMessagesScreen extends StatelessWidget {
  const BarberMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleBtn(
                    icon: Icons.arrow_back_rounded,
                    size: 42,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(L.messages, style: AppTypography.h2(context)),
                        Text(L.yourClients,
                            style: AppTypography.bodySmall(context)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: AnimatedBuilder(
                  animation: AppState.instance,
                  builder: (context, _) {
                    final clients = AppState.instance.barberClients;
                    if (clients.isEmpty) return const _EmptyBarberMessages();
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: clients.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final b = clients[i];
                        final name = b.clientName ?? '—';
                        final msgs = AppState.instance.barberChatWith(name);
                        return FadeSlideIn(
                          delay: Duration(milliseconds: 50 * i),
                          child: _ClientConvoTile(
                            booking: b,
                            index: i,
                            last: msgs.isNotEmpty ? msgs.last : null,
                            onTap: () => Navigator.of(context).push(
                              FadeThroughPageRoute(
                                child: BarberChatScreen(booking: b),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when the barber has no clients yet — nobody to message.
class _EmptyBarberMessages extends StatelessWidget {
  const _EmptyBarberMessages();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.forum_outlined,
                  size: 30, color: AppColors.accent),
            ),
            const SizedBox(height: 16),
            Text(L.noMessagesYet, style: AppTypography.h3(context)),
            const SizedBox(height: 6),
            SizedBox(
              width: 250,
              child: Text(
                L.clientsMessageHere,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientConvoTile extends StatelessWidget {
  const _ClientConvoTile({
    required this.booking,
    required this.index,
    required this.last,
    required this.onTap,
  });

  final Booking booking;
  final int index;
  final ChatMessage? last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final msg = last;
    final name = booking.clientName ?? '—';
    final preview = msg == null ? L.tapToMessage : msg.text;
    // The client spoke last and the barber hasn't replied — surface as unread.
    final unread = msg != null && !msg.mine;
    return PaperCard(
      onTap: onTap,
      radius: 20,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          InitialAvatar(name: name, size: 50, index: index),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.h4(context)),
                    ),
                    if (msg != null)
                      Text(
                        DateFormat('HH:mm').format(msg.at),
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: p.textTertiary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          fontSize: 13.5,
                          fontWeight:
                              unread ? FontWeight.w800 : FontWeight.w600,
                          color: unread ? p.text : p.textSecondary,
                        ),
                      ),
                    ),
                    if (unread)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A 1:1 conversation between the barber and a client. Messages live in
/// [AppState], keyed by client name; the client sends a short canned reply.
class BarberChatScreen extends StatefulWidget {
  const BarberChatScreen({super.key, required this.booking});

  final Booking booking;

  @override
  State<BarberChatScreen> createState() => _BarberChatScreenState();
}

class _BarberChatScreenState extends State<BarberChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  String get _client => widget.booking.clientName ?? '—';

  void _send() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    AppState.instance.sendBarberChat(_client, t);
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
                  InitialAvatar(name: _client, size: 42, index: 1),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_client, style: AppTypography.h4(context)),
                        Text(widget.booking.service.name,
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
                  final msgs = AppState.instance.barberChatWith(_client);
                  _toBottom();
                  if (msgs.isEmpty) {
                    return Center(
                      child: Text(L.sayHiTo(_client),
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
            Container(
              padding: EdgeInsets.fromLTRB(
                  12, 8, 12, 8 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: p.card,
                border: Border(top: BorderSide(color: p.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: p.bg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: p.border),
                      ),
                      child: TextField(
                        controller: _ctrl,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w600, color: p.text),
                        decoration: InputDecoration(
                          isCollapsed: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                          border: InputBorder.none,
                          hintText: L.messageHint,
                          hintStyle: GoogleFonts.nunito(
                              fontWeight: FontWeight.w600,
                              color: p.textSecondary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg});
  final ChatMessage msg;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final mine = msg.mine;
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
                    msg.text,
                    style: GoogleFonts.nunito(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: mine ? Colors.white : p.text,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('HH:mm').format(msg.at),
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
