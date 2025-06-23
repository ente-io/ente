// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a he locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'he';

  static String m8(count) =>
      "${Intl.plural(count, zero: 'אין משתתפים', one: '1 משתתף', two: '2 משתתפים', other: '${count} משתתפים')}";

  static String m12(paymentProvider) =>
      "אנא בטל את המנוי הקיים מ-${paymentProvider} קודם";

  static String m13(user) =>
      "${user} לא יוכל להוסיף עוד תמונות לאלבום זה\n\nהם עדיין יכולו להסיר תמונות קיימות שנוספו על ידיהם";

  static String m14(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true': 'קיבלת ${storageAmountInGb} GB עד כה',
            'false': 'קיבלת ${storageAmountInGb} GB עד כה',
            'other': 'קיבלת ${storageAmountInGb} GB עד כה!',
          })}";

  static String m18(familyAdminEmail) =>
      "אנא צור קשר עם <green>${familyAdminEmail}</green> על מנת לנהל את המנוי שלך";

  static String m19(provider) =>
      "אנא צור איתנו קשר ב-support@ente.io על מנת לנהל את המנוי ${provider}.";

  static String m21(count) =>
      "${Intl.plural(count, one: 'מחק ${count} פריט', other: 'מחק ${count} פריטים')}";

  static String m23(currentlyDeleting, totalCount) =>
      "מוחק ${currentlyDeleting} / ${totalCount}";

  static String m24(albumName) =>
      "זה יסיר את הלינק הפומבי שדרכו ניתן לגשת ל\"${albumName}\".";

  static String m25(supportEmail) =>
      "אנא תשלח דוא\"ל ל${supportEmail} מהכתובת דוא\"ל שנרשמת איתה";

  static String m27(count, formattedSize) =>
      "${count} קבצים, כל אחד ${formattedSize}";

  static String m31(email) =>
      "לא נמצא חשבון ente ל-${email}.\n\nשלח להם הזמנה על מנת לשתף תמונות.";

  static String m37(storageAmountInGB) =>
      "${storageAmountInGB} GB כל פעם שמישהו נרשם עבור תוכנית בתשלום ומחיל את הקוד שלך";

  static String m38(endDate) => "ניסיון חינם בתוקף עד ל-${endDate}";

  static String m44(count) =>
      "${Intl.plural(count, one: '${count} פריט', other: '${count} פריטים')}";

  static String m47(expiryTime) => "תוקף הקישור יפוג ב-${expiryTime}";

  static String m57(passwordStrengthValue) =>
      "חוזק הסיסמא: ${passwordStrengthValue}";

  static String m58(providerName) =>
      "אנא דבר עם התמיכה של ${providerName} אם אתה חוייבת";

  static String m68(storeName) => "דרג אותנו ב-${storeName}";

  static String m73(storageInGB) => "3. שניכים מקבלים ${storageInGB} GB* בחינם";

  static String m74(userEmail) =>
      "${userEmail} יוסר מהאלבום המשותף הזה\n\nגם תמונות שנוספו על ידיהם יוסרו מהאלבום";

  static String m80(count) => "${count} נבחרו";

  static String m81(count, yourCount) => "${count} נבחרו (${yourCount} שלך)";

  static String m83(verificationID) =>
      "הנה מזהה האימות שלי: ${verificationID} עבור ente.io.";

  static String m84(verificationID) =>
      "היי, תוכל לוודא שזה מזהה האימות שלך של ente.io: ${verificationID}";

  static String m86(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'שתף עם אנשים ספציפיים', one: 'שותף עם איש 1', two: 'שותף עם 2 אנשים', other: 'שותף עם ${numberOfPeople} אנשים')}";

  static String m87(emailIDs) => "הושתף ע\"י ${emailIDs}";

  static String m88(fileType) => "${fileType} יימחק מהמכשיר שלך.";

  static String m93(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m96(endDate) => "המנוי שלך יבוטל ב-${endDate}";

  static String m97(completed, total) => "${completed}/${total} זכרונות נשמרו";

  static String m99(storageAmountInGB) => "הם גם יקבלו ${storageAmountInGB} GB";

  static String m100(email) => "זה מזהה האימות של ${email}";

  static String m111(email) => "אמת ${email}";

  static String m114(email) => "שלחנו דוא\"ל ל<green>${email}</green>";

  static String m115(name) => "Wish \$${name} a happy birthday! 🎉";

  static String m116(count) =>
      "${Intl.plural(count, one: 'לפני ${count} שנה', other: 'לפני ${count} שנים')}";

  static String m118(storageSaved) => "הצלחת לפנות ${storageSaved}!";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "about": MessageLookupByLibrary.simpleMessage("אודות"),
        "account": MessageLookupByLibrary.simpleMessage("חשבון"),
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("ברוך שובך!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "אני מבין שאם אאבד את הסיסמא, אני עלול לאבד את המידע שלי מכיוון שהמידע שלי <underline>מוצפן מקצה אל קצה</underline>."),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("חיבורים פעילים"),
        "addANewEmail": MessageLookupByLibrary.simpleMessage("הוסף דוא\"ל חדש"),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("הוסף משתף פעולה"),
        "addLocationButton": MessageLookupByLibrary.simpleMessage("הוסף"),
        "addMore": MessageLookupByLibrary.simpleMessage("הוסף עוד"),
        "addPhotos": MessageLookupByLibrary.simpleMessage("הוסף תמונות"),
        "addToAlbum": MessageLookupByLibrary.simpleMessage("הוסף לאלבום"),
        "addViewer": MessageLookupByLibrary.simpleMessage("הוסף צופה"),
        "addedAs": MessageLookupByLibrary.simpleMessage("הוסף בתור"),
        "addingToFavorites":
            MessageLookupByLibrary.simpleMessage("מוסיף למועדפים..."),
        "advanced": MessageLookupByLibrary.simpleMessage("מתקדם"),
        "advancedSettings": MessageLookupByLibrary.simpleMessage("מתקדם"),
        "after1Day": MessageLookupByLibrary.simpleMessage("אחרי יום 1"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("אחרי שעה 1"),
        "after1Month": MessageLookupByLibrary.simpleMessage("אחרי חודש 1"),
        "after1Week": MessageLookupByLibrary.simpleMessage("אחרי שבוע 1"),
        "after1Year": MessageLookupByLibrary.simpleMessage("אחרי שנה 1"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("בעלים"),
        "albumParticipantsCount": m8,
        "albumTitle": MessageLookupByLibrary.simpleMessage("כותרת האלבום"),
        "albumUpdated": MessageLookupByLibrary.simpleMessage("האלבום עודכן"),
        "albums": MessageLookupByLibrary.simpleMessage("אלבומים"),
        "allClear": MessageLookupByLibrary.simpleMessage("✨ הכל נוקה"),
        "allMemoriesPreserved":
            MessageLookupByLibrary.simpleMessage("כל הזכרונות נשמרו"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "בנוסף אפשר לאנשים עם הלינק להוסיף תמונות לאלבום המשותף."),
        "allowAddingPhotos":
            MessageLookupByLibrary.simpleMessage("אפשר הוספת תמונות"),
        "allowDownloads": MessageLookupByLibrary.simpleMessage("אפשר הורדות"),
        "allowPeopleToAddPhotos":
            MessageLookupByLibrary.simpleMessage("תן לאנשים להוסיף תמונות"),
        "androidBiometricSuccess":
            MessageLookupByLibrary.simpleMessage("הצלחה"),
        "androidCancelButton": MessageLookupByLibrary.simpleMessage("בטל"),
        "androidIosWebDesktop": MessageLookupByLibrary.simpleMessage(
            "Android, iOS, דפדפן, שולחן עבודה"),
        "appleId": MessageLookupByLibrary.simpleMessage("Apple ID"),
        "apply": MessageLookupByLibrary.simpleMessage("החל"),
        "applyCodeTitle": MessageLookupByLibrary.simpleMessage("החל קוד"),
        "appstoreSubscription":
            MessageLookupByLibrary.simpleMessage("מנוי AppStore"),
        "archive": MessageLookupByLibrary.simpleMessage("שמירה בארכיון"),
        "areYouSureThatYouWantToLeaveTheFamily":
            MessageLookupByLibrary.simpleMessage(
                "אתה בטוח שאתה רוצה לעזוב את התוכנית המשפתחית?"),
        "areYouSureYouWantToCancel":
            MessageLookupByLibrary.simpleMessage("אתה בטוח שאתה רוצה לבטל?"),
        "areYouSureYouWantToChangeYourPlan":
            MessageLookupByLibrary.simpleMessage(
                "אתה בטוח שאתה רוצה לשנות את התוכנית שלך?"),
        "areYouSureYouWantToExit":
            MessageLookupByLibrary.simpleMessage("האם אתה בטוח שברצונך לצאת?"),
        "areYouSureYouWantToLogout":
            MessageLookupByLibrary.simpleMessage("אתה בטוח שאתה רוצה להתנתק?"),
        "areYouSureYouWantToRenew":
            MessageLookupByLibrary.simpleMessage("אתה בטוח שאתה רוצה לחדש?"),
        "askCancelReason": MessageLookupByLibrary.simpleMessage(
            "המנוי שלך בוטל. תרצה לשתף את הסיבה?"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "מה הסיבה העיקרית שבגללה אתה מוחק את החשבון שלך?"),
        "atAFalloutShelter":
            MessageLookupByLibrary.simpleMessage("במקלט גרעיני"),
        "authToChangeEmailVerificationSetting":
            MessageLookupByLibrary.simpleMessage(
                "אנא התאמת על מנת לשנות את הדוא\"ל שלך"),
        "authToChangeLockscreenSetting": MessageLookupByLibrary.simpleMessage(
            "אנא התאמת כדי לשנות את הגדרות מסך הנעילה"),
        "authToChangeYourEmail": MessageLookupByLibrary.simpleMessage(
            "אנא אנא התאמת על מנת לשנות את הדוא\"ל שלך"),
        "authToChangeYourPassword": MessageLookupByLibrary.simpleMessage(
            "אנא התאמת על מנת לשנות את הסיסמא שלך"),
        "authToConfigureTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "אנא התאמת כדי להגדיר את האימות הדו-גורמי"),
        "authToInitiateAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "אנא התאמת על מנת להתחיל את מחיקת החשבון שלך"),
        "authToViewYourActiveSessions": MessageLookupByLibrary.simpleMessage(
            "אנא התאמת על מנת לראות את החיבורים הפעילים שלך"),
        "authToViewYourHiddenFiles": MessageLookupByLibrary.simpleMessage(
            "אנא התאמת על מנת לראות את הקבצים החבויים שלך"),
        "authToViewYourMemories": MessageLookupByLibrary.simpleMessage(
            "אנא אמת על מנת לצפות בזכרונות שלך"),
        "authToViewYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "אנא התאמת על מנת לראות את מפתח השחזור שלך"),
        "available": MessageLookupByLibrary.simpleMessage("זמין"),
        "backedUpFolders": MessageLookupByLibrary.simpleMessage("תיקיות שגובו"),
        "backup": MessageLookupByLibrary.simpleMessage("גיבוי"),
        "backupFailed": MessageLookupByLibrary.simpleMessage("הגיבוי נכשל"),
        "backupOverMobileData":
            MessageLookupByLibrary.simpleMessage("גבה על רשת סלולרית"),
        "backupSettings": MessageLookupByLibrary.simpleMessage("הגדרות גיבוי"),
        "backupVideos": MessageLookupByLibrary.simpleMessage("גבה סרטונים"),
        "blog": MessageLookupByLibrary.simpleMessage("בלוג"),
        "cachedData": MessageLookupByLibrary.simpleMessage("נתונים מוטמנים"),
        "canNotUploadToAlbumsOwnedByOthers":
            MessageLookupByLibrary.simpleMessage(
                "לא ניתן להעלות לאלבומים שבבעלות אחרים"),
        "canOnlyCreateLinkForFilesOwnedByYou":
            MessageLookupByLibrary.simpleMessage(
                "ניתן אך ורק ליצור קישור לקבצים שאתה בבעולתם"),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
            "יכול להסיר רק קבצים שבבעלותך"),
        "cancel": MessageLookupByLibrary.simpleMessage("בטל"),
        "cancelOtherSubscription": m12,
        "cancelSubscription": MessageLookupByLibrary.simpleMessage("בטל מנוי"),
        "cannotAddMorePhotosAfterBecomingViewer": m13,
        "cannotDeleteSharedFiles": MessageLookupByLibrary.simpleMessage(
            "לא ניתן למחוק את הקבצים המשותפים"),
        "changeEmail": MessageLookupByLibrary.simpleMessage("שנה דוא\"ל"),
        "changePassword": MessageLookupByLibrary.simpleMessage("שנה סיסמה"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("שנה סיסמה"),
        "changePermissions": MessageLookupByLibrary.simpleMessage("שנה הרשאה?"),
        "checkForUpdates": MessageLookupByLibrary.simpleMessage("בדוק עדכונים"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "אנא בדוק את תיבת הדואר שלך (והספאם) כדי להשלים את האימות"),
        "checking": MessageLookupByLibrary.simpleMessage("בודק..."),
        "claimFreeStorage":
            MessageLookupByLibrary.simpleMessage("תבע מקום אחסון בחינם"),
        "claimMore": MessageLookupByLibrary.simpleMessage("תבע עוד!"),
        "claimed": MessageLookupByLibrary.simpleMessage("נתבע"),
        "claimedStorageSoFar": m14,
        "click": MessageLookupByLibrary.simpleMessage("• לחץ"),
        "close": MessageLookupByLibrary.simpleMessage("סגור"),
        "clubByCaptureTime":
            MessageLookupByLibrary.simpleMessage("קבץ לפי זמן הצילום"),
        "clubByFileName":
            MessageLookupByLibrary.simpleMessage("קבץ לפי שם הקובץ"),
        "codeAppliedPageTitle":
            MessageLookupByLibrary.simpleMessage("הקוד הוחל"),
        "codeCopiedToClipboard":
            MessageLookupByLibrary.simpleMessage("הקוד הועתק ללוח"),
        "codeUsedByYou":
            MessageLookupByLibrary.simpleMessage("הקוד שומש על ידיך"),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
            "צור קישור על מנת לאפשר לאנשים להוסיף ולצפות בתמונות באלבום ששיתפת בלי צורך באפליקציית ente או חשבון. נהדר לאיסוף תמונות של אירועים."),
        "collaborativeLink":
            MessageLookupByLibrary.simpleMessage("קישור לשיתוף פעולה"),
        "collaborator": MessageLookupByLibrary.simpleMessage("משתף פעולה"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "משתפי פעולה יכולים להוסיף תמונות וסרטונים לאלבום המשותף."),
        "collageLayout": MessageLookupByLibrary.simpleMessage("פריסה"),
        "collageSaved":
            MessageLookupByLibrary.simpleMessage("הקולז נשמר לגלריה"),
        "collectEventPhotos":
            MessageLookupByLibrary.simpleMessage("אסף תמונות מאירוע"),
        "collectPhotos": MessageLookupByLibrary.simpleMessage("אסוף תמונות"),
        "color": MessageLookupByLibrary.simpleMessage("צבע"),
        "confirm": MessageLookupByLibrary.simpleMessage("אשר"),
        "confirm2FADisable": MessageLookupByLibrary.simpleMessage(
            "האם אתה בטוח שאתה רוצה להשבית את האימות הדו-גורמי?"),
        "confirmAccountDeletion":
            MessageLookupByLibrary.simpleMessage("אשר את מחיקת החשבון"),
        "confirmPassword": MessageLookupByLibrary.simpleMessage("אמת סיסמא"),
        "confirmPlanChange":
            MessageLookupByLibrary.simpleMessage("אשר שינוי תוכנית"),
        "confirmRecoveryKey":
            MessageLookupByLibrary.simpleMessage("אמת את מפתח השחזור"),
        "confirmYourRecoveryKey":
            MessageLookupByLibrary.simpleMessage("אמת את מפתח השחזור"),
        "contactFamilyAdmin": m18,
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("צור קשר עם התמיכה"),
        "contactToManageSubscription": m19,
        "continueLabel": MessageLookupByLibrary.simpleMessage("המשך"),
        "continueOnFreeTrial":
            MessageLookupByLibrary.simpleMessage("המשך עם ניסיון חינמי"),
        "copyLink": MessageLookupByLibrary.simpleMessage("העתק קישור"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "תעתיק ותדביק את הקוד הזה\nלאפליקציית האימות שלך"),
        "couldNotBackUpTryLater": MessageLookupByLibrary.simpleMessage(
            "לא יכולנו לגבות את המידע שלך.\nאנא נסה שוב מאוחר יותר."),
        "couldNotUpdateSubscription":
            MessageLookupByLibrary.simpleMessage("לא ניתן לעדכן את המנוי"),
        "count": MessageLookupByLibrary.simpleMessage("כמות"),
        "create": MessageLookupByLibrary.simpleMessage("צור"),
        "createAccount": MessageLookupByLibrary.simpleMessage("צור חשבון"),
        "createAlbumActionHint": MessageLookupByLibrary.simpleMessage(
            "לחץ לחיצה ארוכה על מנת לבחור תמונות ולחץ על + על מנת ליצור אלבום"),
        "createCollage": MessageLookupByLibrary.simpleMessage("צור קולז"),
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("צור חשבון חדש"),
        "createOrSelectAlbum":
            MessageLookupByLibrary.simpleMessage("צור או בחר אלבום"),
        "createPublicLink":
            MessageLookupByLibrary.simpleMessage("צור קישור ציבורי"),
        "creatingLink": MessageLookupByLibrary.simpleMessage("יוצר קישור..."),
        "criticalUpdateAvailable":
            MessageLookupByLibrary.simpleMessage("עדכון חשוב זמין"),
        "currentUsageIs": MessageLookupByLibrary.simpleMessage(
            "השימוש במקום האחסון כרגע הוא "),
        "custom": MessageLookupByLibrary.simpleMessage("מותאם אישית"),
        "darkTheme": MessageLookupByLibrary.simpleMessage("כהה"),
        "dayToday": MessageLookupByLibrary.simpleMessage("היום"),
        "dayYesterday": MessageLookupByLibrary.simpleMessage("אתמול"),
        "decrypting": MessageLookupByLibrary.simpleMessage("מפענח..."),
        "decryptingVideo":
            MessageLookupByLibrary.simpleMessage("מפענח את הסרטון..."),
        "deduplicateFiles":
            MessageLookupByLibrary.simpleMessage("הסר קבצים כפולים"),
        "delete": MessageLookupByLibrary.simpleMessage("מחק"),
        "deleteAccount": MessageLookupByLibrary.simpleMessage("מחק חשבון"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "אנחנו מצטערים לראות שאתה עוזב. אנא תחלוק את המשוב שלך כדי לעזור לנו להשתפר."),
        "deleteAccountPermanentlyButton":
            MessageLookupByLibrary.simpleMessage("מחק את החשבון לצמיתות"),
        "deleteAlbum": MessageLookupByLibrary.simpleMessage("מחק אלבום"),
        "deleteAlbumDialog": MessageLookupByLibrary.simpleMessage(
            "גם להסיר תמונות (וסרטונים) שנמצאים באלבום הזה מ<bold>כל</bold> שאר האלבומים שהם שייכים אליהם?"),
        "deleteAlbumsDialogBody": MessageLookupByLibrary.simpleMessage(
            "זה ימחק את כל האלבומים הריקים. זה שימושי כשאתה רוצה להפחית את כמות האי סדר ברשימת האלבומים שלך."),
        "deleteAll": MessageLookupByLibrary.simpleMessage("מחק הכל"),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "אנא תשלח דוא\"ל ל<warning>account-deletion@ente.io</warning> מהכתובת דוא\"ל שנרשמת איתה."),
        "deleteEmptyAlbums":
            MessageLookupByLibrary.simpleMessage("למחוק אלבומים ריקים"),
        "deleteEmptyAlbumsWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("למחוק אלבומים ריקים?"),
        "deleteFromBoth": MessageLookupByLibrary.simpleMessage("מחק משניהם"),
        "deleteFromDevice": MessageLookupByLibrary.simpleMessage("מחק מהמכשיר"),
        "deleteItemCount": m21,
        "deletePhotos": MessageLookupByLibrary.simpleMessage("מחק תמונות"),
        "deleteProgress": m23,
        "deleteReason1":
            MessageLookupByLibrary.simpleMessage("חסר מאפיין מרכזי שאני צריך"),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
            "היישומון או מאפיין מסוים לא מתנהג כמו שאני חושב שהוא צריך"),
        "deleteReason3": MessageLookupByLibrary.simpleMessage(
            "מצאתי שירות אחר שאני יותר מחבב"),
        "deleteReason4":
            MessageLookupByLibrary.simpleMessage("הסיבה שלי לא כלולה"),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
            "הבקשה שלך תועבד תוך 72 שעות."),
        "deleteSharedAlbum":
            MessageLookupByLibrary.simpleMessage("מחק את האלבום המשותף?"),
        "deleteSharedAlbumDialogBody": MessageLookupByLibrary.simpleMessage(
            "האלבום הזה יימחק עבור כולם\n\nאתה תאבד גישה לתמונות משותפות באלבום הזה שבבעלות של אחרים"),
        "deselectAll": MessageLookupByLibrary.simpleMessage("בטל בחירה של הכל"),
        "designedToOutlive":
            MessageLookupByLibrary.simpleMessage("עוצב על מנת לשרוד"),
        "details": MessageLookupByLibrary.simpleMessage("פרטים"),
        "disableAutoLock":
            MessageLookupByLibrary.simpleMessage("השבת נעילה אוטומטית"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "צופים יכולים עדיין לקחת צילומי מסך או לשמור עותק של התמונות שלך בעזרת כלים חיצוניים"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("שים לב"),
        "disableLinkMessage": m24,
        "disableTwofactor":
            MessageLookupByLibrary.simpleMessage("השבת דו-גורמי"),
        "discord": MessageLookupByLibrary.simpleMessage("Discord"),
        "dismiss": MessageLookupByLibrary.simpleMessage("התעלם"),
        "distanceInKMUnit": MessageLookupByLibrary.simpleMessage("ק\"מ"),
        "doThisLater": MessageLookupByLibrary.simpleMessage("מאוחר יותר"),
        "done": MessageLookupByLibrary.simpleMessage("בוצע"),
        "download": MessageLookupByLibrary.simpleMessage("הורד"),
        "downloadFailed": MessageLookupByLibrary.simpleMessage("ההורדה נכשלה"),
        "downloading": MessageLookupByLibrary.simpleMessage("מוריד..."),
        "dropSupportEmail": m25,
        "duplicateItemsGroup": m27,
        "edit": MessageLookupByLibrary.simpleMessage("ערוך"),
        "eligible": MessageLookupByLibrary.simpleMessage("זכאי"),
        "email": MessageLookupByLibrary.simpleMessage("דוא\"ל"),
        "emailNoEnteAccount": m31,
        "emailVerificationToggle":
            MessageLookupByLibrary.simpleMessage("אימות מייל"),
        "empty": MessageLookupByLibrary.simpleMessage("ריק"),
        "encryption": MessageLookupByLibrary.simpleMessage("הצפנה"),
        "encryptionKeys": MessageLookupByLibrary.simpleMessage("מפתחות ההצפנה"),
        "endtoendEncryptedByDefault": MessageLookupByLibrary.simpleMessage(
            "מוצפן מקצה אל קצה כברירת מחדל"),
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
            "Ente <i>צריך הרשאות על מנת </i> לשמור את התמונות שלך"),
        "enteSubscriptionShareWithFamily": MessageLookupByLibrary.simpleMessage(
            "אפשר להוסיף גם את המשפחה שלך לתוכנית."),
        "enterAlbumName": MessageLookupByLibrary.simpleMessage("הזן שם אלבום"),
        "enterCode": MessageLookupByLibrary.simpleMessage("הזן קוד"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
            "הכנס את הקוד שנמסר לך מחברך בשביל לקבל מקום אחסון בחינם עבורך ועבורו"),
        "enterEmail": MessageLookupByLibrary.simpleMessage("הזן דוא\"ל"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "הזן סיסמא חדשה שנוכל להשתמש בה כדי להצפין את המידע שלך"),
        "enterPassword": MessageLookupByLibrary.simpleMessage("הזן את הסיסמה"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "הזן סיסמא כדי שנוכל לפענח את המידע שלך"),
        "enterReferralCode":
            MessageLookupByLibrary.simpleMessage("הזן קוד הפניה"),
        "enterThe6digitCodeFromnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "הכנס את הקוד בעל 6 ספרות מתוך\nאפליקציית האימות שלך"),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
            "אנא הכנס כתובת דוא\"ל חוקית."),
        "enterYourEmailAddress":
            MessageLookupByLibrary.simpleMessage("הכנס את כתובת הדוא״ל שלך"),
        "enterYourPassword": MessageLookupByLibrary.simpleMessage("הכנס סיסמא"),
        "enterYourRecoveryKey":
            MessageLookupByLibrary.simpleMessage("הזן את מפתח השחזור שלך"),
        "error": MessageLookupByLibrary.simpleMessage("שגיאה"),
        "everywhere": MessageLookupByLibrary.simpleMessage("בכל מקום"),
        "exif": MessageLookupByLibrary.simpleMessage("EXIF"),
        "existingUser": MessageLookupByLibrary.simpleMessage("משתמש קיים"),
        "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
            "פג תוקף הקישור. אנא בחר בתאריך תפוגה חדש או השבת את תאריך התפוגה של הקישור."),
        "exportLogs": MessageLookupByLibrary.simpleMessage("ייצוא לוגים"),
        "exportYourData":
            MessageLookupByLibrary.simpleMessage("ייצוא הנתונים שלך"),
        "failedToApplyCode":
            MessageLookupByLibrary.simpleMessage("נכשל בהחלת הקוד"),
        "failedToCancel": MessageLookupByLibrary.simpleMessage("הביטול נכשל"),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
            "אחזור פרטי ההפניה נכשל. אנא נסה שוב מאוחר יותר."),
        "failedToLoadAlbums":
            MessageLookupByLibrary.simpleMessage("נכשל בטעינת האלבומים"),
        "failedToRenew": MessageLookupByLibrary.simpleMessage("החידוש נכשל"),
        "failedToVerifyPaymentStatus":
            MessageLookupByLibrary.simpleMessage("נכשל באימות סטטוס התשלום"),
        "familyPlanPortalTitle": MessageLookupByLibrary.simpleMessage("משפחה"),
        "familyPlans": MessageLookupByLibrary.simpleMessage("תוכניות משפחה"),
        "faq": MessageLookupByLibrary.simpleMessage("שאלות נפוצות"),
        "faqs": MessageLookupByLibrary.simpleMessage("שאלות נפוצות"),
        "favorite": MessageLookupByLibrary.simpleMessage("מועדף"),
        "feedback": MessageLookupByLibrary.simpleMessage("משוב"),
        "fileFailedToSaveToGallery":
            MessageLookupByLibrary.simpleMessage("נכשל בעת שמירת הקובץ לגלריה"),
        "fileSavedToGallery":
            MessageLookupByLibrary.simpleMessage("הקובץ נשמר לגלריה"),
        "flip": MessageLookupByLibrary.simpleMessage("הפוך"),
        "forYourMemories":
            MessageLookupByLibrary.simpleMessage("עבור הזכורונות שלך"),
        "forgotPassword": MessageLookupByLibrary.simpleMessage("שכחתי סיסמה"),
        "freeStorageClaimed":
            MessageLookupByLibrary.simpleMessage("מקום אחסון בחינם נתבע"),
        "freeStorageOnReferralSuccess": m37,
        "freeStorageUsable":
            MessageLookupByLibrary.simpleMessage("מקום אחסון שמיש"),
        "freeTrial": MessageLookupByLibrary.simpleMessage("ניסיון חינמי"),
        "freeTrialValidTill": m38,
        "freeUpDeviceSpace":
            MessageLookupByLibrary.simpleMessage("פנה אחסון במכשיר"),
        "freeUpSpace": MessageLookupByLibrary.simpleMessage("פנה מקום"),
        "general": MessageLookupByLibrary.simpleMessage("כללי"),
        "generatingEncryptionKeys":
            MessageLookupByLibrary.simpleMessage("יוצר מפתחות הצפנה..."),
        "googlePlayId": MessageLookupByLibrary.simpleMessage("Google Play ID"),
        "grantFullAccessPrompt": MessageLookupByLibrary.simpleMessage(
            "נא לתת גישה לכל התמונות בתוך ההגדרות של הטלפון"),
        "grantPermission": MessageLookupByLibrary.simpleMessage("הענק הרשאה"),
        "hidden": MessageLookupByLibrary.simpleMessage("מוסתר"),
        "hide": MessageLookupByLibrary.simpleMessage("הסתר"),
        "hiding": MessageLookupByLibrary.simpleMessage("מחביא..."),
        "howItWorks": MessageLookupByLibrary.simpleMessage("איך זה עובד"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
            "אנא בקש מהם ללחוץ לחיצה ארוכה על הכתובת אימייל שלהם בעמוד ההגדרות, וודא שהמזההים בשני המכשירים תואמים."),
        "iOSOkButton": MessageLookupByLibrary.simpleMessage("אישור"),
        "ignoreUpdate": MessageLookupByLibrary.simpleMessage("התעלם"),
        "importing": MessageLookupByLibrary.simpleMessage("מייבא...."),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("סיסמא לא נכונה"),
        "incorrectRecoveryKeyBody":
            MessageLookupByLibrary.simpleMessage("המפתח שחזור שהזנת שגוי"),
        "incorrectRecoveryKeyTitle":
            MessageLookupByLibrary.simpleMessage("מפתח שחזור שגוי"),
        "insecureDevice":
            MessageLookupByLibrary.simpleMessage("מכשיר בלתי מאובטח"),
        "installManually":
            MessageLookupByLibrary.simpleMessage("התקן באופן ידני"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("כתובת דוא״ל לא תקינה"),
        "invalidKey": MessageLookupByLibrary.simpleMessage("מפתח לא חוקי"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "מפתח השחזור שהזמנת אינו תקין. אנא וודא שהוא מכיל 24 מילים, ותבדוק את האיות של כל אחת.\n\nאם הכנסת קוד שחזור ישן, וודא שהוא בעל 64 אותיות, ותבדוק כל אחת מהן."),
        "invite": MessageLookupByLibrary.simpleMessage("הזמן"),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("הזמן את חברייך"),
        "itemCount": m44,
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
            "הפריטים שנבחרו יוסרו מהאלבום הזה"),
        "keepPhotos": MessageLookupByLibrary.simpleMessage("השאר תמונות"),
        "kiloMeterUnit": MessageLookupByLibrary.simpleMessage("ק\"מ"),
        "kindlyHelpUsWithThisInformation":
            MessageLookupByLibrary.simpleMessage("אנא עזור לנו עם המידע הזה"),
        "language": MessageLookupByLibrary.simpleMessage("שפה"),
        "lastUpdated": MessageLookupByLibrary.simpleMessage("עדכון אחרון"),
        "leave": MessageLookupByLibrary.simpleMessage("עזוב"),
        "leaveAlbum": MessageLookupByLibrary.simpleMessage("צא מהאלבום"),
        "leaveFamily": MessageLookupByLibrary.simpleMessage("עזוב משפחה"),
        "leaveSharedAlbum":
            MessageLookupByLibrary.simpleMessage("לעזוב את האלבום המשותף?"),
        "light": MessageLookupByLibrary.simpleMessage("אור"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("בהיר"),
        "linkCopiedToClipboard":
            MessageLookupByLibrary.simpleMessage("הקישור הועתק ללוח"),
        "linkDeviceLimit":
            MessageLookupByLibrary.simpleMessage("מגבלת כמות מכשירים"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("מאופשר"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("פג תוקף"),
        "linkExpiresOn": m47,
        "linkExpiry": MessageLookupByLibrary.simpleMessage("תאריך תפוגה ללינק"),
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("הקישור פג תוקף"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("לעולם לא"),
        "location": MessageLookupByLibrary.simpleMessage("מקום"),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("נעל"),
        "lockscreen": MessageLookupByLibrary.simpleMessage("מסך נעילה"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("התחבר"),
        "loggingOut": MessageLookupByLibrary.simpleMessage("מתנתק..."),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "על ידי לחיצה על התחברות, אני מסכים ל<u-terms>תנאי שירות</u-terms> ול<u-policy>מדיניות הפרטיות</u-policy>"),
        "logout": MessageLookupByLibrary.simpleMessage("התנתק"),
        "longpressOnAnItemToViewInFullscreen":
            MessageLookupByLibrary.simpleMessage(
                "לחץ לחיצה ארוכה על פריט על מנת לראות אותו במסך מלא"),
        "lostDevice": MessageLookupByLibrary.simpleMessage("איבדת את המכשיר?"),
        "manage": MessageLookupByLibrary.simpleMessage("נהל"),
        "manageFamily": MessageLookupByLibrary.simpleMessage("נהל משפחה"),
        "manageLink": MessageLookupByLibrary.simpleMessage("ניהול קישור"),
        "manageParticipants": MessageLookupByLibrary.simpleMessage("נהל"),
        "manageSubscription": MessageLookupByLibrary.simpleMessage("נהל מנוי"),
        "map": MessageLookupByLibrary.simpleMessage("מפה"),
        "maps": MessageLookupByLibrary.simpleMessage("מפות"),
        "mastodon": MessageLookupByLibrary.simpleMessage("Mastodon"),
        "matrix": MessageLookupByLibrary.simpleMessage("Matrix"),
        "merchandise": MessageLookupByLibrary.simpleMessage("סחורה"),
        "mobileWebDesktop":
            MessageLookupByLibrary.simpleMessage("פלאפון, דפדפן, שולחן עבודה"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("מתונה"),
        "monthly": MessageLookupByLibrary.simpleMessage("חודשי"),
        "moveToAlbum": MessageLookupByLibrary.simpleMessage("הזז לאלבום"),
        "movedToTrash": MessageLookupByLibrary.simpleMessage("הועבר לאשפה"),
        "movingFilesToAlbum":
            MessageLookupByLibrary.simpleMessage("מעביר קבצים לאלבום..."),
        "name": MessageLookupByLibrary.simpleMessage("שם"),
        "never": MessageLookupByLibrary.simpleMessage("לעולם לא"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("אלבום חדש"),
        "newest": MessageLookupByLibrary.simpleMessage("החדש ביותר"),
        "no": MessageLookupByLibrary.simpleMessage("לא"),
        "noDeviceLimit": MessageLookupByLibrary.simpleMessage("אין"),
        "noDeviceThatCanBeDeleted": MessageLookupByLibrary.simpleMessage(
            "אין לך קבצים במכשיר הזה שניתן למחוק אותם"),
        "noDuplicates": MessageLookupByLibrary.simpleMessage("✨ אין כפילויות"),
        "noPhotosAreBeingBackedUpRightNow":
            MessageLookupByLibrary.simpleMessage(
                "אף תמונה אינה נמצאת בתהליך גיבוי כרגע"),
        "noRecoveryKey":
            MessageLookupByLibrary.simpleMessage("אין מפתח שחזור?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "בשל טבע הפרוטוקול של ההצפנת קצה-אל-קצה שלנו, אין אפשרות לפענח את הנתונים שלך בלי הסיסמה או מפתח השחזור שלך"),
        "noResults": MessageLookupByLibrary.simpleMessage("אין תוצאות"),
        "notifications": MessageLookupByLibrary.simpleMessage("התראות"),
        "ok": MessageLookupByLibrary.simpleMessage("אוקיי"),
        "onDevice": MessageLookupByLibrary.simpleMessage("על המכשיר"),
        "onEnte":
            MessageLookupByLibrary.simpleMessage("ב<branding>אנטע</branding>"),
        "oops": MessageLookupByLibrary.simpleMessage("אופס"),
        "oopsSomethingWentWrong":
            MessageLookupByLibrary.simpleMessage("אופס, משהו השתבש"),
        "openSettings": MessageLookupByLibrary.simpleMessage("פתח הגדרות"),
        "optionalAsShortAsYouLike":
            MessageLookupByLibrary.simpleMessage("אופציונלי, קצר ככל שתרצה..."),
        "orPickAnExistingOne":
            MessageLookupByLibrary.simpleMessage("או בחר באחד קיים"),
        "password": MessageLookupByLibrary.simpleMessage("סיסמא"),
        "passwordChangedSuccessfully":
            MessageLookupByLibrary.simpleMessage("הססמה הוחלפה בהצלחה"),
        "passwordLock": MessageLookupByLibrary.simpleMessage("נעילת סיסמא"),
        "passwordStrength": m57,
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "אנחנו לא שומרים את הסיסמא הזו, לכן אם אתה שוכח אותה, <underline>אנחנו לא יכולים לפענח את המידע שלך</underline>"),
        "paymentDetails": MessageLookupByLibrary.simpleMessage("פרטי תשלום"),
        "paymentFailed": MessageLookupByLibrary.simpleMessage("התשלום נכשל"),
        "paymentFailedTalkToProvider": m58,
        "peopleUsingYourCode":
            MessageLookupByLibrary.simpleMessage("אנשים משתמשים בקוד שלך"),
        "permanentlyDelete":
            MessageLookupByLibrary.simpleMessage("למחוק לצמיתות?"),
        "photoGridSize":
            MessageLookupByLibrary.simpleMessage("גודל לוח של התמונה"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("תמונה"),
        "playstoreSubscription":
            MessageLookupByLibrary.simpleMessage("מנוי PlayStore"),
        "pleaseContactSupportAndWeWillBeHappyToHelp":
            MessageLookupByLibrary.simpleMessage(
                "אנא צור קשר עם support@ente.io ואנחנו נשמח לעזור!"),
        "pleaseGrantPermissions":
            MessageLookupByLibrary.simpleMessage("נא הענק את ההרשאות"),
        "pleaseLoginAgain":
            MessageLookupByLibrary.simpleMessage("אנא התחבר שוב"),
        "pleaseTryAgain": MessageLookupByLibrary.simpleMessage("אנא נסה שנית"),
        "pleaseWait": MessageLookupByLibrary.simpleMessage("אנא המתן..."),
        "pleaseWaitForSometimeBeforeRetrying":
            MessageLookupByLibrary.simpleMessage(
                "אנא חכה מעט לפני שאתה מנסה שוב"),
        "preparingLogs": MessageLookupByLibrary.simpleMessage("מכין לוגים..."),
        "preserveMore": MessageLookupByLibrary.simpleMessage("שמור עוד"),
        "pressAndHoldToPlayVideo": MessageLookupByLibrary.simpleMessage(
            "לחץ והחזק על מנת להריץ את הסרטון"),
        "pressAndHoldToPlayVideoDetailed": MessageLookupByLibrary.simpleMessage(
            "לחץ והחזק על התמונה על מנת להריץ את הסרטון"),
        "privacy": MessageLookupByLibrary.simpleMessage("פרטיות"),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("מדיניות פרטיות"),
        "privateBackups":
            MessageLookupByLibrary.simpleMessage("גיבויים פרטיים"),
        "privateSharing": MessageLookupByLibrary.simpleMessage("שיתוף פרטי"),
        "publicLinkCreated":
            MessageLookupByLibrary.simpleMessage("קישור ציבורי נוצר"),
        "publicLinkEnabled":
            MessageLookupByLibrary.simpleMessage("לינק ציבורי אופשר"),
        "radius": MessageLookupByLibrary.simpleMessage("רדיוס"),
        "raiseTicket": MessageLookupByLibrary.simpleMessage("צור ticket"),
        "rateTheApp": MessageLookupByLibrary.simpleMessage("דרג את האפליקציה"),
        "rateUs": MessageLookupByLibrary.simpleMessage("דרג אותנו"),
        "rateUsOnStore": m68,
        "recover": MessageLookupByLibrary.simpleMessage("שחזר"),
        "recoverAccount": MessageLookupByLibrary.simpleMessage("שחזר חשבון"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("שחזר"),
        "recoveryKey": MessageLookupByLibrary.simpleMessage("מפתח שחזור"),
        "recoveryKeyCopiedToClipboard":
            MessageLookupByLibrary.simpleMessage("מפתח השחזור הועתק ללוח"),
        "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
            "אם אתה שוכח את הסיסמא שלך, הדרך היחידה שתוכל לשחזר את המידע שלך היא עם המפתח הזה."),
        "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
            "אנחנו לא מאחסנים את המפתח הזה, אנא שמור את המפתח 24 מילים הזה במקום בטוח."),
        "recoveryKeySuccessBody": MessageLookupByLibrary.simpleMessage(
            "נהדר! מפתח השחזור תקין. אנחנו מודים לך על האימות.\n\nאנא תזכור לגבות את מפתח השחזור שלך באופן בטוח."),
        "recoveryKeyVerified":
            MessageLookupByLibrary.simpleMessage("מפתח השחזור אומת"),
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("השחזור עבר בהצלחה!"),
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "המכשיר הנוכחי אינו חזק מספיק כדי לאמת את הסיסמא שלך, אבל אנחנו יכולים ליצור בצורה שתעבוד עם כל המכשירים.\n\nאנא התחבר בעזרת המפתח שחזור שלך וצור מחדש את הסיסמא שלך (אתה יכול להשתמש באותה אחת אם אתה רוצה)."),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("צור סיסמא מחדש"),
        "reddit": MessageLookupByLibrary.simpleMessage("Reddit"),
        "referralStep1": MessageLookupByLibrary.simpleMessage(
            "1. תמסור את הקוד הזה לחברייך"),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
            "2. הם נרשמים עבור תוכנית בתשלום"),
        "referralStep3": m73,
        "referrals": MessageLookupByLibrary.simpleMessage("הפניות"),
        "referralsAreCurrentlyPaused":
            MessageLookupByLibrary.simpleMessage("הפניות כרגע מושהות"),
        "remindToEmptyDeviceTrash": MessageLookupByLibrary.simpleMessage(
            "גם נקה \"נמחק לאחרונה\" מ-\"הגדרות\" -> \"אחסון\" על מנת לקבל המקום אחסון שהתפנה"),
        "remindToEmptyEnteTrash": MessageLookupByLibrary.simpleMessage(
            "גם נקה את ה-\"אשפה\" שלך על מנת לקבל את המקום אחסון שהתפנה"),
        "remove": MessageLookupByLibrary.simpleMessage("הסר"),
        "removeDuplicates":
            MessageLookupByLibrary.simpleMessage("הסר כפילויות"),
        "removeFromAlbum": MessageLookupByLibrary.simpleMessage("הסר מהאלבום"),
        "removeFromAlbumTitle":
            MessageLookupByLibrary.simpleMessage("הסר מהאלבום?"),
        "removeLink": MessageLookupByLibrary.simpleMessage("הסרת קישור"),
        "removeParticipant": MessageLookupByLibrary.simpleMessage("הסר משתתף"),
        "removeParticipantBody": m74,
        "removePublicLink":
            MessageLookupByLibrary.simpleMessage("הסר לינק ציבורי"),
        "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
            "חלק מהפריטים שאתה מסיר הוספו על ידי אנשים אחרים, ואתה תאבד גישה אליהם"),
        "removeWithQuestionMark": MessageLookupByLibrary.simpleMessage("הסר?"),
        "removingFromFavorites":
            MessageLookupByLibrary.simpleMessage("מסיר מהמועדפים..."),
        "rename": MessageLookupByLibrary.simpleMessage("שנה שם"),
        "renameFile": MessageLookupByLibrary.simpleMessage("שנה שם הקובץ"),
        "renewSubscription": MessageLookupByLibrary.simpleMessage("חדש מנוי"),
        "reportABug": MessageLookupByLibrary.simpleMessage("דווח על באג"),
        "reportBug": MessageLookupByLibrary.simpleMessage("דווח על באג"),
        "resendEmail": MessageLookupByLibrary.simpleMessage("שלח דוא\"ל מחדש"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("איפוס סיסמה"),
        "restore": MessageLookupByLibrary.simpleMessage("שחזר"),
        "restoreToAlbum": MessageLookupByLibrary.simpleMessage("שחזר לאלבום"),
        "restoringFiles":
            MessageLookupByLibrary.simpleMessage("משחזר קבצים..."),
        "retry": MessageLookupByLibrary.simpleMessage("נסה שוב"),
        "reviewDeduplicateItems": MessageLookupByLibrary.simpleMessage(
            "אנא בחן והסר את הפריטים שאתה מאמין שהם כפלים."),
        "rotateLeft": MessageLookupByLibrary.simpleMessage("סובב שמאלה"),
        "safelyStored": MessageLookupByLibrary.simpleMessage("נשמר באופן בטוח"),
        "save": MessageLookupByLibrary.simpleMessage("שמור"),
        "saveCollage": MessageLookupByLibrary.simpleMessage("שמור קולז"),
        "saveCopy": MessageLookupByLibrary.simpleMessage("שמירת עותק"),
        "saveKey": MessageLookupByLibrary.simpleMessage("שמור מפתח"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "שמור את מפתח השחזור שלך אם לא שמרת כבר"),
        "saving": MessageLookupByLibrary.simpleMessage("שומר..."),
        "scanCode": MessageLookupByLibrary.simpleMessage("סרוק קוד"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "סרוק את הברקוד הזה\nבעזרת אפליקציית האימות שלך"),
        "searchByAlbumNameHint":
            MessageLookupByLibrary.simpleMessage("שם האלבום"),
        "security": MessageLookupByLibrary.simpleMessage("אבטחה"),
        "selectAlbum": MessageLookupByLibrary.simpleMessage("בחר אלבום"),
        "selectAll": MessageLookupByLibrary.simpleMessage("בחר הכל"),
        "selectFoldersForBackup":
            MessageLookupByLibrary.simpleMessage("בחר תיקיות לגיבוי"),
        "selectMorePhotos":
            MessageLookupByLibrary.simpleMessage("בחר תמונות נוספות"),
        "selectReason": MessageLookupByLibrary.simpleMessage("בחר סיבה"),
        "selectYourPlan": MessageLookupByLibrary.simpleMessage("בחר תוכנית"),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
                "התיקיות שנבחרו יוצפנו ויגובו"),
        "selectedPhotos": m80,
        "selectedPhotosWithYours": m81,
        "send": MessageLookupByLibrary.simpleMessage("שלח"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("שלח דוא\"ל"),
        "sendInvite": MessageLookupByLibrary.simpleMessage("שלח הזמנה"),
        "sendLink": MessageLookupByLibrary.simpleMessage("שלח קישור"),
        "sessionExpired":
            MessageLookupByLibrary.simpleMessage("פג תוקף החיבור"),
        "setAPassword": MessageLookupByLibrary.simpleMessage("הגדר סיסמה"),
        "setAs": MessageLookupByLibrary.simpleMessage("הגדר בתור"),
        "setCover": MessageLookupByLibrary.simpleMessage("הגדר כרקע"),
        "setLabel": MessageLookupByLibrary.simpleMessage("הגדר"),
        "setPasswordTitle": MessageLookupByLibrary.simpleMessage("הגדר סיסמא"),
        "setRadius": MessageLookupByLibrary.simpleMessage("הגדר רדיוס"),
        "setupComplete": MessageLookupByLibrary.simpleMessage("ההתקנה הושלמה"),
        "share": MessageLookupByLibrary.simpleMessage("שתף"),
        "shareALink": MessageLookupByLibrary.simpleMessage("שתף קישור"),
        "shareAnAlbumNow":
            MessageLookupByLibrary.simpleMessage("שתף אלבום עכשיו"),
        "shareLink": MessageLookupByLibrary.simpleMessage("שתף קישור"),
        "shareMyVerificationID": m83,
        "shareOnlyWithThePeopleYouWant":
            MessageLookupByLibrary.simpleMessage("שתף רק אם אנשים שאתה בוחר"),
        "shareTextConfirmOthersVerificationID": m84,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "הורד את ente על מנת שנוכל לשתף תמונות וסרטונים באיכות המקור באופן קל\n\nhttps://ente.io"),
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
            "שתף עם משתמשים שהם לא של ente"),
        "shareWithPeopleSectionTitle": m86,
        "shareYourFirstAlbum":
            MessageLookupByLibrary.simpleMessage("שתף את האלבום הראשון שלך"),
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
            "צור אלבומים הניתנים לשיתוף ושיתוף פעולה עם משתמשי ente אחרים, כולל משתמשים בתוכניות החינמיות."),
        "sharedByMe": MessageLookupByLibrary.simpleMessage("שותף על ידי"),
        "sharedPhotoNotifications":
            MessageLookupByLibrary.simpleMessage("אלבומים משותפים חדשים"),
        "sharedPhotoNotificationsExplanation":
            MessageLookupByLibrary.simpleMessage(
                "קבל התראות כשמישהו מוסיף תמונה לאלבום משותף שאתה חלק ממנו"),
        "sharedWith": m87,
        "sharedWithMe": MessageLookupByLibrary.simpleMessage("שותף איתי"),
        "sharing": MessageLookupByLibrary.simpleMessage("משתף..."),
        "showMemories": MessageLookupByLibrary.simpleMessage("הצג זכרונות"),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "אני מסכים ל<u-terms>תנאי שירות</u-terms> ול<u-policy>מדיניות הפרטיות</u-policy>"),
        "singleFileDeleteFromDevice": m88,
        "singleFileDeleteHighlight":
            MessageLookupByLibrary.simpleMessage("זה יימחק מכל האלבומים."),
        "skip": MessageLookupByLibrary.simpleMessage("דלג"),
        "social": MessageLookupByLibrary.simpleMessage("חברתי"),
        "someoneSharingAlbumsWithYouShouldSeeTheSameId":
            MessageLookupByLibrary.simpleMessage(
                "מי שמשתף איתך אלבומים יוכל לראות את אותו המזהה במכשיר שלהם."),
        "somethingWentWrong":
            MessageLookupByLibrary.simpleMessage("משהו השתבש"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("משהו השתבש, אנא נסה שנית"),
        "sorry": MessageLookupByLibrary.simpleMessage("מצטער"),
        "sorryCouldNotAddToFavorites": MessageLookupByLibrary.simpleMessage(
            "סליחה, לא ניתן להוסיף למועדפים!"),
        "sorryCouldNotRemoveFromFavorites":
            MessageLookupByLibrary.simpleMessage(
                "סליחה, לא ניתן להסיר מהמועדפים!"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "אנחנו מצטערים, לא הצלחנו ליצור מפתחות מאובטחים על מכשיר זה.\n\nאנא הירשם ממכשיר אחר."),
        "sortAlbumsBy": MessageLookupByLibrary.simpleMessage("מיין לפי"),
        "sortOldestFirst":
            MessageLookupByLibrary.simpleMessage("הישן ביותר קודם"),
        "sparkleSuccess": MessageLookupByLibrary.simpleMessage("✨ הצלחה"),
        "startBackup": MessageLookupByLibrary.simpleMessage("התחל גיבוי"),
        "storage": MessageLookupByLibrary.simpleMessage("אחסון"),
        "storageBreakupFamily": MessageLookupByLibrary.simpleMessage("משפחה"),
        "storageBreakupYou": MessageLookupByLibrary.simpleMessage("אתה"),
        "storageInGB": m93,
        "storageLimitExceeded":
            MessageLookupByLibrary.simpleMessage("גבול מקום האחסון נחרג"),
        "strongStrength": MessageLookupByLibrary.simpleMessage("חזקה"),
        "subWillBeCancelledOn": m96,
        "subscribe": MessageLookupByLibrary.simpleMessage("הרשם"),
        "subscription": MessageLookupByLibrary.simpleMessage("מנוי"),
        "success": MessageLookupByLibrary.simpleMessage("הצלחה"),
        "suggestFeatures":
            MessageLookupByLibrary.simpleMessage("הציעו מאפיינים"),
        "support": MessageLookupByLibrary.simpleMessage("תמיכה"),
        "syncProgress": m97,
        "syncing": MessageLookupByLibrary.simpleMessage("מסנכרן..."),
        "systemTheme": MessageLookupByLibrary.simpleMessage("מערכת"),
        "tapToCopy": MessageLookupByLibrary.simpleMessage("הקש כדי להעתיק"),
        "tapToEnterCode":
            MessageLookupByLibrary.simpleMessage("הקש כדי להזין את הקוד"),
        "terminate": MessageLookupByLibrary.simpleMessage("סיים"),
        "terminateSession": MessageLookupByLibrary.simpleMessage("סיים חיבור?"),
        "terms": MessageLookupByLibrary.simpleMessage("תנאים"),
        "termsOfServicesTitle": MessageLookupByLibrary.simpleMessage("תנאים"),
        "thankYou": MessageLookupByLibrary.simpleMessage("תודה"),
        "thankYouForSubscribing":
            MessageLookupByLibrary.simpleMessage("תודה שנרשמת!"),
        "theDownloadCouldNotBeCompleted":
            MessageLookupByLibrary.simpleMessage("לא ניתן להשלים את ההורדה"),
        "theme": MessageLookupByLibrary.simpleMessage("ערכת נושא"),
        "theyAlsoGetXGb": m99,
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "זה יכול לשמש לשחזור החשבון שלך במקרה ותאבד את הגורם השני"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("מכשיר זה"),
        "thisIsPersonVerificationId": m100,
        "thisIsYourVerificationId":
            MessageLookupByLibrary.simpleMessage("זה מזהה האימות שלך"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage("זה ינתק אותך מהמכשיר הבא:"),
        "thisWillLogYouOutOfThisDevice":
            MessageLookupByLibrary.simpleMessage("זה ינתק אותך במכשיר זה!"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "כדי לאפס את הסיסמא שלך, אנא אמת את האימייל שלך קודם."),
        "total": MessageLookupByLibrary.simpleMessage("סך הכל"),
        "totalSize": MessageLookupByLibrary.simpleMessage("גודל כולל"),
        "trash": MessageLookupByLibrary.simpleMessage("אשפה"),
        "tryAgain": MessageLookupByLibrary.simpleMessage("נסה שוב"),
        "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
        "twoMonthsFreeOnYearlyPlans": MessageLookupByLibrary.simpleMessage(
            "חודשיים בחינם בתוכניות שנתיות"),
        "twofactor": MessageLookupByLibrary.simpleMessage("דו-גורמי"),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage("אימות דו-גורמי"),
        "twofactorSetup": MessageLookupByLibrary.simpleMessage("אימות דו-שלבי"),
        "unarchive": MessageLookupByLibrary.simpleMessage("הוצאה מארכיון"),
        "uncategorized": MessageLookupByLibrary.simpleMessage("ללא קטגוריה"),
        "unhide": MessageLookupByLibrary.simpleMessage("בטל הסתרה"),
        "unhideToAlbum":
            MessageLookupByLibrary.simpleMessage("בטל הסתרה בחזרה לאלבום"),
        "unhidingFilesToAlbum":
            MessageLookupByLibrary.simpleMessage("מבטל הסתרת הקבצים לאלבום"),
        "unlock": MessageLookupByLibrary.simpleMessage("ביטול נעילה"),
        "unselectAll": MessageLookupByLibrary.simpleMessage("בטל בחירה של הכל"),
        "update": MessageLookupByLibrary.simpleMessage("עדכן"),
        "updateAvailable": MessageLookupByLibrary.simpleMessage("עדכון זמין"),
        "updatingFolderSelection":
            MessageLookupByLibrary.simpleMessage("מעדכן את בחירת התיקיות..."),
        "upgrade": MessageLookupByLibrary.simpleMessage("שדרג"),
        "uploadingFilesToAlbum":
            MessageLookupByLibrary.simpleMessage("מעלה קבצים לאלבום..."),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
            "כמות האחסון השמישה שלך מוגבלת בתוכנית הנוכחית. אחסון עודף יהפוך שוב לשמיש אחרי שתשדרג את התוכנית שלך."),
        "useRecoveryKey":
            MessageLookupByLibrary.simpleMessage("השתמש במפתח שחזור"),
        "usedSpace": MessageLookupByLibrary.simpleMessage("מקום בשימוש"),
        "verificationId": MessageLookupByLibrary.simpleMessage("מזהה אימות"),
        "verify": MessageLookupByLibrary.simpleMessage("אמת"),
        "verifyEmail": MessageLookupByLibrary.simpleMessage("אימות דוא\"ל"),
        "verifyEmailID": m111,
        "verifyIDLabel": MessageLookupByLibrary.simpleMessage("אמת"),
        "verifyPassword": MessageLookupByLibrary.simpleMessage("אמת סיסמא"),
        "verifyingRecoveryKey":
            MessageLookupByLibrary.simpleMessage("מוודא את מפתח השחזור..."),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("וידאו"),
        "viewActiveSessions":
            MessageLookupByLibrary.simpleMessage("צפה בחיבורים פעילים"),
        "viewAll": MessageLookupByLibrary.simpleMessage("הצג הכל"),
        "viewLogs": MessageLookupByLibrary.simpleMessage("צפייה בלוגים"),
        "viewRecoveryKey":
            MessageLookupByLibrary.simpleMessage("צפה במפתח השחזור"),
        "viewer": MessageLookupByLibrary.simpleMessage("צפיין"),
        "visitWebToManage": MessageLookupByLibrary.simpleMessage(
            "אנא בקר ב-web.ente.io על מנת לנהל את המנוי שלך"),
        "weAreOpenSource":
            MessageLookupByLibrary.simpleMessage("הקוד שלנו פתוח!"),
        "weHaveSendEmailTo": m114,
        "weakStrength": MessageLookupByLibrary.simpleMessage("חלשה"),
        "welcomeBack": MessageLookupByLibrary.simpleMessage("ברוך שובך!"),
        "wishThemAHappyBirthday": m115,
        "yearly": MessageLookupByLibrary.simpleMessage("שנתי"),
        "yearsAgo": m116,
        "yes": MessageLookupByLibrary.simpleMessage("כן"),
        "yesCancel": MessageLookupByLibrary.simpleMessage("כן, בטל"),
        "yesConvertToViewer":
            MessageLookupByLibrary.simpleMessage("כן, המר לצפיין"),
        "yesDelete": MessageLookupByLibrary.simpleMessage("כן, מחק"),
        "yesLogout": MessageLookupByLibrary.simpleMessage("כן, התנתק"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("כן, הסר"),
        "yesRenew": MessageLookupByLibrary.simpleMessage("כן, חדש"),
        "you": MessageLookupByLibrary.simpleMessage("אתה"),
        "youAreOnAFamilyPlan":
            MessageLookupByLibrary.simpleMessage("אתה על תוכנית משפחתית!"),
        "youAreOnTheLatestVersion":
            MessageLookupByLibrary.simpleMessage("אתה על הגרסא הכי עדכנית"),
        "youCanAtMaxDoubleYourStorage": MessageLookupByLibrary.simpleMessage(
            "* אתה יכול במקסימום להכפיל את מקום האחסון שלך"),
        "youCanManageYourLinksInTheShareTab":
            MessageLookupByLibrary.simpleMessage(
                "אתה יכול לנהת את הקישורים שלך בלשונית שיתוף."),
        "youCannotDowngradeToThisPlan": MessageLookupByLibrary.simpleMessage(
            "אתה לא יכול לשנמך לתוכנית הזו"),
        "youCannotShareWithYourself":
            MessageLookupByLibrary.simpleMessage("אתה לא יכול לשתף עם עצמך"),
        "youHaveSuccessfullyFreedUp": m118,
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("החשבון שלך נמחק"),
        "yourPlanWasSuccessfullyDowngraded":
            MessageLookupByLibrary.simpleMessage("התוכנית שלך שונמכה בהצלחה"),
        "yourPlanWasSuccessfullyUpgraded":
            MessageLookupByLibrary.simpleMessage("התוכנית שלך שודרגה בהצלחה"),
        "yourPurchaseWasSuccessful":
            MessageLookupByLibrary.simpleMessage("התשלום שלך עבר בהצלחה"),
        "yourStorageDetailsCouldNotBeFetched":
            MessageLookupByLibrary.simpleMessage(
                "לא ניתן לאחזר את פרטי מקום האחסון"),
        "yourSubscriptionHasExpired":
            MessageLookupByLibrary.simpleMessage("פג תוקף המנוי שלך"),
        "yourSubscriptionWasUpdatedSuccessfully":
            MessageLookupByLibrary.simpleMessage("המנוי שלך עודכן בהצלחה")
      };
}
