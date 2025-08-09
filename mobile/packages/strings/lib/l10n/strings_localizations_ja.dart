// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'strings_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class StringsLocalizationsJa extends StringsLocalizations {
  StringsLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get networkHostLookUpErr =>
      'Enteに接続できませんでした。ネットワーク設定を確認し、エラーが解決しない場合はサポートにお問い合わせください。';

  @override
  String get networkConnectionRefusedErr =>
      'Enteに接続できませんでした。しばらくしてから再試行してください。エラーが解決しない場合は、サポートにお問い合わせください。';

  @override
  String get itLooksLikeSomethingWentWrongPleaseRetryAfterSome =>
      '問題が発生したようです。しばらくしてから再試行してください。エラーが解決しない場合は、サポートチームにお問い合わせください。';

  @override
  String get error => 'エラー';

  @override
  String get ok => 'OK';

  @override
  String get faq => 'FAQ';

  @override
  String get contactSupport => 'サポートに問い合わせ';

  @override
  String get emailYourLogs => 'ログをメールで送信';

  @override
  String pleaseSendTheLogsTo(String toEmail) {
    return 'ログを以下のアドレスに送信してください \n$toEmail';
  }

  @override
  String get copyEmailAddress => 'メールアドレスをコピー';

  @override
  String get exportLogs => 'ログのエクスポート';

  @override
  String get cancel => 'キャンセル';

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
  String get reportABug => 'バグを報告';

  @override
  String get logsDialogBody =>
      'This will send across logs to help us debug your issue. Please note that file names will be included to help track issues with specific files.';

  @override
  String get viewLogs => 'View logs';

  @override
  String customEndpoint(String endpoint) {
    return '$endpoint に接続しました';
  }

  @override
  String get save => '保存';

  @override
  String get send => '送信';

  @override
  String get saveOrSendDescription =>
      'これをストレージ (デフォルトではダウンロードフォルダ) に保存しますか、もしくは他のアプリに送信しますか？';

  @override
  String get saveOnlyDescription => 'これをストレージに保存しますか？ (デフォルトではダウンロードフォルダに保存)';

  @override
  String get enterNewEmailHint => 'Enter your new email address';

  @override
  String get email => 'E メール';

  @override
  String get verify => '認証';

  @override
  String get invalidEmailTitle => 'メールアドレスが無効です';

  @override
  String get invalidEmailMessage => '有効なメールアドレスを入力して下さい';

  @override
  String get pleaseWait => 'お待ちください...';

  @override
  String get verifyPassword => 'パスワードを確認';

  @override
  String get incorrectPasswordTitle => 'パスワードが正しくありません';

  @override
  String get pleaseTryAgain => '再度お試しください';

  @override
  String get enterPassword => 'パスワードを入力';

  @override
  String get enterYourPasswordHint => 'パスワードを入力してください';

  @override
  String get activeSessions => 'アクティブセッション';

  @override
  String get oops => 'おっと';

  @override
  String get somethingWentWrongPleaseTryAgain => '問題が発生しました、再試行してください';

  @override
  String get thisWillLogYouOutOfThisDevice => 'このデバイスからログアウトします！';

  @override
  String get thisWillLogYouOutOfTheFollowingDevice => '以下のデバイスからログアウトします:';

  @override
  String get terminateSession => 'セッションを終了しますか？';

  @override
  String get terminate => '終了';

  @override
  String get thisDevice => 'このデバイス';

  @override
  String get createAccount => 'アカウント作成';

  @override
  String get weakStrength => '脆弱';

  @override
  String get moderateStrength => 'まあまあ';

  @override
  String get strongStrength => '強力';

  @override
  String get deleteAccount => 'アカウント削除';

  @override
  String get deleteAccountQuery => 'ご不便をおかけして申し訳ありません。なにか問題が発生していますか？';

  @override
  String get yesSendFeedbackAction => 'はい、フィードバックを送信します';

  @override
  String get noDeleteAccountAction => 'いいえ、アカウントを削除します';

  @override
  String get initiateAccountDeleteTitle => 'アカウントの削除を開始するためには認証が必要です';

  @override
  String get confirmAccountDeleteTitle => 'アカウントの削除に同意';

  @override
  String get confirmAccountDeleteMessage =>
      'このアカウントは他のEnteアプリも使用している場合はそれらにも紐づけされています。\nすべてのEnteアプリでアップロードされたデータは削除され、アカウントは完全に削除されます。';

  @override
  String get delete => '削除';

  @override
  String get createNewAccount => '新規アカウント作成';

  @override
  String get password => 'パスワード';

  @override
  String get confirmPassword => 'パスワードの確認';

  @override
  String passwordStrength(String passwordStrengthValue) {
    return 'パスワードの強度: $passwordStrengthValue';
  }

  @override
  String get hearUsWhereTitle => 'Ente についてどのようにお聞きになりましたか？（任意）';

  @override
  String get hearUsExplanation =>
      '私たちはアプリのインストールを追跡していません。私たちをお知りになった場所を教えてください！';

  @override
  String get signUpTerms =>
      '<u-terms>利用規約</u-terms>と<u-policy>プライバシー ポリシー</u-policy>に同意します';

  @override
  String get termsOfServicesTitle => '利用規約';

  @override
  String get privacyPolicyTitle => 'プライバシーポリシー';

  @override
  String get ackPasswordLostWarning =>
      '私のデータは<underline>エンドツーエンドで暗号化される</underline>ため、パスワードを紛失した場合、データが失われる可能性があることを理解しています。';

  @override
  String get encryption => '暗号化';

  @override
  String get logInLabel => 'ログイン';

  @override
  String get welcomeBack => 'おかえりなさい！';

  @override
  String get loginTerms =>
      'ログインをクリックする場合、<u-terms>利用規約</u-terms>および<u-policy>プライバシー ポリシー</u-policy>に同意するものとします。';

  @override
  String get noInternetConnection => 'インターネット接続なし';

  @override
  String get pleaseCheckYourInternetConnectionAndTryAgain =>
      'インターネット接続を確認して、再試行してください。';

  @override
  String get verificationFailedPleaseTryAgain => '確認に失敗しました、再試行してください';

  @override
  String get recreatePasswordTitle => 'パスワードを再設定';

  @override
  String get recreatePasswordBody =>
      '現在のデバイスはパスワードを確認するのには不十分ですが、すべてのデバイスで動作するように再生成することはできます。\n\n回復キーを使用してログインし、パスワードを再生成してください（ご希望の場合は同じものを再度使用できます）。';

  @override
  String get useRecoveryKey => '回復キーを使用';

  @override
  String get forgotPassword => 'パスワードを忘れた場合';

  @override
  String get changeEmail => 'メールアドレスを変更';

  @override
  String get verifyEmail => 'メールアドレス認証';

  @override
  String weHaveSendEmailTo(String email) {
    return '<green>$email</green> にメールを送信しました';
  }

  @override
  String get toResetVerifyEmail => 'パスワードをリセットするには、メールの確認を先に行ってください。';

  @override
  String get checkInboxAndSpamFolder => '受信トレイ（および迷惑メール）を確認して認証を完了してください';

  @override
  String get tapToEnterCode => 'タップしてコードを入力';

  @override
  String get sendEmail => 'メール送信';

  @override
  String get resendEmail => 'メールを再送信';

  @override
  String get passKeyPendingVerification => '認証はまだ保留中です';

  @override
  String get loginSessionExpired => 'セッションの有効期限が切れました';

  @override
  String get loginSessionExpiredDetails => 'セッションの有効期限が切れました。再度ログインしてください。';

  @override
  String get passkeyAuthTitle => 'パスキー認証';

  @override
  String get waitingForVerification => '認証を待っています...';

  @override
  String get tryAgain => '再試行';

  @override
  String get checkStatus => 'ステータスの確認';

  @override
  String get loginWithTOTP => 'TOTPでログイン';

  @override
  String get recoverAccount => 'アカウントを回復';

  @override
  String get setPasswordTitle => 'パスワードの設定';

  @override
  String get changePasswordTitle => 'パスワードの変更';

  @override
  String get resetPasswordTitle => 'パスワードのリセット';

  @override
  String get encryptionKeys => '暗号鍵';

  @override
  String get enterPasswordToEncrypt => 'データの暗号化に使用するパスワードを入力してください';

  @override
  String get enterNewPasswordToEncrypt => 'データの暗号化に使用する新しいパスワードを入力してください';

  @override
  String get passwordWarning =>
      '私たちはこのパスワードを保存していないので、あなたがそれを忘れた場合に<underline>私たちがあなたのデータを代わりに復号することはできません</underline>';

  @override
  String get howItWorks => '動作の仕組み';

  @override
  String get generatingEncryptionKeys => '暗号鍵を生成中...';

  @override
  String get passwordChangedSuccessfully => 'パスワードを変更しました';

  @override
  String get signOutFromOtherDevices => '他のデバイスからサインアウトする';

  @override
  String get signOutOtherBody =>
      '他の誰かがあなたのパスワードを知っている可能性があると判断した場合は、あなたのアカウントを使用している他のすべてのデバイスから強制的にサインアウトできます。';

  @override
  String get signOutOtherDevices => '他のデバイスからサインアウトする';

  @override
  String get doNotSignOut => 'サインアウトしない';

  @override
  String get generatingEncryptionKeysTitle => '暗号化鍵を生成中...';

  @override
  String get continueLabel => '続行';

  @override
  String get insecureDevice => '安全ではないデバイス';

  @override
  String get sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease =>
      '申し訳ありませんが、このデバイスでは安全な鍵を生成できませんでした。\n\n別のデバイスから登録してください。';

  @override
  String get recoveryKeyCopiedToClipboard => '回復キーをクリップボードにコピーしました';

  @override
  String get recoveryKey => '回復キー';

  @override
  String get recoveryKeyOnForgotPassword =>
      'パスワードを忘れた場合、データを回復できる唯一の方法がこのキーです。';

  @override
  String get recoveryKeySaveDescription =>
      '私たちはこのキーを保存しません。この 24 単語のキーを安全な場所に保存してください。';

  @override
  String get doThisLater => '後で行う';

  @override
  String get saveKey => 'キーを保存';

  @override
  String get recoveryKeySaved => 'リカバリキーをダウンロードフォルダに保存しました！';

  @override
  String get noRecoveryKeyTitle => '回復キーがありませんか？';

  @override
  String get twoFactorAuthTitle => '2 要素認証';

  @override
  String get enterCodeHint => '認証アプリに表示された 6 桁のコードを入力してください';

  @override
  String get lostDeviceTitle => 'デバイスを紛失しましたか？';

  @override
  String get enterRecoveryKeyHint => '回復キーを入力';

  @override
  String get recover => '回復';

  @override
  String get loggingOut => 'ログアウト中...';

  @override
  String get immediately => 'すぐに';

  @override
  String get appLock => 'アプリのロック';

  @override
  String get autoLock => '自動ロック';

  @override
  String get noSystemLockFound => 'システムロックが見つかりませんでした';

  @override
  String get deviceLockEnablePreSteps =>
      '端末のロックを有効にするには、システム設定で端末のパスコードまたは画面ロックを設定してください。';

  @override
  String get appLockDescription =>
      '端末のデフォルトのロック画面と、PINまたはパスワードを使用したカスタムロック画面を選択します。';

  @override
  String get deviceLock => '生体認証';

  @override
  String get pinLock => 'PIN';

  @override
  String get autoLockFeatureDescription => 'アプリをバックグラウンドでロックするまでの時間';

  @override
  String get hideContent => '内容を非表示';

  @override
  String get hideContentDescriptionAndroid => 'アプリの内容を非表示にし、スクリーンショットを無効にします';

  @override
  String get hideContentDescriptioniOS => 'アプリを切り替えた際に、アプリの内容を非表示にします';

  @override
  String get tooManyIncorrectAttempts => '間違った回数が多すぎます';

  @override
  String get tapToUnlock => 'タップして解除';

  @override
  String get areYouSureYouWantToLogout => '本当にログアウトしてよろしいですか？';

  @override
  String get yesLogout => 'はい、ログアウトします';

  @override
  String get authToViewSecrets => '秘密鍵を閲覧するためには認証が必要です';

  @override
  String get next => '次へ';

  @override
  String get setNewPassword => '新しいパスワードを設定';

  @override
  String get enterPin => 'PINを入力してください';

  @override
  String get setNewPin => '新しいPINを設定';

  @override
  String get confirm => '確認';

  @override
  String get reEnterPassword => 'パスワードを再入力してください';

  @override
  String get reEnterPin => 'PINを再入力してください';

  @override
  String get androidBiometricHint => '本人を確認する';

  @override
  String get androidBiometricNotRecognized => '認識できません。再試行してください。';

  @override
  String get androidBiometricSuccess => '成功';

  @override
  String get androidCancelButton => 'キャンセル';

  @override
  String get androidSignInTitle => '認証が必要です';

  @override
  String get androidBiometricRequiredTitle => '生体認証が必要です';

  @override
  String get androidDeviceCredentialsRequiredTitle => 'デバイスの認証情報が必要です';

  @override
  String get androidDeviceCredentialsSetupDescription => 'デバイスの認証情報が必要です';

  @override
  String get goToSettings => '設定を開く';

  @override
  String get androidGoToSettingsDescription =>
      '生体認証がデバイスで設定されていません。生体認証を追加するには、\"設定 > セキュリティ\"を開いてください。';

  @override
  String get iOSLockOut => '生体認証が無効化されています。画面をロック・ロック解除して生体認証を有効化してください。';

  @override
  String get iOSOkButton => 'OK';

  @override
  String get emailAlreadyRegistered => 'メールアドレスはすでに登録されています。';

  @override
  String get emailNotRegistered => 'メールアドレスはまだ登録されていません。';

  @override
  String get thisEmailIsAlreadyInUse => 'このアドレスは既に使用されています';

  @override
  String emailChangedTo(String newEmail) {
    return 'メールアドレスが $newEmail に変更されました';
  }

  @override
  String get authenticationFailedPleaseTryAgain => '認証に失敗しました、再試行してください';

  @override
  String get authenticationSuccessful => '認証に成功しました！';

  @override
  String get sessionExpired => 'セッションが失効しました';

  @override
  String get incorrectRecoveryKey => '不正な回復キー';

  @override
  String get theRecoveryKeyYouEnteredIsIncorrect => '入力された回復キーは正しくありません';

  @override
  String get twofactorAuthenticationSuccessfullyReset => '2 要素認証は正常にリセットされました';

  @override
  String get noRecoveryKey => 'No recovery key';

  @override
  String get yourAccountHasBeenDeleted => 'Your account has been deleted';

  @override
  String get verificationId => 'Verification ID';

  @override
  String get yourVerificationCodeHasExpired => '確認コードが失効しました';

  @override
  String get incorrectCode => '不正なコード';

  @override
  String get sorryTheCodeYouveEnteredIsIncorrect =>
      '申し訳ありませんが、入力されたコードは正しくありません';

  @override
  String get developerSettings => '開発者向け設定';

  @override
  String get serverEndpoint => 'サーバーエンドポイント';

  @override
  String get invalidEndpoint => '無効なエンドポイントです';

  @override
  String get invalidEndpointMessage =>
      '入力されたエンドポイントは無効です。有効なエンドポイントを入力して再試行してください。';

  @override
  String get endpointUpdatedMessage => 'エンドポイントの更新に成功しました';
}
