import 'package:glider/data/datasources/auth_service.dart';

class NotificationService {
  NotificationService({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  /// إرسال الـ FCM Token للباك اند عبر PUT /api/Auth/fcm-token
  Future<void> updateFcmToken(String token) {
    return _authService.updateFcmToken(token);
  }
}
