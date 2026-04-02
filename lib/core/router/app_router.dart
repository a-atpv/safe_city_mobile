import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/emergency/presentation/emergency_screen.dart';
import '../../features/emergency/presentation/call_chat_screen.dart';
import '../../features/emergency/presentation/review_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/settings_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../shared/widgets/main_scaffold.dart';
import '../../shared/providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authChangeNotifier = ref.watch(authChangeNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: authChangeNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final status = authState.status;
      final currentPath = state.uri.path;

      // Auth check still in progress — stay on splash
      if (status == AuthStatus.unknown) {
        return currentPath == '/' ? null : '/';
      }

      final isAuthenticated = status == AuthStatus.authenticated;
      final isOnAuthRoute =
          currentPath == '/login' || currentPath == '/otp' || currentPath == '/';

      // Authenticated user trying to access auth routes → go home
      if (isAuthenticated && isOnAuthRoute) {
        return '/home';
      }

      // Unauthenticated user trying to access protected routes → go to login
      if (!isAuthenticated && !isOnAuthRoute) {
        return '/login';
      }

      return null; // no redirect needed
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/otp',
        name: 'otp',
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return OtpScreen(email: email);
        },
      ),
      
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/history',
            name: 'history',
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      
      // Full-screen emergency flow (no shell/bottom nav)
      GoRoute(
        path: '/emergency',
        name: 'emergency',
        builder: (context, state) => const EmergencyScreen(),
      ),
      GoRoute(
        path: '/emergency/chat',
        name: 'emergency_chat',
        builder: (context, state) {
          final callId = state.extra as int;
          return CallChatScreen(callId: callId);
        },
      ),
      GoRoute(
        path: '/emergency/review',
        name: 'emergency_review',
        builder: (context, state) {
          final callId = state.extra as int;
          return ReviewScreen(callId: callId);
        },
      ),
    ],
  );
});

