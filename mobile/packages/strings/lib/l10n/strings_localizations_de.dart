// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'strings_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class StringsLocalizationsDe extends StringsLocalizations {
  StringsLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get networkHostLookUpErr =>
      'Ente ist im Moment nicht erreichbar. Bitte überprüfen Sie Ihre Netzwerkeinstellungen. Sollte das Problem bestehen bleiben, wenden Sie sich bitte an den Support.';

  @override
  String get networkConnectionRefusedErr =>
      'Ente ist im Moment nicht erreichbar. Bitte versuchen Sie es später erneut. Sollte das Problem bestehen bleiben, wenden Sie sich bitte an den Support.';

  @override
  String get itLooksLikeSomethingWentWrongPleaseRetryAfterSome =>
      'Etwas ist schiefgelaufen. Bitte versuchen Sie es später noch einmal. Sollte der Fehler weiter bestehen, kontaktieren Sie unser Supportteam.';

  @override
  String get error => 'Fehler';

  @override
  String get ok => 'Ok';

  @override
  String get faq => 'FAQ';

  @override
  String get contactSupport => 'Support kontaktieren';

  @override
  String get emailYourLogs => 'E-Mail mit Logs senden';

  @override
  String pleaseSendTheLogsTo(String toEmail) {
    return 'Bitte Logs an $toEmail senden';
  }

  @override
  String get copyEmailAddress => 'E-Mail-Adresse kopieren';

  @override
  String get exportLogs => 'Logs exportieren';

  @override
  String get cancel => 'Abbrechen';

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
  String get reportABug => 'Einen Fehler melden';

  @override
  String get logsDialogBody =>
      'This will send across logs to help us debug your issue. Please note that file names will be included to help track issues with specific files.';

  @override
  String get viewLogs => 'View logs';

  @override
  String customEndpoint(String endpoint) {
    return 'Mit $endpoint verbunden';
  }

  @override
  String get save => 'Speichern';

  @override
  String get send => 'Senden';

  @override
  String get saveOrSendDescription =>
      'Möchtest du dies in deinem Speicher (standardmäßig im Ordner Downloads) speichern oder an andere Apps senden?';

  @override
  String get saveOnlyDescription =>
      'Möchtest du dies in deinem Speicher (standardmäßig im Ordner Downloads) speichern?';

  @override
  String get enterNewEmailHint => 'Gib deine neue E-Mail-Adresse ein';

  @override
  String get email => 'E-Mail';

  @override
  String get verify => 'Verifizieren';

  @override
  String get invalidEmailTitle => 'Ungültige E-Mail-Adresse';

  @override
  String get invalidEmailMessage =>
      'Bitte geben Sie eine gültige E-Mail-Adresse ein.';

  @override
  String get pleaseWait => 'Bitte warten...';

  @override
  String get verifyPassword => 'Passwort überprüfen';

  @override
  String get incorrectPasswordTitle => 'Falsches Passwort';

  @override
  String get pleaseTryAgain => 'Bitte versuchen Sie es erneut';

  @override
  String get enterPassword => 'Passwort eingeben';

  @override
  String get enterAppLockPassword => 'Enter app lock password';

  @override
  String get enterYourPasswordHint => 'Geben Sie Ihr Passwort ein';

  @override
  String get activeSessions => 'Aktive Sitzungen';

  @override
  String get oops => 'Hoppla';

  @override
  String get somethingWentWrongPleaseTryAgain =>
      'Ein Fehler ist aufgetreten, bitte erneut versuchen';

  @override
  String get thisWillLogYouOutOfThisDevice =>
      'Dadurch werden Sie von diesem Gerät abgemeldet!';

  @override
  String get thisWillLogYouOutOfTheFollowingDevice =>
      'Dadurch werden Sie vom folgendem Gerät abgemeldet:';

  @override
  String get terminateSession => 'Sitzung beenden?';

  @override
  String get terminate => 'Beenden';

  @override
  String get thisDevice => 'Dieses Gerät';

  @override
  String get createAccount => 'Konto erstellen';

  @override
  String get weakStrength => 'Schwach';

  @override
  String get moderateStrength => 'Mittel';

  @override
  String get strongStrength => 'Stark';

  @override
  String get deleteAccount => 'Konto löschen';

  @override
  String get deleteAccountQuery =>
      'Es tut uns leid, dass Sie gehen. Haben Sie ein Problem?';

  @override
  String get yesSendFeedbackAction => 'Ja, Feedback senden';

  @override
  String get noDeleteAccountAction => 'Nein, Konto löschen';

  @override
  String get deleteAccountWarning =>
      'This will delete your Ente Auth, Ente Photos and Ente Locker account.';

  @override
  String get initiateAccountDeleteTitle =>
      'Bitte authentifizieren Sie sich, um die Kontolöschung einzuleiten';

  @override
  String get confirmAccountDeleteTitle => 'Kontolöschung bestätigen';

  @override
  String get confirmAccountDeleteMessage =>
      'Dieses Konto ist mit anderen Ente-Apps verknüpft, falls Sie welche verwenden.\n\nIhre hochgeladenen Daten werden in allen Ente-Apps zur Löschung vorgemerkt und Ihr Konto wird endgültig gelöscht.';

  @override
  String get delete => 'Löschen';

  @override
  String get createNewAccount => 'Neues Konto erstellen';

  @override
  String get password => 'Passwort';

  @override
  String get confirmPassword => 'Bestätigen Sie das Passwort';

  @override
  String passwordStrength(String passwordStrengthValue) {
    return 'Passwortstärke: $passwordStrengthValue';
  }

  @override
  String get hearUsWhereTitle => 'Wie hast du von Ente erfahren? (optional)';

  @override
  String get hearUsExplanation =>
      'Wir tracken keine App-Installationen. Es würde uns jedoch helfen, wenn du uns mitteilst, wie du von uns erfahren hast!';

  @override
  String get signUpTerms =>
      'Ich stimme den <u-terms>Nutzerbedingungen</u-terms> und <u-policy>Datenschutzbestimmungen</u-policy> zu';

  @override
  String get termsOfServicesTitle => 'Bedingungen';

  @override
  String get privacyPolicyTitle => 'Datenschutzbestimmungen';

  @override
  String get ackPasswordLostWarning =>
      'Ich verstehe, dass der Verlust meines Passworts zum Verlust meiner Daten führen kann, denn diese sind <underline>Ende-zu-Ende verschlüsselt</underline>.';

  @override
  String get encryption => 'Verschlüsselung';

  @override
  String get logInLabel => 'Einloggen';

  @override
  String get welcomeBack => 'Willkommen zurück!';

  @override
  String get loginTerms =>
      'Durch das Klicken auf den Login-Button, stimme ich den <u-terms> Nutzungsbedingungen</u-terms> und den <u-policy>Datenschutzbestimmungen</u-policy> zu';

  @override
  String get noInternetConnection => 'Keine Internetverbindung';

  @override
  String get pleaseCheckYourInternetConnectionAndTryAgain =>
      'Bitte überprüfen Sie Ihre Internetverbindung und versuchen Sie erneut.';

  @override
  String get verificationFailedPleaseTryAgain =>
      'Verifizierung fehlgeschlagen, bitte versuchen Sie es erneut';

  @override
  String get recreatePasswordTitle => 'Neues Passwort erstellen';

  @override
  String get recreatePasswordBody =>
      'Das benutzte Gerät ist nicht leistungsfähig genug das Passwort zu prüfen. Wir können es aber neu erstellen damit es auf jedem Gerät funktioniert. \n\nBitte loggen sie sich mit ihrem Wiederherstellungsschlüssel ein und erstellen sie ein neues Passwort (Sie können das selbe Passwort wieder verwenden, wenn sie möchten).';

  @override
  String get useRecoveryKey => 'Wiederherstellungsschlüssel verwenden';

  @override
  String get forgotPassword => 'Passwort vergessen';

  @override
  String get changeEmail => 'E-Mail ändern';

  @override
  String get verifyEmail => 'E-Mail-Adresse verifizieren';

  @override
  String weHaveSendEmailTo(String email) {
    return 'Wir haben eine E-Mail an <green>$email</green> gesendet';
  }

  @override
  String get toResetVerifyEmail =>
      'Um Ihr Passwort zurückzusetzen, verifizieren Sie bitte zuerst Ihre E-Mail-Adresse.';

  @override
  String get checkInboxAndSpamFolder =>
      'Bitte überprüfe deinen E-Mail-Posteingang (und Spam), um die Verifizierung abzuschließen';

  @override
  String get tapToEnterCode => 'Antippen, um den Code einzugeben';

  @override
  String get sendEmail => 'E-Mail senden';

  @override
  String get resendEmail => 'E-Mail erneut senden';

  @override
  String get passKeyPendingVerification => 'Verifizierung steht noch aus';

  @override
  String get loginSessionExpired => 'Sitzung abgelaufen';

  @override
  String get loginSessionExpiredDetails =>
      'Ihre Sitzung ist abgelaufen. Bitte melden Sie sich erneut an.';

  @override
  String get passkeyAuthTitle => 'Passkey Authentifizierung';

  @override
  String get waitingForVerification => 'Warte auf Bestätigung...';

  @override
  String get tryAgain => 'Noch einmal versuchen';

  @override
  String get checkStatus => 'Status überprüfen';

  @override
  String get loginWithTOTP => 'Mit TOTP anmelden';

  @override
  String get recoverAccount => 'Konto wiederherstellen';

  @override
  String get setPasswordTitle => 'Passwort setzen';

  @override
  String get changePasswordTitle => 'Passwort ändern';

  @override
  String get resetPasswordTitle => 'Passwort zurücksetzen';

  @override
  String get encryptionKeys => 'Verschlüsselungsschlüssel';

  @override
  String get enterPasswordToEncrypt =>
      'Geben Sie ein Passwort ein, mit dem wir Ihre Daten verschlüsseln können';

  @override
  String get enterNewPasswordToEncrypt =>
      'Geben Sie ein neues Passwort ein, mit dem wir Ihre Daten verschlüsseln können';

  @override
  String get passwordWarning =>
      'Wir speichern dieses Passwort nicht. Wenn Sie es vergessen, <underline>können wir Ihre Daten nicht entschlüsseln</underline>';

  @override
  String get howItWorks => 'So funktioniert\'s';

  @override
  String get generatingEncryptionKeys =>
      'Generierung von Verschlüsselungsschlüsseln...';

  @override
  String get passwordChangedSuccessfully => 'Passwort erfolgreich geändert';

  @override
  String get signOutFromOtherDevices => 'Von anderen Geräten abmelden';

  @override
  String get signOutOtherBody =>
      'Falls Sie denken, dass jemand Ihr Passwort kennen könnte, können Sie alle anderen Geräte forcieren, sich von Ihrem Konto abzumelden.';

  @override
  String get signOutOtherDevices => 'Andere Geräte abmelden';

  @override
  String get doNotSignOut => 'Nicht abmelden';

  @override
  String get generatingEncryptionKeysTitle =>
      'Generierung von Verschlüsselungsschlüsseln...';

  @override
  String get continueLabel => 'Weiter';

  @override
  String get insecureDevice => 'Unsicheres Gerät';

  @override
  String get sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease =>
      'Es tut uns leid, wir konnten keine sicheren Schlüssel auf diesem Gerät generieren.\n\nBitte registrieren Sie sich auf einem anderen Gerät.';

  @override
  String get recoveryKeyCopiedToClipboard =>
      'Wiederherstellungsschlüssel in die Zwischenablage kopiert';

  @override
  String get recoveryKey => 'Wiederherstellungsschlüssel';

  @override
  String get recoveryKeyOnForgotPassword =>
      'Sollten sie ihr Passwort vergessen, dann ist dieser Schlüssel die einzige Möglichkeit ihre Daten wiederherzustellen.';

  @override
  String get recoveryKeySaveDescription =>
      'Wir speichern diesen Schlüssel nicht. Sichern Sie diesen Schlüssel bestehend aus 24 Wörtern an einem sicheren Platz.';

  @override
  String get doThisLater => 'Auf später verschieben';

  @override
  String get saveKey => 'Schlüssel speichern';

  @override
  String get recoveryKeySaved =>
      'Wiederherstellungsschlüssel im Downloads-Ordner gespeichert!';

  @override
  String get noRecoveryKeyTitle => 'Kein Wiederherstellungsschlüssel?';

  @override
  String get twoFactorAuthTitle => 'Zwei-Faktor-Authentifizierung';

  @override
  String get enterCodeHint =>
      'Geben Sie den 6-stelligen Code \naus Ihrer Authentifikator-App ein.';

  @override
  String get lostDeviceTitle => 'Gerät verloren?';

  @override
  String get enterRecoveryKeyHint =>
      'Geben Sie Ihren Wiederherstellungsschlüssel ein';

  @override
  String get recover => 'Wiederherstellen';

  @override
  String get loggingOut => 'Wird abgemeldet...';

  @override
  String get immediately => 'Sofort';

  @override
  String get appLock => 'App-Sperre';

  @override
  String get autoLock => 'Automatisches Sperren';

  @override
  String get noSystemLockFound => 'Keine Systemsperre gefunden';

  @override
  String get deviceLockEnablePreSteps =>
      'Um die Gerätesperre zu aktivieren, richte bitte einen Gerätepasscode oder eine Bildschirmsperre in den Systemeinstellungen ein.';

  @override
  String get appLockDescription =>
      'Wähle zwischen dem Standard-Sperrbildschirm deines Gerätes und einem eigenen Sperrbildschirm mit PIN oder Passwort.';

  @override
  String get deviceLock => 'Gerätesperre';

  @override
  String get pinLock => 'PIN-Sperre';

  @override
  String get autoLockFeatureDescription =>
      'Zeit, nach der die App gesperrt wird, nachdem sie in den Hintergrund verschoben wurde';

  @override
  String get hideContent => 'Inhalte verstecken';

  @override
  String get hideContentDescriptionAndroid =>
      'Versteckt Inhalte der App beim Wechseln zwischen Apps und deaktiviert Screenshots';

  @override
  String get hideContentDescriptioniOS =>
      'Versteckt Inhalte der App beim Wechseln zwischen Apps';

  @override
  String get tooManyIncorrectAttempts => 'Zu viele fehlerhafte Versuche';

  @override
  String get tapToUnlock => 'Zum Entsperren antippen';

  @override
  String get areYouSureYouWantToLogout =>
      'Sind sie sicher, dass sie sich ausloggen möchten?';

  @override
  String get yesLogout => 'Ja ausloggen';

  @override
  String get authToViewSecrets =>
      'Bitte authentifizieren, um Ihren Wiederherstellungscode anzuzeigen';

  @override
  String get next => 'Weiter';

  @override
  String get setNewPassword => 'Neues Passwort festlegen';

  @override
  String get enterPin => 'PIN eingeben';

  @override
  String get enterAppLockPin => 'Enter app lock PIN';

  @override
  String get setNewPin => 'Neue PIN festlegen';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get reEnterPassword => 'Passwort erneut eingeben';

  @override
  String get reEnterPin => 'PIN erneut eingeben';

  @override
  String get androidBiometricHint => 'Identität bestätigen';

  @override
  String get androidBiometricNotRecognized =>
      'Nicht erkannt. Versuchen Sie es erneut.';

  @override
  String get androidBiometricSuccess => 'Erfolgreich';

  @override
  String get androidCancelButton => 'Abbrechen';

  @override
  String get androidSignInTitle => 'Authentifizierung erforderlich';

  @override
  String get androidBiometricRequiredTitle => 'Biometrie erforderlich';

  @override
  String get androidDeviceCredentialsRequiredTitle =>
      'Geräteanmeldeinformationen erforderlich';

  @override
  String get androidDeviceCredentialsSetupDescription =>
      'Geräteanmeldeinformationen erforderlich';

  @override
  String get goToSettings => 'Zu den Einstellungen';

  @override
  String get androidGoToSettingsDescription =>
      'Auf Ihrem Gerät ist keine biometrische Authentifizierung eingerichtet. Gehen Sie zu \'Einstellungen > Sicherheit\', um die biometrische Authentifizierung hinzuzufügen.';

  @override
  String get iOSLockOut =>
      'Die biometrische Authentifizierung ist deaktiviert. Bitte sperren und entsperren Sie Ihren Bildschirm, um sie wieder zu aktivieren.';

  @override
  String get iOSOkButton => 'OK';

  @override
  String get emailAlreadyRegistered => 'E-Mail ist bereits registriert.';

  @override
  String get emailNotRegistered => 'E-Mail-Adresse nicht registriert.';

  @override
  String get thisEmailIsAlreadyInUse =>
      'Diese E-Mail-Adresse wird bereits verwendet';

  @override
  String emailChangedTo(String newEmail) {
    return 'E-Mail-Adresse geändert zu $newEmail';
  }

  @override
  String get authenticationFailedPleaseTryAgain =>
      'Authentifizierung fehlgeschlagen, bitte erneut versuchen';

  @override
  String get authenticationSuccessful => 'Authentifizierung erfolgreich!';

  @override
  String get sessionExpired => 'Sitzung abgelaufen';

  @override
  String get incorrectRecoveryKey => 'Falscher Wiederherstellungs-Schlüssel';

  @override
  String get theRecoveryKeyYouEnteredIsIncorrect =>
      'Der eingegebene Wiederherstellungs-Schlüssel ist ungültig';

  @override
  String get twofactorAuthenticationSuccessfullyReset =>
      'Zwei-Faktor-Authentifizierung (2FA) erfolgreich zurückgesetzt';

  @override
  String get noRecoveryKey => 'No recovery key';

  @override
  String get yourAccountHasBeenDeleted => 'Your account has been deleted';

  @override
  String get verificationId => 'Verification ID';

  @override
  String get yourVerificationCodeHasExpired =>
      'Ihr Bestätigungscode ist abgelaufen';

  @override
  String get incorrectCode => 'Falscher Code';

  @override
  String get sorryTheCodeYouveEnteredIsIncorrect =>
      'Leider ist der eingegebene Code falsch';

  @override
  String get developerSettings => 'Entwicklereinstellungen';

  @override
  String get serverEndpoint => 'Server Endpunkt';

  @override
  String get invalidEndpoint => 'Ungültiger Endpunkt';

  @override
  String get invalidEndpointMessage =>
      'Der eingegebene Endpunkt ist ungültig. Bitte geben Sie einen gültigen Endpunkt ein und versuchen Sie es erneut.';

  @override
  String get endpointUpdatedMessage => 'Endpunkt erfolgreich aktualisiert';

  @override
  String get yes => 'Yes';

  @override
  String get remove => 'Remove';

  @override
  String get addMore => 'Add more';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get legacy => 'Legacy';

  @override
  String get recoveryWarning =>
      'A trusted contact is trying to access your account';

  @override
  String recoveryWarningBody(Object email) {
    return '$email is trying to recover your account.';
  }

  @override
  String get legacyPageDesc =>
      'Legacy allows trusted contacts to access your account in your absence.';

  @override
  String get legacyPageDesc2 =>
      'Trusted contacts can initiate account recovery, and if not blocked within 30 days, reset your password and access your account.';

  @override
  String get legacyAccounts => 'Legacy accounts';

  @override
  String get trustedContacts => 'Trusted contacts';

  @override
  String legacyInvite(String email) {
    return '$email has invited you to be a trusted contact';
  }

  @override
  String get acceptTrustInvite => 'Accept invite';

  @override
  String get addTrustedContact => 'Add Trusted Contact';

  @override
  String get removeInvite => 'Remove invite';

  @override
  String get rejectRecovery => 'Reject recovery';

  @override
  String get recoveryInitiated => 'Recovery initiated';

  @override
  String recoveryInitiatedDesc(int days, String email) {
    return 'You can access the account after $days days. A notification will be sent to $email.';
  }

  @override
  String get removeYourselfAsTrustedContact =>
      'Remove yourself as trusted contact';

  @override
  String get declineTrustInvite => 'Decline Invite';

  @override
  String get cancelAccountRecovery => 'Cancel recovery';

  @override
  String get recoveryAccount => 'Recover account';

  @override
  String get cancelAccountRecoveryBody =>
      'Are you sure you want to cancel recovery?';

  @override
  String get startAccountRecoveryTitle => 'Start recovery';

  @override
  String get whyAddTrustContact =>
      'Trusted contact can help in recovering your data.';

  @override
  String recoveryReady(String email) {
    return 'You can now recover $email\'s account by setting a new password.';
  }

  @override
  String get warning => 'Warning';

  @override
  String get proceed => 'Proceed';

  @override
  String get done => 'Done';

  @override
  String get enterEmail => 'Enter email';

  @override
  String get verifyIDLabel => 'Verify';

  @override
  String get invalidEmailAddress => 'Invalid email address';

  @override
  String get enterValidEmail => 'Please enter a valid email address.';

  @override
  String get addANewEmail => 'Add a new email';

  @override
  String get orPickAnExistingOne => 'Or pick an existing one';

  @override
  String get shareTextRecommendUsingEnte =>
      'Download Ente so we can easily share original quality files\n\nhttps://ente.io';

  @override
  String get sendInvite => 'Send invite';

  @override
  String trustedInviteBody(Object email) {
    return 'You have been invited to be a legacy contact by $email.';
  }

  @override
  String verifyEmailID(Object email) {
    return 'Verify $email';
  }

  @override
  String get thisIsYourVerificationId => 'This is your Verification ID';

  @override
  String get someoneSharingAlbumsWithYouShouldSeeTheSameId =>
      'Someone sharing albums with you should see the same ID on their device.';

  @override
  String get howToViewShareeVerificationID =>
      'Please ask them to long-press their email address on the settings screen, and verify that the IDs on both devices match.';

  @override
  String thisIsPersonVerificationId(String email) {
    return 'This is $email\'s Verification ID';
  }

  @override
  String confirmAddingTrustedContact(String email, int numOfDays) {
    return 'You are about to add $email as a trusted contact. They will be able to recover your account if you are absent for $numOfDays days.';
  }

  @override
  String get youCannotShareWithYourself => 'You cannot share with yourself';

  @override
  String emailNoEnteAccount(Object email) {
    return '$email does not have an Ente account.\n\nSend them an invite to share files.';
  }

  @override
  String shareMyVerificationID(Object verificationID) {
    return 'Here\'s my verification ID: $verificationID for ente.io.';
  }

  @override
  String shareTextConfirmOthersVerificationID(Object verificationID) {
    return 'Hey, can you confirm that this is your ente.io verification ID: $verificationID';
  }

  @override
  String get inviteToEnte => 'Invite to Ente';

  @override
  String get lockerExistingUserRequired =>
      'Locker is available to existing Ente users. Sign up for Ente Photos or Auth to get started.';
}
