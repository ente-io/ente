// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'strings_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class StringsLocalizationsId extends StringsLocalizations {
  StringsLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get networkHostLookUpErr =>
      'Tidak dapat terhubung ke Ente. Mohon periksa kembali koneksi internet Anda dan hubungi tim bantuan kami jika galat masih ada.';

  @override
  String get networkConnectionRefusedErr =>
      'Sepertinya ada yang salah. Mohon coba lagi setelah beberapa waktu. Jika galat masih ada, Anda dapat menghubungi tim bantuan kami.';

  @override
  String get itLooksLikeSomethingWentWrongPleaseRetryAfterSome =>
      'Sepertinya ada yang salah. Mohon coba lagi setelah beberapa waktu. Jika galat masih ada, Anda dapat menghubungi tim bantuan kami.';

  @override
  String get error => 'Kesalahan';

  @override
  String get ok => 'Oke';

  @override
  String get faq => 'Pertanyaan yang sering ditanyakan';

  @override
  String get contactSupport => 'Hubungi dukungan';

  @override
  String get emailYourLogs => 'Kirimkan log Anda melalui surel';

  @override
  String pleaseSendTheLogsTo(String toEmail) {
    return 'Mohon kirim log ke $toEmail';
  }

  @override
  String get copyEmailAddress => 'Salin alamat surel';

  @override
  String get exportLogs => 'Ekspor log';

  @override
  String get cancel => 'Batal';

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
  String get reportABug => 'Laporkan bug';

  @override
  String get logsDialogBody =>
      'This will send across logs to help us debug your issue. Please note that file names will be included to help track issues with specific files.';

  @override
  String get viewLogs => 'View logs';

  @override
  String customEndpoint(String endpoint) {
    return 'Terhubung ke $endpoint';
  }

  @override
  String get save => 'Simpan';

  @override
  String get send => 'Kirim';

  @override
  String get saveOrSendDescription =>
      'Anda ingin menyimpan kode ke penyimpanan Anda (folder pilihan bawaan adalah folder Downloads) atau Anda ingin kirimkan ke aplikasi lain?';

  @override
  String get saveOnlyDescription =>
      'Anda ingin menyimpan kode ke penyimpanan Anda (folder pilihan bawaan adalah folder Downloads)';

  @override
  String get enterNewEmailHint => 'Masukkan alamat email baru anda';

  @override
  String get email => 'Email';

  @override
  String get verify => 'Verifikasi';

  @override
  String get invalidEmailTitle => 'Alamat email tidak valid';

  @override
  String get invalidEmailMessage => 'Harap masukkan alamat email yang valid.';

  @override
  String get pleaseWait => 'Mohon tunggu...';

  @override
  String get verifyPassword => 'Verifikasi kata sandi';

  @override
  String get incorrectPasswordTitle => 'Kata sandi salah';

  @override
  String get pleaseTryAgain => 'Harap coba lagi';

  @override
  String get enterPassword => 'Masukkan kata sandi';

  @override
  String get enterYourPasswordHint => 'Masukkan kata sandi Anda';

  @override
  String get activeSessions => 'Sesi aktif';

  @override
  String get oops => 'Ups';

  @override
  String get somethingWentWrongPleaseTryAgain =>
      'Ada yang salah. Mohon coba kembali';

  @override
  String get thisWillLogYouOutOfThisDevice =>
      'Langkah ini akan mengeluarkan Anda dari gawai ini!';

  @override
  String get thisWillLogYouOutOfTheFollowingDevice =>
      'Langkah ini akan mengeluarkan Anda dari gawai berikut:';

  @override
  String get terminateSession => 'Akhiri sesi?';

  @override
  String get terminate => 'Akhiri';

  @override
  String get thisDevice => 'Gawai ini';

  @override
  String get createAccount => 'Buat akun';

  @override
  String get weakStrength => 'Lemah';

  @override
  String get moderateStrength => 'Sedang';

  @override
  String get strongStrength => 'Kuat';

  @override
  String get deleteAccount => 'Hapus akun';

  @override
  String get deleteAccountQuery =>
      'Kami akan merasa kehilangan Anda. Apakah Anda menghadapi masalah?';

  @override
  String get yesSendFeedbackAction => 'Ya, kirim umpan balik';

  @override
  String get noDeleteAccountAction => 'Tidak, hapus akun';

  @override
  String get initiateAccountDeleteTitle =>
      'Harap autentikasi untuk memulai penghapusan akun';

  @override
  String get confirmAccountDeleteTitle => 'Konfirmasikan penghapusan akun';

  @override
  String get confirmAccountDeleteMessage =>
      'Akun ini terhubung dengan aplikasi Ente yang lain (jika Anda pakai).\n\nData yang Anda unggah di seluruh aplikasi Ente akan dijadwalkan untuk dihapus. Akun Anda juga akan dihapus secara permanen.';

  @override
  String get delete => 'Hapus';

  @override
  String get createNewAccount => 'Buat akun baru';

  @override
  String get password => 'Kata Sandi';

  @override
  String get confirmPassword => 'Konfirmasi kata sandi';

  @override
  String passwordStrength(String passwordStrengthValue) {
    return 'Tingkat kekuatan kata sandi: $passwordStrengthValue';
  }

  @override
  String get hearUsWhereTitle => 'Dari mana Anda menemukan Ente? (opsional)';

  @override
  String get hearUsExplanation =>
      'Kami tidak melacak penginstalan aplikasi kami. Akan sangat membantu kami bila Anda memberitahu kami dari mana Anda mengetahui Ente!';

  @override
  String get signUpTerms =>
      'Saya menyetujui <u-terms>syarat dan ketentuan</u-terms> serta <u-policy>kebijakan privasi</u-policy> Ente';

  @override
  String get termsOfServicesTitle => 'Ketentuan';

  @override
  String get privacyPolicyTitle => 'Kebijakan Privasi';

  @override
  String get ackPasswordLostWarning =>
      'Saya mengerti bahwa jika saya lupa kata sandi saya, data saya dapat hilang karena data saya <underline>terenkripsi secara end-to-end</underline>.';

  @override
  String get encryption => 'Enkripsi';

  @override
  String get logInLabel => 'Masuk akun';

  @override
  String get welcomeBack => 'Selamat datang kembali!';

  @override
  String get loginTerms =>
      'Dengan menekan masuk akun, saya menyetujui <u-terms>syarat dan ketentuan</u-terms> serta <u-policy>kebijakan privasi</u-policy> Ente';

  @override
  String get noInternetConnection => 'Tiada koneksi internet';

  @override
  String get pleaseCheckYourInternetConnectionAndTryAgain =>
      'Mohon periksa koneksi internet Anda dan coba kembali.';

  @override
  String get verificationFailedPleaseTryAgain =>
      'Gagal memverifikasi. Mohon coba lagi';

  @override
  String get recreatePasswordTitle => 'Membuat kembali kata sandi';

  @override
  String get recreatePasswordBody =>
      'Gawai Anda saat ini tidak dapat memverifikasi kata sandi Anda. Namun, kami dapat membuat ulang dengan cara yang dapat digunakan pada semua gawai.\n\nMohon masuk log dengan kunci pemulihan dan buat ulang kata sandi Anda (kata sandi yang sama diperbolehkan).';

  @override
  String get useRecoveryKey => 'Gunakan kunci pemulihan';

  @override
  String get forgotPassword => 'Lupa kata sandi';

  @override
  String get changeEmail => 'Ubah alamat email';

  @override
  String get verifyEmail => 'Verifikasi email';

  @override
  String weHaveSendEmailTo(String email) {
    return 'Kami telah mengirimkan sebuah posel ke <green>$email</green>';
  }

  @override
  String get toResetVerifyEmail =>
      'Untuk mengatur ulang kata sandi, mohon verifikasi surel Anda terlebih dahulu.';

  @override
  String get checkInboxAndSpamFolder => 'Mohon cek';

  @override
  String get tapToEnterCode => 'Ketuk untuk memasukkan kode';

  @override
  String get sendEmail => 'Kirim surel';

  @override
  String get resendEmail => 'Kirim ulang surel';

  @override
  String get passKeyPendingVerification => 'Verifikasi tertunda';

  @override
  String get loginSessionExpired => 'Sesi sudah berakhir';

  @override
  String get loginSessionExpiredDetails =>
      'Sesi Anda sudah berakhir. Mohon masuk log kembali.';

  @override
  String get passkeyAuthTitle => 'Verifikasi passkey';

  @override
  String get waitingForVerification => 'Menantikan verifikasi...';

  @override
  String get tryAgain => 'Coba lagi';

  @override
  String get checkStatus => 'Periksa status';

  @override
  String get loginWithTOTP => 'Masuk menggunakan TOTP';

  @override
  String get recoverAccount => 'Pulihkan akun';

  @override
  String get setPasswordTitle => 'Atur kata sandi';

  @override
  String get changePasswordTitle => 'Ubah kata sandi';

  @override
  String get resetPasswordTitle => 'Atur ulang kata sandi';

  @override
  String get encryptionKeys => 'Kunci enkripsi';

  @override
  String get enterPasswordToEncrypt =>
      'Masukkan kata sandi yang dapat kami gunakan untuk mengenkripsi data Anda';

  @override
  String get enterNewPasswordToEncrypt =>
      'Masukkan kata sandi baru yang dapat kami gunakan untuk mengenkripsi data Anda';

  @override
  String get passwordWarning =>
      'Kami tidak menyimpan kata sandi Anda. Jika Anda lupa, <underline>kami tidak dapat mendekripsi data Anda</underline>';

  @override
  String get howItWorks => 'Cara kerjanya';

  @override
  String get generatingEncryptionKeys => 'Sedang membuat kunci enkripsi...';

  @override
  String get passwordChangedSuccessfully => 'Kata sandi sukses diubah';

  @override
  String get signOutFromOtherDevices => 'Keluar dari gawai yang lain';

  @override
  String get signOutOtherBody =>
      'Jika Anda pikir seseorang mungkin mengetahui kata sandi Anda, Anda dapat mengeluarkan akun Anda pada semua gawai';

  @override
  String get signOutOtherDevices => 'Keluar akun pada gawai yang lain';

  @override
  String get doNotSignOut => 'Jangan keluar';

  @override
  String get generatingEncryptionKeysTitle =>
      'Sedang membuat kunci enkripsi...';

  @override
  String get continueLabel => 'Lanjutkan';

  @override
  String get insecureDevice => 'Perangkat tidak aman';

  @override
  String get sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease =>
      'Maaf, kami tidak dapat membuat kunci yang aman pada perangkat ini.\n\nHarap mendaftar dengan perangkat lain.';

  @override
  String get recoveryKeyCopiedToClipboard =>
      'Kunci pemulihan disalin ke papan klip';

  @override
  String get recoveryKey => 'Kunci pemulihan';

  @override
  String get recoveryKeyOnForgotPassword =>
      'Jika Anda lupa kata sandi, satu-satunya cara memulihkan data Anda adalah dengan kunci ini.';

  @override
  String get recoveryKeySaveDescription =>
      'Kami tidak menyimpan kunci ini, jadi harap simpan kunci yang berisi 24 kata ini dengan aman.';

  @override
  String get doThisLater => 'Lakukan lain kali';

  @override
  String get saveKey => 'Simpan kunci';

  @override
  String get recoveryKeySaved =>
      'Kunci pemulihan sudah tersimpan di folder \'Downloads\'!';

  @override
  String get noRecoveryKeyTitle => 'Tidak punya kunci pemulihan?';

  @override
  String get twoFactorAuthTitle => 'Autentikasi dua langkah';

  @override
  String get enterCodeHint =>
      'Masukkan kode 6 digit dari aplikasi autentikator Anda';

  @override
  String get lostDeviceTitle => 'Perangkat hilang?';

  @override
  String get enterRecoveryKeyHint => 'Masukkan kunci pemulihan Anda';

  @override
  String get recover => 'Pulihkan';

  @override
  String get loggingOut => 'Mengeluarkan akun...';

  @override
  String get immediately => 'Segera';

  @override
  String get appLock => 'Kunci aplikasi';

  @override
  String get autoLock => 'Kunci otomatis';

  @override
  String get noSystemLockFound => 'Tidak ditemukan kunci sistem';

  @override
  String get deviceLockEnablePreSteps =>
      'Pasang kunci sandi atau kunci layar pada pengaturan sistem untuk menyalakan Pengunci Gawai.';

  @override
  String get appLockDescription =>
      'Pilih layar kunci bawaan gawai Anda ATAU layar kunci kustom dengan PIN atau kata sandi.';

  @override
  String get deviceLock => 'Kunci perangkat';

  @override
  String get pinLock => 'PIN';

  @override
  String get autoLockFeatureDescription =>
      'Durasi waktu aplikasi akan terkunci setelah aplikasi ditutup';

  @override
  String get hideContent => 'Sembunyikan isi';

  @override
  String get hideContentDescriptionAndroid =>
      'Menyembunyikan konten aplikasi di pemilih aplikasi dan menonaktifkan tangkapan layar';

  @override
  String get hideContentDescriptioniOS =>
      'Menyembunyikan konten aplikasi di pemilih aplikasi';

  @override
  String get tooManyIncorrectAttempts => 'Terlalu banyak percobaan yang salah';

  @override
  String get tapToUnlock => 'Ketuk untuk membuka';

  @override
  String get areYouSureYouWantToLogout =>
      'Anda yakin ingin keluar dari akun ini?';

  @override
  String get yesLogout => 'Ya, keluar akun';

  @override
  String get authToViewSecrets =>
      'Harap lakukan autentikasi untuk melihat rahasia Anda';

  @override
  String get next => 'Selanjutnya';

  @override
  String get setNewPassword => 'Pasang kata sandi baru';

  @override
  String get enterPin => 'Masukkan PIN';

  @override
  String get setNewPin => 'Pasang PIN yang baru';

  @override
  String get confirm => 'Konfirmasikan';

  @override
  String get reEnterPassword => 'Masukkan kembali kata sandi';

  @override
  String get reEnterPin => 'Masukkan kembali PIN';

  @override
  String get androidBiometricHint => 'Verifikasikan identitas Anda';

  @override
  String get androidBiometricNotRecognized => 'Tidak dikenal. Coba lagi.';

  @override
  String get androidBiometricSuccess => 'Sukses';

  @override
  String get androidCancelButton => 'Batalkan';

  @override
  String get androidSignInTitle => 'Autentikasi diperlukan';

  @override
  String get androidBiometricRequiredTitle => 'Biometrik diperlukan';

  @override
  String get androidDeviceCredentialsRequiredTitle =>
      'Kredensial perangkat diperlukan';

  @override
  String get androidDeviceCredentialsSetupDescription =>
      'Kredensial perangkat diperlukan';

  @override
  String get goToSettings => 'Pergi ke pengaturan';

  @override
  String get androidGoToSettingsDescription =>
      'Tidak ada autentikasi biometrik pada gawai Anda. Buka \'Pengaturan > Keamanan\' untuk menambahkan autentikasi biometrik pada gawai Anda.';

  @override
  String get iOSLockOut =>
      'Autentikasi biometrik dimatikan. Kunci dan buka layar Anda untuk menyalakan autentikasi biometrik.';

  @override
  String get iOSOkButton => 'Oke';

  @override
  String get emailAlreadyRegistered => 'Email sudah terdaftar.';

  @override
  String get emailNotRegistered => 'Email belum terdaftar.';

  @override
  String get thisEmailIsAlreadyInUse => 'Surel ini sudah dipakai!';

  @override
  String emailChangedTo(String newEmail) {
    return 'Surel sudah diganti menjadi $newEmail';
  }

  @override
  String get authenticationFailedPleaseTryAgain =>
      'Gagal mengautentikasi. Mohon coba lagi';

  @override
  String get authenticationSuccessful => 'Sukses mengautentikasi!';

  @override
  String get sessionExpired => 'Sesi berakhir';

  @override
  String get incorrectRecoveryKey => 'Kunci pemulihan takbenar';

  @override
  String get theRecoveryKeyYouEnteredIsIncorrect =>
      'Kunci pemulihan yang Anda masukkan takbenar';

  @override
  String get twofactorAuthenticationSuccessfullyReset =>
      'Autentikasi dwifaktor sukses diatur ulang';

  @override
  String get noRecoveryKey => 'No recovery key';

  @override
  String get yourAccountHasBeenDeleted => 'Your account has been deleted';

  @override
  String get verificationId => 'Verification ID';

  @override
  String get yourVerificationCodeHasExpired =>
      'Kode verifikasi Anda telah kedaluwarsa';

  @override
  String get incorrectCode => 'Kode takbenar';

  @override
  String get sorryTheCodeYouveEnteredIsIncorrect =>
      'Maaf, kode yang Anda masukkan takbenar';

  @override
  String get developerSettings => 'Pengaturan Pengembang';

  @override
  String get serverEndpoint => 'Peladen endpoint';

  @override
  String get invalidEndpoint => 'Endpoint takvalid';

  @override
  String get invalidEndpointMessage =>
      'Maaf, endpoint yang Anda masukkan takvalid. Mohon masukkan endpoint yang valid, lalu coba kembali.';

  @override
  String get endpointUpdatedMessage => 'Endpoint berhasil diubah';
}
