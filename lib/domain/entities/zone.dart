import 'package:glider/domain/entities/map_zone.dart';

/// Full Zone entity that mirrors `ZoneDto` from the OpenAPI spec.
///
/// Unlike [MapZone] (which is the lightweight projection returned by
/// `/Scooter/live-map`), this entity also carries `speedLimitKmH` and
/// `isActive`, both of which the Zone Admin CRUD endpoints expose.
class Zone {
  const Zone({
    required this.id,
    required this.name,
    required this.type,
    required this.speedLimitKmH,
    required this.isActive,
    required this.boundary,
  });

  final String id;
  final String name;
  final String type;
  final double? speedLimitKmH;
  final bool isActive;
  final List<GeoPoint> boundary;

  Zone copyWith({
    String? id,
    String? name,
    String? type,
    double? speedLimitKmH,
    bool? isActive,
    List<GeoPoint>? boundary,
  }) {
    return Zone(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      speedLimitKmH: speedLimitKmH ?? this.speedLimitKmH,
      isActive: isActive ?? this.isActive,
      boundary: boundary ?? this.boundary,
    );
  }

  factory Zone.fromJson(Map<String, dynamic> json) {
    final boundaryRaw =
        (json['boundary'] as List<dynamic>? ?? const <dynamic>[]);
    final boundary = boundaryRaw
        .map(
          (item) => GeoPoint.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
    final speedRaw = json['speedLimitKmH'];
    return Zone(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      type: (json['type'] ?? '') as String,
      speedLimitKmH: speedRaw is num ? speedRaw.toDouble() : null,
      isActive: (json['isActive'] as bool?) ?? true,
      boundary: boundary,
    );
  }

  Map<String, dynamic> toCreationJson() {
    return <String, dynamic>{
      'name': name,
      'type': type,
      'speedLimitKmH': speedLimitKmH,
      'boundary': boundary
          .map(
            (point) => <String, dynamic>{
              'latitude': point.latitude,
              'longitude': point.longitude,
            },
          )
          .toList(growable: false),
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return <String, dynamic>{
      'name': name,
      'type': type,
      'speedLimitKmH': speedLimitKmH,
      'isActive': isActive,
      'boundary': boundary
          .map(
            (point) => <String, dynamic>{
              'latitude': point.latitude,
              'longitude': point.longitude,
            },
          )
          .toList(growable: false),
    };
  }
}
