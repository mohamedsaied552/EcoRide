import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:glider/l10n/app_localizations.dart';
import 'package:glider/presentation/cubits/login_cubit.dart';
import 'package:glider/presentation/cubits/verify_otp_cubit.dart';
import 'package:glider/presentation/utils/firebase_auth_error_utils.dart';
import 'package:glider/presentation/utils/phone_utils.dart';
import 'package:glider/presentation/utils/register_flow_utils.dart';
import 'package:glider/data/datasources/firebase_auth_service.dart';
import 'package:glider/presentation/screens/forgot_password_screen.dart';
import 'package:glider/presentation/screens/verify_otp_screen.dart';
import 'package:glider/presentation/widgets/country_code_picker.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final loginCubit = context.read<LoginCubit>();
    final sent = await loginCubit.sendOtp();

    if (!mounted || !sent) return;

    final session = loginCubit.state.verificationSession;
    if (session == null) return;

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => VerifyOtpScreen(
          phoneNumber: loginCubit.state.internationalPhoneNumber,
          flow: VerifyOtpFlow.login,
          password: loginCubit.state.password,
          verificationId: session.verificationId,
          forceResendingToken: session.forceResendingToken,
        ),
      ),
    );

    if (mounted) {
      loginCubit.setIdle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocProvider(
      create: (_) => LoginCubit(),
      child: BlocConsumer<LoginCubit, LoginState>(
        listenWhen: (previous, current) =>
            previous.errorMessage != current.errorMessage &&
            current.errorMessage != null,
        listener: (context, state) {
          if (state.status == LoginStatus.failure &&
              state.errorMessage != null) {
            final phoneError = localizePhoneValidationError(
              l10n,
              state.errorMessage,
            );
            final errorCode = FirebaseAuthErrorCode.values.asNameMap()[
              state.errorMessage!];
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  errorCode != null
                      ? localizeFirebaseAuthError(l10n, errorCode)
                      : phoneError,
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, loginState) {
          final loginCubit = context.read<LoginCubit>();

          return Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      Center(
                        child: Container(
                          height: 84,
                          width: 84,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF1FAE6C,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: const Icon(
                            Icons.electric_scooter,
                            size: 48,
                            color: Color(0xFF1FAE6C),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.welcomeBack,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontSize: 28),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.signInWithPhoneSubtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 120,
                            child: CountryCodePicker(
                              selected: loginState.country,
                              onChanged: loginCubit.updateCountry,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              onChanged: loginCubit.updateLocalPhoneNumber,
                              decoration: _inputDecoration(
                                label: l10n.phoneNumber,
                                hint: l10n.phoneHintLocal,
                                icon: Icons.phone_outlined,
                              ),
                              validator: (value) {
                                final error =
                                    loginState.country.dialCode ==
                                        CountryDialCode.egypt.dialCode
                                    ? PhoneUtils.validateEgyptLocalNumber(
                                        value ?? '',
                                      )
                                    : (PhoneUtils.digitsOnly(value ?? '')
                                              .length <
                                          loginState.country.localDigits
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
                      TextFormField(
                        controller: _passwordController,
                        obscureText: loginState.isPasswordObscured,
                        textInputAction: TextInputAction.done,
                        onChanged: loginCubit.updatePassword,
                        onFieldSubmitted: (_) => _submitLogin(context),
                        decoration:
                            _inputDecoration(
                              label: l10n.password,
                              hint: l10n.enterPassword,
                              icon: Icons.lock_outlined,
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  loginState.isPasswordObscured
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed:
                                    loginCubit.togglePasswordVisibility,
                              ),
                            ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.pleaseEnterPassword;
                          }
                          if (value.length < 6) {
                            return l10n.passwordMin6;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: Text(
                            l10n.forgotPassword,
                            style: const TextStyle(color: Color(0xFF1FAE6C)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: loginState.status == LoginStatus.loading
                              ? null
                              : () => _submitLogin(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1FAE6C),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: loginState.status == LoginStatus.loading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                  ),
                                )
                              : Text(
                                  l10n.sendOtp,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.dontHaveAccount,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SignupScreen(),
                                ),
                              );
                            },
                            child: Text(
                              l10n.signUp,
                              style: const TextStyle(
                                color: Color(0xFF1FAE6C),
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
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
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF1FAE6C), width: 2),
    ),
    filled: true,
    fillColor: Colors.white,
  );
}
