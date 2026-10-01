import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/secure_storage_service.dart';
import '../domain/models/user_profile.dart';
import '../domain/models/user_role.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final storage = ref.watch(secureStorageProvider);
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (e) {
    debugPrint('AuthRepository: SupabaseClient unavailable: $e');
  }
  return AuthRepository(client, storage);
});

class AuthRepository {
  final SupabaseClient? _supabase;
  final SecureStorageService _storage;

  AuthRepository(this._supabase, this._storage);

  Stream<AuthState> get authStateChanges =>
      _supabase?.auth.onAuthStateChange ?? const Stream<AuthState>.empty();

  Session? get currentSession => _supabase?.auth.currentSession;
  User? get currentUser => _supabase?.auth.currentUser;

  Future<Session?> restoreSession() async {
    final client = _supabase;
    if (client == null) return null;
    try {
      if (client.auth.currentSession != null) {
        await _persistCurrentSession(client.auth.currentSession!);
        return client.auth.currentSession;
      }
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        final res = await client.auth.setSession(refreshToken);
        if (res.session != null) {
          await _persistCurrentSession(res.session!);
          return res.session;
        }
      }
    } catch (e) {
      debugPrint('AuthRepository: restoreSession error: $e');
    }
    return null;
  }

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final client = _supabase;
    if (client == null) {
      throw const AuthException('Supabase connection is not initialized');
    }
    final response = await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    if (response.session != null) {
      await _persistCurrentSession(response.session!);
    }
    return response;
  }

  Future<AuthResponse> signUpWithPassword({
    required String email,
    required String password,
    required String fullName,
    String? tenantId,
  }) async {
    final client = _supabase;
    if (client == null) {
      throw const AuthException('Supabase connection is not initialized');
    }
    final cleanEmail = email.trim();
    final cleanName = fullName.trim();
    final response = await client.auth.signUp(
      email: cleanEmail,
      password: password,
      data: {
        'full_name': cleanName,
        'role': 'member',
        if (tenantId != null && tenantId.isNotEmpty) 'tenant_id': tenantId,
      },
    );
    if (response.session != null) {
      await _persistCurrentSession(response.session!);
    }
    if (response.user != null) {
      await syncNewUserProfiles(
        userId: response.user!.id,
        email: cleanEmail,
        fullName: cleanName,
        tenantId: tenantId,
      );
    }
    return response;
  }

  Future<void> syncNewUserProfiles({
    required String userId,
    required String email,
    required String fullName,
    String? tenantId,
  }) async {
    final client = _supabase;
    if (client == null) return;
    try {
      await client.rpc('rpc_sync_new_user_profile', params: {
        'p_user_id': userId,
        'p_email': email,
        'p_full_name': fullName,
        if (tenantId != null && tenantId.isNotEmpty) 'p_tenant_id': tenantId,
      });
    } catch (e) {
      debugPrint('AuthRepository: sync fallback error: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase?.auth.signOut();
    } catch (e) {
      debugPrint('AuthRepository: SignOut error: $e');
    } finally {
      await _storage.clearAll();
    }
  }

  Future<UserProfile> fetchUserProfile(String userId) async {
    final client = _supabase;
    if (client != null) {
      try {
        final res = await client
            .from('profiles')
            .select('*, tenants(name, branding)')
            .eq('id', userId)
            .maybeSingle();
        if (res != null) {
          final profile = UserProfile.fromJson(res);
          if (profile.tenantId != null) {
            await _storage.saveTenantId(profile.tenantId!);
          }
          return profile;
        }
      } catch (e) {
        debugPrint('AuthRepository: fetchUserProfile error: $e');
      }
    }
    final user = _supabase?.auth.currentUser;
    final metaRole = user?.userMetadata?['role'] as String?;
    return UserProfile(
      id: userId,
      role: UserRole.fromString(metaRole),
      fullName: user?.userMetadata?['full_name'] as String? ?? user?.email?.split('@').first ?? 'Member',
      email: user?.email ?? '',
      tenantName: 'Titan Fitness Club',
    );
  }

  Future<void> _persistCurrentSession(Session session) async {
    await _storage.saveToken(session.accessToken);
    final refresh = session.refreshToken;
    if (refresh != null) {
      await _storage.saveRefreshToken(refresh);
    }
  }
}
