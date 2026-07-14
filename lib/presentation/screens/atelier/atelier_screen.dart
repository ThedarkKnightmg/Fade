import 'package:flutter/material.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../../data/mock_data.dart';
import '../../../data/models/barber.dart';
import '../../../data/models/barbershop.dart';
import '../../widgets/barber_card.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/paper_kit.dart';
import 'barber_profile_sheet.dart';

class _BarberInShop {
  const _BarberInShop({required this.barber, required this.shop});

  final Barber barber;
  final Barbershop shop;
}

/// The barbers directory — pick the hands you trust.
class AtelierScreen extends StatefulWidget {
  const AtelierScreen({super.key});

  @override
  State<AtelierScreen> createState() => _AtelierScreenState();
}

class _AtelierScreenState extends State<AtelierScreen> {
  String _filter = 'All';

  static const _filters = ['All', 'Fades', 'Classic', 'Modern', 'Kids'];

  List<_BarberInShop> get _pairs {
    // Two barbers per shop, rotated so the directory feels varied.
    final pairs = <_BarberInShop>[];
    final shops = MockData.barbershops;
    for (var i = 0; i < shops.length; i++) {
      pairs.add(_BarberInShop(
        barber: shops[i].barbers[i % 4],
        shop: shops[i],
      ));
      pairs.add(_BarberInShop(
        barber: shops[i].barbers[(i + 2) % 4],
        shop: shops[i],
      ));
    }
    if (_filter == 'All') return pairs;
    return pairs
        .where((x) => x.barber.specialty
            .toLowerCase()
            .contains(_filter.toLowerCase().substring(0, 4)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: AnimatedBuilder(
        animation: AppState.instance,
        builder: (context, _) {
          final pairs = _pairs;
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
              children: [
                Row(
                  children: [
                    CircleBtn(
                      icon: Icons.arrow_back_rounded,
                      size: 42,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    const BarberLogo(size: 28),
                  ],
                ),
                const SizedBox(height: 20),
                FadeSlideIn(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: L.stTheWord,
                          style: AppTypography.display(context),
                        ),
                        markerBoxSpan(
                            L.stBarbersWord, AppTypography.display(context)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 50),
                  child: Text(
                    L.stPickAMaster,
                    style: AppTypography.scribble(context, size: 21)
                        .copyWith(color: p.textSecondary),
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 100),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    child: Row(
                      children: [
                        for (final f in _filters) ...[
                          CountChip(
                            label: f,
                            selected: _filter == f,
                            onTap: () => setState(() => _filter = f),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (pairs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 48),
                    child: Center(
                      child: ScribbleNote(L.stNoOneCutsThat),
                    ),
                  )
                else
                  for (var i = 0; i < pairs.length; i++) ...[
                    FadeSlideIn(
                      delay: Duration(milliseconds: 140 + i * 50),
                      child: BarberCard(
                        barber: pairs[i].barber,
                        index: i,
                        subtitle:
                            '${L.tr(pairs[i].barber.specialty)} · ${pairs[i].shop.name}',
                        isMyBarber:
                            AppState.instance.isMyBarber(pairs[i].barber.id),
                        onTap: () => showBarberProfileSheet(
                          context,
                          barber: pairs[i].barber,
                          shop: pairs[i].shop,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}
