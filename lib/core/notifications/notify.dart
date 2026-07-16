import 'dart:ui' show Color;

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
  /// unsupported (web).
  ///
  /// Deliberately does NOT ask for the permission: this runs before runApp, so
  /// the prompt used to be the very first thing a new user saw — no app, no
  /// context, nothing earned yet. A cold "Allow notifications?" is the easiest
  /// Deny in the world, and Android only ever asks once. [ensurePermission]
  /// asks later, at a moment where the answer is obviously yes.
  static Future<void> init() async {
    if (kIsWeb) return;
    try {
      // Init with the app's launcher icon — it ALWAYS exists, so init can
      // never fail on a missing resource. The branded scissors icon is only
      // *tried* per-notification (with a fallback), never at init.
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
      );
      final impl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
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
  /// Ask for the notification permission — at a moment the user can see the
  /// point of it (right after booking, when "we'll tell you when your barber
  /// confirms" is a promise they want kept), not on a cold launch.
  ///
  /// Android shows the system prompt only once per install, ever: spend it
  /// where the answer is yes. Safe to call repeatedly — it no-ops once
  /// answered, and a Deny never blocks anything, since notifications are a
  /// nice-to-have.
  static Future<void> ensurePermission() async {
    if (!_ready) return;
    try {
      final impl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await impl?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Notify.ensurePermission failed: $e');
    }
  }

  static Future<void> welcomeOnce(String title, String body) async {
    if (!_ready) return;
    final sp = await SharedPreferences.getInstance();
    if (sp.getBool('notifHelloV6') ?? false) return;
    await sp.setBool('notifHelloV6', true);
    await show(title, body);
  }

  // Fade brand blue — tints the small icon + app name in the shade.
  static const Color _brand = Color(0xFF2E8BFF);

  static Future<void> show(String title, String body) async {
    if (!_ready) return;
    final id = _id++;
    // Branded: scissors small icon (from init) tinted Fade-blue, a "FADE"
    // ribbon, and an expandable big-text body.
    final branded = NotificationDetails(
      android: AndroidNotificationDetails(
        'fade_events',
        'Fade',
        channelDescription: 'Booking updates and requests',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_stat_fade', // branded scissors — falls back if unresolved
        color: _brand,
        subText: 'FADE',
        ticker: title,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: '<b>$title</b>',
          summaryText: 'FADE',
          htmlFormatContentTitle: true,
          htmlFormatSummaryText: true,
        ),
      ),
      iOS: const DarwinNotificationDetails(),
    );
    try {
      await _plugin.show(id, title, body, branded);
    } catch (e) {
      // Safety net: never let a styling issue swallow the notification —
      // fall back to the plainest possible details (icon still from init).
      debugPrint('Notify.show branded failed, retrying plain: $e');
      try {
        await _plugin.show(
          id,
          title,
          body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'fade_events',
              'Fade',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
        );
      } catch (e2) {
        debugPrint('Notify.show plain also failed: $e2');
      }
    }
  }
}
