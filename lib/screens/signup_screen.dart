import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../cubits/register_cubit.dart';
import '../cubits/user_cubit.dart';
import '../services/backend_service.dart';
import '../widgets/id_upload_card.dart';
import '../widgets/register_progress_indicator.dart';
import 'admin_screen.dart';
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
          if (state.submissionStatus == RegisterSubmissionStatus.success &&
              state.createdUser != null) {
            context.read<UserCubit>().applyAuthenticatedUser(state.createdUser!);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account created successfully'),
                backgroundColor: Color(0xFF1FAE6C),
              ),
            );
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    state.createdUser!.isAdmin ? const AdminScreen() : const MapScreen(),
              ),
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
            final cubit = context.read<RegisterCubit>();
            _syncControllers(state);

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
                            ? 'Create your rider profile'
                            : 'Upload both sides of your ID',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontSize: 28,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.currentStep == RegisterStep.details
                            ? 'We will use these details to create your account and keep your rides secure.'
                            : 'Make sure both images are sharp, readable, and fully visible.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          'Testing against: ${BackendService.baseUrl}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                                color: const Color(0xFF0F7A52),
                              ),
                        ),
                      ),
                      const SizedBox(height: 20),
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
                              'Continue to Verification',
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
            children: [
              _RegistrationField(
                controller: nameController,
                label: 'Full Name',
                hint: 'Enter your full legal name',
                icon: Icons.person_outline,
                onChanged: cubit.updateFullName,
                textInputAction: TextInputAction.next,
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
              const SizedBox(height: 16),
              _RegistrationField(
                controller: emailController,
                label: 'Email',
                hint: 'Enter your email address',
                icon: Icons.email_outlined,
                onChanged: cubit.updateEmail,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
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
              const SizedBox(height: 16),
              _RegistrationField(
                controller: phoneController,
                label: 'Phone Number',
                hint: 'Enter your mobile number',
                icon: Icons.phone_outlined,
                onChanged: cubit.updatePhoneNumber,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.phone,
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
              const SizedBox(height: 16),
              _RegistrationField(
                controller: passwordController,
                label: 'Password',
                hint: 'Create a strong password',
                icon: Icons.lock_outline,
                onChanged: cubit.updatePassword,
                textInputAction: TextInputAction.next,
                obscureText: state.isPasswordObscured,
                suffixIcon: IconButton(
                  onPressed: cubit.togglePasswordVisibility,
                  icon: Icon(
                    state.isPasswordObscured
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
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
              const SizedBox(height: 16),
              _RegistrationField(
                controller: confirmPasswordController,
                label: 'Confirm Password',
                hint: 'Re-enter your password',
                icon: Icons.lock_outline,
                onChanged: cubit.updateConfirmPassword,
                obscureText: state.isConfirmPasswordObscured,
                suffixIcon: IconButton(
                  onPressed: cubit.toggleConfirmPasswordVisibility,
                  icon: Icon(
                    state.isConfirmPasswordObscured
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
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
          child: const Text(
            'Upload both the front and back of your national ID before submitting your registration.',
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Front side',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        IdUploadCard(
          imageBytes: state.frontIdBytes,
          fileName: state.frontIdName,
          errorText: state.imageError != null && !state.hasFrontId
              ? state.imageError
              : null,
          onCameraTap: () => cubit.pickIdImage(
            side: RegisterImageSide.front,
            source: ImageSource.camera,
          ),
          onGalleryTap: () => cubit.pickIdImage(
            side: RegisterImageSide.front,
            source: ImageSource.gallery,
          ),
          onClear: () => cubit.clearSelectedIdImage(RegisterImageSide.front),
        ),
        const SizedBox(height: 20),
        Text(
          'Back side',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        IdUploadCard(
          imageBytes: state.backIdBytes,
          fileName: state.backIdName,
          errorText: state.imageError != null && !state.hasBackId
              ? state.imageError
              : null,
          onCameraTap: () => cubit.pickIdImage(
            side: RegisterImageSide.back,
            source: ImageSource.camera,
          ),
          onGalleryTap: () => cubit.pickIdImage(
            side: RegisterImageSide.back,
            source: ImageSource.gallery,
          ),
          onClear: () => cubit.clearSelectedIdImage(RegisterImageSide.back),
        ),
      ],
    );
  }
}

class _RegistrationField extends StatelessWidget {
  const _RegistrationField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.onChanged,
    required this.validator,
    this.textInputAction = TextInputAction.next,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final FormFieldValidator<String> validator;
  final TextInputAction textInputAction;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
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
      ),
      onChanged: onChanged,
      validator: validator,
    );
  }
}
