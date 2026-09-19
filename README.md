# Safe City Mobile

Мобильное приложение для системы экстренного реагирования Safe City.

## Технологии

- **Flutter** - кроссплатформенная разработка (iOS + Android)
- **Riverpod** - управление состоянием
- **Go Router** - навигация
- **Dio** - HTTP клиент
- **Geolocator** - геолокация
- **2GIS** - карты (будет добавлено)

## Запуск

```bash
# Установить зависимости
flutter pub get

# Запустить на устройстве
flutter run

# Сборка APK
flutter build apk --release

# Сборка iOS
flutter build ios --release
```

## Структура проекта

```
lib/
├── core/               # Ядро приложения
│   ├── api/           # HTTP клиент, обработка ошибок
│   ├── constants/     # Константы
│   ├── router/        # Навигация
│   └── theme/         # Тема, цвета
├── features/          # Фичи (по экранам)
│   ├── auth/          # Авторизация
│   ├── home/          # Главный экран с SOS
│   ├── emergency/     # Активный вызов
│   ├── history/       # История вызовов
│   └── profile/       # Профиль
├── shared/            # Общие компоненты
│   ├── providers/     # Глобальные провайдеры
│   └── widgets/       # Общие виджеты
└── main.dart
```

## Экраны

1. **Login** - вход по номеру телефона
2. **OTP** - подтверждение SMS кодом
3. **Home** - главный экран с кнопкой SOS
4. **Emergency** - активный вызов (радар, статус, таймер)
5. **History** - история вызовов
6. **Profile** - профиль пользователя

## Настройка

### API URL

Измените `apiBaseUrl` в `lib/core/constants/app_constants.dart`:

```dart
static const String apiBaseUrl = 'https://your-api.com/api/v1';
```

### Геолокация

iOS: добавьте в `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Для определения вашего местоположения при вызове охраны</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>Для отслеживания местоположения во время активного вызова</string>
```

Android: добавлено автоматически через `geolocator` пакет.

### Аналитика рекламных кампаний

Событие уходит сразу на две площадки — Meta App Events и Google Analytics for
Firebase, — поэтому новые события добавляются только через
`lib/core/analytics/app_analytics.dart`. Звать `MetaAnalytics` или
`GoogleAnalytics` из экранов не нужно: так событие попадёт лишь в один из двух
кабинетов, и расхождение заметят не скоро.

Чего в событиях быть не должно: координат, адреса, содержания вызова SOS,
имени, email и телефона. Причина не в общей осторожности — политика Google Play
запрещает использовать фоновую геолокацию в рекламных целях, а разрешение на
неё у приложения есть и проходило отдельное ревью.

Установку считать руками не надо: Meta засчитывает её сама, Firebase шлёт
`first_open` — это и есть конверсия «Установка приложения» в Google Ads, после
того как проект Firebase связан с аккаунтом Ads. Ключи Meta лежат в
`android/app/src/main/res/values/strings.xml` и `ios/Runner/Info.plist`,
Firebase — в `google-services.json` и `GoogleService-Info.plist`.

Проверить, что события доходят (Firebase Console → Analytics → DebugView):

```bash
adb shell setprop debug.firebase.analytics.app com.safeCity.appname
```

Выключить отладочный режим: `adb shell setprop debug.firebase.analytics.app .none.`

### Языки

Приложение говорит на казахском, русском и английском. Язык выбирают кнопкой
в углу экрана входа или в профиле. Пока человек не выбрал сам, интерфейс
русский, какой бы ни был язык телефона. Выбор хранится на телефоне
(`lib/l10n/app_language.dart`), уходит с каждым запросом в `Accept-Language`
и после входа — в `PATCH /user/settings`, чтобы сервер писал пуши и ошибки на
нём же.

Строки лежат в `lib/l10n/app_ru.arb` (исходный язык), `app_kk.arb` и
`app_en.arb`. Новая строка добавляется во все три файла, в экране — через
`context.l10n.имяСтроки`, в коде без `BuildContext` — через `currentL10n`.
Dart-код из ARB генерирует `flutter pub get` (или `flutter gen-l10n`).
`test/l10n_arb_test.dart` падает, если строку забыли перевести, а
`test/l10n_screens_test.dart` — если текст на каком-то языке вылез за экран
шириной 320 точек.

Системные запросы iOS (геолокация, камера, галерея, трекинг) переведены в
`ios/Runner/{kk,ru,en}.lproj/InfoPlist.strings`. iOS показывает их на языке
телефона, а не на выбранном в приложении.

## TODO

- [ ] Интеграция 2GIS карт
- [ ] Push-уведомления (Firebase)
- [ ] Оплата подписки
- [ ] Экран paywall
