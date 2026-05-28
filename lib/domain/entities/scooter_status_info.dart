class ScooterStatusInfo {
  const ScooterStatusInfo({
    required this.serialNumber,
    required this.batteryLevel,
    required this.status,
  });

  final String serialNumber;
  final int batteryLevel;
  final String status;

  bool get isAvailable {
    switch (status.toLowerCase()) {
      case 'available':
      case 'idle':
        return true;
      default:
        return false;
    }
  }

  factory ScooterStatusInfo.fromJson(Map<String, dynamic> json) {
    return ScooterStatusInfo(
      serialNumber: (json['serialNumber'] ?? '') as String,
      batteryLevel: ((json['batteryLevel'] ?? 0) as num).toInt(),
      status: (json['status'] ?? '') as String,
    );
  }
}
