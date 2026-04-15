import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';

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
    try {
      String? token = await _fcm.getToken();
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

    if (data.containsKey('call_id')) {
      // User app might want to go to emergency detail or status screen
      // Assuming /emergency is the path for active requests
      GoRouter.of(context).push('/emergency');
    } else {
      GoRouter.of(context).go('/home');
    }
  }
}
