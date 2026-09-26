import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthException;
import '../../../../core/services/secure_storage_service.dart';
import '../../data/auth_repository.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/user_role.dart';
import 'auth_state.dart';

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AppAuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AppAuthState> {
  StreamSubscription? _authSub;

  @override
  AppAuthState build() {
    final repo = ref.watch(authRepositoryProvider);

    _authSub?.cancel();
    _authSub = repo.authStateChanges.listen((data) {
      if (data.event == AuthChangeEvent.signedOut) {
        state = const AuthUnauthenticated();
      }
    });

    ref.onDispose(() {
      _authSub?.cancel();
    });

    Future.microtask(() => checkSession());
    return const AuthInitial();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);
  SecureStorageService get _storage => ref.read(secureStorageProvider);

  Future<void> checkSession() async {
    try {
      final session = await _repository.restoreSession();
      final savedRoleStr = await _storage.getActiveRole();

      if (session != null) {
        final profile = await _repository.fetchUserProfile(session.user.id);
        UserRole activeRole = profile.role;

        if (savedRoleStr != null && savedRoleStr.isNotEmpty) {
          activeRole = UserRole.fromString(savedRoleStr);
        }

        if (!ref.mounted) return;
        state = AuthAuthenticated(
          profile: profile,
          activeRole: activeRole,
        );
        return;
      }

      // If Supabase session is not active (e.g. demo role or browser reload)
      if (savedRoleStr != null && savedRoleStr.isNotEmpty) {
        final savedRole = UserRole.fromString(savedRoleStr);
        final profileJsonStr = await _storage.getPersistedProfileJson();
        UserProfile profile;

        if (profileJsonStr != null && profileJsonStr.isNotEmpty) {
          try {
            final map = jsonDecode(profileJsonStr) as Map<String, dynamic>;
            profile = UserProfile(
              id: map['id']?.toString() ?? 'persisted-session-user',
              role: savedRole,
              fullName: map['full_name']?.toString() ??
                  (savedRole == UserRole.superAdmin
                      ? 'Super Administrator'
                      : 'GymConnect Operator'),
              email: map['email']?.toString() ??
                  (savedRole == UserRole.superAdmin
                      ? 'superadmin@gymconnect.io'
                      : 'operator@gymconnect.io'),
              tenantName:
                  map['tenant_name']?.toString() ?? 'TITAN FITNESS CLUB',
              tenantId: map['tenant_id']?.toString(),
            );
          } catch (_) {
            profile = _defaultProfileForRole(savedRole);
          }
        } else {
          profile = _defaultProfileForRole(savedRole);
        }

        if (!ref.mounted) return;
        state = AuthAuthenticated(
          profile: profile,
          activeRole: savedRole,
        );
        return;
      }
    } catch (e) {
      debugPrint('AuthNotifier: checkSession error: $e');
    }
    if (!ref.mounted) return;
    state = const AuthUnauthenticated();
  }

  UserProfile _defaultProfileForRole(UserRole role) {
    return UserProfile(
      id: 'session-user',
      role: role,
      fullName: role == UserRole.superAdmin
          ? 'Super Administrator'
          : (role == UserRole.owner
              ? 'Gym Owner'
              : (role == UserRole.staff
                  ? 'Receptionist & POS Staff'
                  : 'Gym Member')),
      email: role == UserRole.superAdmin
          ? 'superadmin@gymconnect.io'
          : (role == UserRole.owner
              ? 'owner@titanfitness.com'
              : 'operator@gymconnect.io'),
      tenantName: 'TITAN FITNESS CLUB',
      tenantId: '00000000-0000-0000-0000-000000000001',
    );
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AuthAuthenticating();
    try {
      final response = await _repository.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user != null) {
        final profile = await _repository.fetchUserProfile(user.id);
        state = AuthAuthenticated(
          profile: profile,
          activeRole: profile.role,
        );
        await _storage.saveActiveRole(profile.role.dbValue);
        await _saveProfileToStorage(profile, profile.role);
      } else {
        state = const AuthUnauthenticated();
      }
    } on AuthException catch (e) {
      debugPrint('AuthNotifier: signIn AuthException: ${e.message}');
      state = AuthError(e.message);
    } catch (e) {
      debugPrint('AuthNotifier: signIn unexpected error: $e');
      state = AuthError('Login failed: ${e.toString()}');
    }
  }

  Future<void> switchActiveRole(UserRole targetRole) async {
    try {
      await _storage.saveActiveRole(targetRole.dbValue);
    } catch (e) {
      debugPrint('AuthNotifier: Error saving active role: $e');
    }

    final current = state;
    if (current is AuthAuthenticated) {
      final updated = current.copyWith(activeRole: targetRole);
      state = updated;
      await _saveProfileToStorage(updated.profile, targetRole);
    } else {
      final newProfile = _defaultProfileForRole(targetRole);
      state = AuthAuthenticated(
        profile: newProfile,
        activeRole: targetRole,
      );
      await _saveProfileToStorage(newProfile, targetRole);
    }
  }

  Future<void> _saveProfileToStorage(UserProfile profile, UserRole role) async {
    try {
      await _storage.savePersistedProfileJson(
        jsonEncode({
          'id': profile.id,
          'role': role.dbValue,
          'full_name': profile.fullName,
          'email': profile.email,
          'tenant_name': profile.tenantName,
          'tenant_id': profile.tenantId,
        }),
      );
    } catch (_) {}
  }

  Future<void> signOut() async {
    state = const AuthInitial();
    await _repository.signOut();
    await _storage.deleteActiveRole();
    await _storage.deleteToken();
    state = const AuthUnauthenticated();
  }

  void updateProfile(UserProfile newProfile) {
    final current = state;
    if (current is AuthAuthenticated) {
      state = current.copyWith(profile: newProfile);
      _saveProfileToStorage(newProfile, current.activeRole);
    }
  }

  void clearError() {
    if (state is AuthError) {
      state = const AuthUnauthenticated();
    }
  }
}
