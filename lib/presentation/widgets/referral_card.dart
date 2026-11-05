import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/animations/motion.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/app_state.dart';
import 'paper_kit.dart';

/// "Invite friends, go VIP" referral — reciprocity + viral growth loop.
/// Lives on the Profile screen (account/growth), not cluttering Home.
class ReferralCard extends StatelessWidget {
  const ReferralCard({super.key, required this.onShare});

  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    // A white card like the rest of the page: one green gradient block
    // stacked on the blue "Become a barber" card made the profile loud.
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: clayDecoration(p, radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: p.tint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.card_giftcard_rounded,
                    color: AppColors.accent, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  L.wdInviteVip,
                  style: GoogleFonts.nunito(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    color: p.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            L.wdInviteVipSub,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: p.textSecondary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: p.cardAlt,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  // The server-minted code. It used to be built from the user
                  // object's hashCode, which changes on every launch.
                  child: FutureBuilder<String>(
                    future: AppState.instance.referralCode(),
                    builder: (context, snap) => Text(
                      snap.data ?? '······',
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: p.text,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              PressableScale(
                onTap: onShare,
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    L.share,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
