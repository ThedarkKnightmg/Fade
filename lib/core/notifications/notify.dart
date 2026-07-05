import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Real device notifications — booking confirmed/declined for the client,
/// new incoming request for the barber. Local (fired by the app itself);
/// they move to FCM pushes when the Supabase backend lands.
class Notify {
  Notify._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static int _id = 0;

  /// Call once at startup. Safe to call on any platform — no-ops where
  /// unsupported (web) and asks Android 13+ for the notification permission.
  static Future<void> init() async {
    if (kIsWeb) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _ready = true;
    } catch (_) {
      // Notifications are a nice-to-have — never block app startup.
    }
  }

  static Future<void> show(String title, String body) async {
    if (!_ready) return;
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'fade_events',
          'Fade',
          channelDescription: 'Booking updates and requests',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );
      await _plugin.show(_id++, title, body, details);
    } catch (_) {
      // Swallow — a failed toast must never crash a booking action.
    }
  }
}
