import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:glider/presentation/cubits/admin_cubit.dart';
import 'package:glider/presentation/cubits/user_cubit.dart';
import 'package:glider/domain/entities/user.dart';
import 'package:glider/presentation/widgets/loading_spinner.dart';
import 'login_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _codeController = TextEditingController();
  final _modelIdController = TextEditingController();
  final _locationController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _batteryController = TextEditingController(text: '100');

  @override
  void dispose() {
    _codeController.dispose();
    _modelIdController.dispose();
    _locationController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _batteryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserCubit, UserState>(
      builder: (context, userState) {
        if (!userState.isAdmin) {
          return Scaffold(
            appBar: AppBar(title: const Text('Admin Panel')),
            body: const Center(
              child: Text('Only admin users can access this panel.'),
            ),
          );
        }

        return BlocProvider(
          create: (_) => AdminCubit()..load(),
          child: BlocListener<AdminCubit, AdminState>(
            listener: (context, state) {
              _syncControllers(state);
              if (state.errorMessage != null &&
                  state.status == AdminStatus.failure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage!),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              if (state.successMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.successMessage!),
                    backgroundColor: const Color(0xFF1FAE6C),
                  ),
                );
              }
            },
            child: DefaultTabController(
              length: 2,
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('Admin Panel'),
                  bottom: const TabBar(
                    tabs: [
                      Tab(text: 'Users'),
                      Tab(text: 'Scooters'),
                    ],
                  ),
                  actions: [
                    TextButton.icon(
                      onPressed: () async {
                        await context.read<UserCubit>().logout();
                        if (!context.mounted) {
                          return;
                        }
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                    ),
                  ],
                ),
                body: BlocBuilder<AdminCubit, AdminState>(
                  builder: (context, state) {
                    if (state.status == AdminStatus.loading &&
                        state.users.isEmpty &&
                        state.scooters.isEmpty) {
                      return const LoadingSpinner(message: 'Loading admin data...');
                    }

                    return TabBarView(
                      children: [
                        _UsersTab(users: state.users),
                        _ScootersTab(
                          state: state,
                          codeController: _codeController,
                          modelIdController: _modelIdController,
                          locationController: _locationController,
                          latController: _latController,
                          lngController: _lngController,
                          batteryController: _batteryController,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _syncControllers(AdminState state) {
    _sync(_codeController, state.code);
    _sync(_modelIdController, state.modelId);
    _sync(_locationController, state.locationName);
    _sync(_latController, state.lat);
    _sync(_lngController, state.lng);
    _sync(_batteryController, state.batteryPercent);
  }

  void _sync(TextEditingController controller, String value) {
    if (controller.text == value) {
      return;
    }
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab({required this.users});

  final List<AppUser> users;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const Center(child: Text('No registered users yet.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: users.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text(user.name.isEmpty ? '?' : user.name[0].toUpperCase()),
            ),
            title: Text(user.name),
            subtitle: Text('${user.email}\n${user.phone}'),
            isThreeLine: true,
            trailing: Chip(label: Text(user.role.name)),
          ),
        );
      },
    );
  }
}

class _ScootersTab extends StatelessWidget {
  const _ScootersTab({
    required this.state,
    required this.codeController,
    required this.modelIdController,
    required this.locationController,
    required this.latController,
    required this.lngController,
    required this.batteryController,
  });

  final AdminState state;
  final TextEditingController codeController;
  final TextEditingController modelIdController;
  final TextEditingController locationController;
  final TextEditingController latController;
  final TextEditingController lngController;
  final TextEditingController batteryController;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AdminCubit>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.isEditing ? 'Edit scooter' : 'Add scooter',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: codeController,
                    decoration: const InputDecoration(labelText: 'Scooter code'),
                    onChanged: cubit.updateCode,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: modelIdController,
                    decoration: const InputDecoration(labelText: 'Model ID'),
                    onChanged: cubit.updateModelId,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: 'Location'),
                    onChanged: cubit.updateLocationName,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: latController,
                          decoration: const InputDecoration(labelText: 'Latitude'),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          onChanged: cubit.updateLat,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: lngController,
                          decoration: const InputDecoration(labelText: 'Longitude'),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          onChanged: cubit.updateLng,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: batteryController,
                          decoration:
                              const InputDecoration(labelText: 'Battery %'),
                          keyboardType: TextInputType.number,
                          onChanged: cubit.updateBatteryPercent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: state.isAvailable,
                          title: const Text('Available'),
                          onChanged: cubit.updateAvailability,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: cubit.clearForm,
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: state.status == AdminStatus.saving
                              ? null
                              : cubit.saveScooter,
                          child: state.status == AdminStatus.saving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(state.isEditing ? 'Save changes' : 'Add scooter'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...state.scooters.map(
            (scooter) => Card(
              child: ListTile(
                leading: Icon(
                  scooter.isAvailable
                      ? Icons.check_circle
                      : Icons.remove_circle,
                  color: scooter.isAvailable ? Colors.green : Colors.grey,
                ),
                title: Text(scooter.code),
                subtitle: Text(
                  '${scooter.locationName}\n${scooter.batteryPercent}% battery',
                ),
                isThreeLine: true,
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      onPressed: () => cubit.startEditing(scooter),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      onPressed: () => cubit.deleteScooter(scooter.id),
                      icon: const Icon(Icons.delete_outline),
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
