import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../navigation/presentation/adaptive_role_shell.dart';
import 'login_screen.dart';
import 'providers/auth_notifier.dart';
import 'providers/auth_state.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return switch (authState) {
      AuthInitial() => const _AuthSplashView(message: 'CHECKING SECURE SESSION...'),
      AuthAuthenticating() => const _AuthSplashView(message: 'AUTHENTICATING CREDENTIALS...'),
      AuthAuthenticated(:final profile, :final activeRole) => AdaptiveRoleShell(
          key: ValueKey('shell_${profile.id}_${activeRole.name}'),
          profile: profile,
          activeRole: activeRole,
        ),
      AuthUnauthenticated() || AuthError() => const LoginScreen(),
    };
  }
}

class _AuthSplashView extends StatelessWidget {
  final String message;
  const _AuthSplashView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryAccent.withValues(alpha: 0.15),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                color: AppColors.primaryAccent,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'GYMCONNECT',
              style: GoogleFonts.oswald(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
