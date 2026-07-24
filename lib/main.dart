import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/theme.dart';
import 'core/router/app_router.dart';
import 'core/services/push_notification_service.dart';
import 'shared/providers/websocket_provider.dart';
import 'shared/providers/emergency_provider.dart';
import 'shared/providers/location_tracking_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  /// Handle `safecity://pay/success|fail` deep links used to return the user
  /// from the payment browser (SFSafariViewController on iOS) back into the app.
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
    if (uri.scheme != 'safecity' || uri.host != 'pay') return;
    // The status screen polls the backend for the real outcome (the ResultURL
    // callback is the source of truth); we just land the user back on it.
    final router = ref.read(routerProvider);
    if (uri.path.contains('success')) {
      router.go('/subscribe/status');
    } else {
      router.go('/subscribe');
    }
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

  if (status == 'completed') {
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
              emergencyNotifier.clearActiveCall();
              context.go('/emergency/review', extra: callId);
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
              context.go('/home');
            },
            child: const Text('ОК'),
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

  final note = (message['note'] as String?)?.trim();
  final baseMessage = (message['message'] as String?) ??
      'Ваш вызов передан другой службе. Ищем ближайшего свободного сотрудника.';

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.alt_route, color: Color(0xFF2563EB), size: 28),
          SizedBox(width: 8),
          Expanded(
            child: Text('Вызов перенаправлен',
                style: TextStyle(color: Colors.white)),
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
            Text('Комментарий службы:',
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
          child: const Text('Понятно', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
