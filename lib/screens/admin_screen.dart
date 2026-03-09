import 'package:flutter/material.dart';
import '../models/scooter.dart';
import '../services/firebase_service.dart';
import '../widgets/loading_spinner.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final FirebaseService _service = FirebaseService();
  List<Scooter> _scooters = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final scooters = await _service.fetchNearbyScooters();
    if (!mounted) return;
    setState(() {
      _scooters = scooters;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _loading
            ? const LoadingSpinner(message: 'Loading fleet...')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total scooters'),
                          Text('${_scooters.length}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _scooters.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final scooter = _scooters[index];
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              scooter.isAvailable
                                  ? Icons.check_circle
                                  : Icons.remove_circle,
                              color: scooter.isAvailable
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            title: Text(scooter.code),
                            subtitle: Text(
                              '${scooter.locationName} • ${scooter.batteryPercent}% battery',
                            ),
                            trailing: Text(
                              scooter.isAvailable ? 'Available' : 'Offline',
                            ),
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
      ),
    );
  }
}
