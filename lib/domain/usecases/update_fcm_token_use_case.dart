import 'package:glider/domain/repositories/fcm_token_repository.dart';

class UpdateFcmTokenUseCase {
  UpdateFcmTokenUseCase(this._repository);

  final FcmTokenRepository _repository;

  Future<void> call({required String userId, required String token}) async {
    return _repository.updateFcmToken(userId: userId, token: token);
  }
}
