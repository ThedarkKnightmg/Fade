import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

/// The chat message composer — a Flutter recreation of the "AI Input" send
/// interaction (Skiper UI skiper82): the send button stays quiet while the
/// field is empty, springs to a gradient when there's something to send, and
/// on send the arrow "launches" — the old glyph flies up and out while a fresh
/// one slides in behind it, with a light band sweeping across. A haptic tick
/// stands in for the original's send sound.
///
/// Shared by both sides of the marketplace (client chat + barber chat), so the
/// send feel is identical everywhere.
class MessageComposer extends StatefulWidget {
  const MessageComposer({
    super.key,
    required this.controller,
    required this.onSend,
    this.hintText,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final String? hintText;

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _launch = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncHasText);
    _syncHasText();
  }

  void _syncHasText() {
    final has = widget.controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  void _send() {
    if (!_hasText) return;
    HapticFeedback.lightImpact();
    widget.onSend(); // sends + clears the field (parent owns that)
    _launch
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncHasText);
    _launch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, 8 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: p.card,
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
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
                controller: widget.controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w600, color: p.text),
                decoration: InputDecoration(
                  isCollapsed: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: InputBorder.none,
                  hintText: widget.hintText,
                  hintStyle: GoogleFonts.nunito(
                      fontWeight: FontWeight.w600, color: p.textSecondary),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _SendButton(
            active: _hasText,
            launch: _launch,
            onTap: _send,
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.active,
    required this.launch,
    required this.onTap,
  });

  final bool active;
  final Animation<double> launch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        // Springs up the instant there's something worth sending.
        scale: active ? 1 : 0.86,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Quiet grey when empty; a live blue gradient when ready.
            gradient: active
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF57A5FF), AppColors.accentDeep],
                  )
                : null,
            color: active ? null : p.border,
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.35),
                      blurRadius: 14,
                      spreadRadius: -3,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: ClipOval(
            child: AnimatedBuilder(
              animation: launch,
              builder: (context, _) => _LaunchGlyph(
                t: launch.value,
                color: active ? Colors.white : p.textTertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The send-arrow launch: the outgoing glyph flies up-and-out and fades, a
/// fresh one rises in behind it, and a soft light band sweeps across — all
/// driven by one 0→1 value so it's cheap and always resolves back to rest.
class _LaunchGlyph extends StatelessWidget {
  const _LaunchGlyph({required this.t, required this.color});

  final double t; // 0 at rest, 1 at end of a send
  final Color color;

  @override
  Widget build(BuildContext context) {
    const icon = Icons.send_rounded;
    // Outgoing arrow: present in the first half, flying up-right + fading.
    final outEase = Curves.easeIn.transform((t.clamp(0.0, 0.5)) / 0.5);
    // Incoming arrow: arrives in the second half, rising from lower-left.
    final inRaw = ((t - 0.5).clamp(0.0, 0.5)) / 0.5;
    final inEase = Curves.easeOutCubic.transform(inRaw);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Light band sweeping across on send.
        if (t > 0 && t < 1)
          Transform.translate(
            offset: Offset(-24 + 48 * t, 0),
            child: Container(
              width: 14,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0),
                    Colors.white.withValues(alpha: 0.35),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        // Outgoing / resting arrow.
        Opacity(
          opacity: t == 0 ? 1 : (1 - outEase),
          child: Transform.translate(
            offset: Offset(16 * outEase, -16 * outEase),
            child: Icon(icon, color: color, size: 22),
          ),
        ),
        // Incoming arrow (only during a send).
        if (t > 0.5)
          Opacity(
            opacity: inEase,
            child: Transform.translate(
              offset: Offset(-10 * (1 - inEase), 10 * (1 - inEase)),
              child: Icon(icon, color: color, size: 22),
            ),
          ),
      ],
    );
  }
}
