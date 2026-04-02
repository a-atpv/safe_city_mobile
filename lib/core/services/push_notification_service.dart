import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Top-level function to handle background messages.
/// This must be a top-level function (not inside a class) to work correctly.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  log("Handling a background message: ${message.messageId}");
}

class PushNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // 1. Request permissions (essential for iOS)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      log('User granted provisional permission');
    } else {
      log('User declined or has not accepted permission');
      return; // If declined, exit early.
    }

    // 2. Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Got a message whilst in the foreground!');
      log('Message data: ${message.data}');

      if (message.notification != null) {
        log('Message also contained a notification: ${message.notification}');
      }
    });

    // 4. Handle notification taps when app is in background but opened
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('A new onMessageOpenedApp event was published!');
      log('Message data: ${message.data}');
      // Here you could navigate to a specific screen based on message.data
    });

    // 5. Check if the app was launched from a terminated state via a notification
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      log('App launched from terminated state via notification');
      // Handle the initial message here
    }

    // 6. Get the FCM Token
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        log("FCM Token: $token");
        // TODO: Send this token to your backend via API
      }
    } catch (e) {
      log("Error getting FCM token: $e");
    }

    // 7. Listen for token refreshes
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      log("FCM Token updated: $newToken");
      // TODO: Send updated token to your backend
    });
  }
}
