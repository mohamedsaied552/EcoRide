class LiveRideUpdate {
  const LiveRideUpdate({
    required this.rideId,
    this.scooterLatitude,
    this.scooterLongitude,
    this.currentDurationMinutes,
    this.currentCost,
    this.batteryLevel,
  });

  final String rideId;
  final double? scooterLatitude;
  final double? scooterLongitude;
  final double? currentDurationMinutes;
  final double? currentCost;
  final int? batteryLevel;

  factory LiveRideUpdate.fromJson(Map<String, dynamic> json) {
    return LiveRideUpdate(
      rideId: _readString(json, const ['rideId', 'RideId']) ?? '',
      scooterLatitude: _readDouble(json, const [
        'scooterLatitude',
        'ScooterLatitude',
        'latitude',
        'Latitude',
      ]),
      scooterLongitude: _readDouble(json, const [
        'scooterLongitude',
        'ScooterLongitude',
        'longitude',
        'Longitude',
      ]),
      currentDurationMinutes: _readDouble(json, const [
        'currentDurationMinutes',
        'CurrentDurationMinutes',
        'durationMinutes',
      ]),
      currentCost: _readDouble(json, const [
        'currentCost',
        'CurrentCost',
        'cost',
      ]),
      batteryLevel: _readInt(json, const [
        'batteryLevel',
        'BatteryLevel',
        'batteryPercent',
      ]),
    );
  }

  static String? _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  static double? _readDouble(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) {
        return value.toDouble();
      }
    }
    return null;
  }

  static int? _readInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) {
        return value.round();
      }
    }
    return null;
  }
}
