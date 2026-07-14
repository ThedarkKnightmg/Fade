import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/format/money.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../../data/models/booking.dart';
import '../../widgets/paper_kit.dart';

/// The barber's completed-cut history: a summary + a time-filtered list.
class BarberHistoryScreen extends StatefulWidget {
  const BarberHistoryScreen({super.key});

  @override
  State<BarberHistoryScreen> createState() => _BarberHistoryScreenState();
}

class _BarberHistoryScreenState extends State<BarberHistoryScreen> {
  int _tab = 0; // 0 = all time, 1 = this month, 2 = this week

  DateTime? _since() {
    final n = DateTime.now();
    switch (_tab) {
      case 1:
        return DateTime(n.year, n.month, 1);
      case 2:
        return DateTime(n.year, n.month, n.day)
            .subtract(Duration(days: n.weekday - 1));
      default:
        return null;
    }
  }

  /// Deterministic per-cut rating (4.0–5.0) so totals stay stable.
  double _rating(Booking b) => 4.0 + (b.id.hashCode.abs() % 11) / 10.0;

  /// The client book: one entry per person, most loyal first.
  List<_ClientAgg> _clientsOf(List<Booking> list) {
    final map = <String, _ClientAgg>{};
    for (final b in list) {
      final name = b.clientName ?? L.youWord;
      final c = map.putIfAbsent(name, () => _ClientAgg(name));
      c.visits++;
      c.totalSom += Money.toSom(b.service.price);
      if (c.last == null || b.dateTime.isAfter(c.last!)) {
        c.last = b.dateTime;
        c.lastService = L.tr(b.service.name);
      }
    }
    final out = map.values.toList()
      ..sort((a, b) {
        final byVisits = b.visits.compareTo(a.visits);
        if (byVisits != 0) return byVisits;
        return (b.last ?? DateTime(0)).compareTo(a.last ?? DateTime(0));
      });
    return out;
  }

  String _whenLabel(DateTime dt) {
    final now = DateTime.now();
    final d = DateTime(dt.year, dt.month, dt.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(d).inDays;
    final time = DateFormat('HH:mm').format(dt);
    if (diff == 0) return '${L.today}, $time';
    if (diff == 1) return '${L.yesterdayWord}, $time';
    return '${DateFormat('d MMM').format(dt)}, $time';
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: AnimatedBuilder(
        animation: AppState.instance,
        builder: (context, _) {
          final list = AppState.instance.completedHistory(since: _since());
          final count = list.length;
          final earnedSom =
              list.fold(0, (s, b) => s + Money.toSom(b.service.price));
          final avg = list.isEmpty
              ? 0.0
              : list.map(_rating).reduce((a, b) => a + b) / list.length;

          return SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 20, 0),
                  child: Row(
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
                            Text(L.cutHistory,
                                style: AppTypography.h2(context)),
                            Text(L.everythingCompleted,
                                style: AppTypography.bodySmall(context)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // ── Your shareable booking code, right at the top so it's the
                //    first thing you can hand a client. ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: FadeSlideIn(child: const _InviteCard()),
                ),
                const SizedBox(height: 16),
                // Tabs.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _Tabs(
                    index: _tab,
                    labels: [L.tabAllTime, L.tabThisMonth, L.tabThisWeekCap],
                    onChanged: (i) => setState(() => _tab = i),
                  ),
                ),
                const SizedBox(height: 16),
                // Summary.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SummaryCard(
                    count: count,
                    earnedSom: earnedSom,
                    avg: avg,
                  ),
                ),
                const SizedBox(height: 16),
                // The client book + the visit log, one scroll.
                Expanded(
                  child: list.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.history_rounded,
                                  size: 40, color: p.textTertiary),
                              const SizedBox(height: 10),
                              Text(L.noCompletedYet,
                                  style: AppTypography.bodySmall(context)),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                          children: [
                            // ── Every person who has sat in this chair. ──
                            _SectionHead(
                                title: L.clientsWord,
                                count: _clientsOf(list).length),
                            for (final (i, c)
                                in _clientsOf(list).indexed) ...[
                              FadeSlideIn(
                                delay: Duration(milliseconds: 30 * i),
                                child: _ClientRow(client: c),
                              ),
                              const SizedBox(height: 10),
                            ],
                            const SizedBox(height: 12),
                            // ── The chronological visit log. ──
                            _SectionHead(
                                title: L.allVisitsWord, count: list.length),
                            for (final (i, b) in list.indexed) ...[
                              FadeSlideIn(
                                delay: Duration(milliseconds: 25 * i),
                                child: _HistoryRow(
                                  booking: b,
                                  when: _whenLabel(b.dateTime),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The barber's own booking code — a scannable QR + link with Share/Copy, so a
/// client can book them in a tap. The QR encodes the public booking URL; the
/// client app's scanner resolves it back to this barber's shop.
class _InviteCard extends StatelessWidget {
  const _InviteCard();

  Future<void> _share(BuildContext context) async {
    final url = AppState.instance.barberBookingUrl;
    final msg = L.shareInviteMsg(url);
    // Telegram is the dominant channel here — open its share picker. If it
    // isn't installed / can't open, fall back to copying the link.
    final tg = Uri.parse('https://t.me/share/url'
        '?url=${Uri.encodeComponent(url)}&text=${Uri.encodeComponent(msg)}');
    var ok = false;
    try {
      ok = await launchUrl(tg, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok && context.mounted) _copy(context);
  }

  void _copy(BuildContext context) {
    final url = AppState.instance.barberBookingUrl;
    Clipboard.setData(ClipboardData(text: url));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(L.linkCopiedToast),
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final s = AppState.instance;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: clayDecoration(p, radius: 20),
      child: Row(
        children: [
          // Scannable QR of the booking URL.
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.border),
            ),
            child: QrImageView(
              data: s.barberBookingUrl,
              version: QrVersions.auto,
              size: 76,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.circle,
                color: AppColors.accentDeep,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.circle,
                color: AppColors.accentDeep,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(L.inviteClientsTitle, style: AppTypography.h4(context)),
                const SizedBox(height: 2),
                Text(L.showThisToClients,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall(context)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _MiniBtn(
                        icon: Icons.ios_share_rounded,
                        label: L.shareVerb,
                        filled: true,
                        onTap: () => _share(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _MiniBtn(
                      icon: Icons.copy_rounded,
                      label: L.copyVerb,
                      filled: false,
                      onTap: () => _copy(context),
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

/// A compact pill button used in the invite card (filled = primary accent).
class _MiniBtn extends StatelessWidget {
  const _MiniBtn({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: filled ? null : Border.all(color: p.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 15, color: filled ? Colors.white : p.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.nunito(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: filled ? Colors.white : p.textSecondary,
                )),
          ],
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs(
      {required this.index, required this.labels, required this.onChanged});
  final int index;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: p.cardAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: AppCurves.easeOutQuart,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: index == i ? p.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: index == i
                        ? [
                            BoxShadow(
                                color: p.shadow,
                                blurRadius: 8,
                                offset: const Offset(0, 3))
                          ]
                        : null,
                  ),
                  child: Text(
                    labels[i],
                    style: GoogleFonts.nunito(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: index == i ? AppColors.accent : p.textSecondary),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(
      {required this.count, required this.earnedSom, required this.avg});
  final int count;
  final int earnedSom;
  final double avg;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(color: p.shadow, blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _Metric(
              value: Text('$count', style: AppTypography.h1(context)),
              label: L.completedCap,
            ),
          ),
          Container(width: 1, height: 44, color: p.divider),
          Expanded(
            flex: 2,
            child: _Metric(
              value: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(Money.group(earnedSom),
                    maxLines: 1,
                    style: GoogleFonts.nunito(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: p.text)),
              ),
              sub: "so'm",
              label: L.earnedCap,
            ),
          ),
          Container(width: 1, height: 44, color: p.divider),
          Expanded(
            child: _Metric(
              value: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded,
                      size: 18, color: AppColors.gold),
                  const SizedBox(width: 3),
                  Text(avg.toStringAsFixed(2),
                      style: AppTypography.h2(context)),
                ],
              ),
              label: L.avgRatingCap,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label, this.sub});
  final Widget value;
  final String label;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Column(
      children: [
        value,
        if (sub != null)
          Text(sub!,
              style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: p.textTertiary)),
        const SizedBox(height: 3),
        Text(label,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: p.textTertiary)),
      ],
    );
  }
}

/// One person in the client book: visits, total spent, last visit.
class _ClientAgg {
  _ClientAgg(this.name);
  final String name;
  int visits = 0;
  int totalSom = 0;
  DateTime? last;
  String lastService = '';
}

/// Section header inside the scroll: title + count chip.
class _SectionHead extends StatelessWidget {
  const _SectionHead({required this.title, required this.count});
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Row(
        children: [
          Text(title, style: AppTypography.h3(context)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text('$count',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.accent,
                )),
          ),
        ],
      ),
    );
  }
}

/// One client — name-first: avatar, name (+ Regular pill from 2 visits),
/// visits · last date, and their lifetime total on the right.
class _ClientRow extends StatelessWidget {
  const _ClientRow({required this.client});
  final _ClientAgg client;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final c = client;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          InitialAvatar(name: c.name, size: 46, index: c.name.length),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.h4(context)),
                    ),
                    if (c.visits >= 2) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(L.regularWord,
                            style: GoogleFonts.nunito(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF8A6100),
                            )),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${L.visitsCount(c.visits)} · '
                  '${c.last == null ? '' : L.lastVisitShort(DateFormat('d MMM').format(c.last!))}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall(context),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Money.group(c.totalSom),
                  style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.green)),
              Text("SO'M",
                  style: GoogleFonts.nunito(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: p.textTertiary)),
            ],
          ),
        ],
      ),
    );
  }
}

/// One visit — person-first: the client's name leads, the service and time
/// sit under it, the price on the right (✓ when QR-verified).
class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.booking, required this.when});
  final Booking booking;
  final String when;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final b = booking;
    final som = Money.toSom(b.service.price);
    final name = b.clientName ?? L.youWord;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          InitialAvatar(name: name, size: 46, index: name.length),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.h4(context)),
                    ),
                    if (b.isVerified) ...[
                      const SizedBox(width: 5),
                      const Icon(Icons.verified_rounded,
                          size: 14, color: AppColors.green),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text('${L.tr(b.service.name)} · $when',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall(context)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('+${Money.group(som)}',
                  style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.green)),
              Text("SO'M",
                  style: GoogleFonts.nunito(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: p.textTertiary)),
            ],
          ),
        ],
      ),
    );
  }
}
