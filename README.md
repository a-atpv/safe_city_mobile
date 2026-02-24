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

## TODO

- [ ] Интеграция 2GIS карт
- [ ] Push-уведомления (Firebase)
- [ ] Оплата подписки
- [ ] Экран paywall
