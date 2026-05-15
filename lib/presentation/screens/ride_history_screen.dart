import 'package:flutter/material.dart';
import 'package:glider/domain/entities/ride.dart';
import '../../data/repositories/backend_service.dart';
import 'package:glider/presentation/widgets/loading_spinner.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  final BackendService _service = BackendService();
  List<Ride> _rides = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rides = await _service.fetchRideHistory();
    if (!mounted) return;
    setState(() {
      _rides = rides;
      _loading = false;
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ride History")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _loading
            ? const LoadingSpinner(message: 'Loading rides...')
            : ListView.separated(
                itemCount: _rides.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final ride = _rides[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.electric_scooter),
                      title: Text('Scooter ${ride.scooterCode}'),
                      subtitle: Text('${ride.fromName} ? ${ride.toName}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${ride.cost.toStringAsFixed(1)} EGP'),
                          Text(_formatDuration(ride.duration)),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
