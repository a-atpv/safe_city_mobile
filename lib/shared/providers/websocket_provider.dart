import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/web_socket_service.dart';
import 'auth_provider.dart';

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  
  // Listen to auth changes to connect/disconnect
  ref.listen<AuthState>(authProvider, (previous, next) {
    if (next.status == AuthStatus.authenticated) {
      service.connect();
    } else if (next.status == AuthStatus.unauthenticated) {
      service.disconnect();
    }
  }, fireImmediately: true);

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

final webSocketStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.messageStream;
});

final webSocketConnectionProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.connectionStream;
});
