import 'user.dart';

class SignupResult {
  const SignupResult({
    required this.user,
    required this.requiresEmailVerification,
  });

  final AppUser user;
  final bool requiresEmailVerification;
}
