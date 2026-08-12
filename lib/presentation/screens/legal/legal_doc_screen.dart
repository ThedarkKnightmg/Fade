import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/i18n/app_language.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../widgets/paper_kit.dart';

/// Renders a legal document (Terms of Use or Privacy Policy) natively, in the
/// app's current language, from the bundled trilingual `assets/legal/legal.json`.
///
/// Keeping the text in a bundled asset (not remote HTML) means it works offline,
/// matches the app theme and light/dark mode, and never shows a blank WebView.
/// The same JSON is the single source the RU/UZ translations were produced from,
/// so the three languages can't drift apart in code.
class LegalDocScreen extends StatelessWidget {
  const LegalDocScreen({super.key, required this.docKey});

  /// `terms` or `privacy` — the top-level key in legal.json.
  final String docKey;

  static Map<String, dynamic>? _cache;

  Future<Map<String, dynamic>> _load() async {
    _cache ??=
        jsonDecode(await rootBundle.loadString('assets/legal/legal.json'))
            as Map<String, dynamic>;
    return _cache![docKey] as Map<String, dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _load(),
          builder: (context, snap) {
            final doc = snap.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Row(
                    children: [
                      CircleBtn(
                        icon: Icons.arrow_back_rounded,
                        size: 42,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          doc == null ? '' : _pick(doc['title']),
                          style: AppTypography.h1(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: doc == null
                      ? const Center(child: CircularProgressIndicator())
                      : _Body(doc: doc),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.doc});

  final Map<String, dynamic> doc;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final sections = (doc['sections'] as List).cast<Map<String, dynamic>>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 40),
      children: [
        Text(
          '${L.lastUpdated}: ${doc['updated']}',
          style: AppTypography.caption(context),
        ),
        const SizedBox(height: 14),
        _Para(_pick(doc['intro']), color: p.textSecondary),
        const SizedBox(height: 6),
        for (final (i, s) in sections.indexed) ...[
          FadeSlideIn(
            delay: Duration(milliseconds: 30 * (i.clamp(0, 8))),
            child: Padding(
              padding: const EdgeInsets.only(top: 22, bottom: 6),
              child: Text(_pick(s['title']),
                  style: GoogleFonts.nunito(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: p.text,
                    height: 1.25,
                  )),
            ),
          ),
          for (final b in (s['blocks'] as List).cast<Map<String, dynamic>>())
            if (b['type'] == 'ul')
              for (final item in (b['items'] as List).cast<Map<String, dynamic>>())
                _Bullet(_pick(item))
            else
              _Para(_pick(b['text']), color: p.textSecondary),
        ],
      ],
    );
  }
}

/// A paragraph with inline **bold** emphasis parsed out.
class _Para extends StatelessWidget {
  const _Para(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text.rich(
        TextSpan(children: _boldSpans(text, context, color)),
        style: GoogleFonts.nunito(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          height: 1.5,
          color: color,
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 9, left: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7, right: 10),
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                  color: AppColors.accent, shape: BoxShape.circle),
            ),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(children: _boldSpans(text, context, p.textSecondary)),
              style: GoogleFonts.nunito(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                height: 1.5,
                color: p.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Split a string on `**bold**` markers into weighted spans. Bold text uses the
/// primary ink colour to make the legally load-bearing phrases stand out.
List<InlineSpan> _boldSpans(String text, BuildContext context, Color base) {
  final p = Paper.of(context);
  final spans = <InlineSpan>[];
  final parts = text.split('**');
  for (var i = 0; i < parts.length; i++) {
    if (parts[i].isEmpty) continue;
    final bold = i.isOdd; // text between the markers
    spans.add(TextSpan(
      text: parts[i],
      style: bold
          ? TextStyle(fontWeight: FontWeight.w900, color: p.text)
          : null,
    ));
  }
  return spans;
}

/// Pick the string for the app's current language, falling back to English.
String _pick(dynamic tri) {
  final m = (tri as Map).cast<String, dynamic>();
  final en = (m['en'] as String?) ?? '';
  switch (AppState.instance.language) {
    case AppLanguage.ru:
      return (m['ru'] as String?)?.isNotEmpty == true ? m['ru'] as String : en;
    case AppLanguage.uz:
      return (m['uz'] as String?)?.isNotEmpty == true ? m['uz'] as String : en;
    case AppLanguage.en:
      return en;
  }
}
