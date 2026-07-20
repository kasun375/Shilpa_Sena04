import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/courses/presentation/providers/database_provider.dart';
import 'core/services/notification_service.dart';
import 'core/providers/notification_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Set up FCM background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    
    // Initialize Notification Service
    await NotificationService.initialize();
    
    // Retrieve and print FCM Token
    final fcmToken = await FirebaseMessaging.instance.getToken();
    debugPrint('====================================');
    debugPrint('FCM Token: $fcmToken');
    debugPrint('====================================');
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (_) => DatabaseProvider()..initStreams(),
        ),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const ShilpaSenaApp(),
    ),
  );
}

class ShilpaSenaApp extends StatelessWidget {
  const ShilpaSenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Shilpa Sena',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: AppRouter.router,
    );
  }
}
