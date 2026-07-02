import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  // Restore the saved profile + prefs so signed-in users skip onboarding.
  await AppState.instance.load();
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

class _BarberAppState extends State<BarberApp> {
  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_onState);
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_onState);
    super.dispose();
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
