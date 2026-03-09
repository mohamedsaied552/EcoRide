class Ride {
  final String id;
  final String scooterCode;
  final DateTime startedAt;
  final DateTime endedAt;
  final double distanceKm;
  final double cost;
  final String fromName;
  final String toName;

  const Ride({
    required this.id,
    required this.scooterCode,
    required this.startedAt,
    required this.endedAt,
    required this.distanceKm,
    required this.cost,
    required this.fromName,
    required this.toName,
  });

  Duration get duration => endedAt.difference(startedAt);

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'] as String,
      scooterCode: json['scooterCode'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: DateTime.parse(json['endedAt'] as String),
      distanceKm: (json['distanceKm'] as num).toDouble(),
      cost: (json['cost'] as num).toDouble(),
      fromName: json['fromName'] as String,
      toName: json['toName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scooterCode': scooterCode,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'distanceKm': distanceKm,
      'cost': cost,
      'fromName': fromName,
      'toName': toName,
    };
  }
}
