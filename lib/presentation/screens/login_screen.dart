import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'package:glider/presentation/cubits/login_cubit.dart';
import 'package:glider/presentation/cubits/user_cubit.dart';
import 'package:glider/core/notifications/notification_manager.dart';
import '../../data/repositories/backend_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _forgotPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _forgotPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final loginCubit = context.read<LoginCubit>();
    final userCubit = context.read<UserCubit>();
    loginCubit.setLoading();

    final user = await userCubit.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    if (user == null) {
      loginCubit.setFailure(userCubit.state.errorMessage ?? 'Login failed.');
      return;
    }

    loginCubit.setIdle();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Login successful'),
        backgroundColor: Color(0xFF1FAE6C),
      ),
    );

    if (!mounted) {
      return;
    }

    navigator.pushNamedAndRemoveUntil('/map', (route) => false);

    // Initialize notifications in the background after navigation so the UI
    // can move to the home page immediately.
    _initializeNotifications();
  }

  /// Initialize NotificationManager after successful login
  /// This ensures the user has a valid JWT token before requesting notification permissions
  Future<void> _initializeNotifications() async {
    try {
      final notificationManager = GetIt.I<NotificationManager>();
      await notificationManager.initialize();
      debugPrint('Notifications initialized successfully after login.');
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
      // Non-blocking error - notifications failure shouldn't prevent app usage
    }
  }

  Future<void> _showForgotPasswordDialog(BuildContext context) async {
    final backendService = BackendService();
    final messenger = ScaffoldMessenger.of(context);
    _forgotPasswordController.text = _emailController.text.trim();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset password'),
          content: TextField(
            controller: _forgotPasswordController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your account email',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await backendService.forgotPassword(
                    _forgotPasswordController.text.trim(),
                  );
                  if (!dialogContext.mounted) {
                    return;
                  }
                  Navigator.of(dialogContext).pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Reset instructions sent successfully.'),
                      backgroundColor: Color(0xFF1FAE6C),
                    ),
                  );
                } catch (error) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('$error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginCubit(),
      child: BlocListener<UserCubit, UserState>(
        listenWhen: (previous, current) =>
            previous.errorMessage != current.errorMessage &&
            current.errorMessage != null,
        listener: (context, state) {
          if (state.errorMessage != null &&
              state.status == UserStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<LoginCubit, LoginState>(
          builder: (context, loginState) {
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
                          'Welcome Back',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(fontSize: 28),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to ride or manage your fleet.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        // Container(
                        //   padding: const EdgeInsets.all(14),
                        //   decoration: BoxDecoration(
                        //     color: const Color(0xFFF8FAFC),
                        //     borderRadius: BorderRadius.circular(16),
                        //     border: Border.all(color: const Color(0xFFE2E8F0)),
                        //   ),
                        //   child: Text(
                        //     'API URL: ${BackendService.baseUrl}',
                        //     style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        //           fontSize: 12,
                        //           color: const Color(0xFF0F7A52),
                        //         ),
                        //   ),
                        // ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(
                            label: 'Email',
                            hint: 'Enter your email',
                            icon: Icons.email_outlined,
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            final pattern = RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            );
                            if (email.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!pattern.hasMatch(email)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: loginState.isPasswordObscured,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submitLogin(context),
                          decoration:
                              _inputDecoration(
                                label: 'Password',
                                hint: 'Enter your password',
                                icon: Icons.lock_outlined,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    loginState.isPasswordObscured
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: context
                                      .read<LoginCubit>()
                                      .togglePasswordVisibility,
                                ),
                              ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _showForgotPasswordDialog(context),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(color: Color(0xFF1FAE6C)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
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
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            const Expanded(
                              child: Divider(color: Color(0xFFE2E8F0)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(color: Color(0xFFE2E8F0)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Google sign-in is not available',
                                  ),
                                ),
                              );
                            },

                            label: const Text('Sign-In with Google'),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
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
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
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
