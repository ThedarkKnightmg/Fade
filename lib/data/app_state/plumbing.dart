part of '../app_state.dart';

/// The small contract every domain mixin needs from [AppState].
///
/// Domain mixins declare `on AppStatePlumbing` rather than `on AppState`,
/// which would be circular (AppState is the class that mixes them in). The
/// members are abstract here and implemented once by [AppState]; because all
/// of this is one library, they can stay private.
mixin AppStatePlumbing on ChangeNotifier {
  /// Write the whole state blob to shared_preferences. Domains call this after
  /// a mutation they want to survive a relaunch.
  Future<void> _save();
}
