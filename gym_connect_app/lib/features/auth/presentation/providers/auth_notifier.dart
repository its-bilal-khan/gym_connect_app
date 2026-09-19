import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent, AuthException;
import '../../../../core/services/secure_storage_service.dart';
import '../../data/auth_repository.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/user_role.dart';
import 'auth_state.dart';

final authNotifierProvider = NotifierProvider<AuthNotifier, AppAuthState>(AuthNotifier.new);

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
      if (session != null) {
        final profile = await _repository.fetchUserProfile(session.user.id);
        final savedRoleStr = await _storage.getActiveRole();
        UserRole activeRole = profile.role;

        if (savedRoleStr != null && profile.role.canSwitchRoles) {
          activeRole = UserRole.fromString(savedRoleStr);
        }

        state = AuthAuthenticated(
          profile: profile,
          activeRole: activeRole,
        );
        return;
      }
    } catch (e) {
      debugPrint('AuthNotifier: checkSession error: $e');
    }
    state = const AuthUnauthenticated();
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
      } else {
        state = const AuthUnauthenticated();
      }
    } on AuthException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = const AuthError('Authentication failed. Please verify your credentials and network connection.');
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
      state = current.copyWith(activeRole: targetRole);
    } else {
      state = AuthAuthenticated(
        profile: UserProfile(
          id: 'session-user',
          role: targetRole,
          fullName: 'GymConnect Operator',
          email: 'admin@gymconnect.io',
          tenantName: 'TITAN FITNESS CLUB',
        ),
        activeRole: targetRole,
      );
    }
  }

  Future<void> signOut() async {
    state = const AuthInitial();
    await _repository.signOut();
    state = const AuthUnauthenticated();
  }

  void clearError() {
    if (state is AuthError) {
      state = const AuthUnauthenticated();
    }
  }
}
