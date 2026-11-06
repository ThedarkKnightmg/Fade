import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../../data/models/booking.dart';
import '../../widgets/conversation_view.dart';
import '../../widgets/paper_kit.dart';

/// The barber's conversations with clients.
///
/// It used to be one floating card per client in booking order, nearly all
/// reading "Tap to message", with the two clients who had actually written
/// buried among them. Now, the Telegram way:
///  * search at the top;
///  * active conversations on ONE surface, newest activity first, with unread
///    counts, "You:" and ticks on my own last message, and "typing…";
///  * clients nobody has written to yet in a compact "Start a chat" strip,
///    instead of a screenful of empty threads.
class BarberMessagesScreen extends StatefulWidget {
  const BarberMessagesScreen({super.key});

  @override
  State<BarberMessagesScreen> createState() => _BarberMessagesScreenState();
}

class _BarberMessagesScreenState extends State<BarberMessagesScreen> {
  String _query = '';

  void _open(Booking b) => Navigator.of(context).push(
        FadeThroughPageRoute(child: BarberChatScreen(booking: b)),
      );

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: AppState.instance,
          builder: (context, _) {
            final s = AppState.instance;
            final q = _query.trim().toLowerCase();
            final clients = s.barberClients
                .where((b) => (b.clientName ?? '').toLowerCase().contains(q))
                .toList();
            final active = clients
                .where((b) => s.barberChatWith(b.clientName ?? '').isNotEmpty ||
                    s.isTyping(b.clientName ?? ''))
                .toList()
              ..sort((a, b) {
                DateTime at(Booking x) {
                  final m = s.barberChatWith(x.clientName ?? '');
                  return m.isEmpty ? DateTime.now() : m.last.at;
                }

                return at(b).compareTo(at(a));
              });
            final quiet = clients.where((b) => !active.contains(b)).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
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
                const SizedBox(height: 14),
                ChatSearchField(onChanged: (v) => setState(() => _query = v)),
                const SizedBox(height: 14),
                if (s.barberClients.isEmpty)
                  const _EmptyBarberMessages()
                else if (clients.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text(L.chatNoResults,
                          style: AppTypography.bodySmall(context)),
                    ),
                  )
                else ...[
                  if (quiet.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(L.chatStartWith,
                          style: AppTypography.h4(context)),
                    ),
                    SizedBox(
                      height: 92,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: quiet.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (_, i) => _StartChip(
                          booking: quiet[i],
                          onTap: () => _open(quiet[i]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (active.isNotEmpty)
                    Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: p.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: p.border),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < active.length; i++)
                            Builder(builder: (context) {
                              final name = active[i].clientName ?? '—';
                              final msgs = s.barberChatWith(name);
                              return ChatThreadTile(
                                name: name,
                                last: msgs.isEmpty ? null : msgs.last,
                                unread: unreadIn(msgs),
                                typing: s.isTyping(name),
                                showDivider: i < active.length - 1,
                                onTap: () => _open(active[i]),
                              );
                            }),
                        ],
                      ),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A client nobody has written to yet: avatar, first name and when they're
/// coming, one tap to start the conversation.
class _StartChip extends StatelessWidget {
  const _StartChip({required this.booking, required this.onTap});
  final Booking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final name = booking.clientName ?? '—';
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            ChatAvatar(name: name, size: 54),
            const SizedBox(height: 5),
            Text(
              name.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                  fontSize: 12.5, fontWeight: FontWeight.w800, color: p.text),
            ),
            Text(
              DateFormat('HH:mm').format(booking.dateTime),
              style: GoogleFonts.nunito(
                  fontSize: 11, fontWeight: FontWeight.w700, color: p.textTertiary),
            ),
          ],
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
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
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
    );
  }
}

/// A conversation between the barber and a client (shared layout and
/// features: [ConversationView]).
class BarberChatScreen extends StatelessWidget {
  const BarberChatScreen({super.key, required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    final client = booking.clientName ?? '—';
    return ConversationView(
      name: client,
      threadKey: client,
      messages: () => s.barberChatWith(client),
      send: (text, {isSticker = false, replyTo}) => s.sendBarberChat(client,
          text, isSticker: isSticker, replyTo: replyTo),
      delete: (id) => s.deleteBarberChatMessage(client, id),
      quickReplies: L.chatQuickBarber,
      idleSubtitle: L.tr(booking.service.name),
      nextVisit: () => s.nextVisitWithClient(client),
    );
  }
}
