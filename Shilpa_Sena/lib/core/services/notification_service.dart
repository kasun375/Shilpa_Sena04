import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/notification_provider.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    if (kIsWeb) {
      try {
        NotificationSettings settings = await _firebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint('Web FCM Permission status: ${settings.authorizationStatus}');
      } catch (e) {
        debugPrint('Web FCM Permission request failed: $e');
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        if (message.notification != null) {
          final title = message.notification?.title ?? 'New Notification';
          final body = message.notification?.body ?? '';
          await NotificationProvider.saveMessageLocally(title, body);
          NotificationProvider.notifyReceived();
        }
      });
      return;
    }

    // Request permission for push notifications using both Firebase and PermissionHandler
    if (defaultTargetPlatform == TargetPlatform.android) {
      await Permission.notification.request();
    }

    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // Set foreground notification presentation options for iOS
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications for foreground alerts
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    // Create Android Notification Channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'This channel is used for important notifications.', // description
      importance: Importance.max,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Get FCM Token
    String? token = await getToken();
    debugPrint('FCM Token: $token');

    // Subscribe to topics if needed
    // await _firebaseMessaging.subscribeToTopic('all_users');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        
        // Save to local storage
        final title = message.notification?.title ?? 'New Notification';
        final body = message.notification?.body ?? '';
        await NotificationProvider.saveMessageLocally(title, body);
        NotificationProvider.notifyReceived(); // Notify Provider to reload UI in real-time

        _showLocalNotification(message, channel);
      }
    });

    // Handle background/terminated state messages when app is opened
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      debugPrint('A new onMessageOpenedApp event was published!');
      if (message.notification != null) {
        final title = message.notification?.title ?? 'New Notification';
        final body = message.notification?.body ?? '';
        await NotificationProvider.saveMessageLocally(title, body);
        NotificationProvider.notifyReceived();
      }
    });

    // Handle initial message when app is opened from terminated state
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) async {
      if (message != null && message.notification != null) {
        debugPrint('App opened from terminated state by notification');
        final title = message.notification?.title ?? 'New Notification';
        final body = message.notification?.body ?? '';
        await NotificationProvider.saveMessageLocally(title, body);
        NotificationProvider.notifyReceived();
      }
    });
  }

  static void _showLocalNotification(RemoteMessage message, AndroidNotificationChannel channel) {
    RemoteNotification? notification = message.notification;

    if (notification != null) {
      _localNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: '@mipmap/ic_launcher', // Force default launcher icon to prevent crash on null
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    }
  }

  static Future<String?> getToken() async {
    try {
      if (kIsWeb) {
        // VAPID key is required for web. 
        // You can get this from Firebase Console > Cloud Messaging > Web configuration
        return await _firebaseMessaging.getToken(
          vapidKey: "YOUR_VAPID_KEY_HERE"
        );
      }
      return await _firebaseMessaging.getToken();
    } catch (e) {
      debugPrint('Error getting token: $e');
      return null;
    }
  }

  static Stream<String> get onTokenRefresh => _firebaseMessaging.onTokenRefresh;

  static Future<void> requestPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `Firebase.initializeApp()` before using other Firebase services.
  debugPrint("Handling a background message: ${message.messageId}");

  final title = message.notification?.title ?? 'New Notification';
  final body = message.notification?.body ?? '';
  await NotificationProvider.saveMessageLocally(title, body);
}
