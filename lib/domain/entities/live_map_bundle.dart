import 'package:zakzouka/domain/entities/map_zone.dart';
import 'package:zakzouka/domain/entities/scooter.dart';

class LiveMapBundle {
  const LiveMapBundle({required this.scooters, required this.zones});

  final List<Scooter> scooters;
  final List<MapZone> zones;

  factory LiveMapBundle.fromJson(Map<String, dynamic> json) {
    final scootersRaw =
        (json['scooters'] as List<dynamic>? ?? const <dynamic>[]);
    final zonesRaw = (json['zones'] as List<dynamic>? ?? const <dynamic>[]);

    final scooters = scootersRaw
        .map((item) => Scooter.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);
    final zones = zonesRaw
        .map((item) => MapZone.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);

    return LiveMapBundle(scooters: scooters, zones: zones);
  }

  static const empty = LiveMapBundle(
    scooters: <Scooter>[],
    zones: <MapZone>[],
  );
}
