class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  factory GeoPoint.fromJson(Map<String, dynamic> json) {
    return GeoPoint(
      latitude: ((json['latitude'] ?? 0) as num).toDouble(),
      longitude: ((json['longitude'] ?? 0) as num).toDouble(),
    );
  }
}

class MapZone {
  const MapZone({
    required this.id,
    required this.name,
    required this.type,
    required this.boundary,
  });

  final String id;
  final String name;
  final String type;
  final List<GeoPoint> boundary;

  factory MapZone.fromJson(Map<String, dynamic> json) {
    final boundaryRaw = (json['boundary'] as List<dynamic>? ?? const <dynamic>[]);
    final boundary = boundaryRaw
        .map((item) => GeoPoint.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);
    return MapZone(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      type: (json['type'] ?? '') as String,
      boundary: boundary,
    );
  }
}
