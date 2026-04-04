class Scooter {
  const Scooter({
    required this.id,
    required this.code,
    required this.lat,
    required this.lng,
    required this.batteryPercent,
    required this.isAvailable,
    required this.locationName,
  });

  final String id;
  final String code;
  final double lat;
  final double lng;
  final int batteryPercent;
  final bool isAvailable;
  final String locationName;

  String get statusLabel => isAvailable ? 'Available' : 'Offline';

  Scooter copyWith({
    String? id,
    String? code,
    double? lat,
    double? lng,
    int? batteryPercent,
    bool? isAvailable,
    String? locationName,
  }) {
    return Scooter(
      id: id ?? this.id,
      code: code ?? this.code,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      isAvailable: isAvailable ?? this.isAvailable,
      locationName: locationName ?? this.locationName,
    );
  }

  factory Scooter.fromJson(Map<String, dynamic> json) {
    return Scooter(
      id: json['id'] as String,
      code: (json['code'] ?? json['name'] ?? '') as String,
      lat: ((json['lat'] ?? 0) as num).toDouble(),
      lng: ((json['lng'] ?? 0) as num).toDouble(),
      batteryPercent: (json['batteryPercent'] ?? 100) as int,
      isAvailable: (json['isAvailable'] ?? true) as bool,
      locationName: (json['locationName'] ?? json['location'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': code,
      'lat': lat,
      'lng': lng,
      'batteryPercent': batteryPercent,
      'isAvailable': isAvailable,
      'locationName': locationName,
      'location': locationName,
    };
  }
}
