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
///   * таймер — гарантия, что отметка на сервере обновляется каждые 5 секунд
///     независимо от того, движется человек или стоит.
///
/// Грубые фиксы клиент не отбрасывает: качество оценивает сервер, у которого
/// есть предыдущая точка и её возраст. Отфильтрованный на телефоне фикс просто
/// не доедет, и у оператора точка «замрёт» — приблизительная координата в этот
/// момент полезнее, чем никакой, при условии что её погрешность видна на карте.
class EmergencyLocationService {
  EmergencyLocationService({required this.onPosition});

  /// Куда отправлять координату. Инжектируется провайдером, чтобы сервис не
  /// знал ни про Riverpod, ни про API-клиент.
  final Future<void> Function(Position position, Duration fixAge) onPosition;

  /// Как часто переотправлять последний известный фикс.
  static const resendInterval = Duration(seconds: 5);

  /// Заметное перемещение — отправляем сразу, не дожидаясь тика: на скорости
  /// машины между тиками человек уезжает на десятки метров.
  static const _sendImmediatelyAfterMeters = 25.0;

  /// Но не чаще, чем раз в столько — чтобы поток фиксов не превратился в поток
  /// запросов.
  static const _minSendGap = Duration(seconds: 2);

  StreamSubscription<Position>? _subscription;
  Timer? _timer;
  Position? _lastFix;
  Position? _lastSentFix;
  DateTime? _lastSentAt;
  bool _sending = false;

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
        _lastFix = position;
        if (_hasMovedSinceLastSend(position)) _send();
      },
      // Ошибка GPS не должна ронять вызов: таймер продолжит слать последний фикс.
      onError: (_) {},
    );

    _timer = Timer.periodic(resendInterval, (_) => _send());
    // Первый фикс уходит сразу, а не через пять секунд.
    _send();
  }

  void stop() {
    if (!isTracking) return;
    _subscription?.cancel();
    _subscription = null;
    _timer?.cancel();
    _timer = null;
    _lastFix = null;
    _lastSentFix = null;
    _lastSentAt = null;
  }

  void dispose() => stop();

  bool _hasMovedSinceLastSend(Position position) {
    final sentAt = _lastSentAt;
    if (sentAt != null && DateTime.now().difference(sentAt) < _minSendGap) {
      return false;
    }
    final previous = _lastSentFix;
    if (previous == null) return true;
    final moved = Geolocator.distanceBetween(
      previous.latitude,
      previous.longitude,
      position.latitude,
      position.longitude,
    );
    return moved >= _sendImmediatelyAfterMeters;
  }

  Future<void> _send() async {
    final position = _lastFix;
    if (position == null || _sending) return;
    _sending = true;
    // Возраст фикса, а не времени отправки: если GPS отвалился и мы досылаем
    // старую координату, сервер должен видеть её настоящий возраст и показать
    // оператору «точка устарела», а не делать вид, что связь в порядке.
    final age = DateTime.now().difference(position.timestamp);
    try {
      await onPosition(position, age.isNegative ? Duration.zero : age);
      _lastSentFix = position;
      _lastSentAt = DateTime.now();
    } finally {
      _sending = false;
    }
  }
}
