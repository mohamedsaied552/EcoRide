import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../cubits/register_cubit.dart';
import '../widgets/id_upload_card.dart';
import '../widgets/register_progress_indicator.dart';
import 'map_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RegisterCubit(),
      child: BlocListener<RegisterCubit, RegisterState>(
        listenWhen: (previous, current) =>
            previous.submissionStatus != current.submissionStatus,
        listener: (context, state) {
          if (state.submissionStatus == RegisterSubmissionStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account created successfully'),
                backgroundColor: Color(0xFF1FAE6C),
              ),
            );
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MapScreen()),
              (route) => false,
            );
          }

          if (state.submissionStatus == RegisterSubmissionStatus.failure &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<RegisterCubit, RegisterState>(
          builder: (context, state) {
            _syncControllers(state);
            final cubit = context.read<RegisterCubit>();

            return Scaffold(
              appBar: AppBar(
                title: const Text('Create Account'),
                backgroundColor: Colors.transparent,
                elevation: 0,
                foregroundColor: const Color(0xFF1F2937),
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        state.currentStep == RegisterStep.details
                            ? 'Tell us about yourself'
                            : 'Verify your identity',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontSize: 28,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.currentStep == RegisterStep.details
                            ? 'Start with your account details, then upload your national ID.'
                            : 'Upload a clear image of your ID to finish registration.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      RegisterProgressIndicator(
                        currentStep:
                            state.currentStep == RegisterStep.details ? 1 : 2,
                      ),
                      const SizedBox(height: 28),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        child: state.currentStep == RegisterStep.details
                            ? _DetailsStep(
                                key: const ValueKey('details-step'),
                                formKey: _formKey,
                                nameController: _nameController,
                                emailController: _emailController,
                                phoneController: _phoneController,
                                passwordController: _passwordController,
                                confirmPasswordController:
                                    _confirmPasswordController,
                              )
                            : _IdStep(
                                key: const ValueKey('id-step'),
                                state: state,
                              ),
                      ),
                      const SizedBox(height: 28),
                      if (state.currentStep == RegisterStep.details)
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: state.submissionStatus ==
                                    RegisterSubmissionStatus.loading
                                ? null
                                : () {
                                    if (_formKey.currentState?.validate() ??
                                        false) {
                                      cubit.continueToIdStep();
                                    }
                                  },
                            style: _primaryButtonStyle(),
                            child: const Text(
                              'Continue to ID Verification',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 54,
                                child: OutlinedButton(
                                  onPressed: state.submissionStatus ==
                                          RegisterSubmissionStatus.loading
                                      ? null
                                      : cubit.goBackToDetails,
                                  child: const Text('Back'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: SizedBox(
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: state.submissionStatus ==
                                          RegisterSubmissionStatus.loading
                                      ? null
                                      : cubit.submitRegistration,
                                  style: _primaryButtonStyle(),
                                  child: state.submissionStatus ==
                                          RegisterSubmissionStatus.loading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : const Text(
                                          'Create Account',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 18),
                      Text(
                        'By signing up, you agree to our Terms of Service and Privacy Policy.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              color: const Color(0xFF667085),
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Already have an account? Sign in'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _syncControllers(RegisterState state) {
    _syncController(_nameController, state.fullName);
    _syncController(_emailController, state.email);
    _syncController(_phoneController, state.phoneNumber);
    _syncController(_passwordController, state.password);
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

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF1FAE6C),
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.confirmPasswordController,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegisterCubit, RegisterState>(
      builder: (context, state) {
        final cubit = context.read<RegisterCubit>();
        return Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FieldShell(
                child: TextFormField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(
                    label: 'Full Name',
                    hint: 'Enter your full legal name',
                    icon: Icons.person_outline,
                  ),
                  onChanged: cubit.updateFullName,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your full name.';
                    }
                    if (value.trim().length < 3) {
                      return 'Name must be at least 3 characters.';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              _FieldShell(
                child: TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    label: 'Email',
                    hint: 'Enter your email address',
                    icon: Icons.email_outlined,
                  ),
                  onChanged: cubit.updateEmail,
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (email.isEmpty) {
                      return 'Please enter your email.';
                    }
                    if (!pattern.hasMatch(email)) {
                      return 'Please enter a valid email address.';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              _FieldShell(
                child: TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    label: 'Phone Number',
                    hint: 'Enter your mobile number',
                    icon: Icons.phone_outlined,
                  ),
                  onChanged: cubit.updatePhoneNumber,
                  validator: (value) {
                    final phone = value?.replaceAll(RegExp(r'\s+'), '') ?? '';
                    if (phone.isEmpty) {
                      return 'Please enter your phone number.';
                    }
                    if (phone.length < 10) {
                      return 'Phone number looks too short.';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              _FieldShell(
                child: TextFormField(
                  controller: passwordController,
                  obscureText: state.isPasswordObscured,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    label: 'Password',
                    hint: 'Create a strong password',
                    icon: Icons.lock_outline,
                  ).copyWith(
                    suffixIcon: IconButton(
                      onPressed: cubit.togglePasswordVisibility,
                      icon: Icon(
                        state.isPasswordObscured
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  onChanged: cubit.updatePassword,
                  validator: (value) {
                    final password = value ?? '';
                    if (password.isEmpty) {
                      return 'Please enter a password.';
                    }
                    if (password.length < 8) {
                      return 'Password must be at least 8 characters.';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              _FieldShell(
                child: TextFormField(
                  controller: confirmPasswordController,
                  obscureText: state.isConfirmPasswordObscured,
                  textInputAction: TextInputAction.done,
                  decoration: _inputDecoration(
                    label: 'Confirm Password',
                    hint: 'Re-enter your password',
                    icon: Icons.lock_outline,
                  ).copyWith(
                    suffixIcon: IconButton(
                      onPressed: cubit.toggleConfirmPasswordVisibility,
                      icon: Icon(
                        state.isConfirmPasswordObscured
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  onChanged: cubit.updateConfirmPassword,
                  validator: (value) {
                    if ((value ?? '').isEmpty) {
                      return 'Please confirm your password.';
                    }
                    if (value != passwordController.text) {
                      return 'Passwords do not match.';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IdStep extends StatelessWidget {
  const _IdStep({
    required this.state,
    super.key,
  });

  final RegisterState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RegisterCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x141FAE6C),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: Color(0xFF1FAE6C),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Make sure your ID is fully visible, readable, and free from glare before uploading.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        IdUploadCard(
          imageBytes: state.idImageBytes,
          fileName: state.idImageName,
          errorText: state.imageError,
          onCameraTap: () => cubit.pickIdImage(ImageSource.camera),
          onGalleryTap: () => cubit.pickIdImage(ImageSource.gallery),
          onClear: cubit.clearSelectedIdImage,
        ),
      ],
    );
  }
}

class _FieldShell extends StatelessWidget {
  const _FieldShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A101828),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

InputDecoration _inputDecoration({
  required String label,
  required String hint,
  required IconData icon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFF1FAE6C), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFEF4444)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
    ),
  );
}
