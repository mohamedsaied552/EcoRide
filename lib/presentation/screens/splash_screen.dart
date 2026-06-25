import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glider/data/services/ride_hub_service.dart';
import 'package:glider/l10n/app_localizations.dart';
import 'package:glider/presentation/cubits/ride_cubit.dart';
import 'package:glider/presentation/cubits/user_cubit.dart';
import 'package:glider/presentation/cubits/wallet_cubit.dart';
import 'package:glider/presentation/screens/active_ride_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _performStartupCheck();
  }

  Future<void> _performStartupCheck() async {
    final userCubit = context.read<UserCubit>();
    final rideCubit = context.read<RideCubit>();
    final walletCubit = context.read<WalletCubit>();

    final isAuthenticated = await userCubit.restoreSession();
    if (!mounted) return;

    if (!isAuthenticated) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
      return;
    }

    
try {
      await RideHubService().connect();
    } catch (e) {
      debugPrint('SignalR connect failed: $e');
    }

    // Pass balance from already-fetched user profile
    unawaited(
      walletCubit.initialize(
        initialBalance: userCubit.state.user?.walletBalance,
      ),
    );


    await rideCubit.appStartedCheck(currentUser: userCubit.state.user);
    if (!mounted) return;

    final rideState = rideCubit.state;
    if (rideState is RideInProgress) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ActiveRideScreen(scooterCode: rideState.preview.serialNumber),
        ),
      );
      return;
    }

    Navigator.pushReplacementNamed(context, '/map');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F7A52), Color(0xFF1FAE6C), Color(0xFF8CE6B0)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 84,
                width: 84,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.electric_scooter,
                  size: 46,
                  color: Color(0xFF0F7A52),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.appTitle,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.moveFaster,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
