import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/theme.dart';
import 'core/router/app_router.dart';
import 'core/services/push_notification_service.dart';
// import 'firebase_options.dart'; // Uncomment after running `flutterfire configure`

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      // options: DefaultFirebaseOptions.currentPlatform, // Uncomment after running `flutterfire configure`
    );
    
    // Initialize Push Notifications
    final pushService = PushNotificationService();
    await pushService.initialize();
  } catch (e) {
    debugPrint('Firebase initialization failed. Did you run flutterfire configure? Error: $e');
  }
  
  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
  
  // Lock orientation to portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const ProviderScope(child: SafeCityApp()));
}

class SafeCityApp extends ConsumerWidget {
  const SafeCityApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'Safe City',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
      builder: (context, child) => GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: child,
      ),
    );
  }
}
