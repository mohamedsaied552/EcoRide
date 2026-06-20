import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:glider/domain/entities/ride.dart';
import 'package:glider/l10n/app_localizations.dart';

class RideSummaryScreen extends StatelessWidget {
  const RideSummaryScreen({
    super.key,
    required this.ride,
    required this.route,
    this.remainingBalance,
  });

  final Ride ride;
  final List<dynamic> route;
  final double? remainingBalance;

  String _formatDuration(AppLocalizations l10n, Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return l10n.durationMinSec('$minutes', '$seconds');
  }

  LatLng _toMapLatLng(dynamic position) {
    return LatLng(position.latitude as double, position.longitude as double);
  }

  bool _isValidLatLng(LatLng position) {
    return position.latitude.abs() <= 90 &&
        position.longitude.abs() <= 180 &&
        !(position.latitude == 0 && position.longitude == 0) &&
        // 🎯 لو اللوكيشن جاي Cairo التحرير الافتراضي من الباك إند بنلغيه عشان نفتح على إسكندرية
        !((position.latitude - 30.0444).abs() < 0.001 &&
            (position.longitude - 31.2357).abs() < 0.001);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final routePoints = route
        .map(_toMapLatLng)
        .where(_isValidLatLng)
        .toList(growable: false);
   // 🗺️ لو مفيش نقاط خط سير، السنتر التلقائي هيبقى إسكندرية (محطة الرمل) بدال القاهرة
    final centerPosition = routePoints.isNotEmpty
        ? routePoints.first
        : LatLng(31.205753, 29.924526);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.rideSummary)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 180,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: centerPosition,
                    initialZoom: 15, // زووم مريح ومناسب لرؤية المدينة
                    initialCameraFit: routePoints.length > 1
                        ? CameraFit.coordinates(
                            coordinates: routePoints,
                            padding: const EdgeInsets.all(28),
                            maxZoom: 17,
                          )
                        : null,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.glider',
                    ),
                    // يرسم خط السير فقط لو معانا نقطتين أو أكتر
                    if (routePoints.length > 1)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: routePoints,
                            color: const Color(0xFF1FAE6C),
                            strokeWidth: 4,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        // 🚨 حماية: الماركر الأول هيظهر فقط لو اللستة مش فاضية عشان ميعملش كراش
                        if (routePoints.isNotEmpty)
                          Marker(
                            point: routePoints.first,
                            width: 34,
                            height: 34,
                            child: const Icon(
                              Icons.trip_origin,
                              color: Colors.blue,
                              size: 28,
                            ),
                          ),
                        if (routePoints.length > 1)
                          Marker(
                            point: routePoints.last,
                            width: 38,
                            height: 38,
                            child: const Icon(
                              Icons.flag,
                              color: Color(0xFF1FAE6C),
                              size: 32,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.rideComplete,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.scooter),
                        Text(
                          ride.scooterCode,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.time),
                        Text(
                          _formatDuration(l10n, ride.duration),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.distance),
                        Text(
                          l10n.distanceKm(ride.distanceKm.toStringAsFixed(1)),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.cost),
                        Text(
                          l10n.costEgp(ride.cost.toStringAsFixed(1)),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    if (remainingBalance != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.walletAfterRide),
                          Text(
                            l10n.costEgp(
                              remainingBalance!.toStringAsFixed(1),
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/map',
                    (route) => false,
                  );
                },
                child: Text(l10n.done),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
