import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'core/notifications/notify.dart';
import 'core/supabase/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'data/app_state.dart';
import 'presentation/screens/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Connect the backend (local setup; never blocks on the network). Guarded so
  // a failure can never stop the app from launching on mock data.
  try {
    await SupabaseService.init();
  } catch (e) {
    debugPrint('Supabase init failed: $e');
  }
  // Set up the notification channel. Does NOT ask for permission — that now
  // happens after the first booking (Notify.ensurePermission), where the user
  // can see why it's worth a yes.
  await Notify.init();
  // Restore the saved profile + prefs so signed-in users skip onboarding.
  await AppState.instance.load();
  // Pull the live shop catalogue (no-op unless SupabaseConfig.useRealCatalogue).
  // NOT awaited: on a cold start with bad signal this could hold the first frame
  // for the full 8-second timeout, i.e. a frozen launch. The scissors intro
  // covers the fetch, and loadCatalogue() calls notifyListeners() when it lands,
  // so the catalogue repaints itself.
  AppState.instance.loadCatalogue();
  // Best-effort pull of the server-authoritative Fade-Points balance (Phase 3B);
  // unawaited so it never blocks startup, falls back to the local mirror.
  AppState.instance.refreshServerLoyalty();
  // Pull bookings the server says are mine — as a client AND as a barber. This
  // is what makes a request booked on one phone show up on the other one.
  AppState.instance.syncBookings();
  // Localize dates/times to the saved language — without this every DateFormat
  // (weekday/month names) renders in English even in RU/UZ.
  await initializeDateFormatting();
  Intl.defaultLocale = AppState.instance.language.name; // en / ru / uz
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  runApp(const BarberApp());
}

class BarberApp extends StatefulWidget {
  const BarberApp({super.key});

  @override
  State<BarberApp> createState() => _BarberAppState();
}

class _BarberAppState extends State<BarberApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_onState);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppState.instance.removeListener(_onState);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back to the app re-pulls the server's view of my bookings and
    // points, so a request made on another device (or a barber's accept) shows
    // up without needing a restart.
    if (state == AppLifecycleState.resumed) {
      AppState.instance.syncBookings();
      AppState.instance.refreshServerLoyalty();
      // Time passes while the app is backgrounded, and that is exactly when a
      // slot lapses. Without this, a visit stays "upcoming" and an unanswered
      // request stays "waiting for reply" until something else happens to
      // trigger a sweep.
      AppState.instance.settlePastBookings();
    }
  }

  void _onState() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fade',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode:
          AppState.instance.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
      builder: (context, child) {
        // Clamp text scaling so layouts stay clean across accessibility settings.
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(
              mq.textScaler.scale(14).clamp(14 * 0.9, 14 * 1.2) / 14,
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
