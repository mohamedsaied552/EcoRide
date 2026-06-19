//location_accuracy_validator.dart
import 'package:geolocator/geolocator.dart';

class LocationAccuracyValidator {
  /// Maximum acceptable horizontal accuracy in meters when performing
  /// proximity checks for a ride unlock.
  /// Relaxed to 150m for indoor/dev testing (production target: ~25m).
  static const double maximumAcceptableAccuracyMeters = 150.0;

  /// Throws when GPS drift or low accuracy makes the position unreliable.
  static void validate(Position position) {
    if (position.accuracy.isNegative ||
        position.accuracy > maximumAcceptableAccuracyMeters) {
      throw Exception(
        'GPS accuracy is too low (${position.accuracy.toStringAsFixed(1)}m). '
        'Move to an open area and retry.',
      );
    }
  }
}
