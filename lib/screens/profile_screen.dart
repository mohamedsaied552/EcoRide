import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/backend_service.dart';
import '../widgets/loading_spinner.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final BackendService _service = BackendService();
  AppUser? _user;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = await _service.fetchCurrentUser();
      if (!mounted) return;
      setState(() {
        _user = user;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _error != null
            ? Center(child: Text(_error!))
            : _user == null
                ? const LoadingSpinner(message: 'Loading profile...')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: const Color(0xFF1FAE6C)
                                    .withValues(alpha: 0.18),
                                child: const Icon(
                                  Icons.person,
                                  color: Color(0xFF1FAE6C),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _user!.name,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(_user!.email),
                                    const SizedBox(height: 4),
                                    Text(_user!.accountStatus ?? 'Account status unavailable'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.phone),
                          title: const Text('Phone'),
                          subtitle: Text(_user!.phone),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.verified_user_outlined),
                          title: const Text('Verification'),
                          subtitle: Text(
                            _user!.idVerificationStatus ?? 'Pending review',
                          ),
                          trailing: Icon(
                            _user!.phoneVerified
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: _user!.phoneVerified ? Colors.green : Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.directions_bike),
                          title: const Text('Total rides'),
                          subtitle: Text('${_user!.ridesCount} rides'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.star),
                          title: const Text('Rating'),
                          subtitle: Text('${_user!.rating}'),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
