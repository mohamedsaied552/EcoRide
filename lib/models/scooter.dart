class Scooter {
  final String id;
  final String code;
  final double lat;
  final double lng;
  final int batteryPercent;
  final bool isAvailable;
  final String locationName;

  const Scooter({
    required this.id,
    required this.code,
    required this.lat,
    required this.lng,
    required this.batteryPercent,
    required this.isAvailable,
    required this.locationName,
  });

  factory Scooter.fromJson(Map<String, dynamic> json) {
    return Scooter(
      id: json['id'] as String,
      code: json['code'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      batteryPercent: json['batteryPercent'] as int,
      isAvailable: json['isAvailable'] as bool,
      locationName: json['locationName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'lat': lat,
      'lng': lng,
      'batteryPercent': batteryPercent,
      'isAvailable': isAvailable,
      'locationName': locationName,
    };
  }
}
