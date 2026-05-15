import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Simple circular geofence around a center point.
class GeofenceService {
  GeofenceService._internal();

  static final GeofenceService _instance = GeofenceService._internal();

  factory GeofenceService() => _instance;

  // Cairo downtown as demo center.
  final LatLng _center = const LatLng(30.0444, 31.2357);
  // Radius in meters.
  final double _radiusMeters = 3000; // 3 km demo zone.

  LatLng get center => _center;

  /// Returns true if the given point is inside the allowed operating zone.
  bool isInside(LatLng point) {
    return _distanceMeters(point, _center) <= _radiusMeters;
  }

  double _distanceMeters(LatLng a, LatLng b) {
    const earthRadius = 6371000.0;
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLon = _degToRad(b.longitude - a.longitude);

    final lat1 = _degToRad(a.latitude);
    final lat2 = _degToRad(b.latitude);

    final sinDLat = math.sin(dLat / 2);
    final sinDLon = math.sin(dLon / 2);
    final aVal = sinDLat * sinDLat +
        sinDLon * sinDLon * math.cos(lat1) * math.cos(lat2);
    final c = 2 * math.atan2(math.sqrt(aVal), math.sqrt(1 - aVal));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * math.pi / 180.0;
}

