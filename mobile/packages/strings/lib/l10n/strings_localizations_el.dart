// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'strings_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Modern Greek (`el`).
class StringsLocalizationsEl extends StringsLocalizations {
  StringsLocalizationsEl([String locale = 'el']) : super(locale);

  @override
  String get networkHostLookUpErr =>
      'Δεν είναι δυνατή η σύνδεση με το Ente, ελέγξτε τις ρυθμίσεις του δικτύου σας και επικοινωνήστε με την υποστήριξη αν το σφάλμα παραμένει.';

  @override
  String get networkConnectionRefusedErr =>
      'Δεν είναι δυνατή η σύνδεση με το Ente, παρακαλώ προσπαθήστε ξανά μετά από λίγο. Εάν το σφάλμα παραμένει, παρακαλούμε επικοινωνήστε με την υποστήριξη.';

  @override
  String get itLooksLikeSomethingWentWrongPleaseRetryAfterSome =>
      'Φαίνεται ότι κάτι πήγε στραβά. Παρακαλώ προσπαθήστε ξανά μετά από λίγο. Αν το σφάλμα παραμένει, παρακαλούμε επικοινωνήστε με την ομάδα υποστήριξης μας.';

  @override
  String get error => 'Σφάλμα';

  @override
  String get ok => 'Οκ';

  @override
  String get faq => 'Συχνές Ερωτήσεις';

  @override
  String get contactSupport => 'Επικοινωνήστε με την υποστήριξη';

  @override
  String get emailYourLogs => 'Στείλτε με email τα αρχεία καταγραφής σας';

  @override
  String pleaseSendTheLogsTo(String toEmail) {
    return 'Παρακαλώ στείλτε τα αρχεία καταγραφής σας στο \n$toEmail';
  }

  @override
  String get copyEmailAddress => 'Αντιγραφή διεύθυνσης email';

  @override
  String get exportLogs => 'Εξαγωγή αρχείων καταγραφής';

  @override
  String get cancel => 'Ακύρωση';

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
  String get reportABug => 'Αναφορά Σφάλματος';

  @override
  String get logsDialogBody =>
      'This will send across logs to help us debug your issue. Please note that file names will be included to help track issues with specific files.';

  @override
  String get viewLogs => 'View logs';

  @override
  String customEndpoint(String endpoint) {
    return 'Συνδεδεμένο στο $endpoint';
  }

  @override
  String get save => 'Αποθήκευση';

  @override
  String get send => 'Αποστολή';

  @override
  String get saveOrSendDescription =>
      'Θέλετε να το αποθηκεύσετε στον αποθηκευτικό σας χώρο (φάκελος Λήψεις από προεπιλογή) ή να το στείλετε σε άλλες εφαρμογές;';

  @override
  String get saveOnlyDescription =>
      'Θέλετε να το αποθηκεύσετε στον αποθηκευτικό σας χώρο (φάκελος Λήψεις από προεπιλογή);';

  @override
  String get enterNewEmailHint => 'Enter your new email address';

  @override
  String get email => 'Email';

  @override
  String get verify => 'Επαλήθευση';

  @override
  String get invalidEmailTitle => 'Μη έγκυρη διεύθυνση email';

  @override
  String get invalidEmailMessage =>
      'Παρακαλούμε εισάγετε μια έγκυρη διεύθυνση email.';

  @override
  String get pleaseWait => 'Παρακαλώ περιμένετε…';

  @override
  String get verifyPassword => 'Επαλήθευση κωδικού πρόσβασης';

  @override
  String get incorrectPasswordTitle => 'Λάθος κωδικός πρόσβασης';

  @override
  String get pleaseTryAgain => 'Παρακαλώ δοκιμάστε ξανά';

  @override
  String get enterPassword => 'Εισάγετε κωδικό πρόσβασης';

  @override
  String get enterYourPasswordHint => 'Εισάγετε τον κωδικό πρόσβασης σας';

  @override
  String get activeSessions => 'Ενεργές συνεδρίες';

  @override
  String get oops => 'Ουπς';

  @override
  String get somethingWentWrongPleaseTryAgain =>
      'Κάτι πήγε στραβά, παρακαλώ προσπαθήστε ξανά';

  @override
  String get thisWillLogYouOutOfThisDevice =>
      'Αυτό θα σας αποσυνδέσει από αυτή τη συσκευή!';

  @override
  String get thisWillLogYouOutOfTheFollowingDevice =>
      'Αυτό θα σας αποσυνδέσει από την ακόλουθη συσκευή:';

  @override
  String get terminateSession => 'Τερματισμός συνεδρίας;';

  @override
  String get terminate => 'Τερματισμός';

  @override
  String get thisDevice => 'Αυτή η συσκευή';

  @override
  String get createAccount => 'Δημιουργία λογαριασμού';

  @override
  String get weakStrength => 'Αδύναμος';

  @override
  String get moderateStrength => 'Μέτριος';

  @override
  String get strongStrength => 'Δυνατός';

  @override
  String get deleteAccount => 'Διαγραφή λογαριασμού';

  @override
  String get deleteAccountQuery =>
      'Λυπόμαστε που σας βλέπουμε να φεύγετε. Αντιμετωπίζετε κάποιο πρόβλημα;';

  @override
  String get yesSendFeedbackAction => 'Ναι, αποστολή σχολίων';

  @override
  String get noDeleteAccountAction => 'Όχι, διαγραφή λογαριασμού';

  @override
  String get initiateAccountDeleteTitle =>
      'Παρακαλώ πραγματοποιήστε έλεγχο ταυτότητας για να ξεκινήσετε τη διαγραφή λογαριασμού';

  @override
  String get confirmAccountDeleteTitle => 'Επιβεβαίωση διαγραφής λογαριασμού';

  @override
  String get confirmAccountDeleteMessage =>
      'Αυτός ο λογαριασμός είναι συνδεδεμένος με άλλες εφαρμογές Ente, εάν χρησιμοποιείτε κάποια.\n\nΤα δεδομένα σας, σε όλες τις εφαρμογές Ente, θα προγραμματιστούν για διαγραφή και ο λογαριασμός σας θα διαγραφεί οριστικά.';

  @override
  String get delete => 'Διαγραφή';

  @override
  String get createNewAccount => 'Δημιουργία νέου λογαριασμού';

  @override
  String get password => 'Κωδικόs πρόσβασης';

  @override
  String get confirmPassword => 'Επιβεβαίωση κωδικού πρόσβασης';

  @override
  String passwordStrength(String passwordStrengthValue) {
    return 'Ισχύς κωδικού πρόσβασης: $passwordStrengthValue';
  }

  @override
  String get hearUsWhereTitle => 'Πώς ακούσατε για το Ente; (προαιρετικό)';

  @override
  String get hearUsExplanation =>
      'Δεν παρακολουθούμε εγκαταστάσεις εφαρμογών. Θα βοηθούσε αν μας είπατε πού μας βρήκατε!';

  @override
  String get signUpTerms =>
      'Συμφωνώ με τους <u-terms>όρους χρήσης</u-terms> και την <u-policy>πολιτική απορρήτου</u-policy>';

  @override
  String get termsOfServicesTitle => 'Όροι';

  @override
  String get privacyPolicyTitle => 'Πολιτική Απορρήτου';

  @override
  String get ackPasswordLostWarning =>
      'Καταλαβαίνω ότι αν χάσω τον κωδικό μου μπορεί να χάσω τα δεδομένα μου αφού τα δεδομένα μου είναι από <underline>άκρο-σε-άκρο κρυπτογραφημένα</underline>.';

  @override
  String get encryption => 'Kρυπτογράφηση';

  @override
  String get logInLabel => 'Σύνδεση';

  @override
  String get welcomeBack => 'Καλωσορίσατε και πάλι!';

  @override
  String get loginTerms =>
      'Κάνοντας κλικ στη σύνδεση, συμφωνώ με τους <u-terms>όρους χρήσης</u-terms> και την <u-policy>πολιτική απορρήτου</u-policy>';

  @override
  String get noInternetConnection => 'Χωρίς σύνδεση στο διαδίκτυο';

  @override
  String get pleaseCheckYourInternetConnectionAndTryAgain =>
      'Παρακαλούμε ελέγξτε τη σύνδεσή σας στο διαδίκτυο και προσπαθήστε ξανά.';

  @override
  String get verificationFailedPleaseTryAgain =>
      'Η επαλήθευση απέτυχε, παρακαλώ προσπαθήστε ξανά';

  @override
  String get recreatePasswordTitle => 'Επαναδημιουργία κωδικού πρόσβασης';

  @override
  String get recreatePasswordBody =>
      'Η τρέχουσα συσκευή δεν είναι αρκετά ισχυρή για να επαληθεύσει τον κωδικό πρόσβασής σας, αλλά μπορούμε να τον αναδημιουργήσουμε με έναν τρόπο που λειτουργεί με όλες τις συσκευές.\n\nΠαρακαλούμε συνδεθείτε χρησιμοποιώντας το κλειδί ανάκτησης και αναδημιουργήστε τον κωδικό πρόσβασής σας (μπορείτε να χρησιμοποιήσετε ξανά τον ίδιο αν το επιθυμείτε).';

  @override
  String get useRecoveryKey => 'Χρήση κλειδιού ανάκτησης';

  @override
  String get forgotPassword => 'Ξέχασα τον κωδικό πρόσβασης σας';

  @override
  String get changeEmail => 'Αλλαγή email';

  @override
  String get verifyEmail => 'Επαλήθευση email';

  @override
  String weHaveSendEmailTo(String email) {
    return 'Έχουμε στείλει ένα μήνυμα στο <green>$email</green>';
  }

  @override
  String get toResetVerifyEmail =>
      'Για να επαναφέρετε τον κωδικό πρόσβασής σας, επαληθεύστε πρώτα το email σας.';

  @override
  String get checkInboxAndSpamFolder =>
      'Παρακαλώ ελέγξτε τα εισερχόμενά σας (και τα ανεπιθύμητα) για να ολοκληρώσετε την επαλήθευση';

  @override
  String get tapToEnterCode => 'Πατήστε για να εισάγετε τον κωδικό';

  @override
  String get sendEmail => 'Αποστολή email';

  @override
  String get resendEmail => 'Επανάληψη αποστολής email';

  @override
  String get passKeyPendingVerification =>
      'Η επαλήθευση εξακολουθεί να εκκρεμεί';

  @override
  String get loginSessionExpired => 'Η συνεδρία έληξε';

  @override
  String get loginSessionExpiredDetails =>
      'Η συνεδρία σας έληξε. Παρακαλώ συνδεθείτε ξανά.';

  @override
  String get passkeyAuthTitle => 'Επιβεβαίωση κλειδιού πρόσβασης';

  @override
  String get waitingForVerification => 'Αναμονή για επαλήθευση...';

  @override
  String get tryAgain => 'Προσπαθήστε ξανά';

  @override
  String get checkStatus => 'Έλεγχος κατάστασης';

  @override
  String get loginWithTOTP => 'Είσοδος με TOTP';

  @override
  String get recoverAccount => 'Ανάκτηση λογαριασμού';

  @override
  String get setPasswordTitle => 'Ορισμός κωδικού πρόσβασης';

  @override
  String get changePasswordTitle => 'Αλλαγή κωδικού πρόσβασής';

  @override
  String get resetPasswordTitle => 'Επαναφορά κωδικού πρόσβασης';

  @override
  String get encryptionKeys => 'Κλειδιά κρυπτογράφησης';

  @override
  String get enterPasswordToEncrypt =>
      'Εισάγετε έναν κωδικό πρόσβασης που μπορούμε να χρησιμοποιήσουμε για την κρυπτογράφηση των δεδομένων σας';

  @override
  String get enterNewPasswordToEncrypt =>
      'Εισάγετε ένα νέο κωδικό πρόσβασης που μπορούμε να χρησιμοποιήσουμε για να κρυπτογραφήσουμε τα δεδομένα σας';

  @override
  String get passwordWarning =>
      'Δεν αποθηκεύουμε αυτόν τον κωδικό πρόσβασης, οπότε αν τον ξεχάσετε <underline>δεν μπορούμε να αποκρυπτογραφήσουμε τα δεδομένα σας</underline>';

  @override
  String get howItWorks => 'Πώς λειτουργεί';

  @override
  String get generatingEncryptionKeys =>
      'Δημιουργία κλειδιών κρυπτογράφησης...';

  @override
  String get passwordChangedSuccessfully =>
      'Ο κωδικός πρόσβασης άλλαξε επιτυχώς';

  @override
  String get signOutFromOtherDevices => 'Αποσύνδεση από άλλες συσκευές';

  @override
  String get signOutOtherBody =>
      'Αν νομίζετε ότι κάποιος μπορεί να γνωρίζει τον κωδικό πρόσβασής σας, μπορείτε να αναγκάσετε όλες τις άλλες συσκευές που χρησιμοποιούν το λογαριασμό σας να αποσυνδεθούν.';

  @override
  String get signOutOtherDevices => 'Αποσύνδεση άλλων συσκευών';

  @override
  String get doNotSignOut => 'Μην αποσυνδεθείτε';

  @override
  String get generatingEncryptionKeysTitle =>
      'Δημιουργία κλειδιών κρυπτογράφησης…';

  @override
  String get continueLabel => 'Συνέχεια';

  @override
  String get insecureDevice => 'Μη ασφαλής συσκευή';

  @override
  String get sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease =>
      'Συγγνώμη, δεν μπορέσαμε να δημιουργήσουμε ασφαλή κλειδιά σε αυτήν τη συσκευή.\n\nπαρακαλώ εγγραφείτε από μια διαφορετική συσκευή.';

  @override
  String get recoveryKeyCopiedToClipboard =>
      'Το κλειδί ανάκτησης αντιγράφηκε στο πρόχειρο';

  @override
  String get recoveryKey => 'Κλειδί ανάκτησης';

  @override
  String get recoveryKeyOnForgotPassword =>
      'Εάν ξεχάσετε τον κωδικό πρόσβασής σας, ο μόνος τρόπος για να ανακτήσετε τα δεδομένα σας είναι με αυτό το κλειδί.';

  @override
  String get recoveryKeySaveDescription =>
      'Δεν αποθηκεύουμε αυτό το κλειδί, παρακαλώ αποθηκεύστε αυτό το κλειδί 24 λέξεων σε μια ασφαλή τοποθεσία.';

  @override
  String get doThisLater => 'Κάντε το αργότερα';

  @override
  String get saveKey => 'Αποθήκευση κλειδιού';

  @override
  String get recoveryKeySaved =>
      'Το κλειδί ανάκτησης αποθηκεύτηκε στο φάκελο Λήψεις!';

  @override
  String get noRecoveryKeyTitle => 'Χωρίς κλειδί ανάκτησης;';

  @override
  String get twoFactorAuthTitle => 'Αυθεντικοποίηση δύο παραγόντων';

  @override
  String get enterCodeHint =>
      'Εισάγετε τον 6ψήφιο κωδικό από \nτην εφαρμογή αυθεντικοποίησης';

  @override
  String get lostDeviceTitle => 'Χαμένη συσκευή;';

  @override
  String get enterRecoveryKeyHint => 'Εισάγετε το κλειδί ανάκτησης σας';

  @override
  String get recover => 'Ανάκτηση';

  @override
  String get loggingOut => 'Αποσύνδεση…';

  @override
  String get immediately => 'Άμεσα';

  @override
  String get appLock => 'Κλείδωμα εφαρμογής';

  @override
  String get autoLock => 'Αυτόματο κλείδωμα';

  @override
  String get noSystemLockFound => 'Δεν βρέθηκε κλείδωμα συστήματος';

  @override
  String get deviceLockEnablePreSteps =>
      'Για να ενεργοποιήσετε το κλείδωμα της συσκευής, παρακαλώ ρυθμίστε τον κωδικό πρόσβασης της συσκευής ή το κλείδωμα οθόνης στις ρυθμίσεις του συστήματός σας.';

  @override
  String get appLockDescription =>
      'Επιλέξτε ανάμεσα στην προεπιλεγμένη οθόνη κλειδώματος της συσκευής σας και σε μια προσαρμοσμένη οθόνη κλειδώματος με ένα PIN ή έναν κωδικό πρόσβασης.';

  @override
  String get deviceLock => 'Κλείδωμα συσκευής';

  @override
  String get pinLock => 'Κλείδωμα καρφιτσωμάτων';

  @override
  String get autoLockFeatureDescription =>
      'Χρόνος μετά τον οποίο η εφαρμογή κλειδώνει μετά την τοποθέτηση στο παρασκήνιο';

  @override
  String get hideContent => 'Απόκρυψη περιεχομένου';

  @override
  String get hideContentDescriptionAndroid =>
      'Απόκρυψη περιεχομένου εφαρμογής στην εναλλαγή εφαρμογών και απενεργοποίηση στιγμιότυπων οθόνης';

  @override
  String get hideContentDescriptioniOS =>
      'Απόκρυψη περιεχομένου εφαρμογών στην εναλλαγή εφαρμογών';

  @override
  String get tooManyIncorrectAttempts => 'Πάρα πολλές εσφαλμένες προσπάθειες';

  @override
  String get tapToUnlock => 'Πατήστε για ξεκλείδωμα';

  @override
  String get areYouSureYouWantToLogout =>
      'Είστε σίγουροι ότι θέλετε να αποσυνδεθείτε;';

  @override
  String get yesLogout => 'Ναι, αποσύνδεση';

  @override
  String get authToViewSecrets =>
      'Παρακαλώ πραγματοποιήστε έλεγχο ταυτότητας για να δείτε τα μυστικά σας';

  @override
  String get next => 'Επόμενο';

  @override
  String get setNewPassword => 'Ορίστε νέο κωδικό πρόσβασης';

  @override
  String get enterPin => 'Εισαγωγή PIN';

  @override
  String get setNewPin => 'Ορίστε νέο PIN';

  @override
  String get confirm => 'Επιβεβαίωση';

  @override
  String get reEnterPassword => 'Πληκτρολογήστε ξανά τον κωδικό πρόσβασης';

  @override
  String get reEnterPin => 'Πληκτρολογήστε ξανά το PIN';

  @override
  String get androidBiometricHint => 'Επαλήθευση ταυτότητας';

  @override
  String get androidBiometricNotRecognized =>
      'Δεν αναγνωρίζεται. Δοκιμάστε ξανά.';

  @override
  String get androidBiometricSuccess => 'Επιτυχία';

  @override
  String get androidCancelButton => 'Ακύρωση';

  @override
  String get androidSignInTitle => 'Απαιτείται έλεγχος ταυτότητας';

  @override
  String get androidBiometricRequiredTitle => 'Απαιτούνται βιομετρικά';

  @override
  String get androidDeviceCredentialsRequiredTitle =>
      'Απαιτούνται στοιχεία συσκευής';

  @override
  String get androidDeviceCredentialsSetupDescription =>
      'Απαιτούνται στοιχεία συσκευής';

  @override
  String get goToSettings => 'Μετάβαση στις ρυθμίσεις';

  @override
  String get androidGoToSettingsDescription =>
      'Η βιομετρική πιστοποίηση δεν έχει ρυθμιστεί στη συσκευή σας. Μεταβείτε στις \'Ρυθμίσεις > Ασφάλεια\' για να προσθέσετε βιομετρική ταυτοποίηση.';

  @override
  String get iOSLockOut =>
      'Η βιομετρική ταυτοποίηση είναι απενεργοποιημένη. Παρακαλώ κλειδώστε και ξεκλειδώστε την οθόνη σας για να την ενεργοποιήσετε.';

  @override
  String get iOSOkButton => 'ΟΚ';

  @override
  String get emailAlreadyRegistered => 'Email already registered.';

  @override
  String get emailNotRegistered => 'Email not registered.';

  @override
  String get thisEmailIsAlreadyInUse => 'Αυτό το email είναι ήδη σε χρήση';

  @override
  String emailChangedTo(String newEmail) {
    return 'Το email άλλαξε σε $newEmail';
  }

  @override
  String get authenticationFailedPleaseTryAgain =>
      'Αποτυχία ελέγχου ταυτότητας, παρακαλώ προσπαθήστε ξανά';

  @override
  String get authenticationSuccessful => 'Επιτυχής έλεγχος ταυτότητας!';

  @override
  String get sessionExpired => 'Η συνεδρία έληξε';

  @override
  String get incorrectRecoveryKey => 'Εσφαλμένο κλειδί ανάκτησης';

  @override
  String get theRecoveryKeyYouEnteredIsIncorrect =>
      'Το κλειδί ανάκτησης που εισάγατε είναι εσφαλμένο';

  @override
  String get twofactorAuthenticationSuccessfullyReset =>
      'Η αυθεντικοποίηση δύο παραγόντων επαναφέρθηκε επιτυχώς';

  @override
  String get noRecoveryKey => 'No recovery key';

  @override
  String get yourAccountHasBeenDeleted => 'Your account has been deleted';

  @override
  String get verificationId => 'Verification ID';

  @override
  String get yourVerificationCodeHasExpired =>
      'Ο κωδικός επαλήθευσης σας έχει λήξει';

  @override
  String get incorrectCode => 'Εσφαλμένος κωδικός';

  @override
  String get sorryTheCodeYouveEnteredIsIncorrect =>
      'Λυπούμαστε, ο κωδικός που εισαγάγατε είναι εσφαλμένος';

  @override
  String get developerSettings => 'Ρυθμίσεις προγραμματιστή';

  @override
  String get serverEndpoint => 'Τερματικό σημείο διακομιστή';

  @override
  String get invalidEndpoint => 'Μη έγκυρο τερματικό σημείο';

  @override
  String get invalidEndpointMessage =>
      'Λυπούμαστε, το τερματικό σημείο που εισάγατε δεν είναι έγκυρο. Παρακαλώ εισάγετε ένα έγκυρο τερματικό σημείο και προσπαθήστε ξανά.';

  @override
  String get endpointUpdatedMessage =>
      'Το τερματκό σημείο ενημερώθηκε επιτυχώς';
}
