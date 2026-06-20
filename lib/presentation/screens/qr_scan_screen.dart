import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:glider/l10n/app_localizations.dart';
import 'package:glider/presentation/cubits/ride_cubit.dart';
import 'package:glider/presentation/cubits/topup_cubit.dart';
import 'package:glider/presentation/screens/active_ride_screen.dart';
import 'package:glider/presentation/screens/topup_screen.dart';
import 'package:glider/presentation/widgets/qr_view.dart';

String _localizeScooterStatus(AppLocalizations l10n, String statusLabel) {
  switch (statusLabel) {
    case 'Available':
      return l10n.available;
    case 'Offline':
      return l10n.offline;
    default:
      return statusLabel;
  }
}

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  bool _isSheetVisible = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocListener<RideCubit, RideState>(
      listenWhen: (previous, current) =>
          previous.runtimeType != current.runtimeType,
      listener: (context, state) async {
        if (state is RideFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }

        if (state is RideInProgress) {
          final scooterCode = state.preview.serialNumber;
          if (_isSheetVisible && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
            _isSheetVisible = false;
          }
          context.read<RideCubit>().reset();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ActiveRideScreen(scooterCode: scooterCode),
            ),
          );
          return;
        }

        if (state is ScooterLoaded ||
            state is InsufficientFunds ||
            state is ProximityFailure ||
            state is ProximityChecking ||
            state is RideStarting) {
          _presentRideSheet();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.scanQr)),
        body: Stack(
          children: [
            QrViewWidget(
              onScan: (code) {
                if (code == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.invalidQrCode)),
                  );
                  return;
                }

                final rideState = context.read<RideCubit>().state;
                if (rideState is ScooterLoading || rideState is RideStarting) {
                  return;
                }

                context.read<RideCubit>().scanScooter(code);
              },
            ),
            BlocBuilder<RideCubit, RideState>(
              builder: (context, state) {
                if (state is! ScooterLoading) {
                  return const SizedBox.shrink();
                }

                return const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x88000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              },
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 30,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.scanQrInstruction,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _presentRideSheet() async {
    if (_isSheetVisible || !mounted) {
      return;
    }

    _isSheetVisible = true;
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (_) {
        return BlocProvider.value(
          value: context.read<RideCubit>(),
          child: const _RidePreviewSheet(),
        );
      },
    );
    _isSheetVisible = false;
  }
}

class _RidePreviewSheet extends StatelessWidget {
  const _RidePreviewSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: BlocBuilder<RideCubit, RideState>(
          builder: (context, state) {
            final preview = switch (state) {
              ScooterLoaded(:final preview) => preview,
              InsufficientFunds(:final preview) => preview,
              ProximityFailure(:final preview) => preview,
              ProximityChecking(:final preview) => preview,
              RideStarting(:final preview) => preview,
              RideInProgress(:final preview) => preview,
              RideFailure(:final preview?) => preview,
              _ => null,
            };

            if (preview == null) {
              return const SizedBox.shrink();
            }

            final rideCubit = context.read<RideCubit>();
            final isBusy = state is ProximityChecking || state is RideStarting;
            final hasFunds = preview.hasSufficientBalance;
            final withinRange = preview.isWithinUnlockRadius;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD0D5DD),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/scooter.png',
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            preview.scooter.code,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            preview.scooter.modelName ??
                                preview.scooter.locationName,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.batteryPercent(
                              '${preview.scooter.batteryPercent}',
                            ),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _InfoRow(
                  label: l10n.status,
                  value: _localizeScooterStatus(
                    l10n,
                    preview.scooter.statusLabel,
                  ),
                ),
                _InfoRow(
                  label: l10n.wallet,
                  value: l10n.walletBalanceMin(
                    preview.user.walletBalance.toStringAsFixed(0),
                    preview.minimumRequiredBalance.toStringAsFixed(0),
                  ),
                ),
                _InfoRow(
                  label: l10n.distance,
                  value: preview.distanceToScooterMeters == null
                      ? l10n.notCheckedYet
                      : l10n.distanceRadius(
                          preview.distanceToScooterMeters!.toStringAsFixed(1),
                          preview.allowedUnlockRadiusMeters.toStringAsFixed(0),
                        ),
                ),
                if (state is InsufficientFunds) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.balanceTooLow,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                if (state is ProximityFailure) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.moveCloser,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 20),
                if (!hasFunds)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BlocProvider(
                              create: (_) => TopUpCubit(),
                              child: const TopUpScreen(),
                            ),
                          ),
                        );
                        if (context.mounted) {
                          await rideCubit.refreshRidePreview();
                        }
                      },
                      child: Text(l10n.addMoney),
                    ),
                  )
                else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isBusy
                          ? null
                          : withinRange
                          ? rideCubit.startRide
                          : rideCubit.refreshRidePreview,
                      child: isBusy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              withinRange
                                  ? l10n.startRide
                                  : l10n.checkDistance,
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: isBusy ? null : rideCubit.refreshRidePreview,
                      child: Text(l10n.refreshStatus),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: isBusy
                        ? null
                        : () {
                            rideCubit.reset();
                            Navigator.of(context).pop();
                          },
                    child: Text(l10n.scanAnotherScooter),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
