import 'token.dart';
import 'user.dart';

class AuthResult {
  const AuthResult({
    required this.user,
    required this.token,
  });

  final AppUser user;
  final AuthToken token;

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
      token: AuthToken.fromJson(json['token'] as Map<String, dynamic>),
    );
  }
}
