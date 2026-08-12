part of '../app_state.dart';

/// Explicit, recorded agreement to the Terms + Privacy Policy — a ticked box
/// and a timestamp, not just "by continuing you agree". Stored with the
/// document version so that if the documents materially change we can ask
/// again (bump [AppState.legalVersion]) instead of silently relying on stale
/// consent.
///
/// Lives in a `part` file rather than its own library on purpose: [AppState]
/// is one [ChangeNotifier] whose domains share private state (`_save`,
/// `_readEpoch`, the reset path). Parts share the library's privacy scope, so
/// the code can be split by domain without widening any API or touching the
/// 260-odd `AppState.instance` call sites.
mixin LegalConsentState on ChangeNotifier, AppStatePlumbing {
  DateTime? _consentAt;
  String? _consentVersion;

  /// When the user accepted the current legal documents (null = never).
  DateTime? get consentAcceptedAt => _consentAt;

  /// True until the user has explicitly accepted the CURRENT document version.
  bool get needsLegalConsent =>
      _consentAt == null || _consentVersion != AppState.legalVersion;

  /// Record the tick. Persisted immediately so it survives a relaunch.
  void acceptLegal() {
    _consentAt = DateTime.now();
    _consentVersion = AppState.legalVersion;
    _save();
    notifyListeners();
  }
}
