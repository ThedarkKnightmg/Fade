import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/animations/app_animations.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/app_state.dart';
import '../../data/models/booking.dart';
import '../../data/models/chat_message.dart';
import 'chat_kit.dart';
import 'message_composer.dart';
import 'paper_kit.dart';
import 'sticker_picker.dart';

/// Telegram-style avatar colours, picked by name so a person keeps theirs.
const _avatarColors = [
  Color(0xFFE17076), // red
  Color(0xFFF2A65A), // orange
  Color(0xFFA695E7), // violet
  Color(0xFF7BC862), // green
  Color(0xFF6EC9CB), // cyan
  Color(0xFF65AADD), // blue
  Color(0xFFEE7AAE), // pink
];

Color avatarColorFor(String name) {
  var h = 0;
  for (final c in name.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return _avatarColors[h % _avatarColors.length];
}

/// A round initial avatar in the person's own colour, with an optional
/// "online" dot.
class ChatAvatar extends StatelessWidget {
  const ChatAvatar({super.key, required this.name, this.size = 48, this.online = false});

  final String name;
  final double size;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final c = avatarColorFor(name);
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color.lerp(c, Colors.white, 0.18)!, c],
              ),
            ),
            child: Text(
              initial,
              style: GoogleFonts.nunito(
                fontSize: size * 0.42,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          if (online)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: AppColors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: p.card, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "15:42" today, "Yesterday", a weekday within the week, else "12.10".
String chatTimeLabel(DateTime at) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(at.year, at.month, at.day);
  final days = today.difference(d).inDays;
  if (days == 0) return DateFormat('HH:mm').format(at);
  if (days == 1) return L.yesterdayWord;
  if (days < 7) return DateFormat('EEE').format(at);
  return DateFormat('dd.MM').format(at);
}

/// Messages from the other side since my last one: what's unread.
int unreadIn(List<ChatMessage> msgs) {
  var n = 0;
  for (var i = msgs.length - 1; i >= 0 && !msgs[i].mine; i--) {
    n++;
  }
  return n;
}

/// One conversation, both sides of the app: the client talking to a barber
/// and a barber talking to a client.
///
/// What it adds over the old screens (which were two copies of one layout):
/// replies (swipe a message, or long-press → Reply), Copy and Delete, real
/// ticks (one when sent, two once answered), "typing…" with animated dots,
/// the next visit pinned under the header, quick-reply chips fitted to the
/// role, and a jump-to-latest button.
class ConversationView extends StatefulWidget {
  const ConversationView({
    super.key,
    required this.name,
    required this.threadKey,
    required this.messages,
    required this.send,
    required this.delete,
    required this.quickReplies,
    required this.idleSubtitle,
    this.nextVisit,
  });

  final String name;

  /// The AppState thread key (barber id / client name), for "typing…".
  final String threadKey;
  final List<ChatMessage> Function() messages;
  final void Function(String text, {bool isSticker, ChatMessage? replyTo}) send;
  final void Function(String messageId) delete;
  final List<String> quickReplies;

  /// The header's second line when nobody is typing.
  final String idleSubtitle;

  /// The next booking between the two, pinned under the header.
  final Booking? Function()? nextVisit;

  @override
  State<ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends State<ConversationView> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  ChatMessage? _replyTo;
  bool _showJump = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() {}));
    _scroll.addListener(() {
      // The list is reversed: offset 0 is the newest message.
      final far = _scroll.hasClients && _scroll.offset > 280;
      if (far != _showJump) setState(() => _showJump = far);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send([String? quick]) {
    final t = (quick ?? _ctrl.text).trim();
    if (t.isEmpty) return;
    HapticFeedback.selectionClick();
    widget.send(t, replyTo: _replyTo);
    if (quick == null) _ctrl.clear();
    setState(() => _replyTo = null);
    _jumpToLatest();
  }

  Future<void> _sendSticker() async {
    final s = await pickSticker(context);
    if (s == null || !mounted) return;
    widget.send(s, isSticker: true, replyTo: _replyTo);
    setState(() => _replyTo = null);
    _jumpToLatest();
  }

  void _jumpToLatest() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(0,
        duration: const Duration(milliseconds: 300), curve: AppCurves.easeOutQuart);
  }

  void _reply(ChatMessage m) {
    HapticFeedback.selectionClick();
    setState(() => _replyTo = m);
  }

  String _authorOf(ChatMessage m) => m.mine ? L.chatYou : widget.name;

  Future<void> _actions(ChatMessage m) async {
    HapticFeedback.mediumImpact();
    final p = Paper.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(22),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionRow(icon: Icons.reply_rounded, label: L.chatReply, value: 'reply'),
              if (!m.isSticker)
                _ActionRow(icon: Icons.copy_rounded, label: L.chatCopy, value: 'copy'),
              if (m.mine)
                _ActionRow(
                  icon: Icons.delete_outline_rounded,
                  label: L.chatDelete,
                  value: 'delete',
                  danger: true,
                ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case 'reply':
        _reply(m);
      case 'copy':
        await Clipboard.setData(ClipboardData(text: m.text));
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(L.chatCopied),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ));
      case 'delete':
        widget.delete(m.id);
        if (_replyTo?.id == m.id) setState(() => _replyTo = null);
    }
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<Widget> _rows(List<ChatMessage> msgs, bool typing) {
    // The latest reply from the other side: everything of mine before it has
    // been seen.
    var lastTheirs = -1;
    for (var i = msgs.length - 1; i >= 0; i--) {
      if (!msgs[i].mine) {
        lastTheirs = i;
        break;
      }
    }
    final rows = <Widget>[];
    for (var i = 0; i < msgs.length; i++) {
      final m = msgs[i];
      final prev = i == 0 ? null : msgs[i - 1];
      final next = i == msgs.length - 1 ? null : msgs[i + 1];
      if (prev == null || !_sameDay(prev.at, m.at)) {
        rows.add(ChatDateSeparator(day: m.at));
      }
      final lastOfRun =
          next == null || next.mine != m.mine || !_sameDay(next.at, m.at);
      final bubble = m.isSticker
          ? StickerMessage(
              sticker: m.text,
              mine: m.mine,
              time: DateFormat('HH:mm').format(m.at),
            )
          : ChatBubble(
              text: m.text,
              mine: m.mine,
              at: m.at,
              showTail: lastOfRun,
              read: i < lastTheirs,
              quoteAuthor: m.replyTo == null ? null : _authorOf(m.replyTo!),
              quoteText: m.replyTo == null
                  ? null
                  : (m.replyTo!.isSticker ? '${m.replyTo!.text} Sticker' : m.replyTo!.text),
            );
      rows.add(_SwipeToReply(
        key: ValueKey(m.id),
        onReply: () => _reply(m),
        onLongPress: () => _actions(m),
        child: bubble,
      ));
    }
    if (typing) rows.add(const _TypingBubble());
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: AppState.instance,
          builder: (context, _) {
            final s = AppState.instance;
            final msgs = widget.messages();
            final typing = s.isTyping(widget.threadKey);
            final visit = widget.nextVisit?.call();
            final rows = _rows(msgs, typing);
            return Column(
              children: [
                // ── Header ──────────────────────────────────────────────
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
                      ChatAvatar(name: widget.name, size: 42, online: typing),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.h4(context)),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: typing
                                  ? Text(L.chatTyping,
                                      key: const ValueKey('typing'),
                                      style: AppTypography.caption(context)
                                          .copyWith(
                                              color: AppColors.accent,
                                              fontWeight: FontWeight.w800))
                                  : Text(widget.idleSubtitle,
                                      key: const ValueKey('idle'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.caption(context)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: p.border),
                if (visit != null) _PinnedVisit(booking: visit),
                // ── Messages ────────────────────────────────────────────
                Expanded(
                  child: ChatWallpaper(
                    child: Stack(
                      children: [
                        if (msgs.isEmpty && !typing)
                          Center(
                            child: Text(L.sayHiTo(widget.name),
                                style: AppTypography.bodySmall(context)),
                          )
                        else
                          ListView.builder(
                            controller: _scroll,
                            reverse: true, // newest at the bottom, always
                            padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                            itemCount: rows.length,
                            itemBuilder: (_, i) => rows[rows.length - 1 - i],
                          ),
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: AnimatedScale(
                            scale: _showJump ? 1 : 0,
                            duration: const Duration(milliseconds: 180),
                            curve: AppCurves.easeOutQuart,
                            child: _JumpButton(
                              unread: unreadIn(msgs),
                              onTap: _jumpToLatest,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // ── Quick replies (only while the field is empty) ────────
                if (_ctrl.text.isEmpty && _replyTo == null)
                  _QuickReplies(items: widget.quickReplies, onTap: _send),
                if (_replyTo != null)
                  _ReplyStrip(
                    author: _authorOf(_replyTo!),
                    text: _replyTo!.text,
                    onCancel: () => setState(() => _replyTo = null),
                  ),
                MessageComposer(
                  controller: _ctrl,
                  onSend: _send,
                  hintText: L.messageHint,
                  onSticker: _sendSticker,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.value,
    this.danger = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final c = danger ? AppColors.red : p.text;
    return InkWell(
      onTap: () => Navigator.of(context).pop(value),
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            Icon(icon, size: 22, color: danger ? AppColors.red : p.textSecondary),
            const SizedBox(width: 16),
            Text(label,
                style: GoogleFonts.nunito(
                    fontSize: 16, fontWeight: FontWeight.w800, color: c)),
          ],
        ),
      ),
    );
  }
}

/// Swipe a message left-to-right to reply (Telegram's gesture); the reply
/// arrow fades in as you pull, and the bubble springs back.
class _SwipeToReply extends StatefulWidget {
  const _SwipeToReply({
    super.key,
    required this.child,
    required this.onReply,
    required this.onLongPress,
  });
  final Widget child;
  final VoidCallback onReply;
  final VoidCallback onLongPress;

  @override
  State<_SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<_SwipeToReply> {
  double _dx = 0;
  bool _armed = false;
  static const _trigger = 56.0;

  @override
  Widget build(BuildContext context) {
    final t = (_dx / _trigger).clamp(0.0, 1.0);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: widget.onLongPress,
      onHorizontalDragUpdate: (d) {
        setState(() => _dx = math.max(0, math.min(_trigger * 1.3, _dx + d.delta.dx)));
        final armed = _dx >= _trigger;
        if (armed && !_armed) HapticFeedback.selectionClick();
        _armed = armed;
      },
      onHorizontalDragEnd: (_) {
        if (_armed) widget.onReply();
        setState(() {
          _dx = 0;
          _armed = false;
        });
      },
      onHorizontalDragCancel: () => setState(() {
        _dx = 0;
        _armed = false;
      }),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Positioned(
            left: 10,
            child: Opacity(
              opacity: t,
              child: Transform.scale(
                scale: 0.6 + 0.4 * t,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.reply_rounded, size: 18, color: Colors.white),
                ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: Duration(milliseconds: _dx == 0 ? 220 : 0),
            curve: AppCurves.easeOutQuart,
            transform: Matrix4.translationValues(_dx, 0, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

/// Three dots bobbing in an incoming bubble while the other side types.
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 8, bottom: 8, top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: p.isDark ? const Color(0xFF182533) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(5),
          ),
        ),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                  child: Transform.translate(
                    offset: Offset(
                        0, -3 * math.max(0, math.sin((_c.value - i * 0.18) * 2 * math.pi))),
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: p.textTertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The next visit, pinned under the header like a Telegram pinned message.
class _PinnedVisit extends StatelessWidget {
  const _PinnedVisit({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final b = booking;
    final now = DateTime.now();
    final d = DateTime(b.dateTime.year, b.dateTime.month, b.dateTime.day);
    final today = DateTime(now.year, now.month, now.day);
    final days = d.difference(today).inDays;
    final day = days == 0
        ? L.today
        : days == 1
            ? L.tomorrow
            : DateFormat('EEE d MMM').format(b.dateTime);
    final pending = b.status == BookingStatus.requested;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 9, 16, 9),
      decoration: BoxDecoration(
        color: p.card,
        border: Border(bottom: BorderSide(color: p.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(L.chatPinned,
                    style: GoogleFonts.nunito(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.accent)),
                Text(
                  '$day · ${DateFormat('HH:mm').format(b.dateTime)} · ${L.tr(b.service.name)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall(context).copyWith(color: p.text),
                ),
              ],
            ),
          ),
          Icon(
            pending ? Icons.hourglass_top_rounded : Icons.event_available_rounded,
            size: 20,
            color: pending ? const Color(0xFFD99A2E) : AppColors.green,
          ),
        ],
      ),
    );
  }
}

class _JumpButton extends StatelessWidget {
  const _JumpButton({required this.unread, required this.onTap});
  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: p.card,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 10),
              ],
            ),
            child: Icon(Icons.keyboard_arrow_down_rounded, size: 28, color: p.textSecondary),
          ),
          if (unread > 0)
            Positioned(
              top: -6,
              left: 0,
              right: 0,
              child: Center(child: _CountBadge(count: unread)),
            ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: GoogleFonts.nunito(
            fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
      ),
    );
  }
}

/// Chips with the messages this role sends most, one tap to send.
class _QuickReplies extends StatelessWidget {
  const _QuickReplies({required this.items, required this.onTap});
  final List<String> items;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Container(
      color: p.card,
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => onTap(items[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: p.tint,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
            ),
            child: Text(items[i],
                style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent)),
          ),
        ),
      ),
    );
  }
}

/// "Replying to …" above the composer, with a cancel.
class _ReplyStrip extends StatelessWidget {
  const _ReplyStrip({required this.author, required this.text, required this.onCancel});
  final String author;
  final String text;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 6),
      decoration: BoxDecoration(
        color: p.card,
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.reply_rounded, size: 22, color: AppColors.accent),
          const SizedBox(width: 10),
          Container(width: 2.5, height: 32, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(author,
                    style: GoogleFonts.nunito(
                        fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.accent)),
                Text(text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall(context)),
              ],
            ),
          ),
          IconButton(
            onPressed: onCancel,
            icon: Icon(Icons.close_rounded, color: p.textTertiary),
          ),
        ],
      ),
    );
  }
}

/// A conversation row for the chat lists: avatar, name, time, preview with
/// "You:" and ticks for my last message, and an unread count.
class ChatThreadTile extends StatelessWidget {
  const ChatThreadTile({
    super.key,
    required this.name,
    required this.last,
    required this.unread,
    required this.typing,
    required this.onTap,
    this.fallback,
    this.showDivider = true,
  });

  final String name;
  final ChatMessage? last;
  final int unread;
  final bool typing;
  final VoidCallback onTap;

  /// Shown when there are no messages yet (e.g. the next visit).
  final String? fallback;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final m = last;
    final preview = typing
        ? L.chatTyping
        : m == null
            ? (fallback ?? '')
            : (m.isSticker ? '${m.text} Sticker' : m.text);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ChatAvatar(name: name, size: 52, online: typing),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(bottom: 11),
                decoration: BoxDecoration(
                  border: showDivider
                      ? Border(bottom: BorderSide(color: p.border.withValues(alpha: 0.7)))
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.nunito(
                                  fontSize: 16, fontWeight: FontWeight.w900, color: p.text)),
                        ),
                        if (m != null && m.mine) ...[
                          // My message is the latest, so it hasn't been
                          // answered yet: one tick.
                          const Icon(Icons.done_rounded,
                              size: 16, color: AppColors.accent),
                          const SizedBox(width: 3),
                        ],
                        if (m != null)
                          Text(chatTimeLabel(m.at),
                              style: GoogleFonts.nunito(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: unread > 0 ? AppColors.accent : p.textTertiary,
                              )),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(children: [
                              if (m != null && m.mine && !typing)
                                TextSpan(
                                    text: '${L.chatYou}: ',
                                    style: TextStyle(color: p.text, fontWeight: FontWeight.w800)),
                              TextSpan(text: preview),
                            ]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: typing ? AppColors.accent : p.textSecondary,
                            ),
                          ),
                        ),
                        if (unread > 0) ...[
                          const SizedBox(width: 8),
                          _CountBadge(count: unread),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The search field at the top of a chat list.
class ChatSearchField extends StatelessWidget {
  const ChatSearchField({super.key, required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: p.cardAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search_rounded, size: 20, color: p.textTertiary),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: p.text),
              decoration: InputDecoration(
                isCollapsed: true,
                // The app theme gives fields a filled, outlined look; this
                // one lives inside its own pill, so switch all of that off.
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                hintText: L.chatSearch,
                hintStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: p.textTertiary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
