import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/emergency_location_service.dart';
import 'emergency_provider.dart';
import 'user_provider.dart';

/// Статусы, после которых координаты слать уже некому.
const _terminalCallStatuses = {
  'completed',
  'cancelled_by_user',
  'cancelled_by_system',
};

/// Трекинг привязан к состоянию вызова, а не к экрану: пока в
/// [emergencyProvider] есть незавершённый вызов — координаты уходят, как только
/// он завершился или очищен — трекинг гаснет. Экранам ничего запускать и
/// останавливать не нужно, поэтому забыть отменить подписку структурно нельзя.
///
/// Провайдер ленивый, поэтому его держит живым `ref.watch` в `main.dart` —
/// тем же приёмом, что и `webSocketServiceProvider`.
final emergencyLocationProvider = Provider<EmergencyLocationService>((ref) {
  final service = EmergencyLocationService(
    onPosition: (position) => ref.read(userProvider.notifier).updateLocation(
          position.latitude,
          position.longitude,
          accuracy: position.accuracy,
        ),
  );

  ref.listen<EmergencyState>(emergencyProvider, (previous, next) {
    final call = next.activeCall;
    if (call != null && !_terminalCallStatuses.contains(call.status)) {
      service.start();
    } else {
      service.stop();
    }
  }, fireImmediately: true);

  ref.onDispose(service.dispose);

  return service;
});
