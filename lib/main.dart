import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'core/analytics/app_analytics.dart';
import 'core/env/backend_env.dart';
import 'core/theme/theme.dart';
import 'core/router/app_router.dart';
import 'core/services/push_notification_service.dart';
import 'l10n/l10n.dart';
import 'shared/providers/auth_provider.dart';
import 'shared/providers/language_provider.dart';
import 'shared/providers/websocket_provider.dart';
import 'shared/providers/emergency_provider.dart';
import 'shared/providers/location_tracking_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Какой бэкенд слушаем. Строго первым делом: Dio создаётся лениво и
  // запоминает baseUrl при создании, а регистрация пуш-токена ниже — уже
  // сетевой вызов.
  await BackendEnv.load();
  debugPrint('Backend: ${BackendEnv.host}');

  // Язык — до первого кадра, иначе экран успеет мигнуть русским. И до пушей:
  // тексты локальных уведомлений берутся отсюда же.
  await AppLanguageStore.load();

  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 10));
    debugPrint('Firebase initialized');
  } catch (e, st) {
    debugPrint('Firebase initialization failed or timed out: $e\n$st');
  }

  try {
    await PushNotificationService().initialize().timeout(const Duration(seconds: 10));
    debugPrint('Push Notification Service initialized');
  } catch (e, st) {
    debugPrint('Push notification initialization failed or timed out: $e\n$st');
  }

  // Аналитика рекламных кампаний — Meta, Google Analytics for Firebase и
  // AppsFlyer. Meta и Firebase стартуют нативно, от них здесь только согласие
  // на рекламный идентификатор; AppsFlyer заводится отсюда целиком. Запрос
  // ATT — не здесь, а с главного экрана: системный диалог на сплеше
  // пользователь закрывает не читая.
  //
  // Строго после Firebase.initializeApp() выше: без поднятого Firebase
  // события Google Analytics уходить некуда.
  //
  // Намеренно без await, в отличие от соседей выше: без Firebase и пушей
  // приложение работать не может, а без аналитики — может, и задерживать из-за
  // неё экран с тревожной кнопкой неправильно.
  unawaited(AppAnalytics.initialize());


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

class SafeCityApp extends ConsumerStatefulWidget {
  const SafeCityApp({super.key});

  @override
  ConsumerState<SafeCityApp> createState() => _SafeCityAppState();
}

class _SafeCityAppState extends ConsumerState<SafeCityApp> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;

  /// Where a payment deep link wants to land, kept until the router will
  /// actually go there. See [_deliverPayReturn].
  String? _pendingPayReturn;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  /// Handle `safecity://pay/success|fail` deep links used to return the user
  /// from the payment page back into the app. Paying happens in the phone's own
  /// browser on both platforms, so this is the only way back — the backend's
  /// success/fail page redirects to the scheme, and the app may well be cold
  /// when it arrives.
  Future<void> _initDeepLinks() async {
    _linkSub = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (_) {},
    );
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handleUri(initial);
    } catch (_) {}
  }

  void _handleUri(Uri uri) {
    // The status screen polls the backend for the real outcome (the ResultURL
    // callback is the source of truth); we just land the user back on it.
    final target = payReturnRoute(uri);
    if (target == null) return;
    _pendingPayReturn = target;
    _deliverPayReturn();
  }

  /// Navigate to where the payment link points, once the router is willing to
  /// go there.
  ///
  /// Paying happens in the browser now, and a trip long enough to leave the app
  /// killed means the link arrives at a cold start. The router's redirect keeps
  /// everything on the splash screen while the token is being checked, and then
  /// sends the splash to `/home` — so a `go()` fired at that moment is simply
  /// swallowed and the user never sees the confirmation. Hold the target
  /// instead and spend it when auth has settled; [build] retries on every auth
  /// change.
  void _deliverPayReturn() {
    final target = _pendingPayReturn;
    if (target == null) return;
    if (ref.read(authProvider).status == AuthStatus.unknown) return;

    _pendingPayReturn = null;
    // The auth listener below can fire mid-build, and `go()` rebuilds the
    // Router — navigate a frame later so it never lands inside one.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final router = ref.read(routerProvider);
      // The screen may already be up — the paywall pushes it as soon as the
      // payment page opens. Going there again stacks a second identical copy,
      // and then «назад» pops onto its twin and looks like it did nothing.
      // `currentConfiguration` (not `state`) because the link can arrive before
      // the router has resolved anything, and `state` throws on an empty match
      // list.
      if (router.routerDelegate.currentConfiguration.uri.path == target) return;
      router.go(target);
    });
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    // Watch WS service to auto-connect/disconnect based on authentication status
    ref.watch(webSocketServiceProvider);

    // Держим трекер координат живым: он сам стартует и гаснет по состоянию
    // активного вызова, поэтому не должен зависеть от того, какой экран открыт.
    ref.watch(emergencyLocationProvider);

    // Возврат из браузера после оплаты мог прийти раньше, чем проверился токен.
    ref.listen<AuthState>(authProvider, (_, __) => _deliverPayReturn());

    // Listen to WS stream for real-time updates
    ref.listen<AsyncValue<Map<String, dynamic>>>(webSocketStreamProvider, (previous, next) {
      next.whenOrNull(
        data: (message) {
          final type = message['type'] as String?;
          if (type == 'call_status_update') {
            final status = message['status'] as String?;
            final callId = message['call_id'] as int?;
            if (status != null && callId != null) {
              _handleGlobalCallStatusUpdate(ref, status, callId, message);
            }
          } else if (type == 'call_redirected') {
            final callId = message['call_id'] as int?;
            if (callId != null) {
              _handleGlobalCallRedirected(ref, callId, message);
            }
          }
        },
      );
    });

    return MaterialApp.router(
      title: 'Safe City',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
      locale: ref.watch(appLanguageProvider).locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: child,
      ),
    );
  }
}

void _handleGlobalCallStatusUpdate(
  WidgetRef ref,
  String status,
  int callId,
  Map<String, dynamic> message,
) {
  final context = rootNavigatorKey.currentContext;
  if (context == null) return;

  final emergencyNotifier = ref.read(emergencyProvider.notifier);
  final l10n = context.l10n;

  if (status == 'completed') {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.callCompletedTitle,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.callCompletedBody,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              emergencyNotifier.clearActiveCall();
              context.go('/emergency/review', extra: callId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n.callRate, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  } else if (status == 'cancelled_by_user' || status == 'cancelled_by_system') {
    emergencyNotifier.clearActiveCall();
    final text = status == 'cancelled_by_system'
        ? l10n.callCancelledBySystem
        : l10n.callCancelledByUser;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.redAccent, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.callCancelledTitle,
                style: const TextStyle(color: Colors.white),
              ),
            ),
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
              context.go('/home');
            },
            child: Text(l10n.commonOk),
          ),
        ],
      ),
    );
  } else {
    // For other active statuses (accepted, en_route, arrived), update activeCall status
    // and trigger getActiveCall to load any new guard details
    emergencyNotifier.updateActiveCallStatus(status);
    emergencyNotifier.getActiveCall();
  }
}

// The guard handling the call handed it off to another service. Show a
// dedicated dialog and resume tracking on the searching screen while a new
// responder is found.
void _handleGlobalCallRedirected(
  WidgetRef ref,
  int callId,
  Map<String, dynamic> message,
) {
  final context = rootNavigatorKey.currentContext;
  if (context == null) return;

  // Keep local call state fresh (status is now searching/offer_sent again).
  ref.read(emergencyProvider.notifier).getActiveCall();

  final l10n = context.l10n;
  final note = (message['note'] as String?)?.trim();
  // Текст свой, а не message из события: он на языке интерфейса, а
  // комментарий службы (note) показываем ниже отдельно.
  final baseMessage = l10n.callRedirectedBody;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.alt_route, color: Color(0xFF2563EB), size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Text(l10n.callRedirectedTitle,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(baseMessage, style: const TextStyle(color: Colors.white70)),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(l10n.callRedirectedNote,
                style: TextStyle(
                    color: Colors.white.withAlpha(140), fontSize: 12)),
            const SizedBox(height: 4),
            Text(note, style: const TextStyle(color: Colors.white)),
          ],
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(ctx);
            // Resume tracking the existing call on the searching screen.
            context.go('/emergency', extra: callId);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(l10n.commonGotIt, style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
