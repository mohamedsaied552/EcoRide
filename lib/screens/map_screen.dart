import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/scooter.dart';
import '../services/backend_service.dart';
import '../widgets/loading_spinner.dart';
import '../widgets/map_marker.dart';
import 'qr_scan_screen.dart';
import 'wallet_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  final LatLng _center = const LatLng(30.0444, 31.2357);
  late final BackendService _service;
  List<Scooter> _scooters = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service = BackendService();
    _load();
  }

  Future<void> _load() async {
    try {
      final scooters = await _service.fetchNearbyScooters();
      if (!mounted) return;
      setState(() {
        _scooters = scooters;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final markers = _scooters
        .where((scooter) => scooter.isAvailable)
        .map(
          (scooter) => Marker(
            markerId: MarkerId(scooter.id),
            position: LatLng(scooter.lat, scooter.lng),
            infoWindow: InfoWindow(title: scooter.code),
          ),
        )
        .toSet();

    final availableScooters = _scooters
        .where((scooter) => scooter.isAvailable)
        .toList();

    final mapWidget = kIsWeb
        ? Container(
            color: const Color(0xFFEFF4F1),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.map_outlined, size: 48, color: Color(0xFF1FAE6C)),
                SizedBox(height: 8),
                Text('Map preview is not available on Web'),
              ],
            ),
          )
        : GoogleMap(
            onMapCreated: (controller) => mapController = controller,
            initialCameraPosition: CameraPosition(target: _center, zoom: 14.0),
            markers: markers,
            myLocationButtonEnabled: false,
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Scooters'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WalletScreen()),
              );
            },
            icon: const Icon(Icons.account_balance_wallet_outlined),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F7A52), Color(0xFF1FAE6C)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Text(
                    'Smart Scooter',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Ride dashboard',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Ride history'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/history');
              },
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('Admin'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/admin');
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          mapWidget,
          if (_loading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0xAAFFFFFF),
                child: LoadingSpinner(message: 'Finding nearby scooters...'),
              ),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Available scooters',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    if (availableScooters.isEmpty && !_loading)
                      Text(
                        'No scooters nearby. Try a different area.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      )
                    else
                      ...availableScooters.take(2).map(
                        (scooter) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1FAE6C).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.electric_scooter,
                                  color: Color(0xFF1FAE6C),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      scooter.code,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      scooter.locationName,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              ScooterStatusChip(
                                batteryPercent: scooter.batteryPercent,
                                available: scooter.isAvailable,
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.qr_code),
                        label: const Text('Scan to unlock'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const QRScanScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
