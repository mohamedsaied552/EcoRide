import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';

import 'package:zakzouka/l10n/app_localizations.dart';
import 'package:zakzouka/presentation/cubits/locale_cubit.dart';
import 'package:zakzouka/presentation/cubits/ride_cubit.dart';
import 'package:zakzouka/presentation/cubits/user_cubit.dart';
import 'package:zakzouka/presentation/cubits/wallet_cubit.dart';
import 'package:zakzouka/core/events/app_event_bus.dart';
import 'package:zakzouka/presentation/screens/login_screen.dart';
import 'package:zakzouka/core/notifications/notification_manager.dart';
import 'package:zakzouka/presentation/screens/map_screen.dart';
import 'package:zakzouka/presentation/screens/onboarding_screen.dart';
import 'package:zakzouka/presentation/screens/profile_screen.dart';
import 'package:zakzouka/presentation/screens/signup_screen.dart';
import 'package:zakzouka/presentation/screens/splash_screen.dart';
import 'package:zakzouka/presentation/screens/wallet_screen.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final appEventBus = AppEventBus();
  GetIt.I.registerSingleton<AppEventBus>(appEventBus);
  final notificationManager = NotificationManager(
    eventBus: appEventBus,
    scaffoldMessengerKey: rootScaffoldMessengerKey,
  );
  GetIt.I.registerSingleton<NotificationManager>(notificationManager);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

unawaited(notificationManager.initialize());

  appEventBus.on<SessionExpiredEvent>().listen((_) {
    rootNavigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (_) => false,
    );
  });
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => RideCubit()),
        BlocProvider(create: (_) => WalletCubit()),
        BlocProvider(create: (_) => UserCubit()),
        BlocProvider(create: (_) => LocaleCubit()..loadSavedLocale()),
      ],
      child: const ScooterApp(),
    ),
  );
}

class ScooterApp extends StatelessWidget {
  const ScooterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1FAE6C),
      brightness: Brightness.light,
    );

    return BlocBuilder<LocaleCubit, Locale>(
      builder: (context, locale) {
        return MaterialApp(
          key: ValueKey(locale.languageCode),
          navigatorKey: rootNavigatorKey,
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            colorScheme: colorScheme,
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF6F7FB),
            appBarTheme: AppBarTheme(
              backgroundColor: colorScheme.surface,
              elevation: 0,
              titleTextStyle: const TextStyle(
                color: Color(0xFF101828),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            textTheme: const TextTheme(
              headlineSmall: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
              titleMedium: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
              bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF475467)),
            ),
            cardTheme: const CardThemeData(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(18)),
              ),
            ),
          ),
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
          routes: {
            '/login': (_) => const LoginScreen(),
            '/signup': (_) => const SignupScreen(),
            '/map': (_) => const MapScreen(),
            '/onboarding': (_) => const OnboardingScreen(),
            '/profile': (_) => const ProfileScreen(),
            '/wallet': (_) => const WalletScreen(),
          },
        );
      },
    );
  }
}
