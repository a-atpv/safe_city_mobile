import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_city/core/api/api_exception.dart';

/// Контракт отказа «вне зоны обслуживания».
///
/// Бэкенд отвечает на POST /emergency/call структурой
/// `{"detail": {"code": …, "message": …, "city": …}}`. Приложение по коду
/// показывает отдельный экран вместо снекбара «что-то пошло не так», поэтому
/// разъезд формы ответа и разбора здесь — это молча потерянное объяснение
/// человеку, почему помощь не едет.
DioException _badRequest(dynamic body) {
  final options = RequestOptions(path: '/emergency/call');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: options,
      statusCode: 400,
      data: body,
    ),
  );
}

void main() {
  const message =
      'Safe City пока работает только в городе Актобе. По вашим координатам '
      'направить экипаж мы не сможем — при опасности звоните 102.';

  test('структурированный отказ даёт и код, и текст сервера', () {
    final error = ApiException.fromDioError(_badRequest({
      'detail': {
        'code': 'outside_service_area',
        'message': message,
        'city': 'Актобе',
      }
    }));

    expect(error.code, ApiErrorCodes.outsideServiceArea);
    expect(error.message, message);
    expect(error.statusCode, 400);
  });

  test('тело, пришедшее строкой, разбирается так же', () {
    final error = ApiException.fromDioError(_badRequest(
      '{"detail": {"code": "outside_service_area", "message": "$message"}}',
    ));

    expect(error.code, ApiErrorCodes.outsideServiceArea);
    expect(error.message, message);
  });

  test('обычная строковая ошибка кода не получает', () {
    final error = ApiException.fromDioError(
      _badRequest({'detail': 'You already have an active emergency call'}),
    );

    expect(error.code, isNull);
    expect(error.message, 'You already have an active emergency call');
  });

  test('ошибка без тела не ломает разбор', () {
    final error = ApiException.fromDioError(_badRequest(null));

    expect(error.code, isNull);
  });
}
