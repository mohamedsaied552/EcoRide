class Scooter {
  const Scooter({
    required this.id,
    required this.code,
    required this.lat,
    required this.lng,
    required this.batteryPercent,
    required this.isAvailable,
    required this.locationName,
    this.modelName,
    this.rawStatus,
  });

  final String id;
  final String code;
  final double lat;
  final double lng;
  final int batteryPercent;
  final bool isAvailable;
  final String locationName;
  final String? modelName;
  final String? rawStatus;

  String get statusLabel => rawStatus ?? (isAvailable ? 'Available' : 'Offline');

  Scooter copyWith({
    String? id,
    String? code,
    double? lat,
    double? lng,
    int? batteryPercent,
    bool? isAvailable,
    String? locationName,
    String? modelName,
    String? rawStatus,
  }) {
    return Scooter(
      id: id ?? this.id,
      code: code ?? this.code,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      isAvailable: isAvailable ?? this.isAvailable,
      locationName: locationName ?? this.locationName,
      modelName: modelName ?? this.modelName,
      rawStatus: rawStatus ?? this.rawStatus,
    );
  }

  factory Scooter.fromJson(Map<String, dynamic> json) {
    final status = (json['status'] ?? '') as String;
    return Scooter(
      id: json['id'] as String,
      code:
          (json['code'] ?? json['serialNumber'] ?? json['name'] ?? '') as String,
      lat: ((json['lat'] ?? json['latitude'] ?? 0) as num).toDouble(),
      lng: ((json['lng'] ?? json['longitude'] ?? 0) as num).toDouble(),
      batteryPercent:
          ((json['batteryPercent'] ?? json['batteryLevel'] ?? 100) as num).toInt(),
      isAvailable:
          (json['isAvailable'] as bool?) ??
          _isAvailableFromStatus(status),
      locationName:
          (json['locationName'] ?? json['location'] ?? json['modelName'] ?? '') as String,
      modelName: json['modelName'] as String?,
      rawStatus: status.isEmpty ? null : status,
    );
  }

  static bool _isAvailableFromStatus(String status) {
    switch (status.toLowerCase()) {
      case 'available':
      case 'idle':
        return true;
      default:
        return false;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'serialNumber': code,
      'name': code,
      'lat': lat,
      'lng': lng,
      'batteryPercent': batteryPercent,
      'batteryLevel': batteryPercent,
      'isAvailable': isAvailable,
      'status': rawStatus ?? statusLabel,
      'locationName': locationName,
      'location': locationName,
      'modelName': modelName,
    };
  }
}
