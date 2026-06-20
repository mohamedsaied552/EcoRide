import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:glider/l10n/app_localizations.dart';
import 'package:glider/presentation/cubits/register_cubit.dart';
import 'package:glider/presentation/cubits/user_cubit.dart';
import 'package:glider/presentation/screens/selfie_verification_screen.dart';
import 'package:glider/presentation/utils/register_flow_utils.dart';
import 'package:glider/presentation/widgets/id_upload_card.dart';
import 'package:glider/presentation/widgets/register_progress_indicator.dart';
import 'package:image_picker/image_picker.dart';
import 'map_screen.dart';

class RegisterDocumentsScreen extends StatelessWidget {
  const RegisterDocumentsScreen({super.key});

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
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MapScreen()),
            (route) => false,
          );
        } else {
          handleRegisterSubmission(context, state);
        }
      },
      child: BlocBuilder<RegisterCubit, RegisterState>(
        builder: (context, state) {
          final cubit = context.read<RegisterCubit>();

          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.uploadIdTitle),
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
                      l10n.uploadIdTitle,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontSize: 28),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.uploadIdSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    const RegisterProgressIndicator(currentStep: 2),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(l10n.uploadIdInstruction),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.frontSide,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    IdUploadCard(
                      imageBytes: state.frontIdBytes,
                      fileName: state.frontIdName,
                      errorText: state.imageError != null && !state.hasFrontId
                          ? localizeRegisterImageError(l10n, state.imageError)
                          : null,
                      onCameraTap: () => cubit.pickIdImage(
                        side: RegisterImageSide.front,
                        source: ImageSource.camera,
                      ),
                      onGalleryTap: () => cubit.pickIdImage(
                        side: RegisterImageSide.front,
                        source: ImageSource.gallery,
                      ),
                      onClear: () =>
                          cubit.clearSelectedIdImage(RegisterImageSide.front),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.backSide,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    IdUploadCard(
                      imageBytes: state.backIdBytes,
                      fileName: state.backIdName,
                      errorText: state.imageError != null && !state.hasBackId
                          ? localizeRegisterImageError(l10n, state.imageError)
                          : null,
                      onCameraTap: () => cubit.pickIdImage(
                        side: RegisterImageSide.back,
                        source: ImageSource.camera,
                      ),
                      onGalleryTap: () => cubit.pickIdImage(
                        side: RegisterImageSide.back,
                        source: ImageSource.gallery,
                      ),
                      onClear: () =>
                          cubit.clearSelectedIdImage(RegisterImageSide.back),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          if (!state.hasBothIdImages) {
                            cubit.submitRegistration();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  localizeRegisterImageError(
                                    l10n,
                                    RegisterImageError.uploadBothId,
                                  ),
                                ),
                                backgroundColor: Colors.red.shade700,
                              ),
                            );
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: cubit,
                                child: const SelfieVerificationScreen(),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1FAE6C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          l10n.continueToSelfie,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
