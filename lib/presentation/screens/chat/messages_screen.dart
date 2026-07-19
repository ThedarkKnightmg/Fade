import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../../data/models/barber.dart';
import '../../../data/models/barbershop.dart';
import '../../../data/models/chat_message.dart';
import '../../widgets/chat_kit.dart';
import '../../widgets/paper_kit.dart';
import 'chat_screen.dart';

/// The Messages tab — conversations with barbers you've **booked** with.
/// Messaging is a post-booking feature: you reach a barber by booking at their
/// shop first, then texting them from here (or from the shop page).
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

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
              // Title + the Telegram plane mark on the right.
              Row(
                children: [
                  Expanded(
                    child: Text(L.messages, style: AppTypography.h1(context)),
                  ),
                  const TelegramMark(size: 34),
                ],
              ),
              const SizedBox(height: 2),
              Text(L.barbersYouBooked,
                  style: AppTypography.bodySmall(context)),
              const SizedBox(height: 16),
              Expanded(
                child: AnimatedBuilder(
                  animation: AppState.instance,
                  builder: (context, _) {
                    final convos = AppState.instance.bookedBarbers;
                    if (convos.isEmpty) return const _EmptyMessages();
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 120),
                      itemCount: convos.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final ref = convos[i];
                        final msgs = AppState.instance.chatWith(ref.barber.id);
                        return FadeSlideIn(
                          delay: Duration(milliseconds: 50 * i),
                          child: _ConvoTile(
                            shop: ref.shop,
                            barber: ref.barber,
                            index: i,
                            last: msgs.isNotEmpty ? msgs.last : null,
                            onTap: () => Navigator.of(context).push(
                              FadeThroughPageRoute(
                                child: ChatScreen(
                                    shop: ref.shop, barber: ref.barber),
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

class _ConvoTile extends StatelessWidget {
  const _ConvoTile({
    required this.shop,
    required this.barber,
    required this.index,
    required this.last,
    required this.onTap,
  });

  final Barbershop shop;
  final Barber barber;
  final int index;
  final ChatMessage? last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final msg = last;
    final preview = msg == null ? L.tapToMessage : msg.text;
    // Barber spoke last and you haven't replied — surface it as "unread".
    final unread = msg != null && !msg.mine;
    return PaperCard(
      onTap: onTap,
      radius: 20,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          InitialAvatar(name: barber.name, size: 50, index: index),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(barber.name,
                          style: AppTypography.h4(context)),
                    ),
                    if (msg != null)
                      Text(
                        DateFormat('HH:mm').format(msg.at),
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: unread ? AppColors.accent : p.textTertiary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${shop.name} · $preview',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall(context),
                      ),
                    ),
                    if (unread) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded, color: p.textTertiary, size: 22),
        ],
      ),
    );
  }
}
