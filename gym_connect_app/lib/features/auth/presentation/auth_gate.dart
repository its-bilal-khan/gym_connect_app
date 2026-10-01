import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../navigation/presentation/adaptive_role_shell.dart';
import '../../workout/presentation/providers/fitness_profile_provider.dart';
import '../domain/models/user_profile.dart';
import '../domain/models/user_role.dart';
import 'login_screen.dart';
import 'providers/auth_notifier.dart';
import 'providers/auth_state.dart';
import 'widgets/member_onboarding_gate_view.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return switch (authState) {
      AuthInitial() => const _AuthSplashView(message: 'CHECKING SECURE SESSION...'),
      AuthAuthenticated(:final profile, :final activeRole) => _buildAuthenticatedView(ref, profile, activeRole),
      AuthAuthenticating() || AuthUnauthenticated() || AuthError() => const LoginScreen(),
    };
  }

  Widget _buildAuthenticatedView(WidgetRef ref, UserProfile profile, UserRole activeRole) {
    if (activeRole == UserRole.member) {
      final fitnessProfileAsync = ref.watch(fitnessProfileProvider);
      return fitnessProfileAsync.when(
        loading: () => const _AuthSplashView(message: 'INITIALIZING FITNESS PROTOCOL...'),
        error: (e, _) => MemberOnboardingGateView(profile: profile),
        data: (fitnessProfile) {
          if (!fitnessProfile.profileCompleted) {
            return MemberOnboardingGateView(profile: profile);
          }
          return AdaptiveRoleShell(
            key: ValueKey('shell_${profile.id}_${activeRole.name}'),
            profile: profile,
            activeRole: activeRole,
          );
        },
      );
    }

    return AdaptiveRoleShell(
      key: ValueKey('shell_${profile.id}_${activeRole.name}'),
      profile: profile,
      activeRole: activeRole,
    );
  }
}

class _AuthSplashView extends StatelessWidget {
  final String message;
  const _AuthSplashView({required this.message});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

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
                      color: accent.withValues(alpha: 0.15),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.fitness_center_rounded,
                  color: accent,
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
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
