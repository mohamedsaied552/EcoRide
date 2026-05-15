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
    final scooterCode =
        (json['scooterCode'] ?? json['scooterSerialNumber'] ?? '') as String;
    final startedAtRaw =
        (json['startedAt'] ?? json['startTime'] ?? DateTime.now().toIso8601String())
            as String;
    final endedAtRaw =
        (json['endedAt'] ?? json['endTime'] ?? startedAtRaw) as String;

    return Ride(
      id: (json['id'] ?? json['rideId']).toString(),
      scooterCode: scooterCode,
      startedAt: DateTime.parse(startedAtRaw),
      endedAt: DateTime.parse(endedAtRaw),
      distanceKm: ((json['distanceKm'] ?? 0) as num).toDouble(),
      cost:
          ((json['cost'] ?? json['totalCost'] ?? json['currentCost'] ?? 0) as num)
              .toDouble(),
      fromName: (json['fromName'] ?? scooterCode) as String,
      toName: (json['toName'] ?? json['status'] ?? '') as String,
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
