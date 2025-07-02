// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a fa locale. All the
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
  String get localeName => 'fa';

  static String m9(versionValue) => "نسخه: ${versionValue}";

  static String m10(freeAmount, storageUnit) =>
      "${freeAmount} ${storageUnit} رایگان";

  static String m25(supportEmail) =>
      "لطفا یک ایمیل از آدرس ایمیلی که ثبت نام کردید به ${supportEmail} ارسال کنید";

  static String m57(passwordStrengthValue) =>
      "قدرت رمز عبور: ${passwordStrengthValue}";

  static String m68(storeName) => "به ما در ${storeName} امتیاز دهید";

  static String m94(
          usedAmount, usedStorageUnit, totalAmount, totalStorageUnit) =>
      "${usedAmount} ${usedStorageUnit} از ${totalAmount} ${totalStorageUnit} استفاده شده";

  static String m111(email) => "تایید ${email}";

  static String m114(email) =>
      "ما یک ایمیل به <green>${email}</green> ارسال کرده‌ایم";

  static String m115(name) => "Wish \$${name} a happy birthday! 🎉";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aNewVersionOfEnteIsAvailable": MessageLookupByLibrary.simpleMessage(
            "نسخه جدید Ente در دسترس است."),
        "about": MessageLookupByLibrary.simpleMessage("درباره ما"),
        "account": MessageLookupByLibrary.simpleMessage("حساب کاربری"),
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("خوش آمدید!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "من درک می‌کنم که اگر رمز عبور خود را گم کنم، ممکن است اطلاعات خود را از دست بدهم، زیرا اطلاعات من <underline>رمزگذاری سرتاسر شده است</underline>."),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("دستگاه‌های فعال"),
        "addANewEmail":
            MessageLookupByLibrary.simpleMessage("افزودن ایمیل جدید"),
        "addCollaborator": MessageLookupByLibrary.simpleMessage("افزودن همکار"),
        "addMore": MessageLookupByLibrary.simpleMessage("افزودن بیشتر"),
        "addViewer": MessageLookupByLibrary.simpleMessage("افزودن بیننده"),
        "addedAs": MessageLookupByLibrary.simpleMessage("اضافه شده به عنوان"),
        "advanced": MessageLookupByLibrary.simpleMessage("پیشرفته"),
        "albumUpdated": MessageLookupByLibrary.simpleMessage("آلبوم به‌روز شد"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "به افراد که این پیوند را دارند، اجازه دهید عکس‌ها را به آلبوم اشتراک گذاری شده اضافه کنند."),
        "allowAddingPhotos":
            MessageLookupByLibrary.simpleMessage("اجازه اضافه کردن عکس"),
        "allowPeopleToAddPhotos": MessageLookupByLibrary.simpleMessage(
            "به افراد اجازه دهید عکس اضافه کنند"),
        "androidBiometricHint":
            MessageLookupByLibrary.simpleMessage("تایید هویت"),
        "androidBiometricSuccess":
            MessageLookupByLibrary.simpleMessage("موفقیت"),
        "androidCancelButton": MessageLookupByLibrary.simpleMessage("لغو"),
        "androidIosWebDesktop": MessageLookupByLibrary.simpleMessage(
            "اندروید، آی‌اواس، وب، رایانه رومیزی"),
        "appVersion": m9,
        "archive": MessageLookupByLibrary.simpleMessage("بایگانی"),
        "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
            "آیا برای خارج شدن مطمئن هستید؟"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "دلیل اصلی که حساب کاربری‌تان را حذف می‌کنید، چیست؟"),
        "atAFalloutShelter":
            MessageLookupByLibrary.simpleMessage("در یک پناهگاه ذخیره می‌شود"),
        "authToViewYourActiveSessions": MessageLookupByLibrary.simpleMessage(
            "لطفاً برای مشاهده دستگاه‌های فعال خود احراز هویت کنید"),
        "available": MessageLookupByLibrary.simpleMessage("در دسترس"),
        "availableStorageSpace": m10,
        "backedUpFolders":
            MessageLookupByLibrary.simpleMessage("پوشه‌های پشتیبان گیری شده"),
        "backup": MessageLookupByLibrary.simpleMessage("پشتیبان گیری"),
        "blog": MessageLookupByLibrary.simpleMessage("وبلاگ"),
        "cancel": MessageLookupByLibrary.simpleMessage("لغو"),
        "cannotDeleteSharedFiles": MessageLookupByLibrary.simpleMessage(
            "پرونده‌های به اشتراک گذاشته شده را نمی‌توان حذف کرد"),
        "changeEmail": MessageLookupByLibrary.simpleMessage("تغییر ایمیل"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("تغییر رمز عبور"),
        "checkForUpdates":
            MessageLookupByLibrary.simpleMessage("بررسی برای به‌روزرسانی"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "لطفا صندوق ورودی (و هرزنامه) خود را برای تایید کامل بررسی کنید"),
        "checkStatus": MessageLookupByLibrary.simpleMessage("بررسی وضعیت"),
        "checking": MessageLookupByLibrary.simpleMessage("در حال بررسی..."),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
            "پیوندی ایجاد کنید تا به افراد اجازه دهید بدون نیاز به برنامه یا حساب کاربری Ente عکس‌ها را در آلبوم اشتراک گذاشته شده شما اضافه و مشاهده کنند. برای جمع‌آوری عکس‌های رویداد عالی است."),
        "collaborator": MessageLookupByLibrary.simpleMessage("همکار"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "همکاران می‌توانند عکس‌ها و ویدیوها را به آلبوم اشتراک گذاری شده اضافه کنند."),
        "color": MessageLookupByLibrary.simpleMessage("رنگ"),
        "confirm": MessageLookupByLibrary.simpleMessage("تایید"),
        "confirmAccountDeletion":
            MessageLookupByLibrary.simpleMessage("تایید حذف حساب کاربری"),
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "بله، می خواهم این حساب و داده های آن را در همه برنامه ها برای همیشه حذف کنم."),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("تایید رمز عبور"),
        "confirmRecoveryKey":
            MessageLookupByLibrary.simpleMessage("تایید کلید بازیابی"),
        "confirmYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "کلید بازیابی خود را تایید کنید"),
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("ارتباط با پشتیبانی"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("ادامه"),
        "convertToAlbum":
            MessageLookupByLibrary.simpleMessage("تبدیل به آلبوم"),
        "createAccount":
            MessageLookupByLibrary.simpleMessage("ایجاد حساب کاربری"),
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("ایجاد حساب کاربری جدید"),
        "criticalUpdateAvailable": MessageLookupByLibrary.simpleMessage(
            "به‌روزرسانی حیاتی در دسترس است"),
        "custom": MessageLookupByLibrary.simpleMessage("سفارشی"),
        "darkTheme": MessageLookupByLibrary.simpleMessage("تیره"),
        "dayToday": MessageLookupByLibrary.simpleMessage("امروز"),
        "dayYesterday": MessageLookupByLibrary.simpleMessage("دیروز"),
        "decrypting":
            MessageLookupByLibrary.simpleMessage("در حال رمزگشایی..."),
        "deleteAccount":
            MessageLookupByLibrary.simpleMessage("حذف حساب کاربری"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "ما متاسفیم که می‌بینیم شما می‌روید. لطفا نظرات خود را برای کمک به بهبود ما به اشتراک بگذارید."),
        "deleteAccountPermanentlyButton":
            MessageLookupByLibrary.simpleMessage("حذف دائمی حساب کاربری"),
        "deleteAll": MessageLookupByLibrary.simpleMessage("حذف همه"),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "لطفا یک ایمیل به <warning>account-deletion@ente.io</warning> از آدرس ایمیل ثبت شده خود ارسال کنید."),
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
            "یک ویژگی کلیدی که به آن نیاز دارم، وجود ندارد"),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
            "برنامه یا یک ویژگی خاص آنطور که من فکر می‌کنم، عمل نمی‌کند"),
        "deleteReason3": MessageLookupByLibrary.simpleMessage(
            "سرویس دیگری پیدا کردم که بهتر می‌پسندم"),
        "deleteReason4":
            MessageLookupByLibrary.simpleMessage("دلیل من ذکر نشده است"),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
            "درخواست شما ظرف مدت ۷۲ ساعت پردازش خواهد شد."),
        "designedToOutlive": MessageLookupByLibrary.simpleMessage(
            "طراحی شده تا بیشتر زنده بماند"),
        "details": MessageLookupByLibrary.simpleMessage("جزئیات"),
        "developerSettings":
            MessageLookupByLibrary.simpleMessage("تنظیمات توسعه‌دهنده"),
        "didYouKnow": MessageLookupByLibrary.simpleMessage("آیا می‌دانستید؟"),
        "discord": MessageLookupByLibrary.simpleMessage("دیسکورد"),
        "doThisLater": MessageLookupByLibrary.simpleMessage("بعداً انجام شود"),
        "downloading": MessageLookupByLibrary.simpleMessage("در حال دانلود..."),
        "dropSupportEmail": m25,
        "editLocationTagTitle":
            MessageLookupByLibrary.simpleMessage("ویرایش مکان"),
        "email": MessageLookupByLibrary.simpleMessage("ایمیل"),
        "encryption": MessageLookupByLibrary.simpleMessage("رمزگذاری"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("کلیدهای رمزنگاری"),
        "endtoendEncryptedByDefault": MessageLookupByLibrary.simpleMessage(
            "به صورت پیش‌فرض رمزگذاری سرتاسر"),
        "enteCanEncryptAndPreserveFilesOnlyIfYouGrant":
            MessageLookupByLibrary.simpleMessage(
                "Ente فقط در صورتی می‌تواند پرونده‌ها را رمزگذاری و نگه‌داری کند که به آن‌ها دسترسی داشته باشید"),
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
            "Ente برای نگه‌داری عکس‌های شما <i>به دسترسی نیاز دارد</i>"),
        "enterEmail":
            MessageLookupByLibrary.simpleMessage("ایمیل را وارد کنید"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "رمز عبور جدیدی را وارد کنید که بتوانیم از آن برای رمزگذاری اطلاعات شما استفاده کنیم"),
        "enterPassword":
            MessageLookupByLibrary.simpleMessage("رمز عبور را وارد کنید"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "رمز عبوری را وارد کنید که بتوانیم از آن برای رمزگذاری اطلاعات شما استفاده کنیم"),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
            "لطفا یک ایمیل معتبر وارد کنید."),
        "enterYourEmailAddress":
            MessageLookupByLibrary.simpleMessage("آدرس ایمیل خود را وارد کنید"),
        "enterYourPassword":
            MessageLookupByLibrary.simpleMessage("رمز عبور خود را وارد کنید"),
        "enterYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "کلید بازیابی خود را وارد کنید"),
        "error": MessageLookupByLibrary.simpleMessage("خطا"),
        "everywhere": MessageLookupByLibrary.simpleMessage("همه جا"),
        "existingUser": MessageLookupByLibrary.simpleMessage("کاربر موجود"),
        "familyPlanPortalTitle":
            MessageLookupByLibrary.simpleMessage("خانوادگی"),
        "familyPlans":
            MessageLookupByLibrary.simpleMessage("برنامه‌های خانوادگی"),
        "faq": MessageLookupByLibrary.simpleMessage("سوالات متداول"),
        "feedback": MessageLookupByLibrary.simpleMessage("بازخورد"),
        "fileInfoAddDescHint":
            MessageLookupByLibrary.simpleMessage("افزودن توضیحات..."),
        "fileTypes": MessageLookupByLibrary.simpleMessage("انواع پرونده"),
        "forYourMemories":
            MessageLookupByLibrary.simpleMessage("برای خاطرات شما"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("رمز عبور را فراموش کرده‌اید"),
        "general": MessageLookupByLibrary.simpleMessage("عمومی"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "در حال تولید کلیدهای رمزگذاری..."),
        "grantFullAccessPrompt": MessageLookupByLibrary.simpleMessage(
            "لطفا اجازه دسترسی به تمام عکس‌ها را در تنظیمات برنامه بدهید"),
        "grantPermission": MessageLookupByLibrary.simpleMessage("دسترسی دادن"),
        "hearUsExplanation": MessageLookupByLibrary.simpleMessage(
            "ما نصب برنامه را ردیابی نمی‌کنیم. اگر بگویید کجا ما را پیدا کردید، به ما کمک می‌کند!"),
        "hearUsWhereTitle": MessageLookupByLibrary.simpleMessage(
            "از کجا در مورد Ente شنیدی؟ (اختیاری)"),
        "howItWorks": MessageLookupByLibrary.simpleMessage("چگونه کار می‌کند"),
        "ignoreUpdate": MessageLookupByLibrary.simpleMessage("نادیده گرفتن"),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("رمز عبور درست نیست"),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "کلید بازیابی که وارد کردید درست نیست"),
        "incorrectRecoveryKeyTitle":
            MessageLookupByLibrary.simpleMessage("کلید بازیابی درست نیست"),
        "insecureDevice": MessageLookupByLibrary.simpleMessage("دستگاه ناامن"),
        "installManually": MessageLookupByLibrary.simpleMessage("نصب دستی"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("آدرس ایمیل معتبر نیست"),
        "invalidKey": MessageLookupByLibrary.simpleMessage("کلید نامعتبر"),
        "itLooksLikeSomethingWentWrongPleaseRetryAfterSome":
            MessageLookupByLibrary.simpleMessage(
                "به نظر می‌رسد مشکلی وجود دارد. لطفا بعد از مدتی دوباره تلاش کنید. اگر همچنان با خطا مواجه می‌شوید، لطفا با تیم پشتیبانی ما ارتباط برقرار کنید."),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "لطفا با این اطلاعات به ما کمک کنید"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("روشن"),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("قفل"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("ورود"),
        "loggingOut": MessageLookupByLibrary.simpleMessage("در حال خروج..."),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "با کلیک بر روی ورود به سیستم، من با <u-terms>شرایط خدمات</u-terms> و <u-policy>سیاست حفظ حریم خصوصی</u-policy> موافقم"),
        "logout": MessageLookupByLibrary.simpleMessage("خروج"),
        "manage": MessageLookupByLibrary.simpleMessage("مدیریت"),
        "manageFamily": MessageLookupByLibrary.simpleMessage("مدیریت خانواده"),
        "manageLink": MessageLookupByLibrary.simpleMessage("مدیریت پیوند"),
        "manageParticipants": MessageLookupByLibrary.simpleMessage("مدیریت"),
        "manageSubscription":
            MessageLookupByLibrary.simpleMessage("مدیریت اشتراک"),
        "mastodon": MessageLookupByLibrary.simpleMessage("ماستودون"),
        "matrix": MessageLookupByLibrary.simpleMessage("ماتریس"),
        "merchandise": MessageLookupByLibrary.simpleMessage("کالا"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("متوسط"),
        "never": MessageLookupByLibrary.simpleMessage("هرگز"),
        "newToEnte": MessageLookupByLibrary.simpleMessage("کاربر جدید Ente"),
        "no": MessageLookupByLibrary.simpleMessage("خیر"),
        "noRecoveryKey":
            MessageLookupByLibrary.simpleMessage("کلید بازیابی ندارید؟"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "با توجه به ماهیت پروتکل رمزگذاری سرتاسر ما، اطلاعات شما بدون رمز عبور یا کلید بازیابی شما قابل رمزگشایی نیست"),
        "notifications": MessageLookupByLibrary.simpleMessage("آگاه‌سازی‌ها"),
        "ok": MessageLookupByLibrary.simpleMessage("تایید"),
        "oops": MessageLookupByLibrary.simpleMessage("اوه"),
        "password": MessageLookupByLibrary.simpleMessage("رمز عبور"),
        "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
            "رمز عبور با موفقیت تغییر کرد"),
        "passwordStrength": m57,
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "ما این رمز عبور را ذخیره نمی‌کنیم، بنابراین اگر فراموش کنید، <underline>نمی‌توانیم اطلاعات شما را رمزگشایی کنیم</underline>"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("عکس"),
        "pleaseGrantPermissions":
            MessageLookupByLibrary.simpleMessage("لطفا دسترسی بدهید"),
        "pleaseLoginAgain":
            MessageLookupByLibrary.simpleMessage("لطفا دوباره وارد شوید"),
        "pleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("لطفا دوباره تلاش کنید"),
        "pleaseWait": MessageLookupByLibrary.simpleMessage("لطفا صبر کنید..."),
        "preparingLogs":
            MessageLookupByLibrary.simpleMessage("در حال آماده‌سازی لاگ‌ها..."),
        "privacy": MessageLookupByLibrary.simpleMessage("حریم خصوصی"),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("سیاست حفظ حریم خصوصی"),
        "privateBackups":
            MessageLookupByLibrary.simpleMessage("پشتیبان گیری خصوصی"),
        "privateSharing":
            MessageLookupByLibrary.simpleMessage("اشتراک گذاری خصوصی"),
        "rateUsOnStore": m68,
        "recover": MessageLookupByLibrary.simpleMessage("بازیابی"),
        "recoverAccount":
            MessageLookupByLibrary.simpleMessage("بازیابی حساب کاربری"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("بازیابی"),
        "recoveryKey": MessageLookupByLibrary.simpleMessage("کلید بازیابی"),
        "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "کلید بازیابی در کلیپ‌بورد کپی شد"),
        "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
            "اگر رمز عبور خود را فراموش کردید، تنها راهی که می‌توانید اطلاعات خود را بازیابی کنید با این کلید است."),
        "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
            "ما این کلید را ذخیره نمی‌کنیم، لطفا این کلید ۲۴ کلمه‌ای را در مکانی امن ذخیره کنید."),
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("بازیابی موفقیت آمیز بود!"),
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "دستگاه فعلی به اندازه کافی قدرتمند نیست تا رمز عبور شما را تایید کند، اما ما می‌توانیم به گونه‌ای بازسازی کنیم که با تمام دستگاه‌ها کار کند.\n\nلطفا با استفاده از کلید بازیابی خود وارد شوید و رمز عبور خود را دوباره ایجاد کنید (در صورت تمایل می‌توانید دوباره از همان رمز عبور استفاده کنید)."),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("بازتولید رمز عبور"),
        "reddit": MessageLookupByLibrary.simpleMessage("ردیت"),
        "removeLink": MessageLookupByLibrary.simpleMessage("حذف پیوند"),
        "rename": MessageLookupByLibrary.simpleMessage("تغییر نام"),
        "renameAlbum": MessageLookupByLibrary.simpleMessage("تغییر نام آلبوم"),
        "renameFile": MessageLookupByLibrary.simpleMessage("تغییر نام پرونده"),
        "resendEmail": MessageLookupByLibrary.simpleMessage("ارسال مجدد ایمیل"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("بازنشانی رمز عبور"),
        "retry": MessageLookupByLibrary.simpleMessage("سعی مجدد"),
        "reviewSuggestions":
            MessageLookupByLibrary.simpleMessage("مرور پیشنهادها"),
        "safelyStored": MessageLookupByLibrary.simpleMessage("به طور ایمن"),
        "saveKey": MessageLookupByLibrary.simpleMessage("ذخیره کلید"),
        "search": MessageLookupByLibrary.simpleMessage("جستجو"),
        "security": MessageLookupByLibrary.simpleMessage("امنیت"),
        "selectAll": MessageLookupByLibrary.simpleMessage("انتخاب همه"),
        "selectFoldersForBackup": MessageLookupByLibrary.simpleMessage(
            "پوشه‌ها را برای پشتیبان گیری انتخاب کنید"),
        "selectReason": MessageLookupByLibrary.simpleMessage("انتخاب دلیل"),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
                "پوشه‌های انتخاب شده، رمزگذاری شده و از آنها نسخه پشتیبان تهیه می‌شود"),
        "send": MessageLookupByLibrary.simpleMessage("ارسال"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("ارسال ایمیل"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("تنظیم رمز عبور"),
        "shareOnlyWithThePeopleYouWant": MessageLookupByLibrary.simpleMessage(
            "فقط با افرادی که می‌خواهید به اشتراک بگذارید"),
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "Ente را دانلود کنید تا بتوانید به راحتی عکس‌ها و ویدیوهای با کیفیت اصلی را به اشتراک بگذارید\n\nhttps://ente.io"),
        "sharedPhotoNotifications": MessageLookupByLibrary.simpleMessage(
            "عکس‌های جدید به اشتراک گذاشته شده"),
        "sharedPhotoNotificationsExplanation": MessageLookupByLibrary.simpleMessage(
            "هنگامی که شخصی عکسی را به آلبوم مشترکی که شما بخشی از آن هستید اضافه می‌کند، آگاه‌سازی دریافت می‌کنید"),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "من با <u-terms>شرایط خدمات</u-terms> و <u-policy>سیاست حفظ حریم خصوصی</u-policy> موافقم"),
        "skip": MessageLookupByLibrary.simpleMessage("رد کردن"),
        "social": MessageLookupByLibrary.simpleMessage("شبکه اجتماعی"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "مشکلی پیش آمده، لطفا دوباره تلاش کنید"),
        "sorry": MessageLookupByLibrary.simpleMessage("متاسفیم"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "با عرض پوزش، ما نمی‌توانیم کلیدهای امن را در این دستگاه تولید کنیم.\n\nلطفا از دستگاه دیگری ثبت نام کنید."),
        "sortAlbumsBy":
            MessageLookupByLibrary.simpleMessage("مرتب‌سازی براساس"),
        "sortNewestFirst":
            MessageLookupByLibrary.simpleMessage("ایتدا جدیدترین"),
        "sortOldestFirst":
            MessageLookupByLibrary.simpleMessage("ایتدا قدیمی‌ترین"),
        "startBackup":
            MessageLookupByLibrary.simpleMessage("شروع پشتیبان گیری"),
        "status": MessageLookupByLibrary.simpleMessage("وضعیت"),
        "storage": MessageLookupByLibrary.simpleMessage("حافظه ذخیره‌سازی"),
        "storageBreakupFamily":
            MessageLookupByLibrary.simpleMessage("خانوادگی"),
        "storageBreakupYou": MessageLookupByLibrary.simpleMessage("شما"),
        "storageUsageInfo": m94,
        "strongStrength": MessageLookupByLibrary.simpleMessage("قوی"),
        "support": MessageLookupByLibrary.simpleMessage("پشتیبانی"),
        "systemTheme": MessageLookupByLibrary.simpleMessage("سیستم"),
        "tapToEnterCode": MessageLookupByLibrary.simpleMessage(
            "برای وارد کردن کد ضربه بزنید"),
        "tempErrorContactSupportIfPersists": MessageLookupByLibrary.simpleMessage(
            "به نظر می‌رسد مشکلی وجود دارد. لطفا بعد از مدتی دوباره تلاش کنید. اگر همچنان با خطا مواجه می‌شوید، لطفا با تیم پشتیبانی ما ارتباط برقرار کنید."),
        "terminate": MessageLookupByLibrary.simpleMessage("خروج"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("خروچ دستگاه؟"),
        "terms": MessageLookupByLibrary.simpleMessage("شرایط و مقررات"),
        "termsOfServicesTitle":
            MessageLookupByLibrary.simpleMessage("شرایط و مقررات"),
        "theDownloadCouldNotBeCompleted":
            MessageLookupByLibrary.simpleMessage("دانلود کامل نشد"),
        "theme": MessageLookupByLibrary.simpleMessage("تم"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("این دستگاه"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "با این کار شما از دستگاه زیر خارج می‌شوید:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "این کار شما را از این دستگاه خارج می‌کند!"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "برای تنظیم مجدد رمز عبور، لطفا ابتدا ایمیل خود را تایید کنید."),
        "tryAgain": MessageLookupByLibrary.simpleMessage("دوباره امتحان کنید"),
        "twitter": MessageLookupByLibrary.simpleMessage("توییتر"),
        "uncategorized": MessageLookupByLibrary.simpleMessage("دسته‌بندی نشده"),
        "unselectAll": MessageLookupByLibrary.simpleMessage("لغو انتخاب همه"),
        "update": MessageLookupByLibrary.simpleMessage("به‌روزرسانی"),
        "updateAvailable":
            MessageLookupByLibrary.simpleMessage("به‌رورزرسانی در دسترس است"),
        "updatingFolderSelection": MessageLookupByLibrary.simpleMessage(
            "در حال به‌روزرسانی گزینش پوشه..."),
        "usePublicLinksForPeopleNotOnEnte":
            MessageLookupByLibrary.simpleMessage(
                "استفاده از پیوندهای عمومی برای افرادی که در Ente نیستند"),
        "useRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "از کلید بازیابی استفاده کنید"),
        "verify": MessageLookupByLibrary.simpleMessage("تایید"),
        "verifyEmail": MessageLookupByLibrary.simpleMessage("تایید ایمیل"),
        "verifyEmailID": m111,
        "verifyIDLabel": MessageLookupByLibrary.simpleMessage("تایید"),
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("تایید رمز عبور"),
        "verifying": MessageLookupByLibrary.simpleMessage("در حال تایید..."),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("ویدیو"),
        "viewActiveSessions":
            MessageLookupByLibrary.simpleMessage("مشاهده دستگاه‌های فعال"),
        "viewRecoveryKey":
            MessageLookupByLibrary.simpleMessage("نمایش کلید بازیابی"),
        "viewer": MessageLookupByLibrary.simpleMessage("بیننده"),
        "weAreOpenSource":
            MessageLookupByLibrary.simpleMessage("ما متن‌باز هستیم!"),
        "weHaveSendEmailTo": m114,
        "weakStrength": MessageLookupByLibrary.simpleMessage("ضعیف"),
        "welcomeBack": MessageLookupByLibrary.simpleMessage("خوش آمدید!"),
        "whatsNew": MessageLookupByLibrary.simpleMessage("تغییرات جدید"),
        "wishThemAHappyBirthday": m115,
        "yes": MessageLookupByLibrary.simpleMessage("بله"),
        "yesConvertToViewer":
            MessageLookupByLibrary.simpleMessage("بله، تبدیل به بیننده شود"),
        "yesLogout": MessageLookupByLibrary.simpleMessage("بله، خارج می‌شوم"),
        "you": MessageLookupByLibrary.simpleMessage("شما"),
        "youAreOnAFamilyPlan": MessageLookupByLibrary.simpleMessage(
            "شما در یک برنامه خانوادگی هستید!"),
        "youAreOnTheLatestVersion": MessageLookupByLibrary.simpleMessage(
            "شما در حال استفاده از آخرین نسخه هستید"),
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("حساب کاربری شما حذف شده است")
      };
}
