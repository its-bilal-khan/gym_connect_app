import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/secure_storage_service.dart';
import '../../features/auth/domain/models/user_profile.dart';
import '../../features/auth/presentation/providers/auth_notifier.dart';
import '../../features/auth/presentation/providers/auth_state.dart';
import 'app_colors.dart';
import 'app_theme_presets.dart';

class AppThemeState {
  final AppThemePreset currentPreset;
  final bool isPermanentLocked;
  final AppThemePreset? lockedPreset;
  final bool hasPendingRequest;
  final AppThemePreset? pendingRequestedPreset;
  final String? pendingRequestReason;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const AppThemeState({
    required this.currentPreset,
    this.isPermanentLocked = false,
    this.lockedPreset,
    this.hasPendingRequest = false,
    this.pendingRequestedPreset,
    this.pendingRequestReason,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  Color get activeColor => currentPreset.color;

  AppThemeState copyWith({
    AppThemePreset? currentPreset,
    bool? isPermanentLocked,
    AppThemePreset? lockedPreset,
    bool? hasPendingRequest,
    AppThemePreset? pendingRequestedPreset,
    String? pendingRequestReason,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearPendingRequest = false,
  }) {
    return AppThemeState(
      currentPreset: currentPreset ?? this.currentPreset,
      isPermanentLocked: isPermanentLocked ?? this.isPermanentLocked,
      lockedPreset: lockedPreset ?? this.lockedPreset,
      hasPendingRequest: clearPendingRequest ? false : (hasPendingRequest ?? this.hasPendingRequest),
      pendingRequestedPreset: clearPendingRequest ? null : (pendingRequestedPreset ?? this.pendingRequestedPreset),
      pendingRequestReason: clearPendingRequest ? null : (pendingRequestReason ?? this.pendingRequestReason),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

final appThemeNotifierProvider =
    NotifierProvider<AppThemeNotifier, AppThemeState>(AppThemeNotifier.new);

class AppThemeNotifier extends Notifier<AppThemeState> {
  @override
  AppThemeState build() {
    AppColors.setPrimaryAccent(AppThemePreset.neonVolt.color);
    Future.microtask(() => _loadInitialTheme());
    return const AppThemeState(currentPreset: AppThemePreset.neonVolt);
  }

  Future<void> _loadInitialTheme() async {
    final storage = ref.read(secureStorageProvider);
    final savedHex = await storage.getUserAccentColor();
    if (savedHex != null && savedHex.isNotEmpty) {
      final preset = AppThemePreset.fromHex(savedHex);
      AppColors.setPrimaryAccent(preset.color);
      state = state.copyWith(currentPreset: preset);
    }
  }

  /// Synchronizes theme state with the authenticated user profile and tenant branding.
  void syncWithProfile(UserProfile profile) {
    var updatedCurrent = state.currentPreset;
    bool locked = profile.isThemeLocked;
    AppThemePreset? lockedPreset;
    bool pending = false;
    AppThemePreset? pendingPreset;
    String? pendingReason;

    if (profile.tenantPrimaryColor != null) {
      final tenantPreset = AppThemePreset.fromColor(profile.tenantPrimaryColor);
      if (locked) {
        lockedPreset = tenantPreset;
        updatedCurrent = tenantPreset;
      }
    }

    if (profile.pendingThemeRequestColor != null) {
      pending = true;
      pendingPreset = AppThemePreset.fromHex(profile.pendingThemeRequestColor);
      pendingReason = profile.pendingThemeRequestReason;
    }

    AppColors.setPrimaryAccent(updatedCurrent.color);
    state = state.copyWith(
      currentPreset: updatedCurrent,
      isPermanentLocked: locked,
      lockedPreset: lockedPreset,
      hasPendingRequest: pending,
      pendingRequestedPreset: pendingPreset,
      pendingRequestReason: pendingReason,
    );
  }

  /// Sets the active theme preset for the current session and persists to secure storage.
  Future<void> previewTheme(AppThemePreset preset) async {
    AppColors.setPrimaryAccent(preset.color);
    state = state.copyWith(
      currentPreset: preset,
      clearError: true,
      clearSuccess: true,
    );
    try {
      final storage = ref.read(secureStorageProvider);
      await storage.saveUserAccentColor(preset.hex);
    } catch (_) {}
  }

  /// Gym Owner / Tenant permanently locks a brand accent color in Supabase PostgreSQL.
  Future<bool> lockThemePermanently({
    required String tenantId,
    required AppThemePreset preset,
    required UserProfile profile,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final client = Supabase.instance.client;

    try {
      // 1. Fetch current branding JSONB from tenants table
      final tenantRes = await client
          .from('tenants')
          .select('branding')
          .eq('id', tenantId)
          .maybeSingle();

      final existingBranding =
          (tenantRes?['branding'] as Map<String, dynamic>?) ?? {};

      final updatedBranding = {
        ...existingBranding,
        'primary_color': preset.hex,
        'theme_locked': true,
        'locked_at': DateTime.now().toIso8601String(),
        'locked_by_user_id': profile.id,
        'pending_theme_request': null,
      };

      // 2. Persist permanent lock in Supabase
      await client
          .from('tenants')
          .update({'branding': updatedBranding})
          .eq('id', tenantId);

      // 3. Insert real audit notification in database
      try {
        await client.from('notifications').insert({
          'title': 'Brand Theme Permanently Locked',
          'message':
              '${profile.tenantName} official brand theme locked to ${preset.name} (${preset.hex}).',
          'type': 'announcement',
          'tenant_id': tenantId,
          'user_id': profile.id,
        });
      } catch (ne) {
        debugPrint('AppThemeNotifier: notification log error: $ne');
      }

      // 4. Update secure storage
      final storage = ref.read(secureStorageProvider);
      await storage.saveUserAccentColor(preset.hex);

      // 5. Update authenticated user profile in Riverpod
      final authNotifier = ref.read(authNotifierProvider.notifier);
      final currentAuth = ref.read(authNotifierProvider);
      if (currentAuth is AuthAuthenticated) {
        authNotifier.updateProfile(
          currentAuth.profile.copyWith(
            tenantPrimaryColor: preset.color,
            isThemeLocked: true,
            pendingThemeRequestColor: null,
            pendingThemeRequestReason: null,
          ),
        );
      }

      AppColors.setPrimaryAccent(preset.color);
      state = state.copyWith(
        isLoading: false,
        currentPreset: preset,
        isPermanentLocked: true,
        lockedPreset: preset,
        clearPendingRequest: true,
        successMessage: 'Official brand theme permanently locked to ${preset.name}!',
      );
      return true;
    } catch (e) {
      debugPrint('AppThemeNotifier: lockThemePermanently error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to permanently lock theme: $e',
      );
      return false;
    }
  }

  /// Gym Owner generates a theme change request when the theme is already locked.
  Future<bool> submitThemeChangeRequest({
    required String tenantId,
    required AppThemePreset requestedPreset,
    required String reason,
    required UserProfile profile,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final client = Supabase.instance.client;

    try {
      // 1. Fetch current branding
      final tenantRes = await client
          .from('tenants')
          .select('branding')
          .eq('id', tenantId)
          .maybeSingle();

      final existingBranding =
          (tenantRes?['branding'] as Map<String, dynamic>?) ?? {};

      final pendingReq = {
        'requested_color': requestedPreset.hex,
        'requested_color_name': requestedPreset.name,
        'reason': reason.trim(),
        'requested_at': DateTime.now().toIso8601String(),
        'requested_by_user_id': profile.id,
        'requested_by_user_name': profile.fullName,
        'status': 'pending',
      };

      final updatedBranding = {
        ...existingBranding,
        'pending_theme_request': pendingReq,
      };

      // 2. Persist change request in Supabase
      await client
          .from('tenants')
          .update({'branding': updatedBranding})
          .eq('id', tenantId);

      // 3. Post notification alert for Super Admin & Gym Owner
      try {
        await client.from('notifications').insert({
          'title': 'Theme Change Request: ${profile.tenantName}',
          'message':
              '${profile.fullName} requested to switch brand color to ${requestedPreset.name} (${requestedPreset.hex}). Reason: ${reason.trim()}',
          'type': 'announcement',
          'tenant_id': tenantId,
          'user_id': null, // System-wide for admin & owner
        });
      } catch (ne) {
        debugPrint('AppThemeNotifier: change request notification error: $ne');
      }

      // 4. Update Riverpod profile
      final authNotifier = ref.read(authNotifierProvider.notifier);
      final currentAuth = ref.read(authNotifierProvider);
      if (currentAuth is AuthAuthenticated) {
        authNotifier.updateProfile(
          currentAuth.profile.copyWith(
            pendingThemeRequestColor: requestedPreset.hex,
            pendingThemeRequestReason: reason.trim(),
          ),
        );
      }

      state = state.copyWith(
        isLoading: false,
        hasPendingRequest: true,
        pendingRequestedPreset: requestedPreset,
        pendingRequestReason: reason.trim(),
        successMessage: 'Theme Change Request submitted for Super Admin review.',
      );
      return true;
    } catch (e) {
      debugPrint('AppThemeNotifier: submitThemeChangeRequest error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to submit theme request: $e',
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}
