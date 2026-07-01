import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zakzouka/core/events/app_event_bus.dart';
import 'package:zakzouka/core/notifications/local_notification_service.dart';
import 'package:zakzouka/core/storage/fcm_token_storage.dart';
import 'package:zakzouka/core/storage/token_storage.dart';
import 'package:zakzouka/data/services/notification_service.dart';

class NotificationManager {
  NotificationManager({
    NotificationService? notificationService,
    AppEventBus? eventBus,
    LocalNotificationService? localNotificationService,
    FcmTokenStorage? fcmTokenStorage,
    TokenStorage? tokenStorage,
    GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey,
  }) : _notificationService = notificationService ?? NotificationService(),
       _eventBus = eventBus ?? AppEventBus(),
       _localNotificationService =
           localNotificationService ?? LocalNotificationService(),
       _fcmTokenStorage = fcmTokenStorage ?? FcmTokenStorage(),
       _tokenStorage = tokenStorage ?? TokenStorage(),
       _scaffoldMessengerKey = scaffoldMessengerKey;

  final NotificationService _notificationService;
  final AppEventBus _eventBus;
  final LocalNotificationService _localNotificationService;
  final FcmTokenStorage _fcmTokenStorage;
  final TokenStorage _tokenStorage;
  final GlobalKey<ScaffoldMessengerState>? _scaffoldMessengerKey;

  String? currentFcmToken;
  bool _isInitialized = false;
  bool _listenersAttached = false;
  bool _isSyncingToken = false;

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;

  /// Called once from [main] during app startup.
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _localNotificationService.initialize();

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('FCM permission status: ${settings.authorizationStatus.name}');

    _attachListenersOnce();

    currentFcmToken = await FirebaseMessaging.instance.getToken();
    if (kDebugMode) {
      debugPrint('========== FCM TOKEN (debug) ==========');
      debugPrint(currentFcmToken ?? 'null');
      debugPrint('=======================================');
    }

    _isInitialized = true;
  }

  void _attachListenersOnce() {
    if (_listenersAttached) return;
    _listenersAttached = true;

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      currentFcmToken = newToken;
      if (kDebugMode) {
        debugPrint('FCM TOKEN refreshed: $newToken');
      }
      unawaited(_sendTokenToServerIfChanged(newToken));
    });

    _setupNotificationListeners();
  }

  Future<String?> getToken() async {
    currentFcmToken ??= await FirebaseMessaging.instance.getToken();
    return currentFcmToken;
  }

  /// Sync the device FCM token with the backend after the user is authenticated.
  Future<void> syncTokenWithServer() async {
    if (!await _hasAuthenticatedSession()) {
      debugPrint('Skipping FCM sync: user is not authenticated.');
      return;
    }

    final token = await getToken();
    if (token == null || token.trim().isEmpty) {
      debugPrint('Skipping FCM sync: no token available.');
      return;
    }

    await _sendTokenToServerIfChanged(token);
  }

  Future<bool> _hasAuthenticatedSession() async {
    return _tokenStorage.hasToken();
  }

  Future<void> _sendTokenToServerIfChanged(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      debugPrint('Skipping empty FCM token sync.');
      return;
    }

    if (!await _hasAuthenticatedSession()) {
      debugPrint('Skipping FCM sync: no auth session.');
      return;
    }

    final cached = await _fcmTokenStorage.getLastSyncedToken();
    if (cached == trimmed) {
      if (kDebugMode) {
        debugPrint('FCM token unchanged — skipping backend sync.');
      }
      return;
    }

    if (_isSyncingToken) return;
    _isSyncingToken = true;
    try {
      await _notificationService.updateFcmToken(trimmed);
      await _fcmTokenStorage.saveLastSyncedToken(trimmed);
      debugPrint('FCM token successfully synced with backend.');
    } catch (e) {
      debugPrint('Failed to sync FCM token with backend: $e');
    } finally {
      _isSyncingToken = false;
    }
  }

  void _setupNotificationListeners() {
    _foregroundSubscription?.cancel();
    _openedAppSubscription?.cancel();

    _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Received a message in the FOREGROUND!');

      final title =
          message.notification?.title ??
          message.data['title']?.toString() ??
          '';
      final body =
          message.notification?.body ?? message.data['body']?.toString() ?? '';

      if (title.isNotEmpty || body.isNotEmpty) {
        unawaited(
          _showForegroundNotification(
            title: title,
            body: body,
            data: message.data,
          ),
        );
      }

      _handleDataPayload(message.data);
    });

    _openedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
      message,
    ) {
      debugPrint('Notification clicked while app was in BACKGROUND!');
      _handleDataPayload(message.data);
    });

    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
      if (message != null) {
        debugPrint('Notification clicked while app was TERMINATED!');
        _handleDataPayload(message.data);
      }
    });
  }

  void _handleDataPayload(Map<String, dynamic> data) {
    debugPrint('Processing notification data payload: $data');

    _eventBus.publish(
      AppNotificationEvent(
        title: data['title']?.toString(),
        body: data['body']?.toString(),
        data: data,
      ),
    );

    if (data['action']?.toString().toLowerCase() == 'refresh_map') {
      _eventBus.publish(const MapRefreshRequestedEvent());
    }
    
  }

  Future<void> _showForegroundNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    debugPrint('SHOW FOREGROUND NOTIFICATION -> Title: $title | Body: $body');

    final messenger = _scaffoldMessengerKey?.currentState;
    if (messenger != null && body.isNotEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            title.isEmpty ? body : '$title\n$body',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    }

    await _localNotificationService.showNotification(
      title: title,
      body: body,
      payload: data,
    );
  }

  Future<void> logoutCleanup() async {
    await _fcmTokenStorage.clearLastSyncedToken();
    currentFcmToken = null;
  }
}
