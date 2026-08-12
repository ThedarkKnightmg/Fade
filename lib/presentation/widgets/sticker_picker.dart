import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/animations/motion.dart';
import '../../core/i18n/strings.dart';
import '../../core/theme/app_colors.dart';

/// Fade's sticker packs. Barbershop-themed first (the ones people will actually
/// use in a booking chat: "on my way", "fresh cut", "thumbs up"), then the
/// general reactions.
///
/// These are rendered as large glyphs rather than shipped as image assets: no
/// megabytes added to the APK, they stay crisp at any size, and they render
/// identically in every language. The message model marks them
/// [ChatMessage.isSticker] so the thread draws them big and bubble-less, the
/// way Telegram does.
class StickerPack {
  const StickerPack({required this.title, required this.stickers});

  final String title;
  final List<String> stickers;
}

List<StickerPack> stickerPacks() => [
      StickerPack(
        title: L.stickersBarber,
        stickers: const [
          '✂️', '💈', '🪒', '💇‍♂️', '💇', '🧴',
          '🪞', '🧑‍🦱', '🧔', '👨‍🦰', '💺', '🕐',
        ],
      ),
      StickerPack(
        title: L.stickersReactions,
        stickers: const [
          '👍', '🔥', '😍', '😂', '🙌', '💯',
          '👌', '🤝', '🙏', '😎', '🥳', '❤️',
          '😅', '🤔', '👀', '✅', '🚗', '🏃',
        ],
      ),
    ];

/// The sticker sheet — tap a sticker to send it.
class StickerPickerSheet extends StatelessWidget {
  const StickerPickerSheet({super.key, required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final packs = stickerPacks();
    return Container(
      height: MediaQuery.of(context).size.height * 0.45,
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 5,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: p.border,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                  14, 0, 14, 14 + MediaQuery.of(context).padding.bottom),
              children: [
                for (final pack in packs) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
                    child: Text(
                      pack.title.toUpperCase(),
                      style: GoogleFonts.nunito(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: p.textTertiary,
                      ),
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                    ),
                    itemCount: pack.stickers.length,
                    itemBuilder: (context, i) {
                      final s = pack.stickers[i];
                      return PressableScale(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onPick(s);
                        },
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: p.cardAlt,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(s, style: const TextStyle(fontSize: 30)),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens the sticker sheet and returns the chosen sticker (null if dismissed).
Future<String?> pickSticker(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => StickerPickerSheet(
      onPick: (s) => Navigator.of(ctx).pop(s),
    ),
  );
}

/// A sent sticker in the thread: large, no bubble, with the time tucked under
/// it — exactly how Telegram renders stickers.
class StickerMessage extends StatelessWidget {
  const StickerMessage({
    super.key,
    required this.sticker,
    required this.mine,
    required this.time,
  });

  final String sticker;
  final bool mine;
  final String time;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: 8,
        left: mine ? 60 : 8,
        right: mine ? 8 : 60,
      ),
      child: Column(
        crossAxisAlignment:
            mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(sticker, style: const TextStyle(fontSize: 68)),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                time,
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: p.textTertiary,
                ),
              ),
              if (mine) ...[
                const SizedBox(width: 3),
                Icon(Icons.done_all_rounded,
                    size: 15, color: AppColors.accent),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
