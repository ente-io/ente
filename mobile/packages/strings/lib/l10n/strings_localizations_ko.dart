// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'strings_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class StringsLocalizationsKo extends StringsLocalizations {
  StringsLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get networkHostLookUpErr =>
      'Ente에 접속할 수 없습니다, 네트워크 설정을 확인해주시고 에러가 반복되는 경우 저희 지원 팀에 문의해주세요.';

  @override
  String get networkConnectionRefusedErr =>
      'Ente에 접속할 수 없습니다, 잠시 후에 다시 시도해주세요. 에러가 반복되는 경우, 저희 지원 팀에 문의해주세요.';

  @override
  String get itLooksLikeSomethingWentWrongPleaseRetryAfterSome =>
      '뭔가 잘못된 것 같습니다. 잠시 후에 다시 시도해주세요. 에러가 반복되는 경우, 저희 지원 팀에 문의해주세요.';

  @override
  String get error => '에러';

  @override
  String get ok => '확인';

  @override
  String get faq => 'FAQ';

  @override
  String get contactSupport => '지원 문의';

  @override
  String get emailYourLogs => '로그를 이메일로 보내기';

  @override
  String pleaseSendTheLogsTo(String toEmail) {
    return '이 로그를 $toEmail 쪽으로 보내주세요';
  }

  @override
  String get copyEmailAddress => '이메일 주소 복사';

  @override
  String get exportLogs => '로그 내보내기';

  @override
  String get cancel => '취소';

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
  String get reportABug => '버그 제보';

  @override
  String get logsDialogBody =>
      'This will send across logs to help us debug your issue. Please note that file names will be included to help track issues with specific files.';

  @override
  String get viewLogs => 'View logs';

  @override
  String customEndpoint(String endpoint) {
    return '$endpoint에 접속됨';
  }

  @override
  String get save => '저장';

  @override
  String get send => '보내기';

  @override
  String get saveOrSendDescription =>
      '이것을 당신의 스토리지 (일반적으로 다운로드 폴더) 에 저장하시겠습니까, 아니면 다른 App으로 전송하시겠습니까?';

  @override
  String get saveOnlyDescription => '이것을 당신의 스토리지 (일반적으로 다운로드 폴더) 에 저장하시겠습니까?';

  @override
  String get enterNewEmailHint => 'Enter your new email address';

  @override
  String get email => '이메일';

  @override
  String get verify => '인증';

  @override
  String get invalidEmailTitle => '잘못 된 이메일 주소';

  @override
  String get invalidEmailMessage => '유효한 이메일 주소를 입력해주세요';

  @override
  String get pleaseWait => '잠시만 기다려주세요...';

  @override
  String get verifyPassword => '비밀번호 확인';

  @override
  String get incorrectPasswordTitle => '올바르지 않은 비밀번호';

  @override
  String get pleaseTryAgain => '다시 시도해주세요';

  @override
  String get enterPassword => '암호 입력';

  @override
  String get enterYourPasswordHint => '암호 입력';

  @override
  String get activeSessions => '활성화된 Session';

  @override
  String get oops => '이런!';

  @override
  String get somethingWentWrongPleaseTryAgain => '뭔가 잘못됐습니다, 다시 시도해주세요';

  @override
  String get thisWillLogYouOutOfThisDevice => '이 작업을 하시면 기기에서 로그아웃하게 됩니다!';

  @override
  String get thisWillLogYouOutOfTheFollowingDevice =>
      '이 작업을 하시면 다음 기기에서 로그아웃하게 됩니다:';

  @override
  String get terminateSession => '세션을 종결하시겠습니까?';

  @override
  String get terminate => '종결';

  @override
  String get thisDevice => '이 기기';

  @override
  String get createAccount => '계정 만들기';

  @override
  String get weakStrength => '약함';

  @override
  String get moderateStrength => '보통';

  @override
  String get strongStrength => '강함';

  @override
  String get deleteAccount => '계정 삭제하기';

  @override
  String get deleteAccountQuery => '떠나신다니 아쉽습니다. 뭔가 문제가 있으셨나요?';

  @override
  String get yesSendFeedbackAction => '네, 피드백을 보냅니다';

  @override
  String get noDeleteAccountAction => '아니오, 계정을 지웁니다';

  @override
  String get initiateAccountDeleteTitle => '계정 삭제 절차를 시작하려면 인증 절차를 거쳐주세요';

  @override
  String get confirmAccountDeleteTitle => '계정 삭제 확인';

  @override
  String get confirmAccountDeleteMessage =>
      '다른 Ente의 서비스를 이용하고 계시다면, 해당 계정은 모두 연결이 되어있습니다.\n\n모든 Ente 서비스에 업로드 된 당신의 데이터는 삭제 수순에 들어가며, 계정은 불가역적으로 삭제됩니다.';

  @override
  String get delete => '삭제';

  @override
  String get createNewAccount => '새 계정 만들기';

  @override
  String get password => '암호';

  @override
  String get confirmPassword => '암호 확인';

  @override
  String passwordStrength(String passwordStrengthValue) {
    return '암호 보안 강도: $passwordStrengthValue';
  }

  @override
  String get hearUsWhereTitle => 'Ente에 대해 어떻게 알게 되셨나요? (선택사항)';

  @override
  String get hearUsExplanation =>
      '저희는 어플 설치 과정을 관찰하지 않습니다. 어디에서 저희를 발견하셨는지 알려주신다면 도움이 될 겁니다!';

  @override
  String get signUpTerms =>
      '나는 <u-terms>사용자 약관</u-terms>과 <u-policy>개인정보 취급방침</u-policy>에 동의합니다.';

  @override
  String get termsOfServicesTitle => '약관';

  @override
  String get privacyPolicyTitle => '개인정보 취급 방침';

  @override
  String get ackPasswordLostWarning =>
      '나는 암호를 분실한 경우, 데이터가 <underline>종단 간 암호화</underline>되어있기에 데이터를 손실할 수 있음을 이해합니다.';

  @override
  String get encryption => '암호화';

  @override
  String get logInLabel => '로그인';

  @override
  String get welcomeBack => '돌아오신 것을 환영합니다!';

  @override
  String get loginTerms =>
      '로그인을 누름으로써, 나는 <u-terms>사용자 약관</u-terms>과 <u-policy>개인정보 취급방침</u-policy>에 동의합니다.';

  @override
  String get noInternetConnection => '인터넷 연결 없음';

  @override
  String get pleaseCheckYourInternetConnectionAndTryAgain =>
      '인터넷 연결을 확인하시고 다시 시도해주세요.';

  @override
  String get verificationFailedPleaseTryAgain => '검증 실패, 다시 시도해주세요';

  @override
  String get recreatePasswordTitle => '암호 다시 생성';

  @override
  String get recreatePasswordBody =>
      '현재 사용 중인 기기는 암호를 확인하기에 적합하지 않으나, 모든 기기에서 작동하는 방식으로 비밀번호를 다시 생성할 수 있습니다.\n\n복구 키를 사용하여 로그인하고 암호를 다시 생성해주세요. (원하시면 현재 사용 중인 암호와 같은 암호를 다시 사용하실 수 있습니다.)';

  @override
  String get useRecoveryKey => '복구 키 사용';

  @override
  String get forgotPassword => '암호 분실';

  @override
  String get changeEmail => '이메일 변경';

  @override
  String get verifyEmail => '이메일 인증하기';

  @override
  String weHaveSendEmailTo(String email) {
    return '<green>$email</green> 쪽으로 메일을 보냈습니다';
  }

  @override
  String get toResetVerifyEmail => '암호를 재설정하시려면, 먼저 이메일을 인증해주세요.';

  @override
  String get checkInboxAndSpamFolder => '검증을 위해 메일 보관함을 (또는 스팸 메일 보관함) 확인해주세요';

  @override
  String get tapToEnterCode => '눌러서 코드 입력하기';

  @override
  String get sendEmail => '이메일 보내기';

  @override
  String get resendEmail => '이메일 다시 보내기';

  @override
  String get passKeyPendingVerification => '검증 절차가 마무리되지 않았습니다';

  @override
  String get loginSessionExpired => '세션 만료됨';

  @override
  String get loginSessionExpiredDetails => '세션이 만료되었습니다. 다시 로그인해주세요.';

  @override
  String get passkeyAuthTitle => '패스키 검증';

  @override
  String get waitingForVerification => '검증 대기 중...';

  @override
  String get tryAgain => '다시 시도해주세요';

  @override
  String get checkStatus => '상태 확인';

  @override
  String get loginWithTOTP => 'TOTP로 로그인 하기';

  @override
  String get recoverAccount => '계정 복구';

  @override
  String get setPasswordTitle => '암호 지정';

  @override
  String get changePasswordTitle => '암호 변경';

  @override
  String get resetPasswordTitle => '암호 초기화';

  @override
  String get encryptionKeys => '암호화 키';

  @override
  String get enterPasswordToEncrypt => '데이터 암호화를 위한 암호 입력';

  @override
  String get enterNewPasswordToEncrypt => '데이터 암호화를 위한 새로운 암호 입력';

  @override
  String get passwordWarning =>
      '저희는 이 암호를 저장하지 않으니, 만약 잊어버리시게 되면, <underline>데이터를 복호화 해드릴 수 없습니다</underline>';

  @override
  String get howItWorks => '작동 원리';

  @override
  String get generatingEncryptionKeys => '암호화 키 생성 중...';

  @override
  String get passwordChangedSuccessfully => '암호가 성공적으로 변경되었습니다';

  @override
  String get signOutFromOtherDevices => '다른 기기들에서 로그아웃하기';

  @override
  String get signOutOtherBody =>
      '다른 사람이 내 암호를 알 수도 있을 거란 의심이 드신다면, 당신의 계정을 사용 중인 다른 모든 기기에서 로그아웃할 수 있습니다.';

  @override
  String get signOutOtherDevices => '다른 기기들을 로그아웃시키기';

  @override
  String get doNotSignOut => '로그아웃 하지 않기';

  @override
  String get generatingEncryptionKeysTitle => '암호화 키를 생성하는 중...';

  @override
  String get continueLabel => '계속';

  @override
  String get insecureDevice => '보안이 허술한 기기';

  @override
  String get sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease =>
      '죄송합니다, 이 기기에서 보안 키를 생성할 수 없습니다.\n\n다른 기기에서 계정을 생성해주세요.';

  @override
  String get recoveryKeyCopiedToClipboard => '클립보드에 복구 키 복사 됨';

  @override
  String get recoveryKey => '복구 키';

  @override
  String get recoveryKeyOnForgotPassword =>
      '암호를 잊어버린 경우, 데이터를 복구하려면 이 키를 이용하는 방법 뿐입니다.';

  @override
  String get recoveryKeySaveDescription =>
      '저희는 이 키를 보관하지 않으니, 여기에 있는 24 단어로 구성된 키를 안전하게 보관해주세요.';

  @override
  String get doThisLater => '나중에 하기';

  @override
  String get saveKey => '키 저장하기';

  @override
  String get recoveryKeySaved => '다운로드 폴더에 복구 키가 저장되었습니다!';

  @override
  String get noRecoveryKeyTitle => '복구 키가 없으세요?';

  @override
  String get twoFactorAuthTitle => '2단계 인증';

  @override
  String get enterCodeHint => 'Authenticator에 적힌 6 자리 코드를 입력해주세요';

  @override
  String get lostDeviceTitle => '기기를 잃어버리셨나요?';

  @override
  String get enterRecoveryKeyHint => '복구 키를 입력하세요';

  @override
  String get recover => '복구';

  @override
  String get loggingOut => '로그아웃하는 중...';

  @override
  String get immediately => '즉시';

  @override
  String get appLock => '어플 잠금';

  @override
  String get autoLock => '자동 잠금';

  @override
  String get noSystemLockFound => '시스템 잠금 찾을 수 없음';

  @override
  String get deviceLockEnablePreSteps =>
      '기기 잠금을 활성화하시려면, 기기의 암호를 만들거나 시스템 설정에서 화면 잠금을 설정해주세요.';

  @override
  String get appLockDescription =>
      '기본 잠금 화면이나, PIN 번호나 암호를 사용한 사용자 설정 잠금 화면 중에 선택하세요.';

  @override
  String get deviceLock => '기기 잠금';

  @override
  String get pinLock => 'Pin 잠금';

  @override
  String get autoLockFeatureDescription => 'Background로 App 넘어가고 잠기기까지 걸리는 시간';

  @override
  String get hideContent => '내용 숨기기';

  @override
  String get hideContentDescriptionAndroid =>
      'App 전환 화면에서 App의 내용을 숨기고 Screenshot 촬영을 막습니다';

  @override
  String get hideContentDescriptioniOS => 'App 전환 화면에서 App의 내용을 숨깁니다';

  @override
  String get tooManyIncorrectAttempts => '잘못된 시도 횟수가 너무 많습니다';

  @override
  String get tapToUnlock => '잠금을 해제하려면 누르세요';

  @override
  String get areYouSureYouWantToLogout => '로그아웃 하시겠습니까?';

  @override
  String get yesLogout => '네, 로그아웃하기';

  @override
  String get authToViewSecrets => '비밀 부분을 확인하려면 인증 절차를 거쳐주세요';

  @override
  String get next => '다음';

  @override
  String get setNewPassword => '새 비밀번호 설정';

  @override
  String get enterPin => 'PIN 번호 입력';

  @override
  String get setNewPin => '새 PIN 번호 설정';

  @override
  String get confirm => '확인';

  @override
  String get reEnterPassword => '암호 다시 입력';

  @override
  String get reEnterPin => '핀 다시 입력';

  @override
  String get androidBiometricHint => '신원 확인';

  @override
  String get androidBiometricNotRecognized => '식별할 수 없습니다. 다시 시도해주세요.';

  @override
  String get androidBiometricSuccess => '성공';

  @override
  String get androidCancelButton => '취소';

  @override
  String get androidSignInTitle => '인증 필요';

  @override
  String get androidBiometricRequiredTitle => '생체인증 필요';

  @override
  String get androidDeviceCredentialsRequiredTitle => '장치 자격 증명 필요';

  @override
  String get androidDeviceCredentialsSetupDescription => '장치 자격 증명 필요';

  @override
  String get goToSettings => '설정으로 가기';

  @override
  String get androidGoToSettingsDescription =>
      '기기에 생체인증이 설정되어있지 않습니다. \'설정 > 보안\'으로 가셔서 생체인증을 설정해주세요.';

  @override
  String get iOSLockOut => '생체인증에 문제가 있습니다. 활성화하시려면 기기를 잠궜다가 다시 풀어주세요.';

  @override
  String get iOSOkButton => '확인';

  @override
  String get emailAlreadyRegistered => '이미 등록된 이메일입니다.';

  @override
  String get emailNotRegistered => '등록되지 않은 이메일입니다.';

  @override
  String get thisEmailIsAlreadyInUse => '이 이메일은 이미 사용 중입니다';

  @override
  String emailChangedTo(String newEmail) {
    return '$newEmail로 메일이 변경되었습니다';
  }

  @override
  String get authenticationFailedPleaseTryAgain => '인증절차 실패, 다시 시도해주세요';

  @override
  String get authenticationSuccessful => '인증 성공!';

  @override
  String get sessionExpired => '세션 만료';

  @override
  String get incorrectRecoveryKey => '잘못 된 복구 키';

  @override
  String get theRecoveryKeyYouEnteredIsIncorrect => '입력하신 복구 키가 맞지 않습니다';

  @override
  String get twofactorAuthenticationSuccessfullyReset => '2FA가 성공적으로 초기화되었습니다';

  @override
  String get noRecoveryKey => 'No recovery key';

  @override
  String get yourAccountHasBeenDeleted => 'Your account has been deleted';

  @override
  String get verificationId => 'Verification ID';

  @override
  String get yourVerificationCodeHasExpired => '검증 코드의 유효시간이 경과하였습니다';

  @override
  String get incorrectCode => '잘못된 코드';

  @override
  String get sorryTheCodeYouveEnteredIsIncorrect => '죄송합니다, 입력하신 코드가 맞지 않습니다';

  @override
  String get developerSettings => '개발자 설정';

  @override
  String get serverEndpoint => '서버 엔드포인트';

  @override
  String get invalidEndpoint => '유효하지 않은 엔드포인트';

  @override
  String get invalidEndpointMessage =>
      '죄송합니다, 입력하신 엔드포인트가 유효하지 않습니다. 유효한 엔드포인트를 입력하시고 다시 시도해주세요.';

  @override
  String get endpointUpdatedMessage => '엔드포인트가 성공적으로 업데이트됨';
}
