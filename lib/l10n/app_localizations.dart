import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_kk.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('kk'),
    Locale('ru'),
  ];

  /// Кнопка отмены в диалогах
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get commonCancel;

  /// No description provided for @commonOk.
  ///
  /// In ru, this message translates to:
  /// **'ОК'**
  String get commonOk;

  /// No description provided for @commonGotIt.
  ///
  /// In ru, this message translates to:
  /// **'Понятно'**
  String get commonGotIt;

  /// No description provided for @commonClose.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get commonClose;

  /// No description provided for @commonSave.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get commonDelete;

  /// No description provided for @commonRetry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get commonRetry;

  /// No description provided for @commonContinue.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить'**
  String get commonContinue;

  /// No description provided for @commonBack.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get commonBack;

  /// No description provided for @commonError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка'**
  String get commonError;

  /// Подпись в профиле, пока имя не заполнено
  ///
  /// In ru, this message translates to:
  /// **'Пользователь'**
  String get commonUser;

  /// Заголовок шторки выбора языка и пункт профиля
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get languageTitle;

  /// No description provided for @loginTagline.
  ///
  /// In ru, this message translates to:
  /// **'Ваша безопасность — наш приоритет'**
  String get loginTagline;

  /// No description provided for @loginEnterEmail.
  ///
  /// In ru, this message translates to:
  /// **'Введите email'**
  String get loginEnterEmail;

  /// No description provided for @loginInvalidEmail.
  ///
  /// In ru, this message translates to:
  /// **'Введите корректный email'**
  String get loginInvalidEmail;

  /// No description provided for @loginGetCode.
  ///
  /// In ru, this message translates to:
  /// **'Получить код'**
  String get loginGetCode;

  /// No description provided for @loginDocumentOpenFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть документ'**
  String get loginDocumentOpenFailed;

  /// Строка под формой входа. offer, terms, privacy — ссылки на документы (loginConsentOffer и соседние), порядок слов в каждом языке свой
  ///
  /// In ru, this message translates to:
  /// **'Продолжая, вы принимаете {offer}, {terms} и {privacy}'**
  String loginConsent(String offer, String terms, String privacy);

  /// Ссылка в loginConsent, в нужном падеже
  ///
  /// In ru, this message translates to:
  /// **'публичную оферту'**
  String get loginConsentOffer;

  /// Ссылка в loginConsent, в нужном падеже
  ///
  /// In ru, this message translates to:
  /// **'условия использования'**
  String get loginConsentTerms;

  /// Ссылка в loginConsent, в нужном падеже
  ///
  /// In ru, this message translates to:
  /// **'политику конфиденциальности'**
  String get loginConsentPrivacy;

  /// No description provided for @otpTitle.
  ///
  /// In ru, this message translates to:
  /// **'Введите код'**
  String get otpTitle;

  /// No description provided for @otpSentTo.
  ///
  /// In ru, this message translates to:
  /// **'Код отправлен на {target}'**
  String otpSentTo(String target);

  /// No description provided for @otpResendIn.
  ///
  /// In ru, this message translates to:
  /// **'Отправить повторно через {seconds} сек'**
  String otpResendIn(int seconds);

  /// No description provided for @otpResend.
  ///
  /// In ru, this message translates to:
  /// **'Отправить повторно'**
  String get otpResend;

  /// No description provided for @otpConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить'**
  String get otpConfirm;

  /// No description provided for @profileTitle.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get profileTitle;

  /// No description provided for @profilePersonalData.
  ///
  /// In ru, this message translates to:
  /// **'Личные данные'**
  String get profilePersonalData;

  /// No description provided for @profileSubscription.
  ///
  /// In ru, this message translates to:
  /// **'Подписка'**
  String get profileSubscription;

  /// Бейдж у пункта «Подписка»
  ///
  /// In ru, this message translates to:
  /// **'Активна'**
  String get profileSubscriptionActive;

  /// No description provided for @profileDocuments.
  ///
  /// In ru, this message translates to:
  /// **'Документы'**
  String get profileDocuments;

  /// No description provided for @profileSupport.
  ///
  /// In ru, this message translates to:
  /// **'Поддержка'**
  String get profileSupport;

  /// No description provided for @profileMailAppFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть почтовое приложение'**
  String get profileMailAppFailed;

  /// No description provided for @profileAbout.
  ///
  /// In ru, this message translates to:
  /// **'О приложении'**
  String get profileAbout;

  /// No description provided for @profileLogout.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get profileLogout;

  /// No description provided for @profileDeleteAccount.
  ///
  /// In ru, this message translates to:
  /// **'Удалить аккаунт'**
  String get profileDeleteAccount;

  /// No description provided for @profileTakePhoto.
  ///
  /// In ru, this message translates to:
  /// **'Сделать фото'**
  String get profileTakePhoto;

  /// No description provided for @profileChooseFromGallery.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать из галереи'**
  String get profileChooseFromGallery;

  /// No description provided for @profileDeletePhoto.
  ///
  /// In ru, this message translates to:
  /// **'Удалить фото'**
  String get profileDeletePhoto;

  /// No description provided for @profilePhotoDeleteFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось удалить фото'**
  String get profilePhotoDeleteFailed;

  /// No description provided for @profilePhotoUploadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить фото'**
  String get profilePhotoUploadFailed;

  /// No description provided for @profileImagePickFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось выбрать изображение'**
  String get profileImagePickFailed;

  /// No description provided for @profileEditTitle.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать профиль'**
  String get profileEditTitle;

  /// No description provided for @profileNameLabel.
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get profileNameLabel;

  /// No description provided for @profileNameHint.
  ///
  /// In ru, this message translates to:
  /// **'Введите ваше имя'**
  String get profileNameHint;

  /// No description provided for @profilePhoneLabel.
  ///
  /// In ru, this message translates to:
  /// **'Телефон'**
  String get profilePhoneLabel;

  /// Слово, которым человек подтверждает отмену вызова
  ///
  /// In ru, this message translates to:
  /// **'Секретный код'**
  String get profileSecretLabel;

  /// No description provided for @profileSecretHint.
  ///
  /// In ru, this message translates to:
  /// **'Слово для отмены вызова'**
  String get profileSecretHint;

  /// No description provided for @profileSecretHelp.
  ///
  /// In ru, this message translates to:
  /// **'Используется для подтверждения отмены вызова охраны'**
  String get profileSecretHelp;

  /// No description provided for @profileLogoutConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Выйти из аккаунта?'**
  String get profileLogoutConfirm;

  /// No description provided for @profileDeleteConfirmTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить аккаунт?'**
  String get profileDeleteConfirmTitle;

  /// No description provided for @profileDeleteConfirmBody.
  ///
  /// In ru, this message translates to:
  /// **'Это действие необратимо. Все ваши данные будут удалены.'**
  String get profileDeleteConfirmBody;

  /// No description provided for @documentsPublicOffer.
  ///
  /// In ru, this message translates to:
  /// **'Публичная оферта'**
  String get documentsPublicOffer;

  /// No description provided for @documentsPrivacyPolicy.
  ///
  /// In ru, this message translates to:
  /// **'Политика конфиденциальности'**
  String get documentsPrivacyPolicy;

  /// No description provided for @documentsUserAgreement.
  ///
  /// In ru, this message translates to:
  /// **'Пользовательское соглашение'**
  String get documentsUserAgreement;

  /// Пометка в списке документов; на русском интерфейсе не показывается
  ///
  /// In ru, this message translates to:
  /// **'Документы доступны только на русском языке'**
  String get documentsRussianOnly;

  /// No description provided for @errorTimeout.
  ///
  /// In ru, this message translates to:
  /// **'Превышено время ожидания. Проверьте интернет-соединение.'**
  String get errorTimeout;

  /// No description provided for @errorConnection.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка подключения. Проверьте интернет-соединение.'**
  String get errorConnection;

  /// No description provided for @errorSessionExpired.
  ///
  /// In ru, this message translates to:
  /// **'Сессия истекла. Пожалуйста, войдите снова.'**
  String get errorSessionExpired;

  /// No description provided for @errorForbidden.
  ///
  /// In ru, this message translates to:
  /// **'У вас нет доступа к этому ресурсу.'**
  String get errorForbidden;

  /// No description provided for @errorTooManyRequests.
  ///
  /// In ru, this message translates to:
  /// **'Слишком много запросов. Попробуйте позже.'**
  String get errorTooManyRequests;

  /// No description provided for @errorServer.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка сервера: {code}'**
  String errorServer(String code);

  /// No description provided for @errorCancelled.
  ///
  /// In ru, this message translates to:
  /// **'Запрос отменён'**
  String get errorCancelled;

  /// No description provided for @errorUnknown.
  ///
  /// In ru, this message translates to:
  /// **'Произошла неизвестная ошибка'**
  String get errorUnknown;

  /// No description provided for @errorNetworkTitle.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка сети'**
  String get errorNetworkTitle;

  /// No description provided for @errorGenericTitle.
  ///
  /// In ru, this message translates to:
  /// **'Произошла ошибка'**
  String get errorGenericTitle;

  /// No description provided for @errorGenericBody.
  ///
  /// In ru, this message translates to:
  /// **'Что-то пошло не так. Пожалуйста, попробуйте позже.'**
  String get errorGenericBody;

  /// No description provided for @errorRequestFailed.
  ///
  /// In ru, this message translates to:
  /// **'Произошла ошибка при запросе к серверу'**
  String get errorRequestFailed;

  /// No description provided for @callCompletedTitle.
  ///
  /// In ru, this message translates to:
  /// **'Успешно'**
  String get callCompletedTitle;

  /// No description provided for @callCompletedBody.
  ///
  /// In ru, this message translates to:
  /// **'Вызов успешно завершен! Пожалуйста, оцените работу службы безопасности.'**
  String get callCompletedBody;

  /// No description provided for @callRate.
  ///
  /// In ru, this message translates to:
  /// **'Оценить'**
  String get callRate;

  /// No description provided for @callCancelledTitle.
  ///
  /// In ru, this message translates to:
  /// **'Вызов отменен'**
  String get callCancelledTitle;

  /// No description provided for @callCancelledBySystem.
  ///
  /// In ru, this message translates to:
  /// **'Ваш вызов был отменен системой.'**
  String get callCancelledBySystem;

  /// No description provided for @callCancelledByUser.
  ///
  /// In ru, this message translates to:
  /// **'Вызов отменен.'**
  String get callCancelledByUser;

  /// No description provided for @callRedirectedTitle.
  ///
  /// In ru, this message translates to:
  /// **'Вызов перенаправлен'**
  String get callRedirectedTitle;

  /// No description provided for @callRedirectedBody.
  ///
  /// In ru, this message translates to:
  /// **'Ваш вызов передан другой службе. Ищем ближайшего свободного сотрудника.'**
  String get callRedirectedBody;

  /// No description provided for @callRedirectedNote.
  ///
  /// In ru, this message translates to:
  /// **'Комментарий службы:'**
  String get callRedirectedNote;

  /// No description provided for @chatTitle.
  ///
  /// In ru, this message translates to:
  /// **'Чат с экипажем'**
  String get chatTitle;

  /// No description provided for @chatMessageHint.
  ///
  /// In ru, this message translates to:
  /// **'Введите сообщение...'**
  String get chatMessageHint;

  /// No description provided for @reviewCallCompleted.
  ///
  /// In ru, this message translates to:
  /// **'Вызов завершён'**
  String get reviewCallCompleted;

  /// No description provided for @reviewRateCrew.
  ///
  /// In ru, this message translates to:
  /// **'Оцените работу экипажа'**
  String get reviewRateCrew;

  /// No description provided for @reviewCommentHint.
  ///
  /// In ru, this message translates to:
  /// **'Комментарий (необязательно)'**
  String get reviewCommentHint;

  /// No description provided for @reviewSubmit.
  ///
  /// In ru, this message translates to:
  /// **'Отправить отзыв'**
  String get reviewSubmit;

  /// No description provided for @reviewSkip.
  ///
  /// In ru, this message translates to:
  /// **'Пропустить'**
  String get reviewSkip;

  /// No description provided for @historyTitle.
  ///
  /// In ru, this message translates to:
  /// **'История вызовов'**
  String get historyTitle;

  /// No description provided for @historyLoadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка загрузки истории'**
  String get historyLoadFailed;

  /// No description provided for @historyFilterAll.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get historyFilterAll;

  /// No description provided for @historyFilterCompleted.
  ///
  /// In ru, this message translates to:
  /// **'Завершённые'**
  String get historyFilterCompleted;

  /// No description provided for @historyFilterCancelled.
  ///
  /// In ru, this message translates to:
  /// **'Отменённые'**
  String get historyFilterCancelled;

  /// No description provided for @historyEmpty.
  ///
  /// In ru, this message translates to:
  /// **'История пуста'**
  String get historyEmpty;

  /// No description provided for @historyDurationMinutes.
  ///
  /// In ru, this message translates to:
  /// **'{minutes} мин'**
  String historyDurationMinutes(int minutes);

  /// No description provided for @historyStatusCompleted.
  ///
  /// In ru, this message translates to:
  /// **'Завершён'**
  String get historyStatusCompleted;

  /// No description provided for @historyStatusCancelled.
  ///
  /// In ru, this message translates to:
  /// **'Отменён'**
  String get historyStatusCancelled;

  /// No description provided for @historyStatusInProgress.
  ///
  /// In ru, this message translates to:
  /// **'В процессе'**
  String get historyStatusInProgress;

  /// No description provided for @notificationsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get notificationsTitle;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In ru, this message translates to:
  /// **'Прочитать все'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Нет уведомлений'**
  String get notificationsEmpty;

  /// No description provided for @notificationsMinutesAgo.
  ///
  /// In ru, this message translates to:
  /// **'{minutes} мин. назад'**
  String notificationsMinutesAgo(int minutes);

  /// No description provided for @notificationsHoursAgo.
  ///
  /// In ru, this message translates to:
  /// **'{hours} ч. назад'**
  String notificationsHoursAgo(int hours);

  /// No description provided for @commonNo.
  ///
  /// In ru, this message translates to:
  /// **'Нет'**
  String get commonNo;

  /// No description provided for @sosCancelTitle.
  ///
  /// In ru, this message translates to:
  /// **'Отменить вызов?'**
  String get sosCancelTitle;

  /// No description provided for @sosCancelBody.
  ///
  /// In ru, this message translates to:
  /// **'Введите секретный код для подтверждения отмены вызова охраны.'**
  String get sosCancelBody;

  /// No description provided for @sosSecretHint.
  ///
  /// In ru, this message translates to:
  /// **'Ваше секретное слово'**
  String get sosSecretHint;

  /// No description provided for @sosCancelConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Да, отменить'**
  String get sosCancelConfirm;

  /// No description provided for @sosCreateFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось создать вызов.'**
  String get sosCreateFailed;

  /// No description provided for @sosLocationServicesOff.
  ///
  /// In ru, this message translates to:
  /// **'Службы геолокации отключены. Включите GPS в настройках устройства.'**
  String get sosLocationServicesOff;

  /// No description provided for @sosLocationDenied.
  ///
  /// In ru, this message translates to:
  /// **'Доступ к геолокации запрещён. Разрешите доступ для вызова охраны.'**
  String get sosLocationDenied;

  /// No description provided for @sosLocationTimeout.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось определить местоположение за отведенное время. Проверьте GPS и повторите.'**
  String get sosLocationTimeout;

  /// Только в отладочной сборке
  ///
  /// In ru, this message translates to:
  /// **'Не удалось определить местоположение: {error}'**
  String sosLocationFailedDetails(String error);

  /// No description provided for @sosLocationFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось определить местоположение. Проверьте настройки GPS.'**
  String get sosLocationFailed;

  /// No description provided for @sosOutsideAreaTitle.
  ///
  /// In ru, this message translates to:
  /// **'Вы вне зоны обслуживания'**
  String get sosOutsideAreaTitle;

  /// No description provided for @sosCall102.
  ///
  /// In ru, this message translates to:
  /// **'Позвонить 102'**
  String get sosCall102;

  /// No description provided for @sosDialerFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть набор номера. Позвоните 102.'**
  String get sosDialerFailed;

  /// No description provided for @homeNoSubscriptionTitle.
  ///
  /// In ru, this message translates to:
  /// **'Подписка не активна'**
  String get homeNoSubscriptionTitle;

  /// No description provided for @homeNoSubscriptionBody.
  ///
  /// In ru, this message translates to:
  /// **'Для использования функции экстренного вызова необходима активная подписка.'**
  String get homeNoSubscriptionBody;

  /// No description provided for @homeSubscribe.
  ///
  /// In ru, this message translates to:
  /// **'Оформить'**
  String get homeSubscribe;

  /// No description provided for @homeTapToCall.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите для вызова охраны'**
  String get homeTapToCall;

  /// No description provided for @homeTapToSubscribe.
  ///
  /// In ru, this message translates to:
  /// **'Подписка не активна — нажмите, чтобы оформить'**
  String get homeTapToSubscribe;

  /// В круге радара, две строки
  ///
  /// In ru, this message translates to:
  /// **'Поиск\nохраны...'**
  String get homeSearchingSecurity;

  /// В круге радара, когда охранник принял вызов
  ///
  /// In ru, this message translates to:
  /// **'В работе'**
  String get homeInProgress;

  /// No description provided for @homeServicesNotified.
  ///
  /// In ru, this message translates to:
  /// **'Ближайшие службы\nоповещены'**
  String get homeServicesNotified;

  /// No description provided for @sosCancelCall.
  ///
  /// In ru, this message translates to:
  /// **'Отменить вызов'**
  String get sosCancelCall;

  /// No description provided for @homeSecurityAssigned.
  ///
  /// In ru, this message translates to:
  /// **'Охрана назначена'**
  String get homeSecurityAssigned;

  /// No description provided for @homeReviews.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} отзыв} few{{count} отзыва} many{{count} отзывов} other{{count} отзыва}}'**
  String homeReviews(int count);

  /// No description provided for @homeCallDetails.
  ///
  /// In ru, this message translates to:
  /// **'Детали вызова'**
  String get homeCallDetails;

  /// Бейдж подписки в шапке главного экрана
  ///
  /// In ru, this message translates to:
  /// **'Не активна'**
  String get homeSubscriptionInactive;

  /// No description provided for @onboardingRemovePhoto.
  ///
  /// In ru, this message translates to:
  /// **'Убрать фото'**
  String get onboardingRemovePhoto;

  /// No description provided for @onboardingAddPhoto.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте фото профиля'**
  String get onboardingAddPhoto;

  /// No description provided for @onboardingWelcome.
  ///
  /// In ru, this message translates to:
  /// **'Добро пожаловать!'**
  String get onboardingWelcome;

  /// No description provided for @onboardingFillProfile.
  ///
  /// In ru, this message translates to:
  /// **'Заполните данные профиля,\nчтобы продолжить'**
  String get onboardingFillProfile;

  /// No description provided for @onboardingFullName.
  ///
  /// In ru, this message translates to:
  /// **'Полное имя'**
  String get onboardingFullName;

  /// No description provided for @onboardingNameHint.
  ///
  /// In ru, this message translates to:
  /// **'Ваше имя и фамилия'**
  String get onboardingNameHint;

  /// No description provided for @onboardingNameRequired.
  ///
  /// In ru, this message translates to:
  /// **'Пожалуйста, введите ваше имя'**
  String get onboardingNameRequired;

  /// No description provided for @onboardingPhone.
  ///
  /// In ru, this message translates to:
  /// **'Номер телефона'**
  String get onboardingPhone;

  /// No description provided for @onboardingOptional.
  ///
  /// In ru, this message translates to:
  /// **'Необязательно'**
  String get onboardingOptional;

  /// No description provided for @onboardingSecretLabel.
  ///
  /// In ru, this message translates to:
  /// **'Секретное слово * (для отмены вызова)'**
  String get onboardingSecretLabel;

  /// No description provided for @onboardingSecretHint.
  ///
  /// In ru, this message translates to:
  /// **'Секретное слово'**
  String get onboardingSecretHint;

  /// No description provided for @onboardingSecretRequired.
  ///
  /// In ru, this message translates to:
  /// **'Пожалуйста, введите секретное слово'**
  String get onboardingSecretRequired;

  /// No description provided for @settingsDeleteTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удаление аккаунта'**
  String get settingsDeleteTitle;

  /// No description provided for @settingsDeleteBody.
  ///
  /// In ru, this message translates to:
  /// **'Вы действительно хотите удалить свой аккаунт? Это действие необратимо.'**
  String get settingsDeleteBody;

  /// No description provided for @settingsPush.
  ///
  /// In ru, this message translates to:
  /// **'Push-уведомления'**
  String get settingsPush;

  /// No description provided for @settingsCallSound.
  ///
  /// In ru, this message translates to:
  /// **'Звук звонка'**
  String get settingsCallSound;

  /// No description provided for @settingsVibration.
  ///
  /// In ru, this message translates to:
  /// **'Вибрация'**
  String get settingsVibration;

  /// No description provided for @settingsApp.
  ///
  /// In ru, this message translates to:
  /// **'Приложение'**
  String get settingsApp;

  /// No description provided for @settingsLanguage.
  ///
  /// In ru, this message translates to:
  /// **'Язык приложения'**
  String get settingsLanguage;

  /// No description provided for @settingsDarkTheme.
  ///
  /// In ru, this message translates to:
  /// **'Тёмная тема'**
  String get settingsDarkTheme;

  /// No description provided for @documentsLoading.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка... {progress}%'**
  String documentsLoading(int progress);

  /// No description provided for @documentsLoadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить страницу'**
  String get documentsLoadFailed;

  /// No description provided for @documentsCheckConnection.
  ///
  /// In ru, this message translates to:
  /// **'Пожалуйста, проверьте интернет-соединение и попробуйте снова.'**
  String get documentsCheckConnection;

  /// No description provided for @updateNewVersion.
  ///
  /// In ru, this message translates to:
  /// **'Вышла новая версия приложения.'**
  String get updateNewVersion;

  /// No description provided for @updateRequiredTitle.
  ///
  /// In ru, this message translates to:
  /// **'Нужно обновиться'**
  String get updateRequiredTitle;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In ru, this message translates to:
  /// **'Вышло обновление'**
  String get updateAvailableTitle;

  /// No description provided for @updateVersion.
  ///
  /// In ru, this message translates to:
  /// **'Версия {version}.'**
  String updateVersion(String version);

  /// No description provided for @updateAction.
  ///
  /// In ru, this message translates to:
  /// **'Обновить'**
  String get updateAction;

  /// No description provided for @navHome.
  ///
  /// In ru, this message translates to:
  /// **'Главная'**
  String get navHome;

  /// No description provided for @navHistory.
  ///
  /// In ru, this message translates to:
  /// **'История'**
  String get navHistory;

  /// No description provided for @authSendCodeFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить код'**
  String get authSendCodeFailed;

  /// No description provided for @authWrongCode.
  ///
  /// In ru, this message translates to:
  /// **'Неверный код'**
  String get authWrongCode;

  /// No description provided for @permLocationDeniedOpenSettings.
  ///
  /// In ru, this message translates to:
  /// **'Доступ к геолокации запрещён. Откройте настройки приложения.'**
  String get permLocationDeniedOpenSettings;

  /// No description provided for @permLocationTitle.
  ///
  /// In ru, this message translates to:
  /// **'Разрешение на геолокацию'**
  String get permLocationTitle;

  /// Prominent Disclosure перед системным запросом геолокации — требование Google Play: должно упоминать сбор местоположения, работу в фоне и функцию, ради которой он нужен
  ///
  /// In ru, this message translates to:
  /// **'Safe City собирает данные о местоположении для работы функции экстренного вызова SOS, даже когда приложение закрыто или не используется. Эти данные необходимы для оперативного прибытия службы охраны по вашим координатам.'**
  String get permLocationDisclosure;

  /// No description provided for @permDecline.
  ///
  /// In ru, this message translates to:
  /// **'Отклонить'**
  String get permDecline;

  /// No description provided for @permAccept.
  ///
  /// In ru, this message translates to:
  /// **'Принять'**
  String get permAccept;

  /// No description provided for @permBackgroundTitle.
  ///
  /// In ru, this message translates to:
  /// **'Фоновый режим SOS'**
  String get permBackgroundTitle;

  /// No description provided for @permBackgroundBody.
  ///
  /// In ru, this message translates to:
  /// **'Для надежной отправки сигнала SOS при свернутом или закрытом приложении, пожалуйста, выберите «Разрешить в любом режиме» (Allow all the time) в настройках разрешений.'**
  String get permBackgroundBody;

  /// No description provided for @permLater.
  ///
  /// In ru, this message translates to:
  /// **'Позже'**
  String get permLater;

  /// No description provided for @permOpenSettings.
  ///
  /// In ru, this message translates to:
  /// **'В настройки'**
  String get permOpenSettings;

  /// Постоянное уведомление Android во время SOS
  ///
  /// In ru, this message translates to:
  /// **'Отправка координат охране в фоновом режиме'**
  String get locationForegroundNotification;

  /// Название канала уведомлений в настройках Android
  ///
  /// In ru, this message translates to:
  /// **'Статус вызова'**
  String get pushChannelName;

  /// No description provided for @pushChannelDescription.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления о ходе ваших вызовов охраны'**
  String get pushChannelDescription;

  /// No description provided for @sosStatusRedirecting.
  ///
  /// In ru, this message translates to:
  /// **'Передаём другой службе...'**
  String get sosStatusRedirecting;

  /// No description provided for @sosStatusSearching.
  ///
  /// In ru, this message translates to:
  /// **'Поиск охраны...'**
  String get sosStatusSearching;

  /// No description provided for @sosStatusWaiting.
  ///
  /// In ru, this message translates to:
  /// **'Ожидание ответа...'**
  String get sosStatusWaiting;

  /// No description provided for @sosStatusAccepted.
  ///
  /// In ru, this message translates to:
  /// **'Вызов принят'**
  String get sosStatusAccepted;

  /// No description provided for @sosStatusEnRoute.
  ///
  /// In ru, this message translates to:
  /// **'Охрана в пути'**
  String get sosStatusEnRoute;

  /// No description provided for @sosStatusArrived.
  ///
  /// In ru, this message translates to:
  /// **'Охрана прибыла'**
  String get sosStatusArrived;

  /// No description provided for @sosStatusCompleted.
  ///
  /// In ru, this message translates to:
  /// **'Вызов завершён'**
  String get sosStatusCompleted;

  /// No description provided for @sosStatusCancelled.
  ///
  /// In ru, this message translates to:
  /// **'Отменён'**
  String get sosStatusCancelled;

  /// No description provided for @sosStatusCancelledBySystem.
  ///
  /// In ru, this message translates to:
  /// **'Отменён системой'**
  String get sosStatusCancelledBySystem;

  /// No description provided for @sosCallActive.
  ///
  /// In ru, this message translates to:
  /// **'Вызов активен'**
  String get sosCallActive;

  /// No description provided for @sosSettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get sosSettings;

  /// No description provided for @sosRedirectedHint.
  ///
  /// In ru, this message translates to:
  /// **'Ваш вызов передан другой службе.\nИщем ближайшего свободного сотрудника.'**
  String get sosRedirectedHint;

  /// No description provided for @sosServicesNotified.
  ///
  /// In ru, this message translates to:
  /// **'Ближайшие службы оповещены'**
  String get sosServicesNotified;

  /// No description provided for @sosToHome.
  ///
  /// In ru, this message translates to:
  /// **'На главную'**
  String get sosToHome;

  /// No description provided for @paywallHeadline.
  ///
  /// In ru, this message translates to:
  /// **'Полный доступ ко всем функциям'**
  String get paywallHeadline;

  /// No description provided for @paywallSubhead.
  ///
  /// In ru, this message translates to:
  /// **'Кнопка SOS, геолокация в реальном времени и связь с диспетчером 24/7.'**
  String get paywallSubhead;

  /// No description provided for @paywallPaymentCreateFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось создать платёж'**
  String get paywallPaymentCreateFailed;

  /// Условия автосписаний, которые Робокасса требует на форме оплаты. Путь «Профиль → Подписка → …» должен совпадать с подписями кнопок на этом языке
  ///
  /// In ru, this message translates to:
  /// **'Подписка продлевается автоматически: {amounts} — бессрочно, до отмены. Отключить автопродление можно в любой момент: Профиль → Подписка → «Отменить подписку», либо обратившись в службу поддержки. После отмены списаний больше не будет, доступ сохранится до конца оплаченного периода.'**
  String paywallRecurringTerms(String amounts);

  /// No description provided for @paywallOneTimeTerms.
  ///
  /// In ru, this message translates to:
  /// **'Оплата за выбранный период.'**
  String get paywallOneTimeTerms;

  /// No description provided for @paywallChargeMonthly.
  ///
  /// In ru, this message translates to:
  /// **'{price} ₸ каждый месяц'**
  String paywallChargeMonthly(String price);

  /// No description provided for @paywallChargeYearly.
  ///
  /// In ru, this message translates to:
  /// **'{price} ₸ каждый год'**
  String paywallChargeYearly(String price);

  /// No description provided for @paywallChargeEither.
  ///
  /// In ru, this message translates to:
  /// **'{first} или {second}'**
  String paywallChargeEither(String first, String second);

  /// Согласие у кнопки оплаты. privacy и offer — ссылки (paywallConsentPrivacy, paywallConsentOffer)
  ///
  /// In ru, this message translates to:
  /// **'Я даю согласие на регулярные (автоматические) списания, на {privacy} и принимаю условия {offer}, в которой подробно описаны правила рекуррентных платежей.'**
  String paywallConsentRecurring(String privacy, String offer);

  /// Согласие у кнопки оплаты без автосписаний
  ///
  /// In ru, this message translates to:
  /// **'Я даю согласие на {privacy} и принимаю условия {offer}.'**
  String paywallConsent(String privacy, String offer);

  /// Ссылка в согласии, в нужном падеже
  ///
  /// In ru, this message translates to:
  /// **'обработку персональных данных'**
  String get paywallConsentPrivacy;

  /// Ссылка в согласии, в нужном падеже
  ///
  /// In ru, this message translates to:
  /// **'публичной оферты'**
  String get paywallConsentOffer;

  /// No description provided for @paywallPlanYearly.
  ///
  /// In ru, this message translates to:
  /// **'Годовая'**
  String get paywallPlanYearly;

  /// No description provided for @paywallPlanMonthly.
  ///
  /// In ru, this message translates to:
  /// **'Месячная'**
  String get paywallPlanMonthly;

  /// No description provided for @paywallBestValue.
  ///
  /// In ru, this message translates to:
  /// **'выгодно'**
  String get paywallBestValue;

  /// No description provided for @paywallPricePerYear.
  ///
  /// In ru, this message translates to:
  /// **'{price} ₸ / год'**
  String paywallPricePerYear(String price);

  /// No description provided for @paywallPricePerMonth.
  ///
  /// In ru, this message translates to:
  /// **'{price} ₸ / мес'**
  String paywallPricePerMonth(String price);

  /// No description provided for @paywallFeatureSos.
  ///
  /// In ru, this message translates to:
  /// **'Кнопка SOS в одно касание'**
  String get paywallFeatureSos;

  /// No description provided for @paywallFeatureLocation.
  ///
  /// In ru, this message translates to:
  /// **'Геолокация в реальном времени'**
  String get paywallFeatureLocation;

  /// No description provided for @paywallFeatureDispatcher.
  ///
  /// In ru, this message translates to:
  /// **'Связь с диспетчером 24/7'**
  String get paywallFeatureDispatcher;

  /// No description provided for @paywallFeaturePlatforms.
  ///
  /// In ru, this message translates to:
  /// **'Приложение для iOS и Android'**
  String get paywallFeaturePlatforms;

  /// No description provided for @subscriptionManageTitle.
  ///
  /// In ru, this message translates to:
  /// **'Управление подпиской'**
  String get subscriptionManageTitle;

  /// No description provided for @subscriptionPlanYearly.
  ///
  /// In ru, this message translates to:
  /// **'Годовая подписка'**
  String get subscriptionPlanYearly;

  /// No description provided for @subscriptionPlanMonthly.
  ///
  /// In ru, this message translates to:
  /// **'Месячная подписка'**
  String get subscriptionPlanMonthly;

  /// No description provided for @subscriptionCancelTitle.
  ///
  /// In ru, this message translates to:
  /// **'Отменить подписку?'**
  String get subscriptionCancelTitle;

  /// No description provided for @subscriptionCancelBody.
  ///
  /// In ru, this message translates to:
  /// **'Автоматические списания прекратятся. Доступ к функциям сохранится до {until}, деньги за оставшийся период не списываются и не возвращаются. Возобновить подписку можно в любой момент.'**
  String subscriptionCancelBody(String until);

  /// No description provided for @subscriptionKeep.
  ///
  /// In ru, this message translates to:
  /// **'Не отменять'**
  String get subscriptionKeep;

  /// No description provided for @subscriptionCancel.
  ///
  /// In ru, this message translates to:
  /// **'Отменить подписку'**
  String get subscriptionCancel;

  /// No description provided for @subscriptionAutoRenewTurnedOff.
  ///
  /// In ru, this message translates to:
  /// **'Автопродление отключено'**
  String get subscriptionAutoRenewTurnedOff;

  /// No description provided for @subscriptionCancelFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отменить подписку'**
  String get subscriptionCancelFailed;

  /// No description provided for @subscriptionInactiveTitle.
  ///
  /// In ru, this message translates to:
  /// **'Подписка неактивна'**
  String get subscriptionInactiveTitle;

  /// No description provided for @subscriptionInactiveBody.
  ///
  /// In ru, this message translates to:
  /// **'Оформите подписку, чтобы пользоваться кнопкой SOS и связью с диспетчером.'**
  String get subscriptionInactiveBody;

  /// No description provided for @subscriptionNoteCancelled.
  ///
  /// In ru, this message translates to:
  /// **'Автопродление отключено. Подписка действует до {date}, после чего доступ прекратится. Списаний больше не будет.'**
  String subscriptionNoteCancelled(String date);

  /// No description provided for @subscriptionNoteAutoRenew.
  ///
  /// In ru, this message translates to:
  /// **'Подписка продлевается автоматически. Вы можете отключить автопродление в любой момент — доступ сохранится до конца оплаченного периода.'**
  String get subscriptionNoteAutoRenew;

  /// No description provided for @subscriptionNoteNoAutoRenew.
  ///
  /// In ru, this message translates to:
  /// **'Подписка действует до {date}. Автопродление не подключено.'**
  String subscriptionNoteNoAutoRenew(String date);

  /// No description provided for @subscriptionAccessUntil.
  ///
  /// In ru, this message translates to:
  /// **'Доступ до'**
  String get subscriptionAccessUntil;

  /// No description provided for @subscriptionActiveUntilLabel.
  ///
  /// In ru, this message translates to:
  /// **'Активна до'**
  String get subscriptionActiveUntilLabel;

  /// No description provided for @subscriptionAutoRenew.
  ///
  /// In ru, this message translates to:
  /// **'Автопродление'**
  String get subscriptionAutoRenew;

  /// No description provided for @subscriptionOn.
  ///
  /// In ru, this message translates to:
  /// **'Включено'**
  String get subscriptionOn;

  /// No description provided for @subscriptionOff.
  ///
  /// In ru, this message translates to:
  /// **'Отключено'**
  String get subscriptionOff;

  /// No description provided for @subscriptionResume.
  ///
  /// In ru, this message translates to:
  /// **'Возобновить подписку'**
  String get subscriptionResume;

  /// No description provided for @paymentConfirming.
  ///
  /// In ru, this message translates to:
  /// **'Подтверждаем оплату…'**
  String get paymentConfirming;

  /// No description provided for @paymentMayTakeSeconds.
  ///
  /// In ru, this message translates to:
  /// **'Это может занять несколько секунд.'**
  String get paymentMayTakeSeconds;

  /// No description provided for @paymentActiveUntil.
  ///
  /// In ru, this message translates to:
  /// **'Активна до {date}'**
  String paymentActiveUntil(String date);

  /// No description provided for @paymentSubscriptionActive.
  ///
  /// In ru, this message translates to:
  /// **'Подписка активна'**
  String get paymentSubscriptionActive;

  /// No description provided for @paymentSubscribed.
  ///
  /// In ru, this message translates to:
  /// **'Подписка оформлена'**
  String get paymentSubscribed;

  /// No description provided for @paymentDone.
  ///
  /// In ru, this message translates to:
  /// **'Готово'**
  String get paymentDone;

  /// No description provided for @paymentStillProcessing.
  ///
  /// In ru, this message translates to:
  /// **'Оплата ещё обрабатывается'**
  String get paymentStillProcessing;

  /// No description provided for @paymentStillProcessingBody.
  ///
  /// In ru, this message translates to:
  /// **'Если вы завершили оплату, подписка активируется в течение пары минут. Можно проверить снова или вернуться позже.'**
  String get paymentStillProcessingBody;

  /// No description provided for @paymentCheckAgain.
  ///
  /// In ru, this message translates to:
  /// **'Проверить снова'**
  String get paymentCheckAgain;

  /// No description provided for @paymentBackHome.
  ///
  /// In ru, this message translates to:
  /// **'Вернуться на главную'**
  String get paymentBackHome;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'kk', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'kk':
      return AppLocalizationsKk();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
