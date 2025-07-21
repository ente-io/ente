// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'strings_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class StringsLocalizationsTr extends StringsLocalizations {
  StringsLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get networkHostLookUpErr =>
      'Ente\'ye bağlanılamıyor, lütfen ağ ayarlarınızı kontrol edin ve hata devam ederse desteğe başvurun.';

  @override
  String get networkConnectionRefusedErr =>
      'Ente\'ye bağlanılamıyor, lütfen daha sonra tekrar deneyin. Hata devam ederse, lütfen desteğe başvurun.';

  @override
  String get itLooksLikeSomethingWentWrongPleaseRetryAfterSome =>
      'Bir şeyler ters gitmiş gibi görünüyor. Lütfen bir süre sonra tekrar deneyin. Hata devam ederse, lütfen destek ekibimizle iletişime geçin.';

  @override
  String get error => 'Hata';

  @override
  String get ok => 'Tamam';

  @override
  String get faq => 'SSS';

  @override
  String get contactSupport => 'Destek ekibiyle iletişime geçin';

  @override
  String get emailYourLogs => 'Kayıtlarınızı e-postayla gönderin';

  @override
  String pleaseSendTheLogsTo(String toEmail) {
    return 'Lütfen kayıtları şu adrese gönderin\n$toEmail';
  }

  @override
  String get copyEmailAddress => 'E-posta adresini kopyala';

  @override
  String get exportLogs => 'Kayıtları dışa aktar';

  @override
  String get cancel => 'İptal Et';

  @override
  String pleaseEmailUsAt(String toEmail) {
    return 'Email us at $toEmail';
  }

  @override
  String get emailAddressCopied => 'Email address copied';

  @override
  String get supportEmailSubject => '[Support]';

  @override
  String get clientDebugInfoLabel =>
      'Following information can help us in debugging if you are facing any issue';

  @override
  String get registeredEmailLabel => 'Registered email:';

  @override
  String get clientLabel => 'Client:';

  @override
  String get versionLabel => 'Version :';

  @override
  String get notAvailable => 'N/A';

  @override
  String get reportABug => 'Hata bildirin';

  @override
  String get logsDialogBody =>
      'This will send across logs to help us debug your issue. Please note that file names will be included to help track issues with specific files.';

  @override
  String get viewLogs => 'View logs';

  @override
  String customEndpoint(String endpoint) {
    return 'Bağlandı: $endpoint';
  }

  @override
  String get save => 'Kaydet';

  @override
  String get send => 'Gönder';

  @override
  String get saveOrSendDescription =>
      'Bunu belleğinize mi kaydedeceksiniz (İndirilenler klasörü varsayılandır) yoksa diğer uygulamalara mı göndereceksiniz?';

  @override
  String get saveOnlyDescription =>
      'Bunu belleğinize kaydetmek ister misiniz? (İndirilenler klasörü varsayılandır)';

  @override
  String get enterNewEmailHint => 'Yeni e-posta adresinizi girin';

  @override
  String get email => 'E-Posta';

  @override
  String get verify => 'Doğrula';

  @override
  String get invalidEmailTitle => 'Geçersiz e-posta adresi';

  @override
  String get invalidEmailMessage => 'Lütfen geçerli bir e-posta adresi girin.';

  @override
  String get pleaseWait => 'Lütfen bekleyin...';

  @override
  String get verifyPassword => 'Şifreyi doğrulayın';

  @override
  String get incorrectPasswordTitle => 'Yanlış şifre';

  @override
  String get pleaseTryAgain => 'Lütfen tekrar deneyin';

  @override
  String get enterPassword => 'Şifreyi girin';

  @override
  String get enterYourPasswordHint => 'Parolanızı girin';

  @override
  String get activeSessions => 'Aktif oturumlar';

  @override
  String get oops => 'Hay aksi';

  @override
  String get somethingWentWrongPleaseTryAgain =>
      'Bir şeyler ters gitti, lütfen tekrar deneyin';

  @override
  String get thisWillLogYouOutOfThisDevice =>
      'Bu sizin bu cihazdaki oturumunuzu kapatacaktır!';

  @override
  String get thisWillLogYouOutOfTheFollowingDevice =>
      'Bu, aşağıdaki cihazdan çıkış yapmanızı sağlayacaktır:';

  @override
  String get terminateSession => 'Oturumu sonlandır?';

  @override
  String get terminate => 'Sonlandır';

  @override
  String get thisDevice => 'Bu cihaz';

  @override
  String get createAccount => 'Hesap oluştur';

  @override
  String get weakStrength => 'Zayıf';

  @override
  String get moderateStrength => 'Orta';

  @override
  String get strongStrength => 'Güçlü';

  @override
  String get deleteAccount => 'Hesabı sil';

  @override
  String get deleteAccountQuery =>
      'Sizin gittiğinizi görmekten üzüleceğiz. Bazı problemlerle mi karşılaşıyorsunuz?';

  @override
  String get yesSendFeedbackAction => 'Evet, geri bildirimi gönder';

  @override
  String get noDeleteAccountAction => 'Hayır, hesabı sil';

  @override
  String get initiateAccountDeleteTitle =>
      'Hesap silme işlemini yapabilmek için lütfen kimliğinizi doğrulayın';

  @override
  String get confirmAccountDeleteTitle => 'Hesap silme işlemini onayla';

  @override
  String get confirmAccountDeleteMessage =>
      'Kullandığınız Ente uygulamaları varsa bu hesap diğer Ente uygulamalarıyla bağlantılıdır.\n\nTüm Ente uygulamalarına yüklediğiniz veriler ve hesabınız kalıcı olarak silinecektir.';

  @override
  String get delete => 'Sil';

  @override
  String get createNewAccount => 'Yeni hesap oluşturun';

  @override
  String get password => 'Şifre';

  @override
  String get confirmPassword => 'Şifreyi onayla';

  @override
  String passwordStrength(String passwordStrengthValue) {
    return 'Şifre gücü: $passwordStrengthValue';
  }

  @override
  String get hearUsWhereTitle => 'Ente\'yi nereden duydunuz? (opsiyonel)';

  @override
  String get hearUsExplanation =>
      'Biz uygulama kurulumlarını takip etmiyoruz. Bizi nereden duyduğunuzdan bahsetmeniz bize çok yardımcı olacak!';

  @override
  String get signUpTerms =>
      '<u-terms>Kullanım şartları</u-terms>nı ve <u-policy>gizlilik politikası</u-policy>nı kabul ediyorum';

  @override
  String get termsOfServicesTitle => 'Şartlar';

  @override
  String get privacyPolicyTitle => 'Gizlilik Politikası';

  @override
  String get ackPasswordLostWarning =>
      'Eğer şifremi kaybedersem, verilerim <underline> uçtan uca şifrelendiğinden </underline> verilerimi kaybedebileceğimi anladım.';

  @override
  String get encryption => 'Şifreleme';

  @override
  String get logInLabel => 'Giriş yapın';

  @override
  String get welcomeBack => 'Tekrar hoş geldiniz!';

  @override
  String get loginTerms =>
      'Giriş yaparak, <u-terms> kullanım şartları </u-terms>nı ve <u-policy> gizlilik politikası </u-policy>nı onaylıyorum';

  @override
  String get noInternetConnection => 'İnternet bağlantısı yok';

  @override
  String get pleaseCheckYourInternetConnectionAndTryAgain =>
      'Lütfen internet bağlantınızı kontrol edin ve yeniden deneyin.';

  @override
  String get verificationFailedPleaseTryAgain =>
      'Doğrulama başarısız oldu, lütfen tekrar deneyin';

  @override
  String get recreatePasswordTitle => 'Şifreyi yeniden oluştur';

  @override
  String get recreatePasswordBody =>
      'Mevcut cihaz şifrenizi doğrulayacak kadar güçlü değil, ancak tüm cihazlarla çalışacak şekilde yeniden oluşturabiliriz.\n\nLütfen kurtarma anahtarınızı kullanarak giriş yapın ve şifrenizi yeniden oluşturun (isterseniz aynı şifreyi tekrar kullanabilirsiniz).';

  @override
  String get useRecoveryKey => 'Kurtarma anahtarını kullan';

  @override
  String get forgotPassword => 'Şifremi unuttum';

  @override
  String get changeEmail => 'E-posta adresini değiştir';

  @override
  String get verifyEmail => 'E-posta adresini doğrulayın';

  @override
  String weHaveSendEmailTo(String email) {
    return '<green>$email</green> adresine bir posta gönderdik';
  }

  @override
  String get toResetVerifyEmail =>
      'Şifrenizi sıfırlamak için lütfen önce e-postanızı doğrulayın.';

  @override
  String get checkInboxAndSpamFolder =>
      'Doğrulamayı tamamlamak için lütfen gelen kutunuzu (ve spam kutunuzu) kontrol edin';

  @override
  String get tapToEnterCode => 'Kodu girmek için dokunun';

  @override
  String get sendEmail => 'E-posta gönder';

  @override
  String get resendEmail => 'E-postayı yeniden gönder';

  @override
  String get passKeyPendingVerification => 'Doğrulama hala bekliyor';

  @override
  String get loginSessionExpired => 'Oturum süresi doldu';

  @override
  String get loginSessionExpiredDetails =>
      'Oturum süreniz doldu. Tekrar giriş yapın.';

  @override
  String get passkeyAuthTitle => 'Geçiş anahtarı doğrulaması';

  @override
  String get waitingForVerification => 'Doğrulama bekleniyor...';

  @override
  String get tryAgain => 'Tekrar deneyin';

  @override
  String get checkStatus => 'Durumu kontrol et';

  @override
  String get loginWithTOTP => 'TOTP ile giriş yap';

  @override
  String get recoverAccount => 'Hesap kurtarma';

  @override
  String get setPasswordTitle => 'Şifre belirleyin';

  @override
  String get changePasswordTitle => 'Şifreyi değiştirin';

  @override
  String get resetPasswordTitle => 'Şifreyi sıfırlayın';

  @override
  String get encryptionKeys => 'Şifreleme anahtarları';

  @override
  String get enterPasswordToEncrypt =>
      'Verilerinizi şifrelemek için kullanabileceğimiz bir şifre girin';

  @override
  String get enterNewPasswordToEncrypt =>
      'Verilerinizi şifrelemek için kullanabileceğimiz yeni bir şifre girin';

  @override
  String get passwordWarning =>
      'Bu şifreyi saklamıyoruz, bu nedenle unutursanız, <underline>verilerinizin şifresini çözemeyiz</underline>';

  @override
  String get howItWorks => 'Nasıl çalışır';

  @override
  String get generatingEncryptionKeys =>
      'Şifreleme anahtarları oluşturuluyor...';

  @override
  String get passwordChangedSuccessfully => 'Şifre başarıyla değiştirildi';

  @override
  String get signOutFromOtherDevices => 'Diğer cihazlardan çıkış yap';

  @override
  String get signOutOtherBody =>
      'Eğer başka birisinin parolanızı bildiğini düşünüyorsanız, diğer tüm cihazları hesabınızdan çıkışa zorlayabilirsiniz.';

  @override
  String get signOutOtherDevices => 'Diğer cihazlardan çıkış yap';

  @override
  String get doNotSignOut => 'Çıkış yapma';

  @override
  String get generatingEncryptionKeysTitle =>
      'Şifreleme anahtarları üretiliyor...';

  @override
  String get continueLabel => 'Devam et';

  @override
  String get insecureDevice => 'Güvenli olmayan cihaz';

  @override
  String get sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease =>
      'Üzgünüz, bu cihazda güvenli anahtarlar oluşturamadık.\n\nlütfen farklı bir cihazdan kaydolun.';

  @override
  String get recoveryKeyCopiedToClipboard =>
      'Kurtarma anahtarı panoya kopyalandı';

  @override
  String get recoveryKey => 'Kurtarma Anahtarı';

  @override
  String get recoveryKeyOnForgotPassword =>
      'Eğer şifrenizi unutursanız, verilerinizi kurtarabileceğiniz tek yol bu anahtardır.';

  @override
  String get recoveryKeySaveDescription =>
      'Biz bu anahtarı saklamıyoruz, lütfen. bu 24 kelimelik anahtarı güvenli bir yerde saklayın.';

  @override
  String get doThisLater => 'Bunu daha sonra yap';

  @override
  String get saveKey => 'Anahtarı kaydet';

  @override
  String get recoveryKeySaved =>
      'Kurtarma anahtarı İndirilenler klasörüne kaydedildi!';

  @override
  String get noRecoveryKeyTitle => 'Kurtarma anahtarınız yok mu?';

  @override
  String get twoFactorAuthTitle => 'İki faktörlü kimlik doğrulama';

  @override
  String get enterCodeHint =>
      'Kimlik doğrulayıcı uygulamanızdaki 6 haneli doğrulama kodunu girin';

  @override
  String get lostDeviceTitle => 'Cihazınızı mı kaybettiniz?';

  @override
  String get enterRecoveryKeyHint => 'Kurtarma anahtarınızı girin';

  @override
  String get recover => 'Kurtar';

  @override
  String get loggingOut => 'Çıkış yapılıyor...';

  @override
  String get immediately => 'Hemen';

  @override
  String get appLock => 'Uygulama kilidi';

  @override
  String get autoLock => 'Otomatik Kilit';

  @override
  String get noSystemLockFound => 'Sistem kilidi bulunamadı';

  @override
  String get deviceLockEnablePreSteps =>
      'Cihaz kilidini etkinleştirmek için, lütfen cihaz şifresini veya ekran kilidini ayarlayın.';

  @override
  String get appLockDescription =>
      'Cihazınızın varsayılan kilit ekranı ile PIN veya parola içeren özel bir kilit ekranı arasında seçim yapın.';

  @override
  String get deviceLock => 'Cihaz kilidi';

  @override
  String get pinLock => 'Pin kilidi';

  @override
  String get autoLockFeatureDescription =>
      'Uygulamayı arka plana attıktan sonra kilitlendiği süre';

  @override
  String get hideContent => 'İçeriği gizle';

  @override
  String get hideContentDescriptionAndroid =>
      'Uygulama değiştiricide bulunan uygulama içeriğini gizler ve ekran görüntülerini devre dışı bırakır';

  @override
  String get hideContentDescriptioniOS =>
      'Uygulama değiştiricideki uygulama içeriğini gizler';

  @override
  String get tooManyIncorrectAttempts => 'Çok fazla hatalı deneme';

  @override
  String get tapToUnlock => 'Açmak için dokun';

  @override
  String get areYouSureYouWantToLogout =>
      'Çıkış yapmak istediğinize emin misiniz?';

  @override
  String get yesLogout => 'Evet, çıkış yap';

  @override
  String get authToViewSecrets =>
      'Kodlarınızı görmek için lütfen kimlik doğrulaması yapın';

  @override
  String get next => 'Sonraki';

  @override
  String get setNewPassword => 'Yeni şifre belirle';

  @override
  String get enterPin => 'PIN Girin';

  @override
  String get setNewPin => 'Yeni PIN belirleyin';

  @override
  String get confirm => 'Doğrula';

  @override
  String get reEnterPassword => 'Şifrenizi tekrar girin';

  @override
  String get reEnterPin => 'PIN\'inizi tekrar girin';

  @override
  String get androidBiometricHint => 'Kimliği doğrula';

  @override
  String get androidBiometricNotRecognized => 'Tanınmadı. Tekrar deneyin.';

  @override
  String get androidBiometricSuccess => 'Başarılı';

  @override
  String get androidCancelButton => 'İptal et';

  @override
  String get androidSignInTitle => 'Kimlik doğrulaması gerekli';

  @override
  String get androidBiometricRequiredTitle => 'Biyometrik gerekli';

  @override
  String get androidDeviceCredentialsRequiredTitle =>
      'Cihaz kimlik bilgileri gerekli';

  @override
  String get androidDeviceCredentialsSetupDescription =>
      'Cihaz kimlik bilgileri gerekmekte';

  @override
  String get goToSettings => 'Ayarlara git';

  @override
  String get androidGoToSettingsDescription =>
      'Biyometrik kimlik doğrulama cihazınızda ayarlanmamış. Biyometrik kimlik doğrulama eklemek için \'Ayarlar > Güvenlik\' bölümüne gidin.';

  @override
  String get iOSLockOut =>
      'Biyometrik kimlik doğrulama devre dışı. Etkinleştirmek için lütfen ekranınızı kilitleyin ve kilidini açın.';

  @override
  String get iOSOkButton => 'Tamam';

  @override
  String get emailAlreadyRegistered => 'E-posta zaten kayıtlı.';

  @override
  String get emailNotRegistered => 'E-posta kayıtlı değil.';

  @override
  String get thisEmailIsAlreadyInUse => 'Bu e-posta zaten kullanılıyor';

  @override
  String emailChangedTo(String newEmail) {
    return 'E-posta $newEmail olarak değiştirildi';
  }

  @override
  String get authenticationFailedPleaseTryAgain =>
      'Kimlik doğrulama başarısız oldu, lütfen tekrar deneyin';

  @override
  String get authenticationSuccessful => 'Kimlik doğrulama başarılı!';

  @override
  String get sessionExpired => 'Oturum süresi doldu';

  @override
  String get incorrectRecoveryKey => 'Yanlış kurtarma kodu';

  @override
  String get theRecoveryKeyYouEnteredIsIncorrect =>
      'Girdiğiniz kurtarma kodu yanlış';

  @override
  String get twofactorAuthenticationSuccessfullyReset =>
      'İki faktörlü kimlik doğrulama başarıyla sıfırlandı';

  @override
  String get noRecoveryKey => 'No recovery key';

  @override
  String get yourAccountHasBeenDeleted => 'Your account has been deleted';

  @override
  String get verificationId => 'Verification ID';

  @override
  String get yourVerificationCodeHasExpired =>
      'Doğrulama kodunuzun süresi doldu';

  @override
  String get incorrectCode => 'Yanlış kod';

  @override
  String get sorryTheCodeYouveEnteredIsIncorrect =>
      'Üzgünüz, girdiğiniz kod yanlış';

  @override
  String get developerSettings => 'Geliştirici ayarları';

  @override
  String get serverEndpoint => 'Sunucu uç noktası';

  @override
  String get invalidEndpoint => 'Geçersiz uç nokta';

  @override
  String get invalidEndpointMessage =>
      'Üzgünüz, girdiğiniz uç nokta geçersiz. Lütfen geçerli bir uç nokta girin ve tekrar deneyin.';

  @override
  String get endpointUpdatedMessage => 'Uç nokta başarıyla güncellendi';
}
