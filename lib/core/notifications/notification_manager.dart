import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:glider/core/events/app_event_bus.dart';
import 'package:glider/data/services/notification_service.dart';
import 'package:glider/data/repositories/fcm_token_repository_impl.dart';
import 'package:glider/data/repositories/backend_service.dart';
import 'package:glider/domain/usecases/update_fcm_token_use_case.dart';

class NotificationManager {
  NotificationManager({
    NotificationService? notificationService,
    AppEventBus? eventBus,
    UpdateFcmTokenUseCase? updateFcmTokenUseCase,
  }) : _notificationService = notificationService ?? NotificationService(),
       _eventBus = eventBus ?? AppEventBus(),
       _updateFcmTokenUseCase =
           updateFcmTokenUseCase ??
           UpdateFcmTokenUseCase(FcmTokenRepositoryImpl());

  final NotificationService _notificationService;
  final AppEventBus _eventBus;
  final UpdateFcmTokenUseCase _updateFcmTokenUseCase;

  String? currentFcmToken;
  bool _isInitialized = false;

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  /// 1. التشغيل المبدئي واستدعاء التوكن
  Future<void> initialize() async {
    if (_isInitialized) return;

    // طلب صلاحيات الإشعارات من المستخدم (مهم جداً للـ iOS والـ Android 13+)
    NotificationSettings settings = await FirebaseMessaging.instance
        .requestPermission(alert: true, badge: true, sound: true);

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permissions.');

      // جلب التوكن الحالي وإرساله للباك اند
      String? token = await FirebaseMessaging.instance.getToken();
      currentFcmToken = token;
      debugPrint('FCM TOKEN: $token');

      if (token != null) {
        debugPrint('FCM token obtained: $token');
        await _sendTokenToServer(token);
      } else {
        debugPrint('FCM token is null after initialization.');
      }

      // الاستماع في حال تحديث التوكن تلقائياً (Token Lifecycle)
      _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh
          .listen((newToken) async {
            currentFcmToken = newToken;
            await _sendTokenToServer(newToken);
          });

      // إعداد المستمعين للحالات المختلفة
      _setupNotificationListeners();
      _isInitialized = true;
    } else {
      debugPrint('Notification permission was not granted.');
    }
  }

  Future<String?> getToken() async {
    currentFcmToken ??= await FirebaseMessaging.instance.getToken();
    return currentFcmToken;
  }

  /// يُستدعى بعد نجاح تسجيل الدخول لإعادة دفع التوكن للسيرفر
  /// (التوكن قد يكون موجود فعلاً ولكن لم يُرسل بسبب 401 قبل الـ login).
  Future<void> syncTokenWithServer() async {
    final token = await getToken();
    if (token == null || token.trim().isEmpty) {
      debugPrint('Skipping FCM sync: no token available.');
      return;
    }
    await _sendTokenToServer(token);
  }

  /// دالة داخلية لإرسال التوكن عبر الـ Service
  Future<void> _sendTokenToServer(String token) async {
    if (token.trim().isEmpty) {
      debugPrint('Skipping empty FCM token sync.');
      return;
    }

    try {
      final backend = BackendService();
      final currentUser =
          backend.currentUser ?? await backend.fetchCurrentUser();
      await _updateFcmTokenUseCase.call(userId: currentUser.id, token: token);
      await _notificationService.updateFcmToken(token);
      debugPrint('FCM Token successfully synced with backend: $token');
    } catch (e) {
      debugPrint('Failed to sync FCM Token with backend: $e');
    }
  }

  /// 2. إدارة الـ 3 حالات للـ Notifications
  void _setupNotificationListeners() {
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Received a message in the FOREGROUND!');

      // هنا الـ OS لن يظهر بنر علوي، يجب عليك إظهار UI مخصص يدوياً
      if (message.notification != null) {
        _showInAppNotification(
          message.notification!.title ?? '',
          message.notification!.body ?? '',
        );
      }

      // فحص البيانات المخفية
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

  /// 3. التعامل مع الـ Hidden Payload (الأوامر الصامتة)
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

  /// دالة لإظهار بنر أو Snackbar داخلي مخصص لو الأبلكيشن مفتوح
  void _showInAppNotification(String title, String body) {
    debugPrint('SHOW LOCAL UI BANNER -> Title: $title | Body: $body');
  }

  Future<void> logoutCleanup() async {
    await _cancelSubscriptions();
    _isInitialized = false;
    currentFcmToken = null;
  }

  Future<void> _cancelSubscriptions() async {
    await _foregroundSubscription?.cancel();
    await _openedAppSubscription?.cancel();
    await _tokenRefreshSubscription?.cancel();
    _foregroundSubscription = null;
    _openedAppSubscription = null;
    _tokenRefreshSubscription = null;
  }
}
