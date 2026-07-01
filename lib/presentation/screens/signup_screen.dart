import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zakzouka/l10n/app_localizations.dart';
import 'package:zakzouka/presentation/cubits/register_cubit.dart';
import 'package:zakzouka/presentation/utils/register_flow_utils.dart';
import 'package:zakzouka/presentation/utils/phone_utils.dart';
import 'package:zakzouka/presentation/widgets/country_code_picker.dart';
import 'package:zakzouka/presentation/widgets/register_progress_indicator.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
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
        listener: handleRegisterSubmission,
        child: BlocBuilder<RegisterCubit, RegisterState>(
          builder: (context, state) {
            final cubit = context.read<RegisterCubit>();
            final l10n = AppLocalizations.of(context);
            _syncControllers(state);

            final isSendingOtp =
                state.submissionStatus == RegisterSubmissionStatus.sendingOtp;

            return Scaffold(
              appBar: AppBar(
                title: Text(l10n.createAccount),
                backgroundColor: Colors.transparent,
                elevation: 0,
                foregroundColor: const Color(0xFF1F2937),
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.createRiderProfile,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontSize: 28),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.createAccountSubtitle,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        const RegisterProgressIndicator(currentStep: 1),
                        const SizedBox(height: 28),
                        _RegistrationField(
                          controller: _nameController,
                          label: l10n.fullName,
                          hint: l10n.enterFullLegalName,
                          icon: Icons.person_outline,
                          onChanged: cubit.updateFullName,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return l10n.pleaseEnterFullName;
                            }
                            if (value.trim().length < 3) {
                              return l10n.nameMin3;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 120,
                              child: CountryCodePicker(
                                selected: state.country,
                                onChanged: cubit.updateCountry,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _RegistrationField(
                                controller: _phoneController,
                                label: l10n.phoneNumber,
                                hint: l10n.phoneHintLocal,
                                icon: Icons.phone_outlined,
                                onChanged: cubit.updateLocalPhoneNumber,
                                textInputAction: TextInputAction.next,
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  final error = state.country.dialCode ==
                                          CountryDialCode.egypt.dialCode
                                      ? PhoneUtils.validateEgyptLocalNumber(
                                          value ?? '',
                                        )
                                      : (PhoneUtils.digitsOnly(value ?? '')
                                                .length <
                                            state.country.localDigits
                                        ? 'invalidLength'
                                        : null);
                                  if (error != null) {
                                    return localizePhoneValidationError(
                                      l10n,
                                      error,
                                    );
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _RegistrationField(
                          controller: _passwordController,
                          label: l10n.password,
                          hint: l10n.createStrongPassword,
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
                              return l10n.pleaseEnterPasswordField;
                            }
                            if (password.length < 8) {
                              return l10n.passwordMin8;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _RegistrationField(
                          controller: _confirmPasswordController,
                          label: l10n.confirmPassword,
                          hint: l10n.reenterPassword,
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
                              return l10n.pleaseConfirmPassword;
                            }
                            if (value != _passwordController.text) {
                              return l10n.passwordsDoNotMatch;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: isSendingOtp
                                ? null
                                : () async {
                                    if (_formKey.currentState?.validate() ??
                                        false) {
                                      await cubit.startPhoneVerification();
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1FAE6C),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: isSendingOtp
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    l10n.continueToVerification,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          l10n.termsAgreement,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                fontSize: 12,
                                color: const Color(0xFF667085),
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n.alreadyHaveAccount),
                        ),
                      ],
                    ),
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
    _syncController(_phoneController, state.localPhoneNumber);
    _syncController(_passwordController, state.password);
    _syncController(_confirmPasswordController, state.confirmPassword);
  }

  void _syncController(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
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
