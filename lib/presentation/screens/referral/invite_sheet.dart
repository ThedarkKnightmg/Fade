import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../../data/supabase_loyalty.dart';
import '../../widgets/primary_button.dart';

/// "Invite friends & earn" — shows this user's real, server-minted referral
/// code, lets them share it, and lets a new user paste a friend's code. The
/// code and the "who referred me" record both come from the server RPCs; the
/// 5,000-point payout happens server-side on the friend's first completed cut.
void showInviteSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _InviteSheet(),
  );
}

class _InviteSheet extends StatefulWidget {
  const _InviteSheet();

  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet> {
  final _codeCtrl = TextEditingController();
  String? _code;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    AppState.instance.referralCode().then((c) {
      if (mounted) setState(() => _code = c);
    });
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  void _copy() {
    if (_code == null) return;
    Clipboard.setData(ClipboardData(text: L.inviteShareMessage(_code!)));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(L.inviteCopied)));
  }

  Future<void> _share() async {
    if (_code == null) return;
    final text = Uri.encodeComponent(L.inviteShareMessage(_code!));
    final uri = Uri.parse('https://t.me/share/url?url=&text=$text');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _copy();
    }
  }

  Future<void> _apply() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() => _applying = true);
    final ok = await SupabaseLoyalty.setReferrer(code);
    if (!mounted) return;
    setState(() => _applying = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? L.inviteApplied : L.inviteFailed)),
    );
    if (ok) _codeCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Container(
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                  color: p.border, borderRadius: BorderRadius.circular(99)),
            ),
          ),
          const SizedBox(height: 18),
          Text(L.inviteTitle, style: AppTypography.h2(context)),
          const SizedBox(height: 6),
          Text(L.inviteSub, style: AppTypography.bodySmall(context)),
          const SizedBox(height: 20),
          // The code card, on the brand gradient.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF2D7E), Color(0xFF7A3CF0), Color(0xFF2E8BFF)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(L.inviteYourCode.toUpperCase(),
                    style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Colors.white.withValues(alpha: 0.9))),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _code ?? '····',
                        style: GoogleFonts.nunito(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: Colors.white),
                      ),
                    ),
                    _MiniAction(icon: Icons.copy_rounded, onTap: _copy),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: L.inviteShare,
            icon: Icons.send_rounded,
            onPressed: _code == null ? null : _share,
          ),
          const SizedBox(height: 22),
          Text(L.inviteHaveCode,
              style: GoogleFonts.nunito(
                  fontSize: 14, fontWeight: FontWeight.w800, color: p.text)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  style: GoogleFonts.nunito(
                      fontSize: 15, fontWeight: FontWeight.w800, color: p.text),
                  decoration: InputDecoration(
                    hintText: 'FADE·····',
                    filled: true,
                    fillColor: p.cardAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 110,
                child: PrimaryButton(
                  label: L.inviteApply,
                  onPressed: _applying ? null : _apply,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
