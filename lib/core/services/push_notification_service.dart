import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';
import '../../shared/providers/emergency_provider.dart';

/// Top-level function to handle background messages.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log("Handling a background message: ${message.messageId}");
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  late final FirebaseMessaging _fcm;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    if (Firebase.apps.isEmpty) {
      log('PushNotificationService: skip init, no default Firebase app');
      return;
    }

    _fcm = FirebaseMessaging.instance;

    // 1. Request permissions (with timeout)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    ).timeout(const Duration(seconds: 5), onTimeout: () {
      log('requestPermission timed out');
      return const NotificationSettings(
        alert: AppleNotificationSetting.notSupported,
        badge: AppleNotificationSetting.notSupported,
        sound: AppleNotificationSetting.notSupported,
        announcement: AppleNotificationSetting.notSupported,
        authorizationStatus: AuthorizationStatus.notDetermined,
        lockScreen: AppleNotificationSetting.notSupported,
        notificationCenter: AppleNotificationSetting.notSupported,
        showPreviews: AppleShowPreviewSetting.notSupported,
        timeSensitive: AppleNotificationSetting.notSupported,
        criticalAlert: AppleNotificationSetting.notSupported,
        carPlay: AppleNotificationSetting.notSupported,
        providesAppNotificationSettings: AppleNotificationSetting.notSupported,
      );
    });

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      log('User declined or has not accepted notification permissions');
      return;
    }

    // 2. Local Notifications Setup
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 3. Create Android Notification Channel
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'emergency_status_channel', // id
        'Emergency Status Updates', // title
        description: 'This channel is used for updates on your emergency requests.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    // 4. Set up Background Messenger
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Received foreground message: ${message.notification?.title}');
      if (message.notification != null && Platform.isAndroid) {
        _showLocalNotification(message);
      }
    });

    // 6. Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('Notification opened app: ${message.data}');
      _handleNotificationPayload(message.data);
    });

    // 7. Check final launch (with timeout - common hang point)
    try {
      RemoteMessage? initialMessage = await _fcm.getInitialMessage()
          .timeout(const Duration(seconds: 3));
      if (initialMessage != null) {
        log('App launched from terminated state via notification');
        _handleNotificationPayload(initialMessage.data);
      }
    } catch (e) {
      log('Error or timeout getting initial message: $e');
    }

    _isInitialized = true;
    log('PushNotificationService (User App) initialized');
  }

  Future<String?> getFcmToken() async {
    if (!_isInitialized) {
      log('PushNotificationService not initialized — skipping getFcmToken');
      return null;
    }
    try {
      if (Firebase.apps.isEmpty) {
        log('getFcmToken: no Firebase app (init failed or missing config)');
        return null;
      }
      final token = await FirebaseMessaging.instance.getToken();
      log('FCM Token: $token');
      return token;
    } catch (e) {
      log('Error getting FCM token: $e');
      return null;
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'emergency_status_channel',
            'Emergency Status Updates',
            channelDescription: 'This channel is used for updates on your emergency requests.',
            icon: android.smallIcon,
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      _handleNotificationPayload(data);
    }
  }

  void _handleNotificationPayload(Map<String, dynamic> data) {
    log('Handling notification payload: $data');
    
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    final callIdStr = data['call_id']?.toString();
    final callId = callIdStr != null ? int.tryParse(callIdStr) : null;
    final status = data['status']?.toString();

    if (callId != null) {
      final container = ProviderScope.containerOf(context);
      final emergencyNotifier = container.read(emergencyProvider.notifier);

      if (status == 'completed') {
        emergencyNotifier.clearActiveCall();
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
                SizedBox(width: 8),
                Text('Успешно', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: const Text(
              'Вызов успешно завершен! Пожалуйста, оцените работу службы безопасности.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  GoRouter.of(context).go('/emergency/review', extra: callId);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Оценить', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      } else if (status == 'cancelled_by_user' || status == 'cancelled_by_system') {
        emergencyNotifier.clearActiveCall();
        final text = status == 'cancelled_by_system'
            ? 'Ваш вызов был отменен системой.'
            : 'Вызов отменен.';

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.redAccent, size: 28),
                SizedBox(width: 8),
                Text('Вызов отменен', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: Text(
              text,
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  GoRouter.of(context).go('/home');
                },
                child: const Text('ОК'),
              ),
            ],
          ),
        );
      } else {
        emergencyNotifier.getActiveCall();
        GoRouter.of(context).push('/emergency');
      }
    } else {
      GoRouter.of(context).go('/home');
    }
  }
}
