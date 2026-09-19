import '../../domain/models/user_profile.dart';
import '../../domain/models/user_role.dart';

sealed class AppAuthState {
  const AppAuthState();
}

class AuthInitial extends AppAuthState {
  const AuthInitial();
}

class AuthUnauthenticated extends AppAuthState {
  const AuthUnauthenticated();
}

class AuthAuthenticating extends AppAuthState {
  const AuthAuthenticating();
}

class AuthAuthenticated extends AppAuthState {
  final UserProfile profile;
  final UserRole activeRole;

  const AuthAuthenticated({
    required this.profile,
    required this.activeRole,
  });

  AuthAuthenticated copyWith({
    UserProfile? profile,
    UserRole? activeRole,
  }) {
    return AuthAuthenticated(
      profile: profile ?? this.profile,
      activeRole: activeRole ?? this.activeRole,
    );
  }
}

class AuthError extends AppAuthState {
  final String message;
  const AuthError(this.message);
}
