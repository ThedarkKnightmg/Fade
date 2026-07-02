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
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(L.messages, style: AppTypography.h1(context)),
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
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
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
    final p = Paper.of(context);
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
                color: p.card,
                shape: BoxShape.circle,
                border: Border.all(color: p.border),
              ),
              child: Icon(Icons.forum_outlined,
                  size: 30, color: AppColors.accent),
            ),
            const SizedBox(height: 16),
            Text(L.noMessagesYet, style: AppTypography.h3(context)),
            const SizedBox(height: 6),
            SizedBox(
              width: 250,
              child: Text(
                'Book a cut at a shop, then message your barber here if you '
                'need to.',
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
  final dynamic last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final preview = last == null ? 'Tap to message ✍️' : (last.text as String);
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
                    if (last != null)
                      Text(
                        DateFormat('HH:mm').format(last.at as DateTime),
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: p.textTertiary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${shop.name} · $preview',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
