import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      final impl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await impl?.requestNotificationsPermission();
      // Register the channel up front so it exists before the first show.
      await impl?.createNotificationChannel(const AndroidNotificationChannel(
        'fade_events',
        'Fade',
        description: 'Booking updates and requests',
        importance: Importance.high,
      ));
      _ready = true;
    } catch (e) {
      // Notifications are a nice-to-have — never block app startup.
      debugPrint('Notify.init failed: $e');
    }
  }

  /// One-time "notifications are on" ping after the first launch with
  /// permission — proves the pipe and teaches the user where updates land.
  static Future<void> welcomeOnce(String title, String body) async {
    if (!_ready) return;
    final sp = await SharedPreferences.getInstance();
    if (sp.getBool('notifHello') ?? false) return;
    await sp.setBool('notifHello', true);
    await show(title, body);
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
    } catch (e) {
      // Swallow — a failed toast must never crash a booking action.
      debugPrint('Notify.show failed: $e');
    }
  }
}
