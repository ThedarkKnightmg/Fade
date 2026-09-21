import 'package:flutter/material.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../data/app_state.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

/// One step between "signed in" and "using the app": confirm the name.
///
/// Google and Telegram hand back whatever the person set on that account —
/// often a nickname, initials, a single word, or nothing at all — and the app
/// used to adopt it silently. That name is not decoration: it is what the
/// barber reads off the booking when deciding who is sitting in their chair,
/// and what they call out in the shop. Pre-filling it and letting the person
/// correct it costs one tap when it's already right, and saves the barber from
/// a booking made by "az_9931".
class ConfirmNameScreen extends StatefulWidget {
  const ConfirmNameScreen({super.key, required this.onDone});

  /// Where to go once the name is settled — kept as a callback so this screen
  /// doesn't need to know whether it's on the client or barber path.
  final VoidCallback onDone;

  @override
  State<ConfirmNameScreen> createState() => _ConfirmNameScreenState();
}

class _ConfirmNameScreenState extends State<ConfirmNameScreen> {
  late final TextEditingController _name =
      TextEditingController(text: AppState.instance.user.fullName.trim());
  String? _error;
  bool _submitted = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool _validate() {
    final e = Validators.fullName(_name.text);
    setState(() => _error = e);
    return e == null;
  }

  void _continue() {
    setState(() => _submitted = true);
    if (!_validate()) return;
    AppState.instance.setUserName(_name.text);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              FadeSlideIn(
                child: Text(L.whatsYourName, style: AppTypography.h1(context)),
              ),
              const SizedBox(height: 10),
              FadeSlideIn(
                delay: const Duration(milliseconds: 80),
                child: Text(
                  L.soBarberKnows,
                  style: AppTypography.body(context)
                      .copyWith(color: p.textSecondary),
                ),
              ),
              const SizedBox(height: 28),
              FadeSlideIn(
                delay: const Duration(milliseconds: 140),
                child: AppTextField(
                  label: L.authFullName,
                  hint: 'Alex Johnson',
                  controller: _name,
                  prefixIcon: Icons.badge_outlined,
                  maxLength: 60,
                  textInputAction: TextInputAction.done,
                  errorText: _error,
                  onSubmitted: (_) => _continue(),
                  onChanged: (_) {
                    if (_submitted) _validate();
                  },
                ),
              ),
              const Spacer(),
              FadeSlideIn(
                delay: const Duration(milliseconds: 200),
                child: PrimaryButton(
                  label: L.continueWord,
                  onPressed: _continue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
