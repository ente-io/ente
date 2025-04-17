// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ar locale. All the
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
  String get localeName => 'ar';

  static String m0(storageAmount, endDate) =>
      "الإضافة الخاصة بك بسعة ${storageAmount} صالحة حتى ${endDate}";

  static String m1(count) =>
      "${Intl.plural(count, zero: 'لا يوجد مُشاركون', one: 'مُشارك واحد', other: '${count} مُشاركين')}";

  static String m2(paymentProvider) =>
      "يرجى إلغاء اشتراكك الحالي من ${paymentProvider} أولاً";

  static String m3(user) =>
      "${user} لن يتمكن من إضافة المزيد من الصور إلى هذا الألبوم.\n\nسيظل قادرًا على إزالة الصور الحالية التي أضافها";

  static String m4(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true': 'عائلتك حصلت على ${storageAmountInGb} GB حتى الآن',
            'false': 'لقد حصلتَ على ${storageAmountInGb} GB حتى الآن',
            'other': 'لقد حصلتَ على ${storageAmountInGb} GB حتى الآن!',
          })}";

  static String m5(familyAdminEmail) =>
      "يرجى الاتصال ب <green>${familyAdminEmail}</green> لإدارة اشتراكك";

  static String m6(provider) =>
      "يرجى التواصل معنا على support@ente.io لإدارة اشتراكك في ${provider}.";

  static String m7(count) =>
      "${Intl.plural(count, one: 'احذف ${count} عنصرًا', other: 'احذف ${count} عناصر')}";

  static String m8(albumName) =>
      "هذا سيُزيل الرابط العام للوصول إلى \"${albumName}\".";

  static String m9(supportEmail) =>
      "يُرجى إرسال بريد إلكتروني إلى ${supportEmail} من عنوان البريد الإلكتروني المُسَجَّل لديك";

  static String m10(count, storageSaved) =>
      "لقد قمت بتنظيف ${Intl.plural(count, one: '${count} ملف مكرر', other: '${count} ملفات مكررة')}، مما وفر (${storageSaved}!)";

  static String m11(count, formattedSize) =>
      "${count} ملفات، ${formattedSize} لكل";

  static String m12(email) =>
      "${email} ليس لديه حساب على Ente.\n\nأرسل لهم دعوة لمشاركة الصور.";

  static String m13(storageAmountInGB) =>
      "${storageAmountInGB} GB كل مرة يُشترك في خطة مدفوعة ويُطبَّق رمزك";

  static String m14(endDate) =>
      "النسخة التجريبية المجانية صالحة حتى ${endDate}";

  static String m15(count) =>
      "${Intl.plural(count, one: '${count} عُنْصُر', other: '${count} عَنَاصِر')}";

  static String m16(expiryTime) => " ستنتهي صَلاحية الرابط في ${expiryTime}";

  static String m17(familyAdminEmail) =>
      "يرجى الاتصال بـ${familyAdminEmail} لتغيير الكود الخاص بك.";

  static String m18(passwordStrengthValue) =>
      "قوة كلمة المرور: ${passwordStrengthValue}";

  static String m19(providerName) =>
      "يرجى التواصل مع دعم ${providerName} إذا تم خصم المبلغ منك.";

  static String m20(endDate) =>
      "النسخة التجريبية المجانية صالحة حتى ${endDate}.  \nيمكنك اختيار خُطَّة مدفوعة بعد ذلك.";

  static String m21(storeName) => "قيّمنا على ${storeName}";

  static String m22(storageInGB) =>
      "3. يحصل كلاكما على ${storageInGB} GB* مجانًا";

  static String m23(userEmail) =>
      "سيتم إزالة ${userEmail} من هذا الألبوم المشترك\n\nسيتم أيضًا إزالة أي صور أضافوها إلى الألبوم";

  static String m24(endDate) => "يتم تجديد الاشتراك في ${endDate}";

  static String m25(count) => "تم اختيار ${count}";

  static String m26(count, yourCount) =>
      "تم اختيار ${count} (${yourCount} منها لك)";

  static String m27(verificationID) =>
      "إليك معرف التحقق: ${verificationID} لـ ente.io.";

  static String m28(verificationID) =>
      "مرحبًا، هل يمكنك تأكيد أن هذا هو معرف التحقق الخاص بك على ente.io: ${verificationID}";

  static String m29(referralCode, referralStorageInGB) =>
      "رمز إحالة Ente: ${referralCode}\n\nطبّقه في قسم الإعدادات → عام → الإحالات للحصول على ${referralStorageInGB} GB مجانية بعد الاشتراك في خُطَّة مدفوعة.\n\nhttps://ente.io";

  static String m30(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'مشاركة مع أشخاص مُحددين', one: 'مُشارَك مع شخص واحد', other: 'مُشارَك مع ${numberOfPeople} أشخاص')}";

  static String m31(fileType) => "سيتم حذف ${fileType} من جهازك.";

  static String m32(fileType) => "${fileType} موجود في كلٍ من Ente وجهازك.";

  static String m33(fileType) => "سيتم حذف ${fileType} من Ente.";

  static String m34(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m35(id) =>
      "تم ربط ${id} الخاص بك بحساب Ente آخر.  \nإذا كنت ترغب في استخدام ${id} مع هذا الحساب، يرجى الاتصال بدعمنا.";

  static String m36(endDate) => "سيتم إلغاء اشتراكك في ${endDate}";

  static String m37(storageAmountInGB) =>
      "سيحصلون أيضًا على ${storageAmountInGB} GB";

  static String m38(email) => "هذا هو معرف التحقق الخاص بـ ${email}";

  static String m39(endDate) => "صالِح حتى ${endDate}";

  static String m40(email) => "التحقق من ${email}";

  static String m41(email) => "أرسلنا بريدًا إلى <green>${email}</green>";

  static String m42(count) =>
      "${Intl.plural(count, one: 'قبل ${count} سنة', two: 'قبل ${count} سنتين', other: 'قبل ${count} سنوات')}";

  static String m43(storageSaved) => "تم تحرير ${storageSaved} بنجاح!";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aNewVersionOfEnteIsAvailable":
            MessageLookupByLibrary.simpleMessage("يتوفر إصدار جديد من Ente."),
        "about": MessageLookupByLibrary.simpleMessage("حول"),
        "account": MessageLookupByLibrary.simpleMessage("الحساب"),
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("مرحبًا مجددًا!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "أُدركُ أنّني فقدتُ كلمة مروري، فقد أفقد بياناتي لأن بياناتي <underline>مشفرة تشفيرًا تامًّا من النهاية إلى النهاية</underline>."),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("الجلسات النشطة"),
        "addANewEmail":
            MessageLookupByLibrary.simpleMessage("إضافة بريد إلكتروني جديد"),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("إضافة مُشارِك"),
        "addMore": MessageLookupByLibrary.simpleMessage("إضافة المزيد"),
        "addOnValidTill": m0,
        "addViewer": MessageLookupByLibrary.simpleMessage("إضافة مُشاهد"),
        "addedAs": MessageLookupByLibrary.simpleMessage("إضافة كـ"),
        "addingToFavorites":
            MessageLookupByLibrary.simpleMessage("جارٍ إضافتها إلى المفضلة..."),
        "advanced": MessageLookupByLibrary.simpleMessage("خيارات متقدمة"),
        "advancedSettings":
            MessageLookupByLibrary.simpleMessage("خيارات متقدمة"),
        "after1Day": MessageLookupByLibrary.simpleMessage("بعد يوم"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("بعد ساعة"),
        "after1Month": MessageLookupByLibrary.simpleMessage("بعد شهر"),
        "after1Week": MessageLookupByLibrary.simpleMessage("بعد أسبوع"),
        "after1Year": MessageLookupByLibrary.simpleMessage("بعد سنة"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("المالك"),
        "albumParticipantsCount": m1,
        "albumUpdated":
            MessageLookupByLibrary.simpleMessage("تم تحديث الألبوم"),
        "albums": MessageLookupByLibrary.simpleMessage("الألبومات"),
        "allClear": MessageLookupByLibrary.simpleMessage("✨ كل شيء واضح"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "السماح للأشخاص الذين لديهم الرابط بإضافة صور إلى الألبوم المشترك أيضًا."),
        "allowAddingPhotos":
            MessageLookupByLibrary.simpleMessage("السماح بإضافة صور"),
        "allowDownloads":
            MessageLookupByLibrary.simpleMessage("السماح بالتنزيلات"),
        "allowPermBody": MessageLookupByLibrary.simpleMessage(
            "يرجى السماح بالوصول إلى صورك من الإعدادات حتى يتمكن Ente من عرض نسختك الاحتياطية ومكتبتك."),
        "allowPermTitle":
            MessageLookupByLibrary.simpleMessage("السماح بالوصول إلى الصور"),
        "androidIosWebDesktop": MessageLookupByLibrary.simpleMessage(
            "أندرويد، آي أو إس، ويب، سطح المكتب"),
        "appleId": MessageLookupByLibrary.simpleMessage("معرف آبل"),
        "apply": MessageLookupByLibrary.simpleMessage("تطبيق"),
        "applyCodeTitle": MessageLookupByLibrary.simpleMessage("تطبيق الكود"),
        "appstoreSubscription":
            MessageLookupByLibrary.simpleMessage("اشتراك متجر التطبيقات"),
        "archive": MessageLookupByLibrary.simpleMessage("أرشفة"),
        "areYouSureThatYouWantToLeaveTheFamily":
            MessageLookupByLibrary.simpleMessage(
                "هل أنت متأكد من مغادرة الخطة العائلية؟"),
        "areYouSureYouWantToCancel":
            MessageLookupByLibrary.simpleMessage("هل أنت متأكد من الإلغاء؟"),
        "areYouSureYouWantToChangeYourPlan":
            MessageLookupByLibrary.simpleMessage(
                "هل أنت متأكد أنك تريد تغيير خطتك؟"),
        "areYouSureYouWantToExit": MessageLookupByLibrary.simpleMessage(
            "هل أنت متأكد أنك تريد الخروج؟"),
        "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
            "هل أنت متأكد من أنك تريد تسجيل الخروج؟"),
        "areYouSureYouWantToRenew": MessageLookupByLibrary.simpleMessage(
            "هل أنت متأكد أنك تريد التجديد؟"),
        "askCancelReason": MessageLookupByLibrary.simpleMessage(
            "تم إلغاء اشتراكك. هل ترغب في مشاركة السبب؟"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "ما السبب الرئيسي وراء حذف حسابك؟"),
        "atAFalloutShelter": MessageLookupByLibrary.simpleMessage("في ملجأ"),
        "authToChangeEmailVerificationSetting":
            MessageLookupByLibrary.simpleMessage(
                "الرجاء التحقق من الهوية لتغيير إعدادات التحقق من البريد الإلكتروني"),
        "authToChangeLockscreenSetting": MessageLookupByLibrary.simpleMessage(
            "الرجاء المصادقة لتغيير إعدادات شاشة القُفْل"),
        "authToChangeYourEmail": MessageLookupByLibrary.simpleMessage(
            "الرجاء المصادقة لتغيير بريدك الإلكتروني"),
        "authToChangeYourPassword": MessageLookupByLibrary.simpleMessage(
            "الرجاء المصادقة لتغيير كلمة المرور الخاصة بك"),
        "authToConfigureTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "الرجاء المصادقة لإعداد التحقق بخطوتين"),
        "authToInitiateAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "الرجاء المصادقة لبدء حذف الحساب"),
        "authToViewTrashedFiles": MessageLookupByLibrary.simpleMessage(
            "الرجاء التحقق من الهوية لعرض الملفات المحذوفة الخاصة بك."),
        "authToViewYourActiveSessions": MessageLookupByLibrary.simpleMessage(
            "الرجاء المصادقة لعرض جلساتك النشطة"),
        "authToViewYourHiddenFiles": MessageLookupByLibrary.simpleMessage(
            "الرجاء التحقق من الهوية للوصول إلى الملفات المخفية الخاصة بك."),
        "authToViewYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "الرجاء المصادقة لعرض مفتاح الاسترداد الخاص بك"),
        "autoLogoutMessage": MessageLookupByLibrary.simpleMessage(
            "بسبب خلل تقني، تم تسجيل خروجك. نعتذر عن الإزعاج."),
        "available": MessageLookupByLibrary.simpleMessage("متوفر"),
        "backedUpFolders":
            MessageLookupByLibrary.simpleMessage("النسخ الاحتياطي للمجلدات"),
        "backup": MessageLookupByLibrary.simpleMessage("النسخ الاحتياطي"),
        "backupFailed":
            MessageLookupByLibrary.simpleMessage("فشل النسخ الاحتياطي"),
        "backupOverMobileData": MessageLookupByLibrary.simpleMessage(
            "النسخ الاحتياطي عبر بيانات الجوال"),
        "backupSettings":
            MessageLookupByLibrary.simpleMessage("إعدادات النسخ الاحتياطي"),
        "backupStatus":
            MessageLookupByLibrary.simpleMessage("حالة النسخ الاحتياطي"),
        "backupStatusDescription": MessageLookupByLibrary.simpleMessage(
            "العناصر التي تم النسخ الاحتياطي ستظهر هنا"),
        "backupVideos":
            MessageLookupByLibrary.simpleMessage("نسخ احتياطي للفيديوهات"),
        "blog": MessageLookupByLibrary.simpleMessage("المدونة"),
        "canNotOpenBody": MessageLookupByLibrary.simpleMessage(
            "عذراً، لا يمكن فتح هذا الألبوم في التطبيق."),
        "canNotOpenTitle":
            MessageLookupByLibrary.simpleMessage("لا يمكن فتح هذا الألبوم"),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
            "يمكن فقط إزالة الملفات التي تملكها"),
        "cancel": MessageLookupByLibrary.simpleMessage("إلغاء"),
        "cancelOtherSubscription": m2,
        "cancelSubscription":
            MessageLookupByLibrary.simpleMessage("إلغاء الاشتراك"),
        "cannotAddMorePhotosAfterBecomingViewer": m3,
        "cannotDeleteSharedFiles": MessageLookupByLibrary.simpleMessage(
            "لا يمكن حذف الملفات المشتركة"),
        "change": MessageLookupByLibrary.simpleMessage("تغيير"),
        "changeEmail":
            MessageLookupByLibrary.simpleMessage("تغيير البريد الإلكتروني"),
        "changePassword":
            MessageLookupByLibrary.simpleMessage("تغيير كلمة المرور"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("تغيير كلمة المرور"),
        "changePermissions":
            MessageLookupByLibrary.simpleMessage("تغيير الصلاحيّة؟"),
        "changeYourReferralCode":
            MessageLookupByLibrary.simpleMessage("تغيير رمز الإحالة الخاص بك"),
        "checkForUpdates":
            MessageLookupByLibrary.simpleMessage("التحقق من التحديثات"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "تفقد بريدك الوارد والمجلد العشوائي (Spam) لإكمال التحقق"),
        "checkStatus": MessageLookupByLibrary.simpleMessage("التحقق من الحالة"),
        "checking": MessageLookupByLibrary.simpleMessage("جارٍ التحقق..."),
        "claimFreeStorage":
            MessageLookupByLibrary.simpleMessage("المطالبة بتخزين مجاني"),
        "claimMore": MessageLookupByLibrary.simpleMessage("المطالبة بالمزيد!"),
        "claimed": MessageLookupByLibrary.simpleMessage("تم الاستلام"),
        "claimedStorageSoFar": m4,
        "clearIndexes": MessageLookupByLibrary.simpleMessage("مسح الفِهرِس"),
        "codeAppliedPageTitle":
            MessageLookupByLibrary.simpleMessage("تم تطبيق الكود"),
        "codeChangeLimitReached": MessageLookupByLibrary.simpleMessage(
            "عذرًا، لقد تجاوزت الحد المسموح لتعديلات الكود."),
        "codeCopiedToClipboard":
            MessageLookupByLibrary.simpleMessage("تم نسخ الرمز إلى الحافظة"),
        "codeUsedByYou":
            MessageLookupByLibrary.simpleMessage("الرمز المُستخدم من قبلك"),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
            "أنشئ رابطًا يسمح للأشخاص بإضافة الصور ومشاهدتها في ألبومك المشترك دون الحاجة إلى تطبيق Ente أو حساب. خِيار مثالي لجمع صور الفعاليات بسهولة."),
        "collaborativeLink":
            MessageLookupByLibrary.simpleMessage("رابط تعاوني"),
        "collaborator": MessageLookupByLibrary.simpleMessage("مُشارِك"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "المُشارِكون يَستطيعون إضافة صور وفيديوهات للألبوم المشترك."),
        "collectPhotos": MessageLookupByLibrary.simpleMessage("جمع الصور"),
        "confirm": MessageLookupByLibrary.simpleMessage("تأكيد"),
        "confirm2FADisable": MessageLookupByLibrary.simpleMessage(
            "هل أنت متأكد من أنك تريد تعطيل التحقق بخطوتين؟"),
        "confirmAccountDeletion":
            MessageLookupByLibrary.simpleMessage("تأكيد حذف الحساب"),
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "نعم، أريد حذف هذا الحساب وبياناته نهائيًا من جميع التطبيقات."),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("أَكِد كلمة المرور"),
        "confirmPlanChange":
            MessageLookupByLibrary.simpleMessage("تأكيد تغيير الخُطَّة"),
        "confirmRecoveryKey":
            MessageLookupByLibrary.simpleMessage("تأكيد مفتاح الاستِردادِ"),
        "confirmYourRecoveryKey":
            MessageLookupByLibrary.simpleMessage("تأكيد مفتاح الاستِردادِ"),
        "contactFamilyAdmin": m5,
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("الاتصال بالدعم"),
        "contactToManageSubscription": m6,
        "continueLabel": MessageLookupByLibrary.simpleMessage("المتابعة"),
        "continueOnFreeTrial": MessageLookupByLibrary.simpleMessage(
            "الاستمرار في التجربة المجانية"),
        "copyLink": MessageLookupByLibrary.simpleMessage("نسخ الرابط"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "انسخ هذا الرمز وألصقه\n في تطبيق المصادقة الخاص بك"),
        "couldNotBackUpTryLater": MessageLookupByLibrary.simpleMessage(
            "لم نتمكن من نسخ بياناتك احتياطيًا.  \nسنعيد المحاولة لاحقًا."),
        "couldNotUpdateSubscription":
            MessageLookupByLibrary.simpleMessage("تعذر تحديث الاشتراك"),
        "createAccount": MessageLookupByLibrary.simpleMessage("أنشئ حسابًا"),
        "createAlbumActionHint": MessageLookupByLibrary.simpleMessage(
            "اضغط مطولاً لتحديد الصور وانقر + لإنشاء مجموعة الصور"),
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("أنشئ حسابًا جديدًا"),
        "createPublicLink":
            MessageLookupByLibrary.simpleMessage("إنشاء رابط عام"),
        "creatingLink":
            MessageLookupByLibrary.simpleMessage("جارٍ إنشاء الرابط..."),
        "criticalUpdateAvailable":
            MessageLookupByLibrary.simpleMessage("يتوفر تحديث هام"),
        "curatedMemories":
            MessageLookupByLibrary.simpleMessage("Curated memories"),
        "currentUsageIs":
            MessageLookupByLibrary.simpleMessage("استخدامك الحالي هو"),
        "custom": MessageLookupByLibrary.simpleMessage("مُخصّص"),
        "darkTheme": MessageLookupByLibrary.simpleMessage("داكن"),
        "decrypting": MessageLookupByLibrary.simpleMessage("فك التشفير..."),
        "deleteAccount": MessageLookupByLibrary.simpleMessage("حذف الحساب"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "نحن آسفون لرؤيتك تذهب. يرجى مشاركة ملاحظاتك لمساعدتنا على التحسن."),
        "deleteAccountPermanentlyButton":
            MessageLookupByLibrary.simpleMessage("حذف الحساب نهائيًا"),
        "deleteAlbum": MessageLookupByLibrary.simpleMessage("حذف ألبوم"),
        "deleteAlbumDialog": MessageLookupByLibrary.simpleMessage(
            "هل ترغب أيضًا في حذف الصور (والفيديوهات) الموجودة في هذا الألبوم من <bold>جميع</bold> الألبومات الأخرى التي تَظهر فيها؟"),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "أرسل بريدًا إلى <warning>account-deletion@ente.io</warning> من بريدك المسجَّل."),
        "deleteFromBoth":
            MessageLookupByLibrary.simpleMessage("الحذف من كلاهما"),
        "deleteFromDevice":
            MessageLookupByLibrary.simpleMessage("حذف من الجهاز"),
        "deleteFromEnte": MessageLookupByLibrary.simpleMessage("حذف من Ente"),
        "deleteItemCount": m7,
        "deletePhotos": MessageLookupByLibrary.simpleMessage("حذف الصور"),
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
            "هناك مِيزة أساسية ناقصة أحتاج إليها"),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
            "التطبيق أو مِيزة معينة لا تعمل بالطريقة التي ينبغي أن تعمل بها"),
        "deleteReason3":
            MessageLookupByLibrary.simpleMessage("وجدت خدمة أخرى أفضلها"),
        "deleteReason4":
            MessageLookupByLibrary.simpleMessage("السبب الذي أريده غير مذكور"),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
            "سيتم معالجة طلبك خلال 72 ساعة."),
        "deleteSharedAlbum":
            MessageLookupByLibrary.simpleMessage("حذف الألبوم المشترك؟"),
        "deleteSharedAlbumDialogBody": MessageLookupByLibrary.simpleMessage(
            "سيتم حذف الألبوم للجميع.\n\nستفقد الوصول إلى الصور المشتركة في هذا الألبوم التي يملكها الآخرون"),
        "designedToOutlive":
            MessageLookupByLibrary.simpleMessage("مصممة لتدوم"),
        "details": MessageLookupByLibrary.simpleMessage("تفاصيل"),
        "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
            "عطِّل قُفْل شاشة الجهاز عندما يكون تطبيق Ente يعمل في المقدمة ويجري نسخ احتياطي.\nهذا الإجراء غير مطلوب عادةً، لكنه قد يُسَرِّع إكمال عمليات التحميل الكبيرة أو الاستيرادات الأولية للمكتبات الضخمة."),
        "disableAutoLock":
            MessageLookupByLibrary.simpleMessage("تعطيل القُفْل التلقائي"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "يستطيع المشاهدون التقاط لقطات شاشة أو حفظ نسخة من صورك باستخدام أدوات خارجية"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("يرجى ملاحظة"),
        "disableLinkMessage": m8,
        "disableTwofactor":
            MessageLookupByLibrary.simpleMessage("تعطيل التحقق بخطوتين"),
        "discord": MessageLookupByLibrary.simpleMessage("ديسكورد"),
        "discover": MessageLookupByLibrary.simpleMessage("اكتشف"),
        "discover_babies": MessageLookupByLibrary.simpleMessage("أطفال"),
        "discover_celebrations":
            MessageLookupByLibrary.simpleMessage("الاحتفالات"),
        "discover_food": MessageLookupByLibrary.simpleMessage("طعام"),
        "discover_greenery":
            MessageLookupByLibrary.simpleMessage("المساحات الخضراء"),
        "discover_hills": MessageLookupByLibrary.simpleMessage("السهول"),
        "discover_identity": MessageLookupByLibrary.simpleMessage("الهويّة"),
        "discover_memes": MessageLookupByLibrary.simpleMessage("ميمز"),
        "discover_notes": MessageLookupByLibrary.simpleMessage("ملاحظات"),
        "discover_pets":
            MessageLookupByLibrary.simpleMessage("الحيوانات الأليفة"),
        "discover_receipts": MessageLookupByLibrary.simpleMessage("إيصالات"),
        "discover_screenshots":
            MessageLookupByLibrary.simpleMessage("لقطات الشّاشة"),
        "discover_selfies": MessageLookupByLibrary.simpleMessage("سيلفيان"),
        "discover_sunset": MessageLookupByLibrary.simpleMessage("غروب الشمس"),
        "discover_visiting_cards":
            MessageLookupByLibrary.simpleMessage("بطاقات الزيارة"),
        "discover_wallpapers": MessageLookupByLibrary.simpleMessage("خلفيات"),
        "doThisLater": MessageLookupByLibrary.simpleMessage("افعل هذا لاحقًا"),
        "done": MessageLookupByLibrary.simpleMessage("تمّ"),
        "downloading": MessageLookupByLibrary.simpleMessage("جارِ التحميل..."),
        "dropSupportEmail": m9,
        "duplicateFileCountWithStorageSaved": m10,
        "duplicateItemsGroup": m11,
        "eligible": MessageLookupByLibrary.simpleMessage("مُؤهل"),
        "email": MessageLookupByLibrary.simpleMessage("البريد الإلكتروني"),
        "emailAlreadyRegistered": MessageLookupByLibrary.simpleMessage(
            "البريد الإلكتروني مُسجل من قبل."),
        "emailNoEnteAccount": m12,
        "emailNotRegistered":
            MessageLookupByLibrary.simpleMessage("البريد الإلكتروني غير مسجل."),
        "emailVerificationToggle": MessageLookupByLibrary.simpleMessage(
            "تأكيد عنوان البريد الإلكتروني"),
        "encryption": MessageLookupByLibrary.simpleMessage("التشفير"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("مفاتيح التشفير"),
        "endtoendEncryptedByDefault": MessageLookupByLibrary.simpleMessage(
            "تشفير من طرف إلى طرف بشكل افتراضي"),
        "enteCanEncryptAndPreserveFilesOnlyIfYouGrant":
            MessageLookupByLibrary.simpleMessage(
                "يمكن لـ Ente تشفير وحفظ الملفات فقط إذا منحت حق الوصول إليها"),
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
            "Ent <i>يحتاج إلى إذن ل</i> لحفظ صورك"),
        "enteSubscriptionPitch": MessageLookupByLibrary.simpleMessage(
            "يحفظ Ente ذكرياتك، لذا ستظل دائمًا متاحة لك حتى لو فقدت جهازك."),
        "enteSubscriptionShareWithFamily": MessageLookupByLibrary.simpleMessage(
            "من الممكن إضافة عائلتك إلى خطتك أيضاً."),
        "enterCode": MessageLookupByLibrary.simpleMessage("أدخل الرمز"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
            "أدخل الرمز المقدم من صديقك للمطالبة بتخزين مجاني لكما"),
        "enterEmail":
            MessageLookupByLibrary.simpleMessage("أختر بريد إلكتروني"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "أدخل كلمة مرور جديدة يمكننا استخدامها لتشفير بياناتك"),
        "enterPassword":
            MessageLookupByLibrary.simpleMessage("أدخل كلمة المرور"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "أدخل كلمة مرور يمكننا استخدامها لتشفير بياناتك"),
        "enterReferralCode":
            MessageLookupByLibrary.simpleMessage("أدخل رمز الإحالة"),
        "enterThe6digitCodeFromnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "أدخِل الرمز المكوَّن من 6 أرقام مِن\n تطبيق المُصادقة الخاص بك"),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
            "الرجاء إدخال بريد إلكتروني صالح."),
        "enterYourEmailAddress":
            MessageLookupByLibrary.simpleMessage("أدخل عنوان بريدك الإلكتروني"),
        "enterYourPassword":
            MessageLookupByLibrary.simpleMessage("أدخل كلمة المرور"),
        "enterYourRecoveryKey":
            MessageLookupByLibrary.simpleMessage("أدخل رمز الاسترداد"),
        "everywhere": MessageLookupByLibrary.simpleMessage("أي مكان"),
        "existingUser": MessageLookupByLibrary.simpleMessage("مستخدم سابق"),
        "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
            "انتهت صَلاحِيَة هذا الرابط. يرجى اختيار وقت جديد لانتهاء الصَّلاحِيَة أو تعطيل انتهاء صَلاحِيَة الرابط."),
        "exportYourData":
            MessageLookupByLibrary.simpleMessage("صَدِّر بياناتك"),
        "failedToApplyCode":
            MessageLookupByLibrary.simpleMessage("فشل في تطبيق الكود"),
        "failedToCancel": MessageLookupByLibrary.simpleMessage("فشل إلغاء"),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
            "تعذّر استرجاع تفاصيل الإحالة. يُرجى المحاولة مرة أخرى لاحقًا."),
        "failedToLoadAlbums":
            MessageLookupByLibrary.simpleMessage("تعذّر تحميل الألبومات"),
        "failedToRenew": MessageLookupByLibrary.simpleMessage("فشل التجديد"),
        "failedToVerifyPaymentStatus":
            MessageLookupByLibrary.simpleMessage("فشل التحقق من حالة الدفع"),
        "familyPlans": MessageLookupByLibrary.simpleMessage("الخطط العائلية"),
        "faq": MessageLookupByLibrary.simpleMessage("الأسئلة الشائعة"),
        "faqs": MessageLookupByLibrary.simpleMessage("الأسئلة الشائعة"),
        "feedback": MessageLookupByLibrary.simpleMessage("ملاحظات"),
        "forYourMemories": MessageLookupByLibrary.simpleMessage("لذكرياتك"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("نسيت كلمة المرور"),
        "freeStorageClaimed":
            MessageLookupByLibrary.simpleMessage("تمت مطالبة التخزين المجاني"),
        "freeStorageOnReferralSuccess": m13,
        "freeStorageUsable":
            MessageLookupByLibrary.simpleMessage("مساحة تخزين مجانية مُتاحة"),
        "freeTrial": MessageLookupByLibrary.simpleMessage("تجرِبة مجانية"),
        "freeTrialValidTill": m14,
        "freeUpDeviceSpace":
            MessageLookupByLibrary.simpleMessage("تحرير مساحة الجهاز"),
        "freeUpDeviceSpaceDesc": MessageLookupByLibrary.simpleMessage(
            "وفر مساحة على جهازك بمسح الملفات التي تم نسخها احتياطيًا."),
        "general": MessageLookupByLibrary.simpleMessage("العامّة"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "جاري توليد مفاتيح التشفير..."),
        "googlePlayId": MessageLookupByLibrary.simpleMessage("معرف جوجل بلاي"),
        "grantFullAccessPrompt": MessageLookupByLibrary.simpleMessage(
            "الرجاء السماح بالوصول إلى جميع الصور في تطبيق الإعدادات"),
        "grantPermission": MessageLookupByLibrary.simpleMessage("منح الأذن"),
        "help": MessageLookupByLibrary.simpleMessage("مساعدة"),
        "hidden": MessageLookupByLibrary.simpleMessage("المخفية"),
        "howItWorks": MessageLookupByLibrary.simpleMessage("كيف يعمل"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
            "الرجاء أن تطلب منهم الضغط مطولًا على عنوان بريدهم الإلكتروني في شاشة الإعدادات، والتأكد من تطابُق هويات الأجهزة على كلا الجهازين."),
        "ignoreUpdate": MessageLookupByLibrary.simpleMessage("تجاهل"),
        "importing": MessageLookupByLibrary.simpleMessage("جارِ الاستيراد...."),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("كلمة المرور غير صحيحة"),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "مفتاح الاسترداد الذي أدخلته غير صحيح"),
        "incorrectRecoveryKeyTitle":
            MessageLookupByLibrary.simpleMessage("مفتاح الاسترداد غير صحيح"),
        "indexedItems":
            MessageLookupByLibrary.simpleMessage("العناصر المفهرسة"),
        "insecureDevice": MessageLookupByLibrary.simpleMessage("جهاز غير آمن"),
        "installManually": MessageLookupByLibrary.simpleMessage("تثبيت يدويًا"),
        "invalidEmailAddress": MessageLookupByLibrary.simpleMessage(
            "عنوان البريد الإلكتروني غير صالح"),
        "invalidKey": MessageLookupByLibrary.simpleMessage("المفتاح غير صالح"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "مفتاح الاستِردادِ الذي أدخلته غير صالح. يرجى التأكد من أنه يحتوي على 24 كلمة، وتحقق من كتابة كل كلمة بشكل صحيح.\n\nإذا كنت تستخدم رمز استرداد قديمًا، تأكد من أنه مكون من 64 حرفًا، وتحقق من صحة كل حرف."),
        "inviteToEnte": MessageLookupByLibrary.simpleMessage("دعوة لإنهاء"),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("أدعُ أصدقائك"),
        "itemCount": m15,
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
            "سيتم إزالة العناصر المحددة من هذا الألبوم"),
        "keepPhotos": MessageLookupByLibrary.simpleMessage("الاحتفاظ بالصور"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "الرجاء مساعدتنا بهذه المعلومات"),
        "leave": MessageLookupByLibrary.simpleMessage("مغادرة"),
        "leaveFamily":
            MessageLookupByLibrary.simpleMessage("مغادرة خطة العائلة"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("فاتح"),
        "linkDeviceLimit": MessageLookupByLibrary.simpleMessage("حد الأجهزة"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("مفعل"),
        "linkExpired":
            MessageLookupByLibrary.simpleMessage("منتهية الصَّلاحِيَة"),
        "linkExpiresOn": m16,
        "linkExpiry":
            MessageLookupByLibrary.simpleMessage("انتهت صَلاحِية الرابط"),
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("انتهت صَلاحِيَة الرابط"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("أبدًا"),
        "loadingModel":
            MessageLookupByLibrary.simpleMessage("جاري تحميل النماذج..."),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("قُفْل"),
        "lockscreen": MessageLookupByLibrary.simpleMessage("شاشة القُفْل"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("تسجيل الدخول"),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "بالنقر على تسجيل الدخول، أوافق على شروط الخدمة <u-terms></u-terms> و <u-policy>سياسة الخصوصية</u-policy>"),
        "logout": MessageLookupByLibrary.simpleMessage("تسجيل الخروج"),
        "lostDevice": MessageLookupByLibrary.simpleMessage("جهاز مفقود؟"),
        "machineLearning": MessageLookupByLibrary.simpleMessage("التعلم الآلي"),
        "magicSearch": MessageLookupByLibrary.simpleMessage("بحث سحريّ"),
        "manage": MessageLookupByLibrary.simpleMessage("إدارة"),
        "manageDeviceStorage": MessageLookupByLibrary.simpleMessage(
            "إدارة ذاكرة التخزين المؤقت للجهاز"),
        "manageDeviceStorageDesc": MessageLookupByLibrary.simpleMessage(
            "مراجعة ومسح ذاكرة التخزين المؤقت المحلية."),
        "manageFamily": MessageLookupByLibrary.simpleMessage("إدارة العائلة"),
        "manageLink": MessageLookupByLibrary.simpleMessage(" إدارة الرابط"),
        "manageParticipants": MessageLookupByLibrary.simpleMessage("إدارة"),
        "manageSubscription":
            MessageLookupByLibrary.simpleMessage("إدارة الإشراك"),
        "mastodon": MessageLookupByLibrary.simpleMessage("ماستودون"),
        "matrix": MessageLookupByLibrary.simpleMessage("ماتركس"),
        "merchandise": MessageLookupByLibrary.simpleMessage("المنتجات"),
        "mlConsent": MessageLookupByLibrary.simpleMessage("تفعيل التعلم الآلي"),
        "mlConsentConfirmation": MessageLookupByLibrary.simpleMessage(
            "أنا أفهم، وأريد تفعيل التعلم الآلي"),
        "mlConsentDescription": MessageLookupByLibrary.simpleMessage(
            "إذا قمت بتفعيل التعلم الآلي، فإن تطبيق Ente سيقوم باستخلاص معلومات مثل هيئة الوجه من الملفات، بما في ذلك تلك التي تمت مشاركتها معك.\n\nهذا الإجراء سيتم على جهازك مباشرةً، وأي معلومات بيومترية مُنشأة ستكون مشفرةً من طرف إلى طرف."),
        "mlConsentPrivacy": MessageLookupByLibrary.simpleMessage(
            "الرجاء النقر هنا لمعرفة تفاصيل أكثر حول هذه المِيزة في سياسة الخصوصية الخاصة بنا"),
        "mlConsentTitle":
            MessageLookupByLibrary.simpleMessage("هل تريد تفعيل التعلم الآلي؟"),
        "mlIndexingDescription": MessageLookupByLibrary.simpleMessage(
            "يرجى ملاحظة أن التعلم الآلي سيؤدي إلى استهلاكًا أعلى لسعة النطاق الترددي واستهلاك البطارية حتى يتم فهرسة جميع العناصر.\nننصح باستخدام تطبيق الحاسوب لإجراء الفهرسة بسرعة أكبر. سيتم مزامنة جميع النتائج تلقائيًا."),
        "mobileWebDesktop":
            MessageLookupByLibrary.simpleMessage("الجوال، الويب، سطح المكتب"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("متوسط"),
        "monthly": MessageLookupByLibrary.simpleMessage("شهريّا"),
        "movedToTrash":
            MessageLookupByLibrary.simpleMessage("نُقلت إلى سلة المهملات"),
        "never": MessageLookupByLibrary.simpleMessage("أبدًا"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("ألبوم جديد"),
        "newToEnte": MessageLookupByLibrary.simpleMessage("جديد إلى Ente"),
        "no": MessageLookupByLibrary.simpleMessage("لا"),
        "noDeviceLimit": MessageLookupByLibrary.simpleMessage("لا شَيْء"),
        "noDeviceThatCanBeDeleted": MessageLookupByLibrary.simpleMessage(
            "ليس لديك ملفات على هذا الجهاز يمكن حذفها"),
        "noDuplicates":
            MessageLookupByLibrary.simpleMessage("✨ لا توجد ملفات مكررة"),
        "noPhotosAreBeingBackedUpRightNow":
            MessageLookupByLibrary.simpleMessage(
                "لا يتم حاليًا نسخ الصور احتياطيًا."),
        "noRecoveryKey":
            MessageLookupByLibrary.simpleMessage("ما من مفتاح استرداد؟"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "لا يمكن فك تشفير بياناتك دون كلمة المرور أو مفتاح الاسترداد بسبب طبيعة بروتوكول التشفير الخاص بنا من النهاية إلى النهاية"),
        "notifications": MessageLookupByLibrary.simpleMessage("الإشعارات"),
        "ok": MessageLookupByLibrary.simpleMessage("حسنًا"),
        "onlyFamilyAdminCanChangeCode": m17,
        "oops": MessageLookupByLibrary.simpleMessage("عذرًا"),
        "oopsSomethingWentWrong":
            MessageLookupByLibrary.simpleMessage("عذرًا، حدث خطأ ما"),
        "openSettings": MessageLookupByLibrary.simpleMessage("فتح الإعدادات"),
        "optionalAsShortAsYouLike":
            MessageLookupByLibrary.simpleMessage("اختياري، قصير كما تريد..."),
        "orPickAnExistingOne": MessageLookupByLibrary.simpleMessage(
            "أو اختر واحدًا موجودًا مسبقًا"),
        "password": MessageLookupByLibrary.simpleMessage("كلمة المُرور"),
        "passwordChangedSuccessfully":
            MessageLookupByLibrary.simpleMessage("تم تغيير كلمة المرور بنجاح"),
        "passwordLock": MessageLookupByLibrary.simpleMessage("قُفْل بكلة مرور"),
        "passwordStrength": m18,
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "نحن لا نقوم بتخزين كلمة المرور هذه، لذا إذا نسيتها، <underline>لا يمكننا فك تشفير بياناتك</underline>"),
        "paymentDetails": MessageLookupByLibrary.simpleMessage("تفاصيل الدفع"),
        "paymentFailed":
            MessageLookupByLibrary.simpleMessage("فشلت عملية الدفع"),
        "paymentFailedMessage": MessageLookupByLibrary.simpleMessage(
            "للأسف فشلت عملية الدفع الخاصة بك. يرجى الاتصال بالدعم وسوف نساعدك!"),
        "paymentFailedTalkToProvider": m19,
        "pendingItems":
            MessageLookupByLibrary.simpleMessage("العناصر المعلَّقة"),
        "peopleUsingYourCode":
            MessageLookupByLibrary.simpleMessage("مستخدمُو رمزك"),
        "photoGridSize":
            MessageLookupByLibrary.simpleMessage("حجم  أعمدة الصور"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("صور"),
        "playStoreFreeTrialValidTill": m20,
        "playstoreSubscription":
            MessageLookupByLibrary.simpleMessage("الاشتراك في متجر بلاي"),
        "pleaseContactSupportAndWeWillBeHappyToHelp":
            MessageLookupByLibrary.simpleMessage(
                "يرجى التواصل مع support@ente.io وسنكون سعداء بمساعدتك!"),
        "pleaseGrantPermissions":
            MessageLookupByLibrary.simpleMessage("الرجاء منح الأذونات"),
        "pleaseLoginAgain": MessageLookupByLibrary.simpleMessage(
            "الرجاء تسجيل الدخول مرة أخرى"),
        "pleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("يرجى المحاولة مرة أخرى"),
        "pleaseWait": MessageLookupByLibrary.simpleMessage("انتظر قليلاً..."),
        "pleaseWaitForSometimeBeforeRetrying":
            MessageLookupByLibrary.simpleMessage(
                "الرجاء الانتظار لبعض الوقت قبل إعادة المحاولة"),
        "preserveMore":
            MessageLookupByLibrary.simpleMessage("الاحتفاظ بالمزيد"),
        "privacy": MessageLookupByLibrary.simpleMessage("الخصوصية"),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("سياسة الخصوصية"),
        "privateBackups":
            MessageLookupByLibrary.simpleMessage("نسخ احتياطية خاصة"),
        "privateSharing": MessageLookupByLibrary.simpleMessage("مشاركة خاصة"),
        "publicLinkEnabled":
            MessageLookupByLibrary.simpleMessage("تفعيل الرابط العام"),
        "raiseTicket": MessageLookupByLibrary.simpleMessage("ارفع التذكرة"),
        "rateTheApp": MessageLookupByLibrary.simpleMessage("قيّم التطبيق"),
        "rateUs": MessageLookupByLibrary.simpleMessage("امنحنا تقييمًا"),
        "rateUsOnStore": m21,
        "recover": MessageLookupByLibrary.simpleMessage("استعادة"),
        "recoverAccount":
            MessageLookupByLibrary.simpleMessage("استعادة الحساب"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("استرداد"),
        "recoveryKey": MessageLookupByLibrary.simpleMessage("مفتاح الاسترداد"),
        "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "تم نسخ مفتاح الاسترداد إلى الحافظة"),
        "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
            "إذا نسيت كلمة المرور الخاصة بك، فالطريقة الوحيدة التي يمكنك بها استرداد بياناتك هي بهذا المفتاح."),
        "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
            "لا نحتفظ بهذا المفتاح. الرجاء حِفظ مَفتاح 24 كلمة في مكانٍ آمن."),
        "recoveryKeySuccessBody": MessageLookupByLibrary.simpleMessage(
            "رائع! مفتاح الاستِردادِ الخاص بك صالح. شكرا لك على التحقق.\n\nيرجى تذكر الاحتفاظ بنسخة احتياطية من مفتاح الاسترداد بشكل آمن."),
        "recoveryKeyVerified": MessageLookupByLibrary.simpleMessage(
            "تم التحقق من مفتاح الاستِردادِ"),
        "recoveryKeyVerifyReason": MessageLookupByLibrary.simpleMessage(
            "مفتاح الاستِردادِ هو الطريقة الوحيدة لاستعادة صورك إذا نسيت كلمة المرور. يمكنك العثور على مفتاح الاسترداد في الإعدادات > الحساب.\n\nالرجاء إدخال مفتاح الاسترداد هنا للتحقق من أنك حفظته بشكل صحيح."),
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("نجح الاسترداد!"),
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "جهازك الحالي غير قادر على التحقق من كلمة المرور، لكننا نستطيع تعديلها لتعمل على جميع الأجهزة.\n\nسجِّل الدخول بمفتاح الاسترداد، ثم أنشئ كلمة مرور جديدة (يمكنك اختيار نفس الكلمة السابقة إذا أردت)."),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("إعادة كتابة كلمة المرور"),
        "reddit": MessageLookupByLibrary.simpleMessage("ريديت"),
        "referralStep1":
            MessageLookupByLibrary.simpleMessage("1. أعطِ هذا الكود لأصدقائك"),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
            "2. يُشتركون في خُطَّة مدفوعة"),
        "referralStep3": m22,
        "referrals": MessageLookupByLibrary.simpleMessage("الإحالات"),
        "referralsAreCurrentlyPaused":
            MessageLookupByLibrary.simpleMessage("الإحالات غير متاحة حاليًا"),
        "remindToEmptyDeviceTrash": MessageLookupByLibrary.simpleMessage(
            "كما يجب تفريغ \"المحذوفات مؤخرًا\" من \"الإعدادات\" -> \"التخزين\" لاستعادة المساحة المُحررة."),
        "remindToEmptyEnteTrash": MessageLookupByLibrary.simpleMessage(
            "كما يجب إفراغ \"سلة المهملات\" لاستعادة المساحة المُحررة."),
        "remove": MessageLookupByLibrary.simpleMessage("إزالة"),
        "removeDuplicates":
            MessageLookupByLibrary.simpleMessage("إزالة النسخ المكررة"),
        "removeDuplicatesDesc": MessageLookupByLibrary.simpleMessage(
            "راجع وأزل الملفات المتطابقة تمامًا."),
        "removeFromAlbum":
            MessageLookupByLibrary.simpleMessage("إزالة من ألبوم"),
        "removeFromAlbumTitle":
            MessageLookupByLibrary.simpleMessage("إزالة من الألبوم؟"),
        "removeLink": MessageLookupByLibrary.simpleMessage("إزالة "),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("إزالة مُشارِك"),
        "removeParticipantBody": m23,
        "removePublicLink":
            MessageLookupByLibrary.simpleMessage("إزالة الرابط العام"),
        "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
            "حذف عناصر أضافها مُستخدمون آخرون، سوف تفقد الوصول إليها"),
        "removeWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("إزالة؟"),
        "removingFromFavorites":
            MessageLookupByLibrary.simpleMessage("جارٍ إزالتها من المفضلة..."),
        "renewSubscription":
            MessageLookupByLibrary.simpleMessage("جدد الاشتراك"),
        "renewsOn": m24,
        "reportABug":
            MessageLookupByLibrary.simpleMessage("ألإبلاغ عن خلل تقني"),
        "reportBug": MessageLookupByLibrary.simpleMessage("الإبلاغ عن خلل"),
        "resendEmail": MessageLookupByLibrary.simpleMessage(
            "إعادة إرسال البريد الإلكتروني"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("إعادة تعيين كلمة المرور"),
        "retry": MessageLookupByLibrary.simpleMessage("أعد المحاولة"),
        "safelyStored": MessageLookupByLibrary.simpleMessage("تخزين آمن"),
        "saveKey": MessageLookupByLibrary.simpleMessage("حفظ المفتاح"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "أحفظ مفتاح الاستِردادِ إذا لم تكن قد حفِظتَهُ مُسبَقًا"),
        "scanCode": MessageLookupByLibrary.simpleMessage("فحص رمز"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "فحص البار كود باستخدام\nتطبيق المصادقة الخاص بك"),
        "security": MessageLookupByLibrary.simpleMessage("الأمان"),
        "selectAll": MessageLookupByLibrary.simpleMessage("حدد الكل"),
        "selectFoldersForBackup": MessageLookupByLibrary.simpleMessage(
            "حدد المجلدات للنسخ الاحتياطي"),
        "selectMorePhotos":
            MessageLookupByLibrary.simpleMessage("حدد المزيد من الصور"),
        "selectReason": MessageLookupByLibrary.simpleMessage("أختر سببًا"),
        "selectYourPlan": MessageLookupByLibrary.simpleMessage("اختر اشتراكك"),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
                "سيتم حماية المجلدات المحددة بالتشفير وحفظ نسخة احتياطية"),
        "selectedPhotos": m25,
        "selectedPhotosWithYours": m26,
        "send": MessageLookupByLibrary.simpleMessage("إرسال"),
        "sendEmail":
            MessageLookupByLibrary.simpleMessage("إرسال بريد إلكتروني"),
        "sendInvite": MessageLookupByLibrary.simpleMessage("إرسال دعوة"),
        "sendLink": MessageLookupByLibrary.simpleMessage("إرسال رابط"),
        "setAPassword": MessageLookupByLibrary.simpleMessage("تعيين كلمة مرور"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("تعيين كلمة المرور"),
        "setupComplete": MessageLookupByLibrary.simpleMessage("اكتمل الإعداد"),
        "shareALink": MessageLookupByLibrary.simpleMessage("مشاركة رابط"),
        "shareMyVerificationID": m27,
        "shareTextConfirmOthersVerificationID": m28,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "حمّل تطبيق Ente حتى نتمكن من مشاركة الصور ومقاطع الفيديو بالجودة الأصلية بسهولة\n\nhttps://ente.io"),
        "shareTextReferralCode": m29,
        "shareWithNonenteUsers":
            MessageLookupByLibrary.simpleMessage("مشاركة مع غير مستخدمي Ente"),
        "shareWithPeopleSectionTitle": m30,
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
            "أنشئ ألبومات مُشتركة وتَعاوُنية مع مُستخدمي Ente الآخرين، بما في ذلك المُستخدمين ذوي الاشتراكات المجانية."),
        "sharedPhotoNotifications":
            MessageLookupByLibrary.simpleMessage("الصور المشتركة الجديدة"),
        "sharedPhotoNotificationsExplanation": MessageLookupByLibrary.simpleMessage(
            "استلم إشعارات عندما يضيف شخص ما صورة إلى ألبوم مشترك أنت جزء منه."),
        "sharing": MessageLookupByLibrary.simpleMessage("جارٍ المشاركة..."),
        "showMemories": MessageLookupByLibrary.simpleMessage("إظهار الذكريات"),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "أوافق على <u-terms>شروط الخدمة</u-terms> و<u-policy>سياسة الخصوصية</u-policy>"),
        "singleFileDeleteFromDevice": m31,
        "singleFileDeleteHighlight":
            MessageLookupByLibrary.simpleMessage("سَيُحذَف من جميع الألبومات."),
        "singleFileInBothLocalAndRemote": m32,
        "singleFileInRemoteOnly": m33,
        "skip": MessageLookupByLibrary.simpleMessage("تخطّي"),
        "social": MessageLookupByLibrary.simpleMessage("وسائل التواصل"),
        "someoneSharingAlbumsWithYouShouldSeeTheSameId":
            MessageLookupByLibrary.simpleMessage(
                "يجب أن يرى أي شخص يشارك ألبومات معك نفس معرف التحقق على جهازه."),
        "somethingWentWrong":
            MessageLookupByLibrary.simpleMessage("لقد حدث خطأ ما"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "حدث خطأ ما، يرجى المحاولة مرة أخرى"),
        "sorry": MessageLookupByLibrary.simpleMessage("المعذرة"),
        "sorryCouldNotAddToFavorites": MessageLookupByLibrary.simpleMessage(
            "عذرًا، تعذرت إضافتها إلى المفضلة!"),
        "sorryCouldNotRemoveFromFavorites":
            MessageLookupByLibrary.simpleMessage(
                "عذرًا، تعذرت إضافتها إلى المفضلة!"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "عذرًا، لم نتمكن من إنشاء مفاتيح آمنة على هذا الجهاز.\n\nيرجى التسجيل من جهاز مختلف."),
        "sparkleSuccess": MessageLookupByLibrary.simpleMessage("✨ النجاح"),
        "startBackup":
            MessageLookupByLibrary.simpleMessage("حفظ نسخة احتياطية"),
        "status": MessageLookupByLibrary.simpleMessage("الحَالَة"),
        "storageInGB": m34,
        "storageLimitExceeded":
            MessageLookupByLibrary.simpleMessage("تم تجاوز حد التخزين"),
        "strongStrength": MessageLookupByLibrary.simpleMessage("قوي"),
        "subAlreadyLinkedErrMessage": m35,
        "subWillBeCancelledOn": m36,
        "subscribe": MessageLookupByLibrary.simpleMessage("اشترك"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
            "المشاركة مُتاحة فقط للاشتراكات المدفوعة النشطة."),
        "subscription": MessageLookupByLibrary.simpleMessage("الاشتراك"),
        "success": MessageLookupByLibrary.simpleMessage("تم بنجاح"),
        "suggestFeatures": MessageLookupByLibrary.simpleMessage("اقتراح مِيزة"),
        "support": MessageLookupByLibrary.simpleMessage("الدعم"),
        "systemTheme": MessageLookupByLibrary.simpleMessage("النظام"),
        "tapToCopy": MessageLookupByLibrary.simpleMessage("انقر للنسخ"),
        "tapToEnterCode":
            MessageLookupByLibrary.simpleMessage("انقر لإدخال الرمز"),
        "terminate": MessageLookupByLibrary.simpleMessage("إنهاء"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("إنهاء الجَلسةِ؟"),
        "terms": MessageLookupByLibrary.simpleMessage("الشروط"),
        "termsOfServicesTitle":
            MessageLookupByLibrary.simpleMessage("الشروط والأحكام"),
        "thankYou": MessageLookupByLibrary.simpleMessage("شكرًا لك"),
        "thankYouForSubscribing":
            MessageLookupByLibrary.simpleMessage("شكرا لك على الاشتراك!"),
        "theDownloadCouldNotBeCompleted":
            MessageLookupByLibrary.simpleMessage("تعذّر إكمال التنزيل"),
        "theme": MessageLookupByLibrary.simpleMessage("مظهر"),
        "theyAlsoGetXGb": m37,
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "يُمكن استخدامُ هذا المفتاح لاستعادةِ حسابِكَ إذا فقدتَ أداة التحققِ الثانِية"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("هذا الجهاز"),
        "thisIsPersonVerificationId": m38,
        "thisIsYourVerificationId":
            MessageLookupByLibrary.simpleMessage("هذا هو معرف التحقق الخاص بك"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "سيؤدي هذا إلى تسجيل خروجك من الجهاز التالي:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "سيؤدي هذا إلى تسجيل خروجك من هذا الجهاز!"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "لإعادة تعيين كلمة المرور، يرجى التحقق من بريدك الإلكتروني أولاً."),
        "total": MessageLookupByLibrary.simpleMessage("المجموع"),
        "trash": MessageLookupByLibrary.simpleMessage("سلة المهملات"),
        "tryAgain": MessageLookupByLibrary.simpleMessage("حاول مرة أخرى"),
        "twitter": MessageLookupByLibrary.simpleMessage("أكس"),
        "twoMonthsFreeOnYearlyPlans": MessageLookupByLibrary.simpleMessage(
            "شهرين مجانيين على الخطط السنوية."),
        "twofactor": MessageLookupByLibrary.simpleMessage("التحقق بخطوتين"),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage("التحقق بخطوتين"),
        "twofactorSetup":
            MessageLookupByLibrary.simpleMessage("إعداد التحقق بخطوتين"),
        "unavailableReferralCode":
            MessageLookupByLibrary.simpleMessage("عذراً، هذا الرمز غير متوفر."),
        "uncategorized": MessageLookupByLibrary.simpleMessage("غير مصنّف"),
        "unselectAll":
            MessageLookupByLibrary.simpleMessage("إلغاء اختيار الكلّ"),
        "update": MessageLookupByLibrary.simpleMessage("تحديث"),
        "updateAvailable": MessageLookupByLibrary.simpleMessage("تحديث متاح"),
        "updatingFolderSelection":
            MessageLookupByLibrary.simpleMessage("جارٍ تحديث اختيار المجلد..."),
        "upgrade": MessageLookupByLibrary.simpleMessage("ترقية"),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
            "التخزين القابل للاستخدام مُقيَّدٌ بخطتك الحالية.\nالمساحة التخزينية الزائدة التي تمت مطالبتها ستصبح قابلةً للاستخدام تلقائيًا عند ترقية خطتك."),
        "useRecoveryKey":
            MessageLookupByLibrary.simpleMessage("استخدم مفتاح الاسترداد"),
        "validTill": m39,
        "verificationId": MessageLookupByLibrary.simpleMessage("معرف التحقق"),
        "verify": MessageLookupByLibrary.simpleMessage("التحقّق"),
        "verifyEmail":
            MessageLookupByLibrary.simpleMessage("التحقق من البريد الإلكتروني"),
        "verifyEmailID": m40,
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("التحقق من كلمة المرور"),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "جارٍ التحقق من مفتاح الاستِردادِ..."),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("فيديو"),
        "viewActiveSessions":
            MessageLookupByLibrary.simpleMessage("عرض الجلسات النشطة"),
        "viewLargeFiles":
            MessageLookupByLibrary.simpleMessage("‮الملفات الكبيرة"),
        "viewLargeFilesDesc": MessageLookupByLibrary.simpleMessage(
            "عرض الملفات التي تستهلك أكبر قدر من التخزين."),
        "viewRecoveryKey":
            MessageLookupByLibrary.simpleMessage("عرض مفتاح الاستِردادِ"),
        "viewer": MessageLookupByLibrary.simpleMessage("المُشاهد"),
        "visitWebToManage": MessageLookupByLibrary.simpleMessage(
            "الرجاء زيارة web.ente.io لإدارة اشتراكك"),
        "waitingForWifi":
            MessageLookupByLibrary.simpleMessage("في انتظار شبكة WiFi..."),
        "weAreOpenSource":
            MessageLookupByLibrary.simpleMessage("نحن مفتوح المصدر!"),
        "weHaveSendEmailTo": m41,
        "weakStrength": MessageLookupByLibrary.simpleMessage("ضعيف"),
        "welcomeBack": MessageLookupByLibrary.simpleMessage("مرحبًا مجددًا!"),
        "yearly": MessageLookupByLibrary.simpleMessage("سنويًا"),
        "yearsAgo": m42,
        "yes": MessageLookupByLibrary.simpleMessage("نعم"),
        "yesCancel": MessageLookupByLibrary.simpleMessage("نعم، إلغاء"),
        "yesConvertToViewer":
            MessageLookupByLibrary.simpleMessage("نعم، تحول إلى مُشاهد"),
        "yesDelete": MessageLookupByLibrary.simpleMessage("نعم، حذف"),
        "yesLogout": MessageLookupByLibrary.simpleMessage("نعم، تسجيل الخروج"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("نعم، إزالة"),
        "yesRenew": MessageLookupByLibrary.simpleMessage("نعم، جدد الاشتراك"),
        "you": MessageLookupByLibrary.simpleMessage("أنت"),
        "youAreOnAFamilyPlan":
            MessageLookupByLibrary.simpleMessage("أنت على خطة عائلية!"),
        "youAreOnTheLatestVersion":
            MessageLookupByLibrary.simpleMessage("أنت في الإصدار لأحدث"),
        "youCanAtMaxDoubleYourStorage": MessageLookupByLibrary.simpleMessage(
            "* تستطيع زيادة تخزينك إلى الضعف كحد أقصى"),
        "youCannotDowngradeToThisPlan": MessageLookupByLibrary.simpleMessage(
            "لا يمكنك الترقية إلى هذه الخُطَّة"),
        "youCannotShareWithYourself":
            MessageLookupByLibrary.simpleMessage("لا يمكنك المُشاركة مع نفسك"),
        "youHaveSuccessfullyFreedUp": m43,
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("تم حذف حسابك بنجاح"),
        "yourPlanWasSuccessfullyDowngraded":
            MessageLookupByLibrary.simpleMessage("تم تخفيض خطتك بنجاح"),
        "yourPlanWasSuccessfullyUpgraded":
            MessageLookupByLibrary.simpleMessage("تم ترقية خطتك بنجاح"),
        "yourPurchaseWasSuccessful":
            MessageLookupByLibrary.simpleMessage("نجح الشراء"),
        "yourStorageDetailsCouldNotBeFetched":
            MessageLookupByLibrary.simpleMessage(
                "تعذر جلب تفاصيل التخزين الخاصة بك."),
        "yourSubscriptionHasExpired":
            MessageLookupByLibrary.simpleMessage("انتهت صَلاحِيَة اشتراكك"),
        "yourSubscriptionWasUpdatedSuccessfully":
            MessageLookupByLibrary.simpleMessage("تم تحديث اشتراكك بنجاح"),
        "youveNoDuplicateFilesThatCanBeCleared":
            MessageLookupByLibrary.simpleMessage(
                "ليس لديك أي ملفات مكررة يمكن مسحها.")
      };
}
