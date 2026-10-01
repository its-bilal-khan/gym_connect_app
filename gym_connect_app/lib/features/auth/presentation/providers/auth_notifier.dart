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
      } else if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.tokenRefreshed) {
        checkSession();
      }
    });
    ref.onDispose(() => _authSub?.cancel());
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
        final activeRole = (savedRoleStr != null && savedRoleStr.isNotEmpty)
            ? UserRole.fromString(savedRoleStr)
            : profile.role;
        if (!ref.mounted) return;
        state = AuthAuthenticated(profile: profile, activeRole: activeRole);
        return;
      }

      if (savedRoleStr != null && savedRoleStr.isNotEmpty) {
        final savedRole = UserRole.fromString(savedRoleStr);
        final pJson = await _storage.getPersistedProfileJson();
        UserProfile profile;
        if (pJson != null && pJson.isNotEmpty) {
          try {
            final m = jsonDecode(pJson) as Map<String, dynamic>;
            profile = UserProfile(
              id: m['id']?.toString() ?? 'session-user',
              role: savedRole,
              fullName: m['full_name']?.toString() ?? 'Gym User',
              email: m['email']?.toString() ?? '',
              tenantName: m['tenant_name']?.toString() ?? 'TITAN FITNESS CLUB',
              tenantId: m['tenant_id']?.toString(),
            );
          } catch (_) {
            profile = _defaultProfileForRole(savedRole);
          }
        } else {
          profile = _defaultProfileForRole(savedRole);
        }
        if (!ref.mounted) return;
        state = AuthAuthenticated(profile: profile, activeRole: savedRole);
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
      fullName: role == UserRole.superAdmin ? 'Super Administrator' : 'Gym Member',
      email: 'member@titanfitness.com',
      tenantName: 'TITAN FITNESS CLUB',
      tenantId: '00000000-0000-0000-0000-000000000001',
    );
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AuthAuthenticating();
    try {
      final res = await _repository.signInWithPassword(email: email, password: password);
      final user = res.user;
      if (user != null) {
        final profile = await _repository.fetchUserProfile(user.id);
        state = AuthAuthenticated(profile: profile, activeRole: profile.role);
        await _storage.saveActiveRole(profile.role.dbValue);
        await _saveProfileToStorage(profile, profile.role);
      } else {
        state = const AuthUnauthenticated();
      }
    } on AuthException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError('Login failed: ${e.toString()}');
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? tenantId,
  }) async {
    state = const AuthAuthenticating();
    try {
      final res = await _repository.signUpWithPassword(
        email: email,
        password: password,
        fullName: fullName,
        tenantId: tenantId,
      );
      final user = res.user;
      if (user != null) {
        if (res.session != null) {
          final profile = await _repository.fetchUserProfile(user.id);
          state = AuthAuthenticated(profile: profile, activeRole: profile.role);
          await _storage.saveActiveRole(profile.role.dbValue);
          await _saveProfileToStorage(profile, profile.role);
        } else {
          state = const AuthError('Account created! Please check your email to confirm or sign in.');
        }
      } else {
        state = const AuthUnauthenticated();
      }
    } on AuthException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError('Registration failed: ${e.toString()}');
    }
  }

  Future<void> switchActiveRole(UserRole targetRole) async {
    await _storage.saveActiveRole(targetRole.dbValue);
    final cur = state;
    if (cur is AuthAuthenticated) {
      final updated = cur.copyWith(activeRole: targetRole);
      state = updated;
      await _saveProfileToStorage(updated.profile, targetRole);
    } else {
      final p = _defaultProfileForRole(targetRole);
      state = AuthAuthenticated(profile: p, activeRole: targetRole);
      await _saveProfileToStorage(p, targetRole);
    }
  }

  Future<void> _saveProfileToStorage(UserProfile profile, UserRole role) async {
    try {
      await _storage.savePersistedProfileJson(jsonEncode({
        'id': profile.id, 'role': role.dbValue, 'full_name': profile.fullName,
        'email': profile.email, 'tenant_name': profile.tenantName, 'tenant_id': profile.tenantId,
      }));
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
    final cur = state;
    if (cur is AuthAuthenticated) {
      state = cur.copyWith(profile: newProfile);
      _saveProfileToStorage(newProfile, cur.activeRole);
    }
  }

  void clearError() {
    if (state is AuthError) state = const AuthUnauthenticated();
  }
}
