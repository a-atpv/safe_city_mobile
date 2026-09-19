// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonOk => 'ОК';

  @override
  String get commonGotIt => 'Понятно';

  @override
  String get commonClose => 'Закрыть';

  @override
  String get commonSave => 'Сохранить';

  @override
  String get commonDelete => 'Удалить';

  @override
  String get commonRetry => 'Повторить';

  @override
  String get commonContinue => 'Продолжить';

  @override
  String get commonBack => 'Назад';

  @override
  String get commonError => 'Ошибка';

  @override
  String get commonUser => 'Пользователь';

  @override
  String get languageTitle => 'Язык';

  @override
  String get loginTagline => 'Ваша безопасность — наш приоритет';

  @override
  String get loginEnterEmail => 'Введите email';

  @override
  String get loginInvalidEmail => 'Введите корректный email';

  @override
  String get loginGetCode => 'Получить код';

  @override
  String get loginDocumentOpenFailed => 'Не удалось открыть документ';

  @override
  String loginConsent(String offer, String terms, String privacy) {
    return 'Продолжая, вы принимаете $offer, $terms и $privacy';
  }

  @override
  String get loginConsentOffer => 'публичную оферту';

  @override
  String get loginConsentTerms => 'условия использования';

  @override
  String get loginConsentPrivacy => 'политику конфиденциальности';

  @override
  String get otpTitle => 'Введите код';

  @override
  String otpSentTo(String target) {
    return 'Код отправлен на $target';
  }

  @override
  String otpResendIn(int seconds) {
    return 'Отправить повторно через $seconds сек';
  }

  @override
  String get otpResend => 'Отправить повторно';

  @override
  String get otpConfirm => 'Подтвердить';

  @override
  String get profileTitle => 'Профиль';

  @override
  String get profilePersonalData => 'Личные данные';

  @override
  String get profileSubscription => 'Подписка';

  @override
  String get profileSubscriptionActive => 'Активна';

  @override
  String get profileDocuments => 'Документы';

  @override
  String get profileSupport => 'Поддержка';

  @override
  String get profileMailAppFailed => 'Не удалось открыть почтовое приложение';

  @override
  String get profileAbout => 'О приложении';

  @override
  String get profileLogout => 'Выйти';

  @override
  String get profileDeleteAccount => 'Удалить аккаунт';

  @override
  String get profileTakePhoto => 'Сделать фото';

  @override
  String get profileChooseFromGallery => 'Выбрать из галереи';

  @override
  String get profileDeletePhoto => 'Удалить фото';

  @override
  String get profilePhotoDeleteFailed => 'Не удалось удалить фото';

  @override
  String get profilePhotoUploadFailed => 'Не удалось загрузить фото';

  @override
  String get profileImagePickFailed => 'Не удалось выбрать изображение';

  @override
  String get profileEditTitle => 'Редактировать профиль';

  @override
  String get profileNameLabel => 'Имя';

  @override
  String get profileNameHint => 'Введите ваше имя';

  @override
  String get profilePhoneLabel => 'Телефон';

  @override
  String get profileSecretLabel => 'Секретный код';

  @override
  String get profileSecretHint => 'Слово для отмены вызова';

  @override
  String get profileSecretHelp =>
      'Используется для подтверждения отмены вызова охраны';

  @override
  String get profileLogoutConfirm => 'Выйти из аккаунта?';

  @override
  String get profileDeleteConfirmTitle => 'Удалить аккаунт?';

  @override
  String get profileDeleteConfirmBody =>
      'Это действие необратимо. Все ваши данные будут удалены.';

  @override
  String get documentsPublicOffer => 'Публичная оферта';

  @override
  String get documentsPrivacyPolicy => 'Политика конфиденциальности';

  @override
  String get documentsUserAgreement => 'Пользовательское соглашение';

  @override
  String get documentsRussianOnly =>
      'Документы доступны только на русском языке';

  @override
  String get errorTimeout =>
      'Превышено время ожидания. Проверьте интернет-соединение.';

  @override
  String get errorConnection =>
      'Ошибка подключения. Проверьте интернет-соединение.';

  @override
  String get errorSessionExpired =>
      'Сессия истекла. Пожалуйста, войдите снова.';

  @override
  String get errorForbidden => 'У вас нет доступа к этому ресурсу.';

  @override
  String get errorTooManyRequests =>
      'Слишком много запросов. Попробуйте позже.';

  @override
  String errorServer(String code) {
    return 'Ошибка сервера: $code';
  }

  @override
  String get errorCancelled => 'Запрос отменён';

  @override
  String get errorUnknown => 'Произошла неизвестная ошибка';

  @override
  String get errorNetworkTitle => 'Ошибка сети';

  @override
  String get errorGenericTitle => 'Произошла ошибка';

  @override
  String get errorGenericBody =>
      'Что-то пошло не так. Пожалуйста, попробуйте позже.';

  @override
  String get errorRequestFailed => 'Произошла ошибка при запросе к серверу';

  @override
  String get callCompletedTitle => 'Успешно';

  @override
  String get callCompletedBody =>
      'Вызов успешно завершен! Пожалуйста, оцените работу службы безопасности.';

  @override
  String get callRate => 'Оценить';

  @override
  String get callCancelledTitle => 'Вызов отменен';

  @override
  String get callCancelledBySystem => 'Ваш вызов был отменен системой.';

  @override
  String get callCancelledByUser => 'Вызов отменен.';

  @override
  String get callRedirectedTitle => 'Вызов перенаправлен';

  @override
  String get callRedirectedBody =>
      'Ваш вызов передан другой службе. Ищем ближайшего свободного сотрудника.';

  @override
  String get callRedirectedNote => 'Комментарий службы:';

  @override
  String get chatTitle => 'Чат с экипажем';

  @override
  String get chatMessageHint => 'Введите сообщение...';

  @override
  String get reviewCallCompleted => 'Вызов завершён';

  @override
  String get reviewRateCrew => 'Оцените работу экипажа';

  @override
  String get reviewCommentHint => 'Комментарий (необязательно)';

  @override
  String get reviewSubmit => 'Отправить отзыв';

  @override
  String get reviewSkip => 'Пропустить';

  @override
  String get historyTitle => 'История вызовов';

  @override
  String get historyLoadFailed => 'Ошибка загрузки истории';

  @override
  String get historyFilterAll => 'Все';

  @override
  String get historyFilterCompleted => 'Завершённые';

  @override
  String get historyFilterCancelled => 'Отменённые';

  @override
  String get historyEmpty => 'История пуста';

  @override
  String historyDurationMinutes(int minutes) {
    return '$minutes мин';
  }

  @override
  String get historyStatusCompleted => 'Завершён';

  @override
  String get historyStatusCancelled => 'Отменён';

  @override
  String get historyStatusInProgress => 'В процессе';

  @override
  String get notificationsTitle => 'Уведомления';

  @override
  String get notificationsMarkAllRead => 'Прочитать все';

  @override
  String get notificationsEmpty => 'Нет уведомлений';

  @override
  String notificationsMinutesAgo(int minutes) {
    return '$minutes мин. назад';
  }

  @override
  String notificationsHoursAgo(int hours) {
    return '$hours ч. назад';
  }

  @override
  String get commonNo => 'Нет';

  @override
  String get sosCancelTitle => 'Отменить вызов?';

  @override
  String get sosCancelBody =>
      'Введите секретный код для подтверждения отмены вызова охраны.';

  @override
  String get sosSecretHint => 'Ваше секретное слово';

  @override
  String get sosCancelConfirm => 'Да, отменить';

  @override
  String get sosCreateFailed => 'Не удалось создать вызов.';

  @override
  String get sosLocationServicesOff =>
      'Службы геолокации отключены. Включите GPS в настройках устройства.';

  @override
  String get sosLocationDenied =>
      'Доступ к геолокации запрещён. Разрешите доступ для вызова охраны.';

  @override
  String get sosLocationTimeout =>
      'Не удалось определить местоположение за отведенное время. Проверьте GPS и повторите.';

  @override
  String sosLocationFailedDetails(String error) {
    return 'Не удалось определить местоположение: $error';
  }

  @override
  String get sosLocationFailed =>
      'Не удалось определить местоположение. Проверьте настройки GPS.';

  @override
  String get sosOutsideAreaTitle => 'Вы вне зоны обслуживания';

  @override
  String get sosCall102 => 'Позвонить 102';

  @override
  String get sosDialerFailed =>
      'Не удалось открыть набор номера. Позвоните 102.';

  @override
  String get homeNoSubscriptionTitle => 'Подписка не активна';

  @override
  String get homeNoSubscriptionBody =>
      'Для использования функции экстренного вызова необходима активная подписка.';

  @override
  String get homeSubscribe => 'Оформить';

  @override
  String get homeTapToCall => 'Нажмите для вызова охраны';

  @override
  String get homeTapToSubscribe =>
      'Подписка не активна — нажмите, чтобы оформить';

  @override
  String get homeSearchingSecurity => 'Поиск\nохраны...';

  @override
  String get homeInProgress => 'В работе';

  @override
  String get homeServicesNotified => 'Ближайшие службы\nоповещены';

  @override
  String get sosCancelCall => 'Отменить вызов';

  @override
  String get homeSecurityAssigned => 'Охрана назначена';

  @override
  String homeReviews(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count отзыва',
      many: '$count отзывов',
      few: '$count отзыва',
      one: '$count отзыв',
    );
    return '$_temp0';
  }

  @override
  String get homeCallDetails => 'Детали вызова';

  @override
  String get homeSubscriptionInactive => 'Не активна';

  @override
  String get onboardingRemovePhoto => 'Убрать фото';

  @override
  String get onboardingAddPhoto => 'Добавьте фото профиля';

  @override
  String get onboardingWelcome => 'Добро пожаловать!';

  @override
  String get onboardingFillProfile =>
      'Заполните данные профиля,\nчтобы продолжить';

  @override
  String get onboardingFullName => 'Полное имя';

  @override
  String get onboardingNameHint => 'Ваше имя и фамилия';

  @override
  String get onboardingNameRequired => 'Пожалуйста, введите ваше имя';

  @override
  String get onboardingPhone => 'Номер телефона';

  @override
  String get onboardingOptional => 'Необязательно';

  @override
  String get onboardingSecretLabel => 'Секретное слово * (для отмены вызова)';

  @override
  String get onboardingSecretHint => 'Секретное слово';

  @override
  String get onboardingSecretRequired => 'Пожалуйста, введите секретное слово';

  @override
  String get settingsDeleteTitle => 'Удаление аккаунта';

  @override
  String get settingsDeleteBody =>
      'Вы действительно хотите удалить свой аккаунт? Это действие необратимо.';

  @override
  String get settingsPush => 'Push-уведомления';

  @override
  String get settingsCallSound => 'Звук звонка';

  @override
  String get settingsVibration => 'Вибрация';

  @override
  String get settingsApp => 'Приложение';

  @override
  String get settingsLanguage => 'Язык приложения';

  @override
  String get settingsDarkTheme => 'Тёмная тема';

  @override
  String documentsLoading(int progress) {
    return 'Загрузка... $progress%';
  }

  @override
  String get documentsLoadFailed => 'Не удалось загрузить страницу';

  @override
  String get documentsCheckConnection =>
      'Пожалуйста, проверьте интернет-соединение и попробуйте снова.';

  @override
  String get updateNewVersion => 'Вышла новая версия приложения.';

  @override
  String get updateRequiredTitle => 'Нужно обновиться';

  @override
  String get updateAvailableTitle => 'Вышло обновление';

  @override
  String updateVersion(String version) {
    return 'Версия $version.';
  }

  @override
  String get updateAction => 'Обновить';

  @override
  String get navHome => 'Главная';

  @override
  String get navHistory => 'История';

  @override
  String get authSendCodeFailed => 'Не удалось отправить код';

  @override
  String get authWrongCode => 'Неверный код';

  @override
  String get permLocationDeniedOpenSettings =>
      'Доступ к геолокации запрещён. Откройте настройки приложения.';

  @override
  String get permLocationTitle => 'Разрешение на геолокацию';

  @override
  String get permLocationDisclosure =>
      'Safe City собирает данные о местоположении для работы функции экстренного вызова SOS, даже когда приложение закрыто или не используется. Эти данные необходимы для оперативного прибытия службы охраны по вашим координатам.';

  @override
  String get permDecline => 'Отклонить';

  @override
  String get permAccept => 'Принять';

  @override
  String get permBackgroundTitle => 'Фоновый режим SOS';

  @override
  String get permBackgroundBody =>
      'Для надежной отправки сигнала SOS при свернутом или закрытом приложении, пожалуйста, выберите «Разрешить в любом режиме» (Allow all the time) в настройках разрешений.';

  @override
  String get permLater => 'Позже';

  @override
  String get permOpenSettings => 'В настройки';

  @override
  String get locationForegroundNotification =>
      'Отправка координат охране в фоновом режиме';

  @override
  String get pushChannelName => 'Статус вызова';

  @override
  String get pushChannelDescription =>
      'Уведомления о ходе ваших вызовов охраны';

  @override
  String get sosStatusRedirecting => 'Передаём другой службе...';

  @override
  String get sosStatusSearching => 'Поиск охраны...';

  @override
  String get sosStatusWaiting => 'Ожидание ответа...';

  @override
  String get sosStatusAccepted => 'Вызов принят';

  @override
  String get sosStatusEnRoute => 'Охрана в пути';

  @override
  String get sosStatusArrived => 'Охрана прибыла';

  @override
  String get sosStatusCompleted => 'Вызов завершён';

  @override
  String get sosStatusCancelled => 'Отменён';

  @override
  String get sosStatusCancelledBySystem => 'Отменён системой';

  @override
  String get sosCallActive => 'Вызов активен';

  @override
  String get sosSettings => 'Настройки';

  @override
  String get sosRedirectedHint =>
      'Ваш вызов передан другой службе.\nИщем ближайшего свободного сотрудника.';

  @override
  String get sosServicesNotified => 'Ближайшие службы оповещены';

  @override
  String get sosToHome => 'На главную';

  @override
  String get paywallHeadline => 'Полный доступ ко всем функциям';

  @override
  String get paywallSubhead =>
      'Кнопка SOS, геолокация в реальном времени и связь с диспетчером 24/7.';

  @override
  String get paywallPaymentCreateFailed => 'Не удалось создать платёж';

  @override
  String paywallRecurringTerms(String amounts) {
    return 'Подписка продлевается автоматически: $amounts — бессрочно, до отмены. Отключить автопродление можно в любой момент: Профиль → Подписка → «Отменить подписку», либо обратившись в службу поддержки. После отмены списаний больше не будет, доступ сохранится до конца оплаченного периода.';
  }

  @override
  String get paywallOneTimeTerms => 'Оплата за выбранный период.';

  @override
  String paywallChargeMonthly(String price) {
    return '$price ₸ каждый месяц';
  }

  @override
  String paywallChargeYearly(String price) {
    return '$price ₸ каждый год';
  }

  @override
  String paywallChargeEither(String first, String second) {
    return '$first или $second';
  }

  @override
  String paywallConsentRecurring(String privacy, String offer) {
    return 'Я даю согласие на регулярные (автоматические) списания, на $privacy и принимаю условия $offer, в которой подробно описаны правила рекуррентных платежей.';
  }

  @override
  String paywallConsent(String privacy, String offer) {
    return 'Я даю согласие на $privacy и принимаю условия $offer.';
  }

  @override
  String get paywallConsentPrivacy => 'обработку персональных данных';

  @override
  String get paywallConsentOffer => 'публичной оферты';

  @override
  String get paywallPlanYearly => 'Годовая';

  @override
  String get paywallPlanMonthly => 'Месячная';

  @override
  String get paywallBestValue => 'выгодно';

  @override
  String paywallPricePerYear(String price) {
    return '$price ₸ / год';
  }

  @override
  String paywallPricePerMonth(String price) {
    return '$price ₸ / мес';
  }

  @override
  String get paywallFeatureSos => 'Кнопка SOS в одно касание';

  @override
  String get paywallFeatureLocation => 'Геолокация в реальном времени';

  @override
  String get paywallFeatureDispatcher => 'Связь с диспетчером 24/7';

  @override
  String get paywallFeaturePlatforms => 'Приложение для iOS и Android';

  @override
  String get subscriptionManageTitle => 'Управление подпиской';

  @override
  String get subscriptionPlanYearly => 'Годовая подписка';

  @override
  String get subscriptionPlanMonthly => 'Месячная подписка';

  @override
  String get subscriptionCancelTitle => 'Отменить подписку?';

  @override
  String subscriptionCancelBody(String until) {
    return 'Автоматические списания прекратятся. Доступ к функциям сохранится до $until, деньги за оставшийся период не списываются и не возвращаются. Возобновить подписку можно в любой момент.';
  }

  @override
  String get subscriptionKeep => 'Не отменять';

  @override
  String get subscriptionCancel => 'Отменить подписку';

  @override
  String get subscriptionAutoRenewTurnedOff => 'Автопродление отключено';

  @override
  String get subscriptionCancelFailed => 'Не удалось отменить подписку';

  @override
  String get subscriptionInactiveTitle => 'Подписка неактивна';

  @override
  String get subscriptionInactiveBody =>
      'Оформите подписку, чтобы пользоваться кнопкой SOS и связью с диспетчером.';

  @override
  String subscriptionNoteCancelled(String date) {
    return 'Автопродление отключено. Подписка действует до $date, после чего доступ прекратится. Списаний больше не будет.';
  }

  @override
  String get subscriptionNoteAutoRenew =>
      'Подписка продлевается автоматически. Вы можете отключить автопродление в любой момент — доступ сохранится до конца оплаченного периода.';

  @override
  String subscriptionNoteNoAutoRenew(String date) {
    return 'Подписка действует до $date. Автопродление не подключено.';
  }

  @override
  String get subscriptionAccessUntil => 'Доступ до';

  @override
  String get subscriptionActiveUntilLabel => 'Активна до';

  @override
  String get subscriptionAutoRenew => 'Автопродление';

  @override
  String get subscriptionOn => 'Включено';

  @override
  String get subscriptionOff => 'Отключено';

  @override
  String get subscriptionResume => 'Возобновить подписку';

  @override
  String get paymentConfirming => 'Подтверждаем оплату…';

  @override
  String get paymentMayTakeSeconds => 'Это может занять несколько секунд.';

  @override
  String paymentActiveUntil(String date) {
    return 'Активна до $date';
  }

  @override
  String get paymentSubscriptionActive => 'Подписка активна';

  @override
  String get paymentSubscribed => 'Подписка оформлена';

  @override
  String get paymentDone => 'Готово';

  @override
  String get paymentStillProcessing => 'Оплата ещё обрабатывается';

  @override
  String get paymentStillProcessingBody =>
      'Если вы завершили оплату, подписка активируется в течение пары минут. Можно проверить снова или вернуться позже.';

  @override
  String get paymentCheckAgain => 'Проверить снова';

  @override
  String get paymentBackHome => 'Вернуться на главную';
}
