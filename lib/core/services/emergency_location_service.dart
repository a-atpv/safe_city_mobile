import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'location_permission_service.dart';

/// Отправка координат пользователя во время активного экстренного вызова.
///
/// Раньше трекинг принадлежал конкретному экрану, и на переходе «поиск охраны»
/// → «чат с экипажем» поток координат гасился: охрана переставала видеть
/// перемещение ровно тогда, когда уже выехала к человеку. Поэтому сервис живёт
/// на уровне провайдера и переживает смену экранов.
///
/// Почему поток и таймер работают вместе:
///   * поток (`getPositionStream`) — единственное, что не даёт iOS усыпить
///     процесс: geolocator выставляет `allowsBackgroundLocationUpdates` только
///     потоковому `CLLocationManager` и только при `location` в
///     `UIBackgroundModes`. Разовый `getCurrentPosition` этого не делает;
///   * таймер — потому что при `distanceFilter` в 10 м у стоящего на месте
///     человека поток не эмитит ничего, а серверу нужна свежая отметка времени.
class EmergencyLocationService {
  EmergencyLocationService({required this.onPosition});

  /// Куда отправлять координату. Инжектируется провайдером, чтобы сервис не
  /// знал ни про Riverpod, ни про API-клиент.
  final Future<void> Function(Position position) onPosition;

  /// Как часто переотправлять последний известный фикс.
  static const resendInterval = Duration(seconds: 5);

  StreamSubscription<Position>? _subscription;
  Timer? _timer;
  Position? _lastFix;

  bool get isTracking => _subscription != null;

  /// Идемпотентно: повторный вызов при уже идущем трекинге не пересоздаёт ни
  /// поток, ни таймер, поэтому дёргать его можно из любого места, не зная,
  /// запущен ли трекинг уже.
  void start({Position? initialFix}) {
    // Стартовый фикс принимаем даже при работающем трекинге — он свежее ничего.
    if (initialFix != null) _lastFix = initialFix;
    if (isTracking) return;

    _subscription = Geolocator.getPositionStream(
      locationSettings: LocationPermissionService.getLocationSettings(),
    ).listen(
      (position) {
        // Отсекаем грубые сетевые фиксы, чтобы точка на карте охраны не «прыгала».
        if (!LocationPermissionService.isAcceptableFix(position)) return;
        _lastFix = position;
      },
      // Ошибка GPS не должна ронять вызов: таймер продолжит слать последний фикс.
      onError: (_) {},
    );

    _timer = Timer.periodic(resendInterval, (_) => _send());
  }

  void stop() {
    if (!isTracking) return;
    _subscription?.cancel();
    _subscription = null;
    _timer?.cancel();
    _timer = null;
    _lastFix = null;
  }

  void dispose() => stop();

  Future<void> _send() async {
    final position = _lastFix;
    if (position == null) return;
    await onPosition(position);
  }
}
