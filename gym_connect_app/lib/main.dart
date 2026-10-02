import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_theme_provider.dart';
import 'features/auth/presentation/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch synchronous Flutter framework errors
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter uncaught error: ${details.exceptionAsString()}');
  };

  // Catch asynchronous platform errors to prevent fatal process crash
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Async platform error: $error\n$stack');
    return true;
  };

  String supabaseUrl = 'https://vtvexencluhysmkqyhln.supabase.co';
  String supabaseAnonKey = 'sb_publishable_7U6YdA-3cgaR5YTH9hKLdw_2zVUxTqw';

  try {
    await dotenv.load(fileName: '.env');
    final envUrl = dotenv.env['SUPABASE_URL'];
    final envKey = dotenv.env['SUPABASE_ANON_KEY'];
    if (envUrl != null && envUrl.trim().isNotEmpty) supabaseUrl = envUrl.trim();
    if (envKey != null && envKey.trim().isNotEmpty) supabaseAnonKey = envKey.trim();
  } catch (error) {
    debugPrint('Notice: .env loaded fallback credentials: $error');
  }

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: supabaseAnonKey,
    );
  } catch (error, stackTrace) {
    debugPrint('Error initializing Supabase: $error\n$stackTrace');
  }

  runApp(const ProviderScope(child: GymConnectApp()));
}

class GymConnectApp extends ConsumerWidget {
  const GymConnectApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(appThemeNotifierProvider);
    AppColors.setPrimaryAccent(themeState.currentPreset.color);

    return MaterialApp(
      title: 'GymConnect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme(tenantAccentColor: themeState.currentPreset.color),
      home: const AuthGate(),
    );
  }
}
