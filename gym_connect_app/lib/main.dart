import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
      await Supabase.initialize(
        url: supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: supabaseAnonKey,
      );
    } else {
      debugPrint('Warning: SUPABASE_URL or SUPABASE_ANON_KEY not configured in .env');
    }
  } catch (error, stackTrace) {
    debugPrint('Error initializing Supabase: $error\n$stackTrace');
  }

  runApp(const ProviderScope(child: GymConnectApp()));
}

class GymConnectApp extends StatelessWidget {
  const GymConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GymConnect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme(),
      home: const AuthGate(),
    );
  }
}
