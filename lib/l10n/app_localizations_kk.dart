// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kazakh (`kk`).
class AppLocalizationsKk extends AppLocalizations {
  AppLocalizationsKk([String locale = 'kk']) : super(locale);

  @override
  String get commonCancel => 'Бас тарту';

  @override
  String get commonOk => 'Жарайды';

  @override
  String get commonGotIt => 'Түсінікті';

  @override
  String get commonClose => 'Жабу';

  @override
  String get commonSave => 'Сақтау';

  @override
  String get commonDelete => 'Жою';

  @override
  String get commonRetry => 'Қайталау';

  @override
  String get commonContinue => 'Жалғастыру';

  @override
  String get commonBack => 'Артқа';

  @override
  String get commonError => 'Қате';

  @override
  String get commonUser => 'Пайдаланушы';

  @override
  String get languageTitle => 'Тіл';

  @override
  String get loginTagline => 'Сіздің қауіпсіздігіңіз — біздің басымдығымыз';

  @override
  String get loginEnterEmail => 'Email енгізіңіз';

  @override
  String get loginInvalidEmail => 'Дұрыс email енгізіңіз';

  @override
  String get loginGetCode => 'Код алу';

  @override
  String get loginDocumentOpenFailed => 'Құжатты ашу мүмкін болмады';

  @override
  String loginConsent(String offer, String terms, String privacy) {
    return 'Жалғастыра отырып, сіз $offer, $terms және $privacy қабылдайсыз';
  }

  @override
  String get loginConsentOffer => 'жария офертаны';

  @override
  String get loginConsentTerms => 'пайдалану шарттарын';

  @override
  String get loginConsentPrivacy => 'құпиялылық саясатын';

  @override
  String get otpTitle => 'Кодты енгізіңіз';

  @override
  String otpSentTo(String target) {
    return 'Код $target адресіне жіберілді';
  }

  @override
  String otpResendIn(int seconds) {
    return '$seconds секундтан кейін қайта жіберу';
  }

  @override
  String get otpResend => 'Қайта жіберу';

  @override
  String get otpConfirm => 'Растау';

  @override
  String get profileTitle => 'Профиль';

  @override
  String get profilePersonalData => 'Жеке деректер';

  @override
  String get profileSubscription => 'Жазылым';

  @override
  String get profileSubscriptionActive => 'Белсенді';

  @override
  String get profileDocuments => 'Құжаттар';

  @override
  String get profileSupport => 'Қолдау қызметі';

  @override
  String get profileMailAppFailed => 'Пошта қолданбасын ашу мүмкін болмады';

  @override
  String get profileAbout => 'Қолданба туралы';

  @override
  String get profileLogout => 'Шығу';

  @override
  String get profileDeleteAccount => 'Аккаунтты жою';

  @override
  String get profileTakePhoto => 'Суретке түсіру';

  @override
  String get profileChooseFromGallery => 'Галереядан таңдау';

  @override
  String get profileDeletePhoto => 'Суретті жою';

  @override
  String get profilePhotoDeleteFailed => 'Суретті жою мүмкін болмады';

  @override
  String get profilePhotoUploadFailed => 'Суретті жүктеу мүмкін болмады';

  @override
  String get profileImagePickFailed => 'Суретті таңдау мүмкін болмады';

  @override
  String get profileEditTitle => 'Профильді өңдеу';

  @override
  String get profileNameLabel => 'Аты';

  @override
  String get profileNameHint => 'Атыңызды енгізіңіз';

  @override
  String get profilePhoneLabel => 'Телефон';

  @override
  String get profileSecretLabel => 'Құпия сөз';

  @override
  String get profileSecretHint => 'Шақырудан бас тартуға арналған сөз';

  @override
  String get profileSecretHelp =>
      'Күзетті шақырудан бас тартуды растау үшін қолданылады';

  @override
  String get profileLogoutConfirm => 'Аккаунттан шығасыз ба?';

  @override
  String get profileDeleteConfirmTitle => 'Аккаунтты жоясыз ба?';

  @override
  String get profileDeleteConfirmBody =>
      'Бұл әрекетті қайтару мүмкін емес. Барлық деректеріңіз жойылады.';

  @override
  String get documentsPublicOffer => 'Жария оферта';

  @override
  String get documentsPrivacyPolicy => 'Құпиялылық саясаты';

  @override
  String get documentsUserAgreement => 'Пайдаланушы келісімі';

  @override
  String get documentsRussianOnly => 'Құжаттар тек орыс тілінде қолжетімді';

  @override
  String get errorTimeout =>
      'Күту уақыты асып кетті. Интернет байланысын тексеріңіз.';

  @override
  String get errorConnection =>
      'Қосылу қатесі. Интернет байланысын тексеріңіз.';

  @override
  String get errorSessionExpired => 'Сеанс мерзімі аяқталды. Қайта кіріңіз.';

  @override
  String get errorForbidden => 'Сізде бұл ресурсқа қолжетімділік жоқ.';

  @override
  String get errorTooManyRequests =>
      'Сұраулар тым көп. Кейінірек қайталап көріңіз.';

  @override
  String errorServer(String code) {
    return 'Сервер қатесі: $code';
  }

  @override
  String get errorCancelled => 'Сұрау тоқтатылды';

  @override
  String get errorUnknown => 'Белгісіз қате орын алды';

  @override
  String get errorNetworkTitle => 'Желі қатесі';

  @override
  String get errorGenericTitle => 'Қате орын алды';

  @override
  String get errorGenericBody =>
      'Бірдеңе дұрыс болмады. Кейінірек қайталап көріңіз.';

  @override
  String get errorRequestFailed =>
      'Серверге сұрау жіберу кезінде қате орын алды';

  @override
  String get callCompletedTitle => 'Сәтті';

  @override
  String get callCompletedBody =>
      'Шақыру сәтті аяқталды! Күзет қызметінің жұмысын бағалаңыз.';

  @override
  String get callRate => 'Бағалау';

  @override
  String get callCancelledTitle => 'Шақыру жойылды';

  @override
  String get callCancelledBySystem => 'Шақыруыңызды жүйе жойды.';

  @override
  String get callCancelledByUser => 'Шақыру жойылды.';

  @override
  String get callRedirectedTitle => 'Шақыру басқа қызметке берілді';

  @override
  String get callRedirectedBody =>
      'Шақыруыңыз басқа қызметке берілді. Ең жақын бос қызметкерді іздеп жатырмыз.';

  @override
  String get callRedirectedNote => 'Қызметтің түсініктемесі:';

  @override
  String get chatTitle => 'Экипажбен чат';

  @override
  String get chatMessageHint => 'Хабарлама жазыңыз...';

  @override
  String get reviewCallCompleted => 'Шақыру аяқталды';

  @override
  String get reviewRateCrew => 'Экипаж жұмысын бағалаңыз';

  @override
  String get reviewCommentHint => 'Пікір (міндетті емес)';

  @override
  String get reviewSubmit => 'Пікір жіберу';

  @override
  String get reviewSkip => 'Өткізіп жіберу';

  @override
  String get historyTitle => 'Шақырулар тарихы';

  @override
  String get historyLoadFailed => 'Тарихты жүктеу қатесі';

  @override
  String get historyFilterAll => 'Барлығы';

  @override
  String get historyFilterCompleted => 'Аяқталған';

  @override
  String get historyFilterCancelled => 'Жойылған';

  @override
  String get historyEmpty => 'Тарих бос';

  @override
  String historyDurationMinutes(int minutes) {
    return '$minutes мин';
  }

  @override
  String get historyStatusCompleted => 'Аяқталды';

  @override
  String get historyStatusCancelled => 'Жойылды';

  @override
  String get historyStatusInProgress => 'Орындалуда';

  @override
  String get notificationsTitle => 'Хабарландырулар';

  @override
  String get notificationsMarkAllRead => 'Барлығын оқу';

  @override
  String get notificationsEmpty => 'Хабарландыру жоқ';

  @override
  String notificationsMinutesAgo(int minutes) {
    return '$minutes минут бұрын';
  }

  @override
  String notificationsHoursAgo(int hours) {
    return '$hours сағат бұрын';
  }

  @override
  String get commonNo => 'Жоқ';

  @override
  String get sosCancelTitle => 'Шақырудан бас тартасыз ба?';

  @override
  String get sosCancelBody =>
      'Күзетті шақырудан бас тартуды растау үшін құпия сөзді енгізіңіз.';

  @override
  String get sosSecretHint => 'Сіздің құпия сөзіңіз';

  @override
  String get sosCancelConfirm => 'Иә, бас тарту';

  @override
  String get sosCreateFailed => 'Шақыру жасау мүмкін болмады.';

  @override
  String get sosLocationServicesOff =>
      'Геолокация қызметтері өшірулі. Құрылғы баптауларында GPS-ті қосыңыз.';

  @override
  String get sosLocationDenied =>
      'Геолокацияға рұқсат жоқ. Күзетті шақыру үшін рұқсат беріңіз.';

  @override
  String get sosLocationTimeout =>
      'Орналасқан жерді белгіленген уақытта анықтау мүмкін болмады. GPS-ті тексеріп, қайталап көріңіз.';

  @override
  String sosLocationFailedDetails(String error) {
    return 'Орналасқан жерді анықтау мүмкін болмады: $error';
  }

  @override
  String get sosLocationFailed =>
      'Орналасқан жерді анықтау мүмкін болмады. GPS баптауларын тексеріңіз.';

  @override
  String get sosOutsideAreaTitle => 'Сіз қызмет көрсету аймағынан тыссыз';

  @override
  String get sosCall102 => '102-ге қоңырау шалу';

  @override
  String get sosDialerFailed =>
      'Нөмір теруді ашу мүмкін болмады. 102-ге қоңырау шалыңыз.';

  @override
  String get homeNoSubscriptionTitle => 'Жазылым белсенді емес';

  @override
  String get homeNoSubscriptionBody =>
      'Шұғыл шақыру функциясын пайдалану үшін белсенді жазылым қажет.';

  @override
  String get homeSubscribe => 'Рәсімдеу';

  @override
  String get homeTapToCall => 'Күзетті шақыру үшін басыңыз';

  @override
  String get homeTapToSubscribe =>
      'Жазылым белсенді емес — рәсімдеу үшін басыңыз';

  @override
  String get homeSearchingSecurity => 'Күзет\nізделуде...';

  @override
  String get homeInProgress => 'Орындалуда';

  @override
  String get homeServicesNotified => 'Жақын қызметтерге\nхабар берілді';

  @override
  String get sosCancelCall => 'Шақырудан бас тарту';

  @override
  String get homeSecurityAssigned => 'Күзет тағайындалды';

  @override
  String homeReviews(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count пікір',
    );
    return '$_temp0';
  }

  @override
  String get homeCallDetails => 'Шақыру мәліметтері';

  @override
  String get homeSubscriptionInactive => 'Белсенді емес';

  @override
  String get onboardingRemovePhoto => 'Суретті алып тастау';

  @override
  String get onboardingAddPhoto => 'Профиль суретін қосыңыз';

  @override
  String get onboardingWelcome => 'Қош келдіңіз!';

  @override
  String get onboardingFillProfile =>
      'Жалғастыру үшін\nпрофиль деректерін толтырыңыз';

  @override
  String get onboardingFullName => 'Толық аты-жөні';

  @override
  String get onboardingNameHint => 'Атыңыз және тегіңіз';

  @override
  String get onboardingNameRequired => 'Атыңызды енгізіңіз';

  @override
  String get onboardingPhone => 'Телефон нөмірі';

  @override
  String get onboardingOptional => 'Міндетті емес';

  @override
  String get onboardingSecretLabel => 'Құпия сөз * (шақырудан бас тарту үшін)';

  @override
  String get onboardingSecretHint => 'Құпия сөз';

  @override
  String get onboardingSecretRequired => 'Құпия сөзді енгізіңіз';

  @override
  String get settingsDeleteTitle => 'Аккаунтты жою';

  @override
  String get settingsDeleteBody =>
      'Аккаунтыңызды шынымен жойғыңыз келе ме? Бұл әрекетті қайтару мүмкін емес.';

  @override
  String get settingsPush => 'Push-хабарландырулар';

  @override
  String get settingsCallSound => 'Қоңырау дыбысы';

  @override
  String get settingsVibration => 'Діріл';

  @override
  String get settingsApp => 'Қолданба';

  @override
  String get settingsLanguage => 'Қолданба тілі';

  @override
  String get settingsDarkTheme => 'Қараңғы тақырып';

  @override
  String documentsLoading(int progress) {
    return 'Жүктелуде... $progress%';
  }

  @override
  String get documentsLoadFailed => 'Бетті жүктеу мүмкін болмады';

  @override
  String get documentsCheckConnection =>
      'Интернет байланысын тексеріп, қайталап көріңіз.';

  @override
  String get updateNewVersion => 'Қолданбаның жаңа нұсқасы шықты.';

  @override
  String get updateRequiredTitle => 'Жаңарту қажет';

  @override
  String get updateAvailableTitle => 'Жаңарту шықты';

  @override
  String updateVersion(String version) {
    return 'Нұсқа $version.';
  }

  @override
  String get updateAction => 'Жаңарту';

  @override
  String get navHome => 'Басты бет';

  @override
  String get navHistory => 'Тарих';

  @override
  String get authSendCodeFailed => 'Кодты жіберу мүмкін болмады';

  @override
  String get authWrongCode => 'Код қате';

  @override
  String get permLocationDeniedOpenSettings =>
      'Геолокацияға рұқсат жоқ. Қолданба баптауларын ашыңыз.';

  @override
  String get permLocationTitle => 'Геолокацияға рұқсат';

  @override
  String get permLocationDisclosure =>
      'Safe City SOS шұғыл шақыру функциясы жұмыс істеуі үшін орналасқан жер туралы деректерді жинайды, тіпті қолданба жабық немесе пайдаланылмай тұрғанда да. Бұл деректер күзет қызметі сіздің координаттарыңыз бойынша жедел жетуі үшін қажет.';

  @override
  String get permDecline => 'Қабылдамау';

  @override
  String get permAccept => 'Қабылдау';

  @override
  String get permBackgroundTitle => 'SOS фондық режимі';

  @override
  String get permBackgroundBody =>
      'Қолданба жиналып не жабық тұрғанда да SOS сигналы сенімді жіберілуі үшін рұқсат баптауларында геолокацияға үнемі рұқсат беріңіз (Allow all the time).';

  @override
  String get permLater => 'Кейінірек';

  @override
  String get permOpenSettings => 'Баптауларға өту';

  @override
  String get locationForegroundNotification =>
      'Координаттар күзетке фондық режимде жіберілуде';

  @override
  String get pushChannelName => 'Шақыру мәртебесі';

  @override
  String get pushChannelDescription =>
      'Күзет шақыруларыңыздың барысы туралы хабарландырулар';

  @override
  String get sosStatusRedirecting => 'Басқа қызметке беріп жатырмыз...';

  @override
  String get sosStatusSearching => 'Күзет ізделуде...';

  @override
  String get sosStatusWaiting => 'Жауап күтілуде...';

  @override
  String get sosStatusAccepted => 'Шақыру қабылданды';

  @override
  String get sosStatusEnRoute => 'Күзет жолда';

  @override
  String get sosStatusArrived => 'Күзет келді';

  @override
  String get sosStatusCompleted => 'Шақыру аяқталды';

  @override
  String get sosStatusCancelled => 'Жойылды';

  @override
  String get sosStatusCancelledBySystem => 'Жүйе жойды';

  @override
  String get sosCallActive => 'Шақыру белсенді';

  @override
  String get sosSettings => 'Баптаулар';

  @override
  String get sosRedirectedHint =>
      'Шақыруыңыз басқа қызметке берілді.\nЕң жақын бос қызметкерді іздеп жатырмыз.';

  @override
  String get sosServicesNotified => 'Жақын қызметтерге хабар берілді';

  @override
  String get sosToHome => 'Басты бетке';

  @override
  String get paywallHeadline => 'Барлық функцияларға толық қолжетімділік';

  @override
  String get paywallSubhead =>
      'SOS батырмасы, нақты уақыттағы геолокация және диспетчермен тәулік бойы байланыс.';

  @override
  String get paywallPaymentCreateFailed => 'Төлем жасау мүмкін болмады';

  @override
  String paywallRecurringTerms(String amounts) {
    return 'Жазылым автоматты түрде ұзартылады: $amounts — мерзімсіз, бас тартқанға дейін. Автоұзартуды кез келген уақытта өшіруге болады: Профиль → Жазылым → «Жазылымнан бас тарту» арқылы немесе қолдау қызметіне жүгіну арқылы. Бас тартқаннан кейін ақша алынбайды, қолжетімділік төленген кезеңнің соңына дейін сақталады.';
  }

  @override
  String get paywallOneTimeTerms => 'Таңдалған кезең үшін төлем.';

  @override
  String paywallChargeMonthly(String price) {
    return 'ай сайын $price ₸';
  }

  @override
  String paywallChargeYearly(String price) {
    return 'жыл сайын $price ₸';
  }

  @override
  String paywallChargeEither(String first, String second) {
    return '$first немесе $second';
  }

  @override
  String paywallConsentRecurring(String privacy, String offer) {
    return 'Мен тұрақты (автоматты) түрде ақша алынуына, $privacy келісім беремін және $offer шарттарын қабылдаймын — онда рекуррентті төлемдер ережелері толық сипатталған.';
  }

  @override
  String paywallConsent(String privacy, String offer) {
    return 'Мен $privacy келісім беремін және $offer шарттарын қабылдаймын.';
  }

  @override
  String get paywallConsentPrivacy => 'дербес деректерімді өңдеуге';

  @override
  String get paywallConsentOffer => 'жария оферта';

  @override
  String get paywallPlanYearly => 'Жылдық';

  @override
  String get paywallPlanMonthly => 'Айлық';

  @override
  String get paywallBestValue => 'тиімді';

  @override
  String paywallPricePerYear(String price) {
    return '$price ₸ / жыл';
  }

  @override
  String paywallPricePerMonth(String price) {
    return '$price ₸ / ай';
  }

  @override
  String get paywallFeatureSos => 'Бір рет басумен SOS шақыру';

  @override
  String get paywallFeatureLocation => 'Нақты уақыттағы геолокация';

  @override
  String get paywallFeatureDispatcher => 'Диспетчермен тәулік бойы байланыс';

  @override
  String get paywallFeaturePlatforms => 'iOS және Android қолданбасы';

  @override
  String get subscriptionManageTitle => 'Жазылымды басқару';

  @override
  String get subscriptionPlanYearly => 'Жылдық жазылым';

  @override
  String get subscriptionPlanMonthly => 'Айлық жазылым';

  @override
  String get subscriptionCancelTitle => 'Жазылымнан бас тартасыз ба?';

  @override
  String subscriptionCancelBody(String until) {
    return 'Автоматты түрде ақша алу тоқтатылады. Функцияларға қолжетімділік $until дейін сақталады, қалған кезең үшін ақша алынбайды және қайтарылмайды. Жазылымды кез келген уақытта қайта рәсімдеуге болады.';
  }

  @override
  String get subscriptionKeep => 'Бас тартпау';

  @override
  String get subscriptionCancel => 'Жазылымнан бас тарту';

  @override
  String get subscriptionAutoRenewTurnedOff => 'Автоұзарту өшірілді';

  @override
  String get subscriptionCancelFailed => 'Жазылымнан бас тарту мүмкін болмады';

  @override
  String get subscriptionInactiveTitle => 'Жазылым белсенді емес';

  @override
  String get subscriptionInactiveBody =>
      'SOS батырмасы мен диспетчермен байланысты пайдалану үшін жазылымды рәсімдеңіз.';

  @override
  String subscriptionNoteCancelled(String date) {
    return 'Автоұзарту өшірілген. Жазылым $date дейін жарамды, одан кейін қолжетімділік тоқтайды. Бұдан былай ақша алынбайды.';
  }

  @override
  String get subscriptionNoteAutoRenew =>
      'Жазылым автоматты түрде ұзартылады. Автоұзартуды кез келген уақытта өшіре аласыз — қолжетімділік төленген кезеңнің соңына дейін сақталады.';

  @override
  String subscriptionNoteNoAutoRenew(String date) {
    return 'Жазылым $date дейін жарамды. Автоұзарту қосылмаған.';
  }

  @override
  String get subscriptionAccessUntil => 'Қолжетімділік мерзімі';

  @override
  String get subscriptionActiveUntilLabel => 'Белсенді мерзімі';

  @override
  String get subscriptionAutoRenew => 'Автоұзарту';

  @override
  String get subscriptionOn => 'Қосулы';

  @override
  String get subscriptionOff => 'Өшірулі';

  @override
  String get subscriptionResume => 'Жазылымды қайта рәсімдеу';

  @override
  String get paymentConfirming => 'Төлемді растап жатырмыз…';

  @override
  String get paymentMayTakeSeconds => 'Бұл бірнеше секундқа созылуы мүмкін.';

  @override
  String paymentActiveUntil(String date) {
    return '$date дейін белсенді';
  }

  @override
  String get paymentSubscriptionActive => 'Жазылым белсенді';

  @override
  String get paymentSubscribed => 'Жазылым рәсімделді';

  @override
  String get paymentDone => 'Дайын';

  @override
  String get paymentStillProcessing => 'Төлем әлі өңделуде';

  @override
  String get paymentStillProcessingBody =>
      'Егер төлемді аяқтаған болсаңыз, жазылым бірнеше минут ішінде іске қосылады. Қайта тексеруге немесе кейінірек оралуға болады.';

  @override
  String get paymentCheckAgain => 'Қайта тексеру';

  @override
  String get paymentBackHome => 'Басты бетке оралу';
}
