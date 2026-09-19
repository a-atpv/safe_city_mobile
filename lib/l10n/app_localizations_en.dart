// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonOk => 'OK';

  @override
  String get commonGotIt => 'Got it';

  @override
  String get commonClose => 'Close';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonBack => 'Back';

  @override
  String get commonError => 'Error';

  @override
  String get commonUser => 'User';

  @override
  String get languageTitle => 'Language';

  @override
  String get loginTagline => 'Your safety is our priority';

  @override
  String get loginEnterEmail => 'Enter your email';

  @override
  String get loginInvalidEmail => 'Enter a valid email';

  @override
  String get loginGetCode => 'Get code';

  @override
  String get loginDocumentOpenFailed => 'Couldn\'t open the document';

  @override
  String loginConsent(String offer, String terms, String privacy) {
    return 'By continuing, you accept the $offer, $terms and $privacy';
  }

  @override
  String get loginConsentOffer => 'public offer';

  @override
  String get loginConsentTerms => 'terms of use';

  @override
  String get loginConsentPrivacy => 'privacy policy';

  @override
  String get otpTitle => 'Enter the code';

  @override
  String otpSentTo(String target) {
    return 'We sent the code to $target';
  }

  @override
  String otpResendIn(int seconds) {
    return 'Resend in $seconds s';
  }

  @override
  String get otpResend => 'Resend code';

  @override
  String get otpConfirm => 'Confirm';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profilePersonalData => 'Personal details';

  @override
  String get profileSubscription => 'Subscription';

  @override
  String get profileSubscriptionActive => 'Active';

  @override
  String get profileDocuments => 'Documents';

  @override
  String get profileSupport => 'Support';

  @override
  String get profileMailAppFailed => 'Couldn\'t open the mail app';

  @override
  String get profileAbout => 'About the app';

  @override
  String get profileLogout => 'Log out';

  @override
  String get profileDeleteAccount => 'Delete account';

  @override
  String get profileTakePhoto => 'Take a photo';

  @override
  String get profileChooseFromGallery => 'Choose from gallery';

  @override
  String get profileDeletePhoto => 'Remove photo';

  @override
  String get profilePhotoDeleteFailed => 'Couldn\'t remove the photo';

  @override
  String get profilePhotoUploadFailed => 'Couldn\'t upload the photo';

  @override
  String get profileImagePickFailed => 'Couldn\'t pick the image';

  @override
  String get profileEditTitle => 'Edit profile';

  @override
  String get profileNameLabel => 'Name';

  @override
  String get profileNameHint => 'Enter your name';

  @override
  String get profilePhoneLabel => 'Phone';

  @override
  String get profileSecretLabel => 'Secret code';

  @override
  String get profileSecretHint => 'A word to cancel a call';

  @override
  String get profileSecretHelp => 'Used to confirm cancelling a security call';

  @override
  String get profileLogoutConfirm => 'Log out of your account?';

  @override
  String get profileDeleteConfirmTitle => 'Delete your account?';

  @override
  String get profileDeleteConfirmBody =>
      'This can\'t be undone. All your data will be deleted.';

  @override
  String get documentsPublicOffer => 'Public offer';

  @override
  String get documentsPrivacyPolicy => 'Privacy policy';

  @override
  String get documentsUserAgreement => 'User agreement';

  @override
  String get documentsRussianOnly =>
      'These documents are available in Russian only';

  @override
  String get errorTimeout =>
      'The request timed out. Check your internet connection.';

  @override
  String get errorConnection =>
      'Connection error. Check your internet connection.';

  @override
  String get errorSessionExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String get errorForbidden => 'You don\'t have access to this resource.';

  @override
  String get errorTooManyRequests =>
      'Too many requests. Please try again later.';

  @override
  String errorServer(String code) {
    return 'Server error: $code';
  }

  @override
  String get errorCancelled => 'Request cancelled';

  @override
  String get errorUnknown => 'An unknown error occurred';

  @override
  String get errorNetworkTitle => 'Network error';

  @override
  String get errorGenericTitle => 'Something went wrong';

  @override
  String get errorGenericBody =>
      'Something went wrong. Please try again later.';

  @override
  String get errorRequestFailed => 'The request to the server failed';

  @override
  String get callCompletedTitle => 'Done';

  @override
  String get callCompletedBody =>
      'The call is complete. Please rate the security team.';

  @override
  String get callRate => 'Rate';

  @override
  String get callCancelledTitle => 'Call cancelled';

  @override
  String get callCancelledBySystem => 'Your call was cancelled by the system.';

  @override
  String get callCancelledByUser => 'The call has been cancelled.';

  @override
  String get callRedirectedTitle => 'Call redirected';

  @override
  String get callRedirectedBody =>
      'Your call has been passed to another service. We\'re looking for the nearest available officer.';

  @override
  String get callRedirectedNote => 'Note from the service:';

  @override
  String get chatTitle => 'Chat with the crew';

  @override
  String get chatMessageHint => 'Type a message...';

  @override
  String get reviewCallCompleted => 'Call completed';

  @override
  String get reviewRateCrew => 'Rate the crew\'s work';

  @override
  String get reviewCommentHint => 'Comment (optional)';

  @override
  String get reviewSubmit => 'Send feedback';

  @override
  String get reviewSkip => 'Skip';

  @override
  String get historyTitle => 'Call history';

  @override
  String get historyLoadFailed => 'Couldn\'t load the history';

  @override
  String get historyFilterAll => 'All';

  @override
  String get historyFilterCompleted => 'Completed';

  @override
  String get historyFilterCancelled => 'Cancelled';

  @override
  String get historyEmpty => 'No calls yet';

  @override
  String historyDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get historyStatusCompleted => 'Completed';

  @override
  String get historyStatusCancelled => 'Cancelled';

  @override
  String get historyStatusInProgress => 'In progress';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsMarkAllRead => 'Mark all as read';

  @override
  String get notificationsEmpty => 'No notifications';

  @override
  String notificationsMinutesAgo(int minutes) {
    return '$minutes min ago';
  }

  @override
  String notificationsHoursAgo(int hours) {
    return '$hours h ago';
  }

  @override
  String get commonNo => 'No';

  @override
  String get sosCancelTitle => 'Cancel the call?';

  @override
  String get sosCancelBody =>
      'Enter your secret code to confirm cancelling the security call.';

  @override
  String get sosSecretHint => 'Your secret word';

  @override
  String get sosCancelConfirm => 'Yes, cancel';

  @override
  String get sosCreateFailed => 'Couldn\'t create the call.';

  @override
  String get sosLocationServicesOff =>
      'Location services are off. Turn on GPS in your device settings.';

  @override
  String get sosLocationDenied =>
      'Location access is denied. Allow access to call security.';

  @override
  String get sosLocationTimeout =>
      'Couldn\'t determine your location in time. Check GPS and try again.';

  @override
  String sosLocationFailedDetails(String error) {
    return 'Couldn\'t determine your location: $error';
  }

  @override
  String get sosLocationFailed =>
      'Couldn\'t determine your location. Check your GPS settings.';

  @override
  String get sosOutsideAreaTitle => 'You\'re outside the service area';

  @override
  String get sosCall102 => 'Call 102';

  @override
  String get sosDialerFailed => 'Couldn\'t open the dialer. Call 102.';

  @override
  String get homeNoSubscriptionTitle => 'No active subscription';

  @override
  String get homeNoSubscriptionBody =>
      'You need an active subscription to use emergency calls.';

  @override
  String get homeSubscribe => 'Subscribe';

  @override
  String get homeTapToCall => 'Tap to call security';

  @override
  String get homeTapToSubscribe => 'No active subscription — tap to subscribe';

  @override
  String get homeSearchingSecurity => 'Finding\nsecurity...';

  @override
  String get homeInProgress => 'In progress';

  @override
  String get homeServicesNotified => 'Nearby services\nhave been notified';

  @override
  String get sosCancelCall => 'Cancel call';

  @override
  String get homeSecurityAssigned => 'Security assigned';

  @override
  String homeReviews(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '$count review',
    );
    return '$_temp0';
  }

  @override
  String get homeCallDetails => 'Call details';

  @override
  String get homeSubscriptionInactive => 'Inactive';

  @override
  String get onboardingRemovePhoto => 'Remove photo';

  @override
  String get onboardingAddPhoto => 'Add a profile photo';

  @override
  String get onboardingWelcome => 'Welcome!';

  @override
  String get onboardingFillProfile => 'Fill in your profile\nto continue';

  @override
  String get onboardingFullName => 'Full name';

  @override
  String get onboardingNameHint => 'Your first and last name';

  @override
  String get onboardingNameRequired => 'Please enter your name';

  @override
  String get onboardingPhone => 'Phone number';

  @override
  String get onboardingOptional => 'Optional';

  @override
  String get onboardingSecretLabel => 'Secret word * (to cancel a call)';

  @override
  String get onboardingSecretHint => 'Secret word';

  @override
  String get onboardingSecretRequired => 'Please enter a secret word';

  @override
  String get settingsDeleteTitle => 'Deleting your account';

  @override
  String get settingsDeleteBody =>
      'Do you really want to delete your account? This can\'t be undone.';

  @override
  String get settingsPush => 'Push notifications';

  @override
  String get settingsCallSound => 'Call sound';

  @override
  String get settingsVibration => 'Vibration';

  @override
  String get settingsApp => 'App';

  @override
  String get settingsLanguage => 'App language';

  @override
  String get settingsDarkTheme => 'Dark theme';

  @override
  String documentsLoading(int progress) {
    return 'Loading... $progress%';
  }

  @override
  String get documentsLoadFailed => 'Couldn\'t load the page';

  @override
  String get documentsCheckConnection =>
      'Please check your internet connection and try again.';

  @override
  String get updateNewVersion => 'A new version of the app is available.';

  @override
  String get updateRequiredTitle => 'Update required';

  @override
  String get updateAvailableTitle => 'Update available';

  @override
  String updateVersion(String version) {
    return 'Version $version.';
  }

  @override
  String get updateAction => 'Update';

  @override
  String get routeNotFoundTitle => 'Page not found';

  @override
  String get routeNotFoundBody =>
      'Looks like this link leads nowhere. If you\'ve just paid for a subscription, your money isn\'t lost: the status will update on its own, and you can check it in your profile.';

  @override
  String get navHome => 'Home';

  @override
  String get navHistory => 'History';

  @override
  String get authSendCodeFailed => 'Couldn\'t send the code';

  @override
  String get authWrongCode => 'Wrong code';

  @override
  String get permLocationDeniedOpenSettings =>
      'Location access is denied. Open the app settings.';

  @override
  String get permLocationTitle => 'Location permission';

  @override
  String get permLocationDisclosure =>
      'Safe City collects location data to enable the SOS emergency call feature, even when the app is closed or not in use. This data is needed so the security team can quickly reach you at your coordinates.';

  @override
  String get permDecline => 'Decline';

  @override
  String get permAccept => 'Accept';

  @override
  String get permBackgroundTitle => 'SOS in the background';

  @override
  String get permBackgroundBody =>
      'To reliably send an SOS signal when the app is minimized or closed, choose “Allow all the time” in the permission settings.';

  @override
  String get permLater => 'Later';

  @override
  String get permOpenSettings => 'Open settings';

  @override
  String get locationForegroundNotification =>
      'Sending your location to security in the background';

  @override
  String get pushChannelName => 'Emergency status updates';

  @override
  String get pushChannelDescription => 'Updates on your emergency requests';

  @override
  String get sosStatusRedirecting => 'Passing to another service...';

  @override
  String get sosStatusSearching => 'Finding security...';

  @override
  String get sosStatusWaiting => 'Waiting for a response...';

  @override
  String get sosStatusAccepted => 'Call accepted';

  @override
  String get sosStatusEnRoute => 'Security is on the way';

  @override
  String get sosStatusArrived => 'Security has arrived';

  @override
  String get sosStatusCompleted => 'Call completed';

  @override
  String get sosStatusCancelled => 'Cancelled';

  @override
  String get sosStatusCancelledBySystem => 'Cancelled by the system';

  @override
  String get sosCallActive => 'Call active';

  @override
  String get sosSettings => 'Settings';

  @override
  String get sosRedirectedHint =>
      'Your call has been passed to another service.\nWe\'re looking for the nearest available officer.';

  @override
  String get sosServicesNotified => 'Nearby services have been notified';

  @override
  String get sosToHome => 'Back to home';

  @override
  String get paywallHeadline => 'Full access to all features';

  @override
  String get paywallSubhead =>
      'SOS button, real-time location and 24/7 contact with the dispatcher.';

  @override
  String get paywallPaymentCreateFailed => 'Couldn\'t create the payment';

  @override
  String paywallRecurringTerms(String amounts) {
    return 'Your subscription renews automatically: $amounts, indefinitely until you cancel. You can turn off auto-renewal at any time: Profile → Subscription → “Cancel subscription”, or by contacting support. After you cancel there will be no more charges, and access stays until the end of the paid period.';
  }

  @override
  String get paywallOneTimeTerms => 'Payment for the selected period.';

  @override
  String paywallChargeMonthly(String price) {
    return '$price ₸ every month';
  }

  @override
  String paywallChargeYearly(String price) {
    return '$price ₸ every year';
  }

  @override
  String paywallChargeEither(String first, String second) {
    return '$first or $second';
  }

  @override
  String paywallConsentRecurring(String privacy, String offer) {
    return 'I consent to recurring (automatic) charges and to the $privacy, and accept the terms of the $offer, which describes the recurring payment rules in detail.';
  }

  @override
  String paywallConsent(String privacy, String offer) {
    return 'I consent to the $privacy and accept the terms of the $offer.';
  }

  @override
  String get paywallConsentPrivacy => 'processing of my personal data';

  @override
  String get paywallConsentOffer => 'public offer';

  @override
  String get paywallPlanYearly => 'Yearly';

  @override
  String get paywallPlanMonthly => 'Monthly';

  @override
  String get paywallBestValue => 'best value';

  @override
  String paywallPricePerYear(String price) {
    return '$price ₸ / year';
  }

  @override
  String paywallPricePerMonth(String price) {
    return '$price ₸ / month';
  }

  @override
  String get paywallFeatureSos => 'One-tap SOS button';

  @override
  String get paywallFeatureLocation => 'Real-time location';

  @override
  String get paywallFeatureDispatcher => '24/7 contact with the dispatcher';

  @override
  String get paywallFeaturePlatforms => 'App for iOS and Android';

  @override
  String get subscriptionManageTitle => 'Manage subscription';

  @override
  String get subscriptionPlanYearly => 'Yearly subscription';

  @override
  String get subscriptionPlanMonthly => 'Monthly subscription';

  @override
  String get subscriptionCancelTitle => 'Cancel your subscription?';

  @override
  String subscriptionCancelBody(String until) {
    return 'Automatic charges will stop. You keep access until $until; nothing more is charged or refunded for the remaining period. You can resubscribe at any time.';
  }

  @override
  String get subscriptionKeep => 'Keep subscription';

  @override
  String get subscriptionCancel => 'Cancel subscription';

  @override
  String get subscriptionAutoRenewTurnedOff => 'Auto-renewal turned off';

  @override
  String get subscriptionCancelFailed => 'Couldn\'t cancel the subscription';

  @override
  String get subscriptionInactiveTitle => 'No active subscription';

  @override
  String get subscriptionInactiveBody =>
      'Subscribe to use the SOS button and contact the dispatcher.';

  @override
  String subscriptionNoteCancelled(String date) {
    return 'Auto-renewal is off. Your subscription is valid until $date, after which access ends. There will be no more charges.';
  }

  @override
  String get subscriptionNoteAutoRenew =>
      'Your subscription renews automatically. You can turn off auto-renewal at any time — access stays until the end of the paid period.';

  @override
  String subscriptionNoteNoAutoRenew(String date) {
    return 'Your subscription is valid until $date. Auto-renewal is not set up.';
  }

  @override
  String get subscriptionAccessUntil => 'Access until';

  @override
  String get subscriptionActiveUntilLabel => 'Active until';

  @override
  String get subscriptionAutoRenew => 'Auto-renewal';

  @override
  String get subscriptionOn => 'On';

  @override
  String get subscriptionOff => 'Off';

  @override
  String get subscriptionResume => 'Renew subscription';

  @override
  String get paymentConfirming => 'Confirming your payment…';

  @override
  String get paymentMayTakeSeconds => 'This may take a few seconds.';

  @override
  String paymentActiveUntil(String date) {
    return 'Active until $date';
  }

  @override
  String get paymentSubscriptionActive => 'Subscription active';

  @override
  String get paymentSubscribed => 'You\'re subscribed';

  @override
  String get paymentDone => 'Done';

  @override
  String get paymentStillProcessing => 'Payment is still processing';

  @override
  String get paymentStillProcessingBody =>
      'If you\'ve completed the payment, your subscription will activate within a couple of minutes. You can check again or come back later.';

  @override
  String get paymentCheckAgain => 'Check again';

  @override
  String get paymentBackHome => 'Back to home';
}
