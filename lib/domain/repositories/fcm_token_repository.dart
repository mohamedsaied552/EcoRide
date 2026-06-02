abstract class FcmTokenRepository {
  Future<void> updateFcmToken({required String userId, required String token});
}
