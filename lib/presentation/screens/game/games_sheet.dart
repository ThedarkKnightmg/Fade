import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/animations/motion.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../widgets/fade_points_pill.dart';
import '../../widgets/paper_kit.dart';
import 'clean_line_game.dart';
import 'scissor_master_game.dart';

/// "Your chair is booked — now play while you wait."
///
/// The games existed but were reachable only through a ghost button stacked
/// under another ghost button, so nobody found them. This card gives them a
/// visible offer of their own at the two moments that matter — right after a
/// booking is made, and while sitting in the shop waiting to be called — with
/// a breathing PLAY chip that invites the tap without shouting over the
/// booking details themselves.
class GameInviteCard extends StatelessWidget {
  const GameInviteCard({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return PressableScale(
      onTap: () => showGamesSheet(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accent.withValues(alpha: 0.20),
              AppColors.accent.withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.45)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.sports_esports_rounded,
                  size: 24, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    L.gamesTitle,
                    style: GoogleFonts.nunito(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: p.text,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(L.gameKillTime,
                      style: AppTypography.bodySmall(context)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Breathe(
              period: const Duration(milliseconds: 1800),
              builder: (context, t) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: [
                    BoxShadow(
                      color:
                          AppColors.accent.withValues(alpha: 0.30 + 0.35 * t),
                      blurRadius: 8 + 10 * t,
                      spreadRadius: 1 * t,
                    ),
                  ],
                ),
                child: Text(
                  L.gamePlay,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Picks between the waiting-chair games.
///
/// A sheet rather than more menu rows: the two games are one idea ("something
/// to do while you wait"), and the list will grow. It also gives the pair a
/// place to state what they have in common — the Fade Points you can earn from
/// either, out of one shared daily allowance.
void showGamesSheet(BuildContext context) {
  final p = Paper.of(context);
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: p.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(L.gamesTitle, style: AppTypography.h2(ctx)),
                  ),
                  FadePointsPill(
                    som: AppState.instance.pointsBalanceSom,
                    scale: 0.82,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _GameRow(
                icon: Icons.content_cut_rounded,
                title: L.gameTitle,
                sub: L.gameKillTime,
                best: AppState.instance.fadeGameBest,
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    FadeThroughPageRoute(child: const ScissorMasterGame()),
                  );
                },
              ),
              const SizedBox(height: 10),
              _GameRow(
                icon: Icons.gesture_rounded,
                title: L.lineGameTitle,
                sub: L.lineGameTagline,
                best: AppState.instance.lineGameBest,
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    FadeThroughPageRoute(child: const CleanLineGame()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _GameRow extends StatelessWidget {
  const _GameRow({
    required this.icon,
    required this.title,
    required this.sub,
    required this.best,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String sub;
  final int best;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.border),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 22, color: AppColors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.h4(context)),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall(context)
                        .copyWith(color: p.textSecondary),
                  ),
                ],
              ),
            ),
            // Only show a best once there is one — a row of zeroes on first
            // open makes the games look already-played and already-lost.
            if (best > 0) MiniPill('${L.gameBest} $best'),
          ],
        ),
      ),
    );
  }
}
