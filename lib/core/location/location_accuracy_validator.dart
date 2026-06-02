import 'package:geolocator/geolocator.dart';

class LocationAccuracyValidator {
  /// Maximum acceptable horizontal accuracy in meters when performing
  /// proximity checks for a ride unlock.
  static const double maximumAcceptableAccuracyMeters = 25.0;

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
