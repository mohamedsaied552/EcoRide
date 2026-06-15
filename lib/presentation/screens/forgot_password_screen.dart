import 'package:flutter/material.dart';

import 'package:glider/data/datasources/firebase_auth_service.dart';
import 'package:glider/l10n/app_localizations.dart';
import 'package:glider/presentation/cubits/verify_otp_cubit.dart';
import 'package:glider/presentation/screens/verify_otp_screen.dart';
import 'package:glider/presentation/utils/firebase_auth_error_utils.dart';
import 'package:glider/presentation/utils/phone_utils.dart';
import 'package:glider/presentation/utils/register_flow_utils.dart';
import 'package:glider/presentation/widgets/country_code_picker.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _firebaseAuthService = FirebaseAuthService();

  CountryDialCode _country = CountryDialCode.egypt;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final phoneNumber = PhoneUtils.toInternational(
      dialCode: _country.dialCode,
      localNumber: _phoneController.text,
    );

    try {
      final session = await _firebaseAuthService.verifyPhoneNumber(phoneNumber);
      if (!mounted) return;

      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyOtpScreen(
            phoneNumber: phoneNumber,
            flow: VerifyOtpFlow.forgotPassword,
            verificationId: session.verificationId,
            forceResendingToken: session.forceResendingToken,
          ),
        ),
      );
    } on FirebaseAuthFailure catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizeFirebaseAuthError(
              AppLocalizations.of(context),
              error.code,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.forgotPassword),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF1F2937),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.forgotPasswordSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: CountryCodePicker(
                        selected: _country,
                        onChanged: (value) => setState(() => _country = value),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: l10n.phoneNumber,
                          hintText: l10n.phoneHintLocal,
                          prefixIcon: const Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        validator: (value) {
                          final error = _country.dialCode ==
                                  CountryDialCode.egypt.dialCode
                              ? PhoneUtils.validateEgyptLocalNumber(value ?? '')
                              : (PhoneUtils.digitsOnly(value ?? '').length <
                                        _country.localDigits
                                    ? 'invalidLength'
                                    : null);
                          if (error != null) {
                            return localizePhoneValidationError(l10n, error);
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1FAE6C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(l10n.sendOtp),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
