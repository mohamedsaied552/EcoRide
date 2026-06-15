import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:glider/l10n/app_localizations.dart';
import 'package:glider/presentation/cubits/register_cubit.dart';
import 'package:glider/presentation/cubits/user_cubit.dart';
import 'package:glider/presentation/utils/register_flow_utils.dart';
import 'package:glider/presentation/screens/map_screen.dart';

class SelfieVerificationScreen extends StatefulWidget {
  const SelfieVerificationScreen({super.key});

  static const Color accent = Color(0xFF00E5FF);
  static const Color background = Color(0xFF050A0F);

  @override
  State<SelfieVerificationScreen> createState() =>
      _SelfieVerificationScreenState();
}

class _SelfieVerificationScreenState extends State<SelfieVerificationScreen> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _selfieBytes;
  bool _isCapturing = false;

  Future<void> _captureSelfie() async {
    setState(() => _isCapturing = true);
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
        maxWidth: 1280,
      );
      if (!mounted) return;
      if (image == null) {
        setState(() => _isCapturing = false);
        return;
      }
      final bytes = await image.readAsBytes();
      setState(() {
        _selfieBytes = bytes;
        _isCapturing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCapturing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).selfieCaptureError),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _retake() {
    setState(() => _selfieBytes = null);
    _captureSelfie();
  }

  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context);
    if (_selfieBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.selfieRequired),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final cubit = context.read<RegisterCubit>();
    cubit.setSelfieImage(_selfieBytes!);
    await cubit.submitRegistration();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocListener<RegisterCubit, RegisterState>(
      listenWhen: (previous, current) =>
          previous.submissionStatus != current.submissionStatus,
      listener: (context, state) {
        if (state.submissionStatus == RegisterSubmissionStatus.success &&
            state.registeredUser != null) {
          context.read<UserCubit>().applyAuthenticatedUser(
            state.registeredUser!,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).accountCreatedSuccess),
              backgroundColor: const Color(0xFF1FAE6C),
            ),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MapScreen()),
            (route) => false,
          );
          return;
        }
        handleRegisterSubmission(context, state);
      },
      child: Scaffold(
        backgroundColor: SelfieVerificationScreen.background,
        appBar: AppBar(
          title: Text(l10n.selfieVerificationTitle),
          backgroundColor: Colors.transparent,
          foregroundColor: SelfieVerificationScreen.accent,
          elevation: 0,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                Text(
                  l10n.selfieLookAtCamera,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.selfieInstruction,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: Center(
                    child: _CameraFrame(
                      selfieBytes: _selfieBytes,
                      isCapturing: _isCapturing,
                      onCapture: _captureSelfie,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (_selfieBytes == null)
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _isCapturing ? null : _captureSelfie,
                      icon: _isCapturing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: SelfieVerificationScreen.background,
                              ),
                            )
                          : const Icon(Icons.camera_alt_outlined),
                      label: Text(l10n.captureSelfie),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SelfieVerificationScreen.accent,
                        foregroundColor: SelfieVerificationScreen.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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
                            onPressed: _retake,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: SelfieVerificationScreen.accent,
                              side: const BorderSide(
                                color: SelfieVerificationScreen.accent,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(l10n.retake),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: BlocBuilder<RegisterCubit, RegisterState>(
                          builder: (context, state) {
                            final isLoading = state.submissionStatus ==
                                RegisterSubmissionStatus.loading;
                            return SizedBox(
                              height: 54,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _confirm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      SelfieVerificationScreen.accent,
                                  foregroundColor:
                                      SelfieVerificationScreen.background,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: SelfieVerificationScreen
                                              .background,
                                        ),
                                      )
                                    : Text(
                                        l10n.confirm,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            );
                          },
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
  }
}

class _CameraFrame extends StatelessWidget {
  const _CameraFrame({
    required this.selfieBytes,
    required this.isCapturing,
    required this.onCapture,
  });

  final Uint8List? selfieBytes;
  final bool isCapturing;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    const frameSize = 260.0;

    return GestureDetector(
      onTap: selfieBytes == null && !isCapturing ? onCapture : null,
      child: Container(
        width: frameSize,
        height: frameSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: SelfieVerificationScreen.accent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: SelfieVerificationScreen.accent.withValues(alpha: 0.35),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipOval(
          child: selfieBytes != null
              ? Image.memory(selfieBytes!, fit: BoxFit.cover)
              : ColoredBox(
                  color: const Color(0xFF0D1520),
                  child: isCapturing
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: SelfieVerificationScreen.accent,
                          ),
                        )
                      : Icon(
                          Icons.face_retouching_natural,
                          size: 72,
                          color: SelfieVerificationScreen.accent
                              .withValues(alpha: 0.5),
                        ),
                ),
        ),
      ),
    );
  }
}
