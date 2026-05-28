import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:glider/presentation/cubits/profile_cubit.dart';
import 'package:glider/presentation/cubits/user_cubit.dart';
import 'package:glider/presentation/widgets/loading_spinner.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileCubit()..load(),
      child: BlocListener<ProfileCubit, ProfileState>(
        listener: (context, state) {
          _syncControllers(state);
          if (state.user != null) {
            context.read<UserCubit>().applyAuthenticatedUser(state.user!);
          }
          if (state.errorMessage != null &&
              state.status == ProfileStatus.failure) {
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
        child: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            final cubit = context.read<ProfileCubit>();
            final avatarProvider = _avatarProvider(state.avatarDataUrl);

            return Scaffold(
              appBar: AppBar(
                title: const Text('Profile'),
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
              body: state.status == ProfileStatus.loading
                  ? const LoadingSpinner(message: 'Loading profile...')
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 46,
                                    backgroundColor: const Color(0xFF1FAE6C)
                                        .withValues(alpha: 0.18),
                                    backgroundImage: avatarProvider,
                                    child: avatarProvider == null
                                        ? const Icon(
                                            Icons.person,
                                            size: 40,
                                            color: Color(0xFF1FAE6C),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    state.user?.name ?? '',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    state.user?.email ?? '',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              cubit.pickAvatar(ImageSource.camera),
                                          icon: const Icon(Icons.photo_camera_outlined),
                                          label: const Text('Camera'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => cubit.pickAvatar(
                                            ImageSource.gallery,
                                          ),
                                          icon: const Icon(Icons.photo_library_outlined),
                                          label: const Text('Gallery'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SectionCard(
                            title: 'Account Information',
                            child: Form(
                              key: _profileFormKey,
                              child: Column(
                                children: [
                                  _ProfileField(
                                    controller: _nameController,
                                    label: 'Full Name',
                                    icon: Icons.person_outline,
                                    onChanged: cubit.updateFullName,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter your name.';
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  const SizedBox(height: 14),
                                  _ProfileField(
                                    controller: _phoneController,
                                    label: 'Phone Number',
                                    icon: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone,
                                    onChanged: cubit.updatePhone,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter your phone number.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 18),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: state.status == ProfileStatus.saving
                                          ? null
                                          : () async {
                                              if (_profileFormKey.currentState
                                                      ?.validate() ??
                                                  false) {
                                                await cubit.saveProfile();
                                              }
                                            },
                                      child: state.status == ProfileStatus.saving
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text('Save profile'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SectionCard(
                            title: 'Security',
                            child: Form(
                              key: _passwordFormKey,
                              child: Column(
                                children: [
                                  _ProfileField(
                                    controller: _currentPasswordController,
                                    label: 'Current Password',
                                    icon: Icons.lock_outline,
                                    obscureText: true,
                                    onChanged: cubit.updateCurrentPassword,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Enter your current password.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  _ProfileField(
                                    controller: _newPasswordController,
                                    label: 'New Password',
                                    icon: Icons.lock_reset_outlined,
                                    obscureText: true,
                                    onChanged: cubit.updateNewPassword,
                                    validator: (value) {
                                      if (value == null || value.length < 8) {
                                        return 'New password must be at least 8 characters.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  _ProfileField(
                                    controller: _confirmPasswordController,
                                    label: 'Confirm New Password',
                                    icon: Icons.lock_outline,
                                    obscureText: true,
                                    onChanged: cubit.updateConfirmPassword,
                                    validator: (value) {
                                      if (value != _newPasswordController.text) {
                                        return 'Passwords do not match.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 18),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: state.status ==
                                              ProfileStatus.changingPassword
                                          ? null
                                          : () async {
                                              if (_passwordFormKey.currentState
                                                      ?.validate() ??
                                                  false) {
                                                await cubit.changePassword();
                                              }
                                            },
                                      child: state.status ==
                                              ProfileStatus.changingPassword
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text('Update password'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }

  void _syncControllers(ProfileState state) {
    _syncController(_nameController, state.fullName);
    _syncController(_emailController, state.email);
    _syncController(_phoneController, state.phone);
    _syncController(_currentPasswordController, state.currentPassword);
    _syncController(_newPasswordController, state.newPassword);
    _syncController(_confirmPasswordController, state.confirmPassword);
  }

  void _syncController(TextEditingController controller, String value) {
    if (controller.text == value) {
      return;
    }
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  ImageProvider<Object>? _avatarProvider(String? avatarDataUrl) {
    if (avatarDataUrl == null || avatarDataUrl.isEmpty) {
      return null;
    }
    if (avatarDataUrl.startsWith('data:image')) {
      final encoded = avatarDataUrl.split(',').last;
      return MemoryImage(base64Decode(encoded));
    }
    return NetworkImage(avatarDataUrl);
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.onChanged,
    required this.validator,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final FormFieldValidator<String> validator;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      onChanged: onChanged,
      validator: validator,
    );
  }
}
