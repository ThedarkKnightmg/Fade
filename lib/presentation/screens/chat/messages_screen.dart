import 'package:flutter/material.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../widgets/chat_kit.dart';
import '../../widgets/conversation_view.dart';
import 'chat_screen.dart';

/// The Messages tab — conversations with barbers you've **booked** with.
/// Messaging is a post-booking feature: you reach a barber by booking at their
/// shop first, then texting them from here (or from the shop page).
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + the Telegram plane mark on the right.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    Expanded(
                      child:
                          Text(L.messages, style: AppTypography.h1(context)),
                    ),
                    const TelegramMark(size: 34),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(L.barbersYouBooked,
                    style: AppTypography.bodySmall(context)),
              ),
              const SizedBox(height: 12),
              ChatSearchField(onChanged: (v) => setState(() => _query = v)),
              const SizedBox(height: 12),
              Expanded(
                child: AnimatedBuilder(
                  animation: AppState.instance,
                  builder: (context, _) {
                    final s = AppState.instance;
                    if (s.bookedBarbers.isEmpty) return const _EmptyMessages();
                    final q = _query.trim().toLowerCase();
                    // Newest activity first: a conversation with a fresh
                    // message rises to the top, like every messenger.
                    final convos = s.bookedBarbers
                        .where((r) => r.barber.name.toLowerCase().contains(q))
                        .toList()
                      ..sort((a, b) {
                        DateTime at(BarberRef r) {
                          final m = s.chatWith(r.barber.id);
                          return m.isEmpty ? DateTime(2000) : m.last.at;
                        }

                        return at(b).compareTo(at(a));
                      });
                    if (convos.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Text(L.chatNoResults,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall(context)),
                      );
                    }
                    return ListView(
                      padding: const EdgeInsets.only(bottom: 120),
                      children: [
                        Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: p.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: p.border),
                          ),
                          child: Column(
                            children: [
                              for (var i = 0; i < convos.length; i++)
                                Builder(builder: (context) {
                                  final ref = convos[i];
                                  final msgs = s.chatWith(ref.barber.id);
                                  return ChatThreadTile(
                                    name: ref.barber.name,
                                    last: msgs.isEmpty ? null : msgs.last,
                                    unread: unreadIn(msgs),
                                    typing: s.isTyping(ref.barber.id),
                                    fallback: ref.shop.name,
                                    showDivider: i < convos.length - 1,
                                    onTap: () => Navigator.of(context).push(
                                      FadeThroughPageRoute(
                                        child: ChatScreen(
                                            shop: ref.shop, barber: ref.barber),
                                      ),
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                      ],
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

/// Shown when the user hasn't booked anyone yet — texting is locked until then.
class _EmptyMessages extends StatelessWidget {
  const _EmptyMessages();

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
                L.pfMessagesEmptyBody,
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
