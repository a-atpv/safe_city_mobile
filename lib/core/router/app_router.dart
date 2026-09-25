import 'package:go_router/go_router.dart';
import '../analytics/app_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/emergency/presentation/emergency_screen.dart';
import '../../features/emergency/presentation/call_chat_screen.dart';
import '../../features/emergency/presentation/review_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/settings_screen.dart';
import '../../features/profile/presentation/documents_screen.dart';
import '../../features/subscription/presentation/paywall_screen.dart';
import '../../features/subscription/presentation/payment_status_screen.dart';
import '../../features/subscription/presentation/subscription_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../shared/widgets/main_scaffold.dart';
import '../../shared/widgets/route_error_screen.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/user_provider.dart';
import '../../l10n/l10n.dart';

import 'package:flutter/material.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Куда ведёт возврат из браузера после оплаты (`safecity://pay/success|fail`),
/// или null, если адрес к оплате не относится.
///
/// Одна точка на два входа: ссылку ловит и app_links в `main.dart`, и движок
/// Flutter, который отдаёт её роутеру как обычный адрес — целиком, вместе со
/// схемой. Второй путь и приводил к «Page Not Found» с текстом исключения на
/// экране человека, который только что заплатил.
String? payReturnRoute(Uri uri) {
  if (uri.scheme != 'safecity' || uri.host != 'pay') return null;
  return uri.path.contains('success') ? '/subscribe/status' : '/subscribe';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authChangeNotifier = ref.watch(authChangeNotifierProvider);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: authChangeNotifier,
    // Никакой адрес не должен выводить человеку текст исключения.
    errorBuilder: (context, state) => const RouteErrorScreen(),
    redirect: (context, state) {
      // Схему оплаты переводим во внутренний маршрут раньше всех остальных
      // проверок — дальше по нему отработает обычный редирект авторизации.
      final payReturn = payReturnRoute(state.uri);
      if (payReturn != null) return payReturn;

      final authState = ref.read(authProvider);
      final userState = ref.read(userProvider);
      final status = authState.status;
      final currentPath = state.uri.path;

      // Auth check still in progress — stay on splash
      if (status == AuthStatus.unknown) {
        return currentPath == '/' ? null : '/';
      }

      final isAuthenticated = status == AuthStatus.authenticated;
      final isNewUser = authState.isNew || (userState.user?.isNew ?? false);

      // Auth check finished: splash must not remain visible.
      if (currentPath == '/') {
        if (isAuthenticated) {
          return isNewUser ? '/onboarding' : '/home';
        } else {
          return '/login';
        }
      }

      final isOnAuthRoute =
          currentPath == '/login' ||
          currentPath == '/otp' ||
          currentPath == '/onboarding' ||
          currentPath == '/';

      // Authenticated user trying to access login/otp → go home or onboarding
      if (isAuthenticated &&
          (currentPath == '/login' || currentPath == '/otp')) {
        return isNewUser ? '/onboarding' : '/home';
      }

      // If user is authenticated, is a new user, and is not on onboarding/documents, force them to onboarding
      if (isAuthenticated && isNewUser && currentPath != '/onboarding') {
        if (currentPath != '/documents') {
          return '/onboarding';
        }
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
      
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                name: 'history',
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
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
              GoRoute(
                path: '/documents',
                name: 'documents',
                builder: (context, state) {
                  final extra = state.extra as Map<String, String>?;
                  final title = extra?['title'] ?? context.l10n.documentsPrivacyPolicy;
                  final url = extra?['url'] ?? 'https://www.safe-city.kz/legal/privacy-policy';
                  return DocumentsScreen(title: title, url: url);
                },
              ),
            ],
          ),
        ],
      ),
      
      // Full-screen onboarding flow (no shell/bottom nav)
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      
      // Full-screen emergency flow (no shell/bottom nav)
      GoRoute(
        path: '/emergency',
        name: 'emergency',
        builder: (context, state) {
          // When an existing call id is passed, the screen resumes tracking
          // that call (e.g. after it was redirected to another service) instead
          // of creating a brand-new emergency call.
          final existingCallId = state.extra as int?;
          return EmergencyScreen(
            existingCallId: existingCallId,
            redirected: existingCallId != null,
          );
        },
      ),
      GoRoute(
        path: '/emergency/chat',
        name: 'emergency_chat',
        builder: (context, state) {
          final callId = state.extra as int? ?? 0;
          return CallChatScreen(callId: callId);
        },
      ),
      GoRoute(
        path: '/emergency/review',
        name: 'emergency_review',
        builder: (context, state) {
          final callId = state.extra as int? ?? 0;
          return ReviewScreen(callId: callId);
        },
      ),

      // Subscription / paywall (full-screen, outside the bottom-nav shell)
      GoRoute(
        path: '/subscribe',
        name: 'subscribe',
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: '/subscribe/status',
        name: 'subscribe_status',
        builder: (context, state) => const PaymentStatusScreen(),
      ),
      GoRoute(
        path: '/subscription',
        name: 'subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
    ],
  );

  // Экраны для аналитики. Навигатор-обсервер здесь не годится: вкладки
  // StatefulShellRoute живут в своих навигаторах, и переключение между ними
  // обсервер корневого навигатора не видит. Делегат роутера меняется на любой
  // переход, включая вкладки.
  void reportScreen() {
    try {
      AppAnalytics.logScreen(router.state.name);
    } catch (_) {
      // Адрес без маршрута (errorBuilder) — отчитываться не о чем.
    }
  }

  router.routerDelegate.addListener(reportScreen);
  ref.onDispose(() => router.routerDelegate.removeListener(reportScreen));
  return router;
});


