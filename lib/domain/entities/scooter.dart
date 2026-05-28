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
    this.unlockFee,
    this.feePerMinute,
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
  final double? unlockFee;
  final double? feePerMinute;

  String get statusLabel =>
      rawStatus ?? (isAvailable ? 'Available' : 'Offline');

  bool get hasCoordinates => lat != 0 || lng != 0;

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
    double? unlockFee,
    double? feePerMinute,
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
      unlockFee: unlockFee ?? this.unlockFee,
      feePerMinute: feePerMinute ?? this.feePerMinute,
    );
  }

  factory Scooter.fromJson(Map<String, dynamic> json) {
    final status = (json['status'] ?? '') as String;
    final lat = ((json['lat'] ?? json['latitude'] ?? 0) as num).toDouble();
    final lng = ((json['lng'] ?? json['longitude'] ?? 0) as num).toDouble();
    final unlockFeeRaw = json['unlockFee'];
    final feePerMinuteRaw = json['feePerMinute'];
    // MapScooterDto from /Scooter/live-map omits an explicit status. When
    // coordinates are present (i.e. the scooter is being advertised on the
    // live map) we treat it as available unless told otherwise.
    final hasMapStatus = json.containsKey('status');
    return Scooter(
      id: json['id'] as String,
      code:
          (json['code'] ?? json['serialNumber'] ?? json['name'] ?? '')
              as String,
      lat: lat,
      lng: lng,
      batteryPercent:
          ((json['batteryPercent'] ?? json['batteryLevel'] ?? 100) as num)
              .toInt(),
      isAvailable:
          (json['isAvailable'] as bool?) ??
          (hasMapStatus ? _isAvailableFromStatus(status) : true),
      locationName:
          (json['locationName'] ?? json['location'] ?? json['modelName'] ?? '')
              as String,
      modelName: json['modelName'] as String?,
      rawStatus: status.isEmpty ? null : status,
      unlockFee: unlockFeeRaw is num ? unlockFeeRaw.toDouble() : null,
      feePerMinute: feePerMinuteRaw is num ? feePerMinuteRaw.toDouble() : null,
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
      'latitude': lat,
      'longitude': lng,
      'batteryPercent': batteryPercent,
      'batteryLevel': batteryPercent,
      'isAvailable': isAvailable,
      'status': rawStatus ?? statusLabel,
      'locationName': locationName,
      'location': locationName,
      'modelName': modelName,
      'unlockFee': unlockFee,
      'feePerMinute': feePerMinute,
    };
  }
}
