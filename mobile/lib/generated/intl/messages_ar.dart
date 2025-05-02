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

  static String m0(title) => "${title} (أنا)";

  static String m1(count) =>
      "${Intl.plural(count, zero: 'إضافة متعاون', one: 'إضافة متعاون', two: 'إضافة متعاونين', few: 'إضافة ${count} متعاونين', many: 'إضافة ${count} متعاونًا', other: 'إضافة ${count} متعاونًا')}";

  static String m2(count) =>
      "${Intl.plural(count, one: 'إضافة عنصر', two: 'إضافة عنصرين', few: 'إضافة ${count} عناصر', many: 'إضافة ${count} عنصرًا', other: 'إضافة ${count} عنصرًا')}";

  static String m3(storageAmount, endDate) =>
      "إضافتك بسعة ${storageAmount} صالحة حتى ${endDate}";

  static String m4(count) =>
      "${Intl.plural(count, zero: 'إضافة مشاهد', one: 'إضافة مشاهد', two: 'إضافة مشاهدين', few: 'إضافة ${count} مشاهدين', many: 'إضافة ${count} مشاهدًا', other: 'إضافة ${count} مشاهدًا')}";

  static String m5(emailOrName) => "تمت الإضافة بواسطة ${emailOrName}";

  static String m6(albumName) => "تمت الإضافة بنجاح إلى ${albumName}";

  static String m7(name) => "الإعجاب بـ ${name}";

  static String m8(count) =>
      "${Intl.plural(count, zero: 'لا يوجد مشاركون', one: 'مشارك واحد', two: 'مشاركان', few: '${count} مشاركين', many: '${count} مشاركًا', other: '${count} مشارك')}";

  static String m9(versionValue) => "الإصدار: ${versionValue}";

  static String m10(freeAmount, storageUnit) =>
      "${freeAmount} ${storageUnit} متوفرة";

  static String m11(name) => "مناظر جميلة مع ${name}";

  static String m12(paymentProvider) =>
      "يرجى إلغاء اشتراكك الحالي من ${paymentProvider} أولاً.";

  static String m13(user) =>
      "لن يتمكن ${user} من إضافة المزيد من الصور إلى هذا الألبوم.\n\nسيظل بإمكانه إزالة الصور الحالية التي أضافها.";

  static String m14(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true': 'عائلتك حصلت على ${storageAmountInGb} جيجابايت حتى الآن',
            'false': 'لقد حصلت على ${storageAmountInGb} جيجابايت حتى الآن',
            'other': 'لقد حصلت على ${storageAmountInGb} جيجابايت حتى الآن!',
          })}";

  static String m15(albumName) => "تم إنشاء رابط تعاوني لـ ${albumName}";

  static String m16(count) =>
      "${Intl.plural(count, zero: 'تمت إضافة 0 متعاونين', one: 'تمت إضافة متعاون واحد', two: 'تمت إضافة متعاونين', few: 'تمت إضافة ${count} متعاونين', many: 'تمت إضافة ${count} متعاونًا', other: 'تمت إضافة ${count} متعاونًا')}";

  static String m17(email, numOfDays) =>
      "أنت على وشك إضافة ${email} كجهة اتصال موثوقة. سيكون بإمكانهم استعادة حسابك إذا كنت غائبًا لمدة ${numOfDays} أيام.";

  static String m18(familyAdminEmail) =>
      "يرجى الاتصال بـ <green>${familyAdminEmail}</green> لإدارة اشتراكك.";

  static String m19(provider) =>
      "يرجى التواصل معنا على support@ente.io لإدارة اشتراكك في ${provider}.";

  static String m20(endpoint) => "متصل بـ ${endpoint}";

  static String m21(count) =>
      "${Intl.plural(count, one: 'حذف عنصر واحد', two: 'حذف عنصرين', few: 'حذف ${count} عناصر', many: 'حذف ${count} عنصرًا', other: 'حذف ${count} عنصرًا')}";

  static String m22(currentlyDeleting, totalCount) =>
      "جارٍ الحذف ${currentlyDeleting} / ${totalCount}";

  static String m23(albumName) =>
      "سيؤدي هذا إلى إزالة الرابط العام للوصول إلى \"${albumName}\".";

  static String m24(supportEmail) =>
      "يرجى إرسال بريد إلكتروني إلى ${supportEmail} من عنوان بريدك الإلكتروني المسجل.";

  static String m25(count, storageSaved) =>
      "لقد قمت بتنظيف ${Intl.plural(count, one: 'ملف مكرر واحد', two: 'ملفين مكررين', few: '${count} ملفات مكررة', many: '${count} ملفًا مكررًا', other: '${count} ملفًا مكررًا')}، مما وفر ${storageSaved}!";

  static String m26(count, formattedSize) =>
      "${count} ملفات، ${formattedSize} لكل منها";

  static String m27(newEmail) => "تم تغيير البريد الإلكتروني إلى ${newEmail}";

  static String m28(email) => "${email} لا يملك حساب Ente.";

  static String m29(email) =>
      "${email} لا يملك حسابًا على Ente.\n\nأرسل له دعوة لمشاركة الصور.";

  static String m30(name) => "معانقة ${name}";

  static String m31(text) => "تم العثور على صور إضافية لـ ${text}";

  static String m32(name) => "الاستمتاع بالطعام مع ${name}";

  static String m33(count, formattedNumber) =>
      "${Intl.plural(count, one: 'ملف واحد', two: 'ملفان', few: '${formattedNumber} ملفات', many: '${formattedNumber} ملفًا', other: '${formattedNumber} ملفًا')} على هذا الجهاز تم نسخه احتياطيًا بأمان";

  static String m34(count, formattedNumber) =>
      "${Intl.plural(count, one: 'ملف واحد', two: 'ملفان', few: '${formattedNumber} ملفات', many: '${formattedNumber} ملفًا', other: '${formattedNumber} ملفًا')} في هذا الألبوم تم نسخه احتياطيًا بأمان";

  static String m35(storageAmountInGB) =>
      "${storageAmountInGB} جيجابايت مجانية في كل مرة يشترك فيها شخص بخطة مدفوعة ويطبق رمزك";

  static String m36(endDate) => "التجربة المجانية صالحة حتى ${endDate}";

  static String m37(count) =>
      "لا يزال بإمكانك الوصول ${Intl.plural(count, one: 'إليه', two: 'إليهما', other: 'إليها')} على Ente طالما لديك اشتراك نشط.";

  static String m38(sizeInMBorGB) => "تحرير ${sizeInMBorGB}";

  static String m39(count, formattedSize) =>
      "${Intl.plural(count, one: 'يمكن حذفه من الجهاز لتحرير ${formattedSize}', two: 'يمكن حذفهما من الجهاز لتحرير ${formattedSize}', few: 'يمكن حذفها من الجهاز لتحرير ${formattedSize}', many: 'يمكن حذفها من الجهاز لتحرير ${formattedSize}', other: 'يمكن حذفها من الجهاز لتحرير ${formattedSize}')}";

  static String m40(currentlyProcessing, totalCount) =>
      "جارٍ المعالجة ${currentlyProcessing} / ${totalCount}";

  static String m41(name) => "التنزه مع ${name}";

  static String m42(count) =>
      "${Intl.plural(count, one: '${count} عُنْصُر', other: '${count} عَنَاصِر')}";

  static String m43(name) => "آخر مرة مع ${name}";

  static String m44(email) => "${email} دعاك لتكون جهة اتصال موثوقة";

  static String m45(expiryTime) => "ستنتهي صلاحية الرابط في ${expiryTime}";

  static String m46(email) => "ربط الشخص بـ ${email}";

  static String m47(personName, email) =>
      "سيؤدي هذا إلى ربط ${personName} بـ ${email}";

  static String m48(count, formattedCount) =>
      "${Intl.plural(count, zero: 'لا توجد ذكريات', one: 'ذكرى واحدة', two: 'ذكريتان', few: '${formattedCount} ذكريات', many: '${formattedCount} ذكرى', other: '${formattedCount} ذكرى')}";

  static String m49(count) =>
      "${Intl.plural(count, one: 'نقل عنصر', two: 'نقل عنصرين', few: 'نقل ${count} عناصر', many: 'نقل ${count} عنصرًا', other: 'نقل ${count} عنصرًا')}";

  static String m50(albumName) => "تم النقل بنجاح إلى ${albumName}";

  static String m51(personName) => "لا توجد اقتراحات لـ ${personName}";

  static String m52(name) => "ليس ${name}؟";

  static String m53(familyAdminEmail) =>
      "يرجى الاتصال بـ ${familyAdminEmail} لتغيير الرمز الخاص بك.";

  static String m54(name) => "الاحتفال مع ${name}";

  static String m55(passwordStrengthValue) =>
      "قوة كلمة المرور: ${passwordStrengthValue}";

  static String m56(providerName) =>
      "يرجى التواصل مع دعم ${providerName} إذا تم خصم المبلغ منك.";

  static String m57(name, age) => "${name} يبلغ ${age}!";

  static String m58(name, age) => "${name} سيبلغ ${age} قريبًا";

  static String m59(count) =>
      "${Intl.plural(count, zero: 'لا توجد صور', one: 'صورة واحدة', two: 'صورتان', few: '${count} صور', many: '${count} صورة', other: '${count} صورة')}";

  static String m60(count) =>
      "${Intl.plural(count, zero: 'لا توجد صور', one: 'صورة واحدة', two: 'صورتان', few: '${count} صور', many: '${count} صورة', other: '${count} صورة')}";

  static String m61(endDate) =>
      "التجربة المجانية صالحة حتى ${endDate}.\nيمكنك اختيار خطة مدفوعة بعد ذلك.";

  static String m62(toEmail) =>
      "يرجى مراسلتنا عبر البريد الإلكتروني على ${toEmail}";

  static String m63(toEmail) => "يرجى إرسال السجلات إلى \n${toEmail}";

  static String m64(name) => "التقاط صور مع ${name}";

  static String m65(folderName) => "جارٍ معالجة ${folderName}...";

  static String m66(storeName) => "قيّمنا على ${storeName}";

  static String m67(name) => "تمت إعادة تعيينك إلى ${name}";

  static String m68(days, email) =>
      "يمكنك الوصول إلى الحساب بعد ${days} أيام. سيتم إرسال إشعار إلى ${email}.";

  static String m69(email) =>
      "يمكنك الآن استرداد حساب ${email} عن طريق تعيين كلمة مرور جديدة.";

  static String m70(email) => "${email} يحاول استرداد حسابك.";

  static String m71(storageInGB) =>
      "3. تحصلون كلاكما على ${storageInGB} جيجابايت* مجانًا";

  static String m72(userEmail) =>
      "سيتم إزالة ${userEmail} من هذا الألبوم المشترك.\n\nسيتم أيضًا إزالة أي صور أضافها إلى الألبوم.";

  static String m73(endDate) => "يتجدد الاشتراك في ${endDate}";

  static String m74(name) => "رحلة برية مع ${name}";

  static String m75(snapshotLength, searchLength) =>
      "عدم تطابق طول الأقسام: ${snapshotLength} != ${searchLength}";

  static String m76(count) => "تم تحديد ${count}";

  static String m77(count, yourCount) =>
      "تم تحديد ${count} (${yourCount} منها لك)";

  static String m78(name) => "صور سيلفي مع ${name}";

  static String m79(verificationID) =>
      "إليك معرّف التحقق الخاص بي لـ ente.io: ${verificationID}";

  static String m80(verificationID) =>
      "مرحبًا، هل يمكنك تأكيد أن هذا هو معرّف التحقق الخاص بك على ente.io: ${verificationID}؟";

  static String m81(referralCode, referralStorageInGB) =>
      "رمز إحالة Ente الخاص بي: ${referralCode}\n\nطبقه في الإعدادات ← عام ← الإحالات للحصول على ${referralStorageInGB} جيجابايت مجانًا بعد الاشتراك في خطة مدفوعة.\n\nhttps://ente.io";

  static String m82(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'مشاركة مع أشخاص محددين', one: 'تمت المشاركة مع شخص واحد', two: 'تمت المشاركة مع شخصين', few: 'تمت المشاركة مع ${numberOfPeople} أشخاص', many: 'تمت المشاركة مع ${numberOfPeople} شخصًا', other: 'تمت المشاركة مع ${numberOfPeople} شخصًا')}";

  static String m83(emailIDs) => "تمت المشاركة مع ${emailIDs}";

  static String m84(fileType) => "سيتم حذف ${fileType} من جهازك.";

  static String m85(fileType) => "${fileType} موجود في Ente وعلى جهازك.";

  static String m86(fileType) => "سيتم حذف ${fileType} من Ente.";

  static String m87(name) => "الرياضة مع ${name}";

  static String m88(name) => "تسليط الضوء على ${name}";

  static String m89(storageAmountInGB) => "${storageAmountInGB} جيجابايت";

  static String m90(
          usedAmount, usedStorageUnit, totalAmount, totalStorageUnit) =>
      "تم استخدام ${usedAmount} ${usedStorageUnit} من ${totalAmount} ${totalStorageUnit}";

  static String m91(id) =>
      "تم ربط ${id} الخاص بك بحساب Ente آخر.\nإذا كنت ترغب في استخدام ${id} مع هذا الحساب، يرجى الاتصال بدعمنا.";

  static String m92(endDate) => "سيتم إلغاء اشتراكك في ${endDate}";

  static String m93(completed, total) => "${completed}/${total} ذكريات محفوظة";

  static String m94(ignoreReason) =>
      "انقر للتحميل، تم تجاهل التحميل حاليًا بسبب ${ignoreReason}";

  static String m95(storageAmountInGB) =>
      "سيحصلون أيضًا على ${storageAmountInGB} جيجابايت";

  static String m96(email) => "هذا هو معرّف التحقق الخاص بـ ${email}";

  static String m97(count) =>
      "${Intl.plural(count, one: 'هذا الأسبوع، قبل سنة', two: 'هذا الأسبوع، قبل سنتين', few: 'هذا الأسبوع، قبل ${count} سنوات', many: 'هذا الأسبوع، قبل ${count} سنة', other: 'هذا الأسبوع، قبل ${count} سنة')}";

  static String m98(dateFormat) => "${dateFormat} عبر السنين";

  static String m99(count) =>
      "${Intl.plural(count, zero: 'قريبًا', one: 'يوم واحد', two: 'يومان', few: '${count} أيام', many: '${count} يومًا', other: '${count} يومًا')}";

  static String m100(year) => "رحلة في ${year}";

  static String m101(location) => "رحلة إلى ${location}";

  static String m102(email) =>
      "لقد تمت دعوتك لتكون جهة اتصال موثوقة بواسطة ${email}.";

  static String m103(galleryType) =>
      "نوع المعرض ${galleryType} غير مدعوم لإعادة التسمية.";

  static String m104(ignoreReason) => "تم تجاهل التحميل بسبب ${ignoreReason}";

  static String m105(count) => "جارٍ حفظ ${count} ذكريات...";

  static String m106(endDate) => "صالح حتى ${endDate}";

  static String m107(email) => "التحقق من ${email}";

  static String m108(count) =>
      "${Intl.plural(count, zero: 'تمت إضافة 0 مشاهدين', one: 'تمت إضافة مشاهد واحد', two: 'تمت إضافة مشاهدين', few: 'تمت إضافة ${count} مشاهدين', many: 'تمت إضافة ${count} مشاهدًا', other: 'تمت إضافة ${count} مشاهدًا')}";

  static String m109(email) =>
      "لقد أرسلنا بريدًا إلكترونيًا إلى <green>${email}</green>";

  static String m110(count) =>
      "${Intl.plural(count, one: 'قبل سنة', two: 'قبل سنتين', few: 'قبل ${count} سنوات', many: 'قبل ${count} سنة', other: 'قبل ${count} سنة')}";

  static String m111(name) => "أنت و ${name}";

  static String m112(storageSaved) => "لقد حررت ${storageSaved} بنجاح!";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aNewVersionOfEnteIsAvailable":
            MessageLookupByLibrary.simpleMessage("يتوفر إصدار جديد من Ente."),
        "about": MessageLookupByLibrary.simpleMessage("حول التطبيق"),
        "acceptTrustInvite":
            MessageLookupByLibrary.simpleMessage("قبول الدعوة"),
        "account": MessageLookupByLibrary.simpleMessage("الحساب"),
        "accountIsAlreadyConfigured":
            MessageLookupByLibrary.simpleMessage("الحساب تم تكوينه بالفعل."),
        "accountOwnerPersonAppbarTitle": m0,
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("مرحبًا مجددًا!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "أدرك أنني إذا فقدت كلمة المرور، فقد أفقد بياناتي لأنها <underline>مشفرة بالكامل من طرف إلى طرف</underline>."),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("الجلسات النشطة"),
        "add": MessageLookupByLibrary.simpleMessage("إضافة"),
        "addAName": MessageLookupByLibrary.simpleMessage("إضافة اسم"),
        "addANewEmail":
            MessageLookupByLibrary.simpleMessage("إضافة بريد إلكتروني جديد"),
        "addCollaborator": MessageLookupByLibrary.simpleMessage("إضافة متعاون"),
        "addCollaborators": m1,
        "addFiles": MessageLookupByLibrary.simpleMessage("إضافة ملفات"),
        "addFromDevice":
            MessageLookupByLibrary.simpleMessage("إضافة من الجهاز"),
        "addItem": m2,
        "addLocation": MessageLookupByLibrary.simpleMessage("إضافة موقع"),
        "addLocationButton": MessageLookupByLibrary.simpleMessage("إضافة"),
        "addMore": MessageLookupByLibrary.simpleMessage("إضافة المزيد"),
        "addName": MessageLookupByLibrary.simpleMessage("إضافة اسم"),
        "addNameOrMerge":
            MessageLookupByLibrary.simpleMessage("إضافة اسم أو دمج"),
        "addNew": MessageLookupByLibrary.simpleMessage("إضافة جديد"),
        "addNewPerson": MessageLookupByLibrary.simpleMessage("إضافة شخص جديد"),
        "addOnPageSubtitle":
            MessageLookupByLibrary.simpleMessage("تفاصيل الإضافات"),
        "addOnValidTill": m3,
        "addOns": MessageLookupByLibrary.simpleMessage("الإضافات"),
        "addPhotos": MessageLookupByLibrary.simpleMessage("إضافة صور"),
        "addSelected": MessageLookupByLibrary.simpleMessage("إضافة المحدد"),
        "addToAlbum": MessageLookupByLibrary.simpleMessage("إضافة إلى الألبوم"),
        "addToEnte": MessageLookupByLibrary.simpleMessage("إضافة إلى Ente"),
        "addToHiddenAlbum":
            MessageLookupByLibrary.simpleMessage("إضافة إلى الألبوم المخفي"),
        "addTrustedContact":
            MessageLookupByLibrary.simpleMessage("إضافة جهة اتصال موثوقة"),
        "addViewer": MessageLookupByLibrary.simpleMessage("إضافة مشاهد"),
        "addViewers": m4,
        "addYourPhotosNow":
            MessageLookupByLibrary.simpleMessage("أضف صورك الآن"),
        "addedAs": MessageLookupByLibrary.simpleMessage("تمت الإضافة كـ"),
        "addedBy": m5,
        "addedSuccessfullyTo": m6,
        "addingToFavorites":
            MessageLookupByLibrary.simpleMessage("جارٍ الإضافة إلى المفضلة..."),
        "admiringThem": m7,
        "advanced": MessageLookupByLibrary.simpleMessage("متقدم"),
        "advancedSettings":
            MessageLookupByLibrary.simpleMessage("الإعدادات المتقدمة"),
        "after1Day": MessageLookupByLibrary.simpleMessage("بعد يوم"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("بعد ساعة"),
        "after1Month": MessageLookupByLibrary.simpleMessage("بعد شهر"),
        "after1Week": MessageLookupByLibrary.simpleMessage("بعد أسبوع"),
        "after1Year": MessageLookupByLibrary.simpleMessage("بعد سنة"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("المالك"),
        "albumParticipantsCount": m8,
        "albumTitle": MessageLookupByLibrary.simpleMessage("عنوان الألبوم"),
        "albumUpdated":
            MessageLookupByLibrary.simpleMessage("تم تحديث الألبوم"),
        "albums": MessageLookupByLibrary.simpleMessage("الألبومات"),
        "allClear": MessageLookupByLibrary.simpleMessage("✨ كل شيء واضح"),
        "allMemoriesPreserved":
            MessageLookupByLibrary.simpleMessage("تم حفظ جميع الذكريات"),
        "allPersonGroupingWillReset": MessageLookupByLibrary.simpleMessage(
            "سيتم إعادة تعيين جميع تجمعات هذا الشخص، وستفقد جميع الاقتراحات المقدمة لهذا الشخص."),
        "allWillShiftRangeBasedOnFirst": MessageLookupByLibrary.simpleMessage(
            "هذه هي الأولى في المجموعة. سيتم تغيير تواريخ الصور المحددة الأخرى تلقائيًا بناءً على هذا التاريخ الجديد."),
        "allow": MessageLookupByLibrary.simpleMessage("السماح"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "السماح للأشخاص الذين لديهم الرابط بإضافة صور إلى الألبوم المشترك أيضًا."),
        "allowAddingPhotos":
            MessageLookupByLibrary.simpleMessage("السماح بإضافة الصور"),
        "allowAppToOpenSharedAlbumLinks": MessageLookupByLibrary.simpleMessage(
            "السماح للتطبيق بفتح روابط الألبومات المشتركة"),
        "allowDownloads":
            MessageLookupByLibrary.simpleMessage("السماح بالتنزيلات"),
        "allowPeopleToAddPhotos":
            MessageLookupByLibrary.simpleMessage("السماح للأشخاص بإضافة الصور"),
        "allowPermBody": MessageLookupByLibrary.simpleMessage(
            "يرجى السماح بالوصول إلى صورك من الإعدادات حتى يتمكن Ente من عرض نسختك الاحتياطية ومكتبتك."),
        "allowPermTitle":
            MessageLookupByLibrary.simpleMessage("السماح بالوصول إلى الصور"),
        "androidBiometricHint":
            MessageLookupByLibrary.simpleMessage("تحقق من الهوية"),
        "androidBiometricNotRecognized": MessageLookupByLibrary.simpleMessage(
            "لم يتم التعرف. حاول مرة أخرى."),
        "androidBiometricRequiredTitle":
            MessageLookupByLibrary.simpleMessage("المصادقة البيومترية مطلوبة"),
        "androidBiometricSuccess": MessageLookupByLibrary.simpleMessage("نجاح"),
        "androidCancelButton": MessageLookupByLibrary.simpleMessage("إلغاء"),
        "androidDeviceCredentialsRequiredTitle":
            MessageLookupByLibrary.simpleMessage("بيانات اعتماد الجهاز مطلوبة"),
        "androidDeviceCredentialsSetupDescription":
            MessageLookupByLibrary.simpleMessage("بيانات اعتماد الجهاز مطلوبة"),
        "androidGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "لم يتم إعداد المصادقة البيومترية على جهازك. انتقل إلى \'الإعدادات > الأمان\' لإضافة المصادقة البيومترية."),
        "androidIosWebDesktop": MessageLookupByLibrary.simpleMessage(
            "أندرويد، iOS، الويب، سطح المكتب"),
        "androidSignInTitle":
            MessageLookupByLibrary.simpleMessage("المصادقة مطلوبة"),
        "appIcon": MessageLookupByLibrary.simpleMessage("أيقونة التطبيق"),
        "appLock": MessageLookupByLibrary.simpleMessage("قفل التطبيق"),
        "appLockDescriptions": MessageLookupByLibrary.simpleMessage(
            "اختر بين شاشة القفل الافتراضية لجهازك وشاشة قفل مخصصة برمز PIN أو كلمة مرور."),
        "appVersion": m9,
        "appleId": MessageLookupByLibrary.simpleMessage("معرّف Apple"),
        "apply": MessageLookupByLibrary.simpleMessage("تطبيق"),
        "applyCodeTitle": MessageLookupByLibrary.simpleMessage("تطبيق الرمز"),
        "appstoreSubscription":
            MessageLookupByLibrary.simpleMessage("اشتراك متجر App Store"),
        "archive": MessageLookupByLibrary.simpleMessage("الأرشيف"),
        "archiveAlbum": MessageLookupByLibrary.simpleMessage("أرشفة الألبوم"),
        "archiving": MessageLookupByLibrary.simpleMessage("جارٍ الأرشفة..."),
        "areYouSureThatYouWantToLeaveTheFamily":
            MessageLookupByLibrary.simpleMessage(
                "هل أنت متأكد من رغبتك في مغادرة الخطة العائلية؟"),
        "areYouSureYouWantToCancel": MessageLookupByLibrary.simpleMessage(
            "هل أنت متأكد من رغبتك في الإلغاء؟"),
        "areYouSureYouWantToChangeYourPlan":
            MessageLookupByLibrary.simpleMessage(
                "هل أنت متأكد من رغبتك في تغيير خطتك؟"),
        "areYouSureYouWantToExit": MessageLookupByLibrary.simpleMessage(
            "هل أنت متأكد من رغبتك في الخروج؟"),
        "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
            "هل أنت متأكد من رغبتك في تسجيل الخروج؟"),
        "areYouSureYouWantToRenew": MessageLookupByLibrary.simpleMessage(
            "هل أنت متأكد من رغبتك في التجديد؟"),
        "areYouSureYouWantToResetThisPerson":
            MessageLookupByLibrary.simpleMessage(
                "هل أنت متأكد من رغبتك في إعادة تعيين هذا الشخص؟"),
        "askCancelReason": MessageLookupByLibrary.simpleMessage(
            "تم إلغاء اشتراكك. هل ترغب في مشاركة السبب؟"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "ما السبب الرئيسي لحذف حسابك؟"),
        "askYourLovedOnesToShare":
            MessageLookupByLibrary.simpleMessage("اطلب من أحبائك المشاركة"),
        "atAFalloutShelter":
            MessageLookupByLibrary.simpleMessage("في ملجأ للطوارئ"),
        "authToChangeEmailVerificationSetting":
            MessageLookupByLibrary.simpleMessage(
                "يرجى المصادقة لتغيير إعداد التحقق من البريد الإلكتروني."),
        "authToChangeLockscreenSetting": MessageLookupByLibrary.simpleMessage(
            "يرجى المصادقة لتغيير إعدادات شاشة القفل."),
        "authToChangeYourEmail": MessageLookupByLibrary.simpleMessage(
            "يرجى المصادقة لتغيير بريدك الإلكتروني."),
        "authToChangeYourPassword": MessageLookupByLibrary.simpleMessage(
            "يرجى المصادقة لتغيير كلمة المرور الخاصة بك."),
        "authToConfigureTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "يرجى المصادقة لإعداد المصادقة الثنائية."),
        "authToInitiateAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "يرجى المصادقة لبدء عملية حذف الحساب."),
        "authToManageLegacy": MessageLookupByLibrary.simpleMessage(
            "يرجى المصادقة لإدارة جهات الاتصال الموثوقة الخاصة بك."),
        "authToViewPasskey": MessageLookupByLibrary.simpleMessage(
            "يرجى المصادقة لعرض مفتاح المرور الخاص بك."),
        "authToViewTrashedFiles": MessageLookupByLibrary.simpleMessage(
            "يرجى المصادقة لعرض ملفاتك المحذوفة."),
        "authToViewYourActiveSessions": MessageLookupByLibrary.simpleMessage(
            "يرجى المصادقة لعرض جلساتك النشطة."),
        "authToViewYourHiddenFiles": MessageLookupByLibrary.simpleMessage(
            "يرجى المصادقة للوصول إلى ملفاتك المخفية."),
        "authToViewYourMemories":
            MessageLookupByLibrary.simpleMessage("يرجى المصادقة لعرض ذكرياتك."),
        "authToViewYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "يرجى المصادقة لعرض مفتاح الاسترداد الخاص بك."),
        "authenticating":
            MessageLookupByLibrary.simpleMessage("جارٍ المصادقة..."),
        "authenticationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "فشلت المصادقة، يرجى المحاولة مرة أخرى."),
        "authenticationSuccessful":
            MessageLookupByLibrary.simpleMessage("تمت المصادقة بنجاح!"),
        "autoCastDialogBody": MessageLookupByLibrary.simpleMessage(
            "سترى أجهزة Cast المتاحة هنا."),
        "autoCastiOSPermission": MessageLookupByLibrary.simpleMessage(
            "تأكد من تشغيل أذونات الشبكة المحلية لتطبيق Ente Photos في الإعدادات."),
        "autoLock": MessageLookupByLibrary.simpleMessage("قفل تلقائي"),
        "autoLockFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "الوقت الذي يتم بعده قفل التطبيق بعد وضعه في الخلفية."),
        "autoLogoutMessage": MessageLookupByLibrary.simpleMessage(
            "بسبب خلل تقني، تم تسجيل خروجك. نعتذر عن الإزعاج."),
        "autoPair": MessageLookupByLibrary.simpleMessage("إقران تلقائي"),
        "autoPairDesc": MessageLookupByLibrary.simpleMessage(
            "الإقران التلقائي يعمل فقط مع الأجهزة التي تدعم Chromecast."),
        "available": MessageLookupByLibrary.simpleMessage("متوفر"),
        "availableStorageSpace": m10,
        "backedUpFolders":
            MessageLookupByLibrary.simpleMessage("المجلدات المنسوخة احتياطيًا"),
        "backgroundWithThem": m11,
        "backup": MessageLookupByLibrary.simpleMessage("النسخ الاحتياطي"),
        "backupFailed":
            MessageLookupByLibrary.simpleMessage("فشل النسخ الاحتياطي"),
        "backupFile": MessageLookupByLibrary.simpleMessage("نسخ احتياطي للملف"),
        "backupOverMobileData": MessageLookupByLibrary.simpleMessage(
            "النسخ الاحتياطي عبر بيانات الجوال"),
        "backupSettings":
            MessageLookupByLibrary.simpleMessage("إعدادات النسخ الاحتياطي"),
        "backupStatus":
            MessageLookupByLibrary.simpleMessage("حالة النسخ الاحتياطي"),
        "backupStatusDescription": MessageLookupByLibrary.simpleMessage(
            "ستظهر العناصر التي تم نسخها احتياطيًا هنا"),
        "backupVideos": MessageLookupByLibrary.simpleMessage(
            "النسخ الاحتياطي لمقاطع الفيديو"),
        "beach": MessageLookupByLibrary.simpleMessage("رمال وبحر"),
        "birthday": MessageLookupByLibrary.simpleMessage("تاريخ الميلاد"),
        "blackFridaySale":
            MessageLookupByLibrary.simpleMessage("تخفيضات الجمعة السوداء"),
        "blog": MessageLookupByLibrary.simpleMessage("المدونة"),
        "cLBulkEdit":
            MessageLookupByLibrary.simpleMessage("تعديل التواريخ بشكل جماعي"),
        "cLBulkEditDesc": MessageLookupByLibrary.simpleMessage(
            "يمكنك الآن تحديد صور متعددة، وتعديل التاريخ/الوقت لجميعها بإجراء سريع واحد. تغيير التواريخ مدعوم أيضًا."),
        "cLFamilyPlan":
            MessageLookupByLibrary.simpleMessage("حدود الخطة العائلية"),
        "cLFamilyPlanDesc": MessageLookupByLibrary.simpleMessage(
            "يمكنك الآن تعيين حدود لمقدار التخزين الذي يمكن لأفراد عائلتك استخدامه."),
        "cLIcon": MessageLookupByLibrary.simpleMessage("أيقونة جديدة"),
        "cLIconDesc": MessageLookupByLibrary.simpleMessage(
            "أخيرًا، أيقونة تطبيق جديدة، نعتقد أنها تمثل عملنا على أفضل وجه. أضفنا أيضًا مبدل أيقونات حتى تتمكن من الاستمرار في استخدام الأيقونة القديمة."),
        "cLMemories": MessageLookupByLibrary.simpleMessage("الذكريات"),
        "cLMemoriesDesc": MessageLookupByLibrary.simpleMessage(
            "أعد اكتشاف لحظاتك الخاصة - تسليط الضوء على الأشخاص المفضلين لديك، رحلاتك وعطلاتك، أفضل لقطاتك، وأكثر من ذلك بكثير. قم بتشغيل تعلم الآلة، ضع علامة على نفسك وقم بتسمية أصدقائك للحصول على أفضل تجربة."),
        "cLWidgets":
            MessageLookupByLibrary.simpleMessage("الأدوات المصغرة (Widgets)"),
        "cLWidgetsDesc": MessageLookupByLibrary.simpleMessage(
            "الأدوات المصغرة للشاشة الرئيسية المدمجة مع الذكريات متاحة الآن. ستعرض لحظاتك الخاصة دون فتح التطبيق."),
        "cachedData": MessageLookupByLibrary.simpleMessage("البيانات المؤقتة"),
        "calculating": MessageLookupByLibrary.simpleMessage("جارٍ الحساب..."),
        "canNotOpenBody": MessageLookupByLibrary.simpleMessage(
            "عذرًا، لا يمكن فتح هذا الألبوم في التطبيق."),
        "canNotOpenTitle":
            MessageLookupByLibrary.simpleMessage("لا يمكن فتح هذا الألبوم"),
        "canNotUploadToAlbumsOwnedByOthers":
            MessageLookupByLibrary.simpleMessage(
                "لا يمكن التحميل إلى ألبومات يملكها آخرون."),
        "canOnlyCreateLinkForFilesOwnedByYou":
            MessageLookupByLibrary.simpleMessage(
                "يمكن إنشاء رابط للملفات التي تملكها فقط."),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
            "يمكنك فقط إزالة الملفات التي تملكها."),
        "cancel": MessageLookupByLibrary.simpleMessage("إلغاء"),
        "cancelAccountRecovery":
            MessageLookupByLibrary.simpleMessage("إلغاء استرداد الحساب"),
        "cancelAccountRecoveryBody": MessageLookupByLibrary.simpleMessage(
            "هل أنت متأكد من رغبتك في إلغاء الاسترداد؟"),
        "cancelOtherSubscription": m12,
        "cancelSubscription":
            MessageLookupByLibrary.simpleMessage("إلغاء الاشتراك"),
        "cannotAddMorePhotosAfterBecomingViewer": m13,
        "cannotDeleteSharedFiles": MessageLookupByLibrary.simpleMessage(
            "لا يمكن حذف الملفات المشتركة."),
        "castAlbum": MessageLookupByLibrary.simpleMessage("بث الألبوم"),
        "castIPMismatchBody": MessageLookupByLibrary.simpleMessage(
            "يرجى التأكد من أنك متصل بنفس الشبكة المتصل بها التلفزيون."),
        "castIPMismatchTitle":
            MessageLookupByLibrary.simpleMessage("فشل بث الألبوم"),
        "castInstruction": MessageLookupByLibrary.simpleMessage(
            "قم بزيارة cast.ente.io على الجهاز الذي تريد إقرانه.\n\nأدخل الرمز أدناه لتشغيل الألبوم على تلفزيونك."),
        "centerPoint": MessageLookupByLibrary.simpleMessage("نقطة المركز"),
        "change": MessageLookupByLibrary.simpleMessage("تغيير"),
        "changeEmail":
            MessageLookupByLibrary.simpleMessage("تغيير البريد الإلكتروني"),
        "changeLocationOfSelectedItems":
            MessageLookupByLibrary.simpleMessage("تغيير موقع العناصر المحددة؟"),
        "changePassword":
            MessageLookupByLibrary.simpleMessage("تغيير كلمة المرور"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("تغيير كلمة المرور"),
        "changePermissions":
            MessageLookupByLibrary.simpleMessage("تغيير الإذن؟"),
        "changeYourReferralCode":
            MessageLookupByLibrary.simpleMessage("تغيير رمز الإحالة الخاص بك"),
        "checkForUpdates":
            MessageLookupByLibrary.simpleMessage("التحقق من وجود تحديثات"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "تحقق من صندوق الوارد ومجلد البريد غير الهام (Spam) لإكمال التحقق"),
        "checkStatus": MessageLookupByLibrary.simpleMessage("التحقق من الحالة"),
        "checking": MessageLookupByLibrary.simpleMessage("جارٍ التحقق..."),
        "checkingModels":
            MessageLookupByLibrary.simpleMessage("جارٍ فحص النماذج..."),
        "city": MessageLookupByLibrary.simpleMessage("في المدينة"),
        "claimFreeStorage": MessageLookupByLibrary.simpleMessage(
            "المطالبة بمساحة تخزين مجانية"),
        "claimMore": MessageLookupByLibrary.simpleMessage("المطالبة بالمزيد!"),
        "claimed": MessageLookupByLibrary.simpleMessage("تم الحصول عليها"),
        "claimedStorageSoFar": m14,
        "cleanUncategorized":
            MessageLookupByLibrary.simpleMessage("تنظيف غير المصنف"),
        "cleanUncategorizedDescription": MessageLookupByLibrary.simpleMessage(
            "إزالة جميع الملفات من قسم \'غير مصنف\' الموجودة في ألبومات أخرى."),
        "clearCaches":
            MessageLookupByLibrary.simpleMessage("مسح ذاكرة التخزين المؤقت"),
        "clearIndexes": MessageLookupByLibrary.simpleMessage("مسح الفهارس"),
        "click": MessageLookupByLibrary.simpleMessage("• انقر على"),
        "clickOnTheOverflowMenu": MessageLookupByLibrary.simpleMessage(
            "• انقر على قائمة الخيارات الإضافية"),
        "close": MessageLookupByLibrary.simpleMessage("إغلاق"),
        "clubByCaptureTime":
            MessageLookupByLibrary.simpleMessage("التجميع حسب وقت الالتقاط"),
        "clubByFileName":
            MessageLookupByLibrary.simpleMessage("التجميع حسب اسم الملف"),
        "clusteringProgress":
            MessageLookupByLibrary.simpleMessage("تقدم التجميع"),
        "codeAppliedPageTitle":
            MessageLookupByLibrary.simpleMessage("تم تطبيق الرمز"),
        "codeChangeLimitReached": MessageLookupByLibrary.simpleMessage(
            "عذرًا، لقد تجاوزت الحد المسموح به لتعديلات الرمز."),
        "codeCopiedToClipboard":
            MessageLookupByLibrary.simpleMessage("تم نسخ الرمز إلى الحافظة"),
        "codeUsedByYou":
            MessageLookupByLibrary.simpleMessage("الرمز المستخدم من قبلك"),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
            "أنشئ رابطًا يسمح للأشخاص بإضافة الصور ومشاهدتها في ألبومك المشترك دون الحاجة إلى تطبيق Ente أو حساب. خيار مثالي لجمع صور الفعاليات بسهولة."),
        "collaborativeLink":
            MessageLookupByLibrary.simpleMessage("رابط تعاوني"),
        "collaborativeLinkCreatedFor": m15,
        "collaborator": MessageLookupByLibrary.simpleMessage("متعاون"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "يمكن للمتعاونين إضافة الصور ومقاطع الفيديو إلى الألبوم المشترك."),
        "collaboratorsSuccessfullyAdded": m16,
        "collageLayout": MessageLookupByLibrary.simpleMessage("التخطيط"),
        "collageSaved":
            MessageLookupByLibrary.simpleMessage("تم حفظ الكولاج في المعرض."),
        "collect": MessageLookupByLibrary.simpleMessage("جمع"),
        "collectEventPhotos":
            MessageLookupByLibrary.simpleMessage("جمع صور الفعالية"),
        "collectPhotos": MessageLookupByLibrary.simpleMessage("جمع الصور"),
        "collectPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "أنشئ رابطًا يمكن لأصدقائك من خلاله تحميل الصور بالجودة الأصلية."),
        "color": MessageLookupByLibrary.simpleMessage("اللون"),
        "configuration": MessageLookupByLibrary.simpleMessage("التكوين"),
        "confirm": MessageLookupByLibrary.simpleMessage("تأكيد"),
        "confirm2FADisable": MessageLookupByLibrary.simpleMessage(
            "هل أنت متأكد من رغبتك في تعطيل المصادقة الثنائية؟"),
        "confirmAccountDeletion":
            MessageLookupByLibrary.simpleMessage("تأكيد حذف الحساب"),
        "confirmAddingTrustedContact": m17,
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "نعم، أرغب في حذف هذا الحساب وبياناته نهائيًا من جميع التطبيقات."),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("تأكيد كلمة المرور"),
        "confirmPlanChange":
            MessageLookupByLibrary.simpleMessage("تأكيد تغيير الخطة"),
        "confirmRecoveryKey":
            MessageLookupByLibrary.simpleMessage("تأكيد مفتاح الاسترداد"),
        "confirmYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "تأكيد مفتاح الاسترداد الخاص بك"),
        "connectToDevice":
            MessageLookupByLibrary.simpleMessage("الاتصال بالجهاز"),
        "contactFamilyAdmin": m18,
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("الاتصال بالدعم"),
        "contactToManageSubscription": m19,
        "contacts": MessageLookupByLibrary.simpleMessage("جهات الاتصال"),
        "contents": MessageLookupByLibrary.simpleMessage("المحتويات"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("متابعة"),
        "continueOnFreeTrial": MessageLookupByLibrary.simpleMessage(
            "الاستمرار في التجربة المجانية"),
        "convertToAlbum":
            MessageLookupByLibrary.simpleMessage("تحويل إلى ألبوم"),
        "copyEmailAddress":
            MessageLookupByLibrary.simpleMessage("نسخ عنوان البريد الإلكتروني"),
        "copyLink": MessageLookupByLibrary.simpleMessage("نسخ الرابط"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "انسخ هذا الرمز وألصقه\n في تطبيق المصادقة الخاص بك"),
        "couldNotBackUpTryLater": MessageLookupByLibrary.simpleMessage(
            "لم نتمكن من نسخ بياناتك احتياطيًا.\nسنحاول مرة أخرى لاحقًا."),
        "couldNotFreeUpSpace":
            MessageLookupByLibrary.simpleMessage("تعذر تحرير المساحة."),
        "couldNotUpdateSubscription":
            MessageLookupByLibrary.simpleMessage("تعذر تحديث الاشتراك."),
        "count": MessageLookupByLibrary.simpleMessage("العدد"),
        "crashReporting":
            MessageLookupByLibrary.simpleMessage("الإبلاغ عن الأعطال"),
        "create": MessageLookupByLibrary.simpleMessage("إنشاء"),
        "createAccount": MessageLookupByLibrary.simpleMessage("إنشاء حساب"),
        "createAlbumActionHint": MessageLookupByLibrary.simpleMessage(
            "اضغط مطولاً لتحديد الصور ثم انقر على \'+\' لإنشاء ألبوم"),
        "createCollaborativeLink":
            MessageLookupByLibrary.simpleMessage("إنشاء رابط تعاوني"),
        "createCollage": MessageLookupByLibrary.simpleMessage("إنشاء كولاج"),
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("إنشاء حساب جديد"),
        "createOrSelectAlbum":
            MessageLookupByLibrary.simpleMessage("إنشاء أو تحديد ألبوم"),
        "createPublicLink":
            MessageLookupByLibrary.simpleMessage("إنشاء رابط عام"),
        "creatingLink":
            MessageLookupByLibrary.simpleMessage("جارٍ إنشاء الرابط..."),
        "criticalUpdateAvailable":
            MessageLookupByLibrary.simpleMessage("يتوفر تحديث حرج"),
        "crop": MessageLookupByLibrary.simpleMessage("اقتصاص"),
        "curatedMemories": MessageLookupByLibrary.simpleMessage("ذكريات منسقة"),
        "currentUsageIs":
            MessageLookupByLibrary.simpleMessage("استخدامك الحالي هو"),
        "currentlyRunning":
            MessageLookupByLibrary.simpleMessage("قيد التشغيل حاليًا"),
        "custom": MessageLookupByLibrary.simpleMessage("مخصص"),
        "customEndpoint": m20,
        "darkTheme": MessageLookupByLibrary.simpleMessage("داكن"),
        "dayToday": MessageLookupByLibrary.simpleMessage("اليوم"),
        "dayYesterday": MessageLookupByLibrary.simpleMessage("الأمس"),
        "declineTrustInvite":
            MessageLookupByLibrary.simpleMessage("رفض الدعوة"),
        "decrypting":
            MessageLookupByLibrary.simpleMessage("جارٍ فك التشفير..."),
        "decryptingVideo":
            MessageLookupByLibrary.simpleMessage("جارٍ فك تشفير الفيديو..."),
        "deduplicateFiles":
            MessageLookupByLibrary.simpleMessage("إزالة الملفات المكررة"),
        "delete": MessageLookupByLibrary.simpleMessage("حذف"),
        "deleteAccount": MessageLookupByLibrary.simpleMessage("حذف الحساب"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "نأسف لمغادرتك. نرجو مشاركة ملاحظاتك لمساعدتنا على التحسين."),
        "deleteAccountPermanentlyButton":
            MessageLookupByLibrary.simpleMessage("حذف الحساب نهائيًا"),
        "deleteAlbum": MessageLookupByLibrary.simpleMessage("حذف الألبوم"),
        "deleteAlbumDialog": MessageLookupByLibrary.simpleMessage(
            "هل ترغب أيضًا في حذف الصور (ومقاطع الفيديو) الموجودة في هذا الألبوم من <bold>جميع</bold> الألبومات الأخرى التي هي جزء منها؟"),
        "deleteAlbumsDialogBody": MessageLookupByLibrary.simpleMessage(
            "سيؤدي هذا إلى حذف جميع الألبومات الفارغة. هذا مفيد عندما تريد تقليل الفوضى في قائمة ألبوماتك."),
        "deleteAll": MessageLookupByLibrary.simpleMessage("حذف الكل"),
        "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
            "هذا الحساب مرتبط بتطبيقات Ente الأخرى، إذا كنت تستخدم أيًا منها. سيتم جدولة بياناتك التي تم تحميلها، عبر جميع تطبيقات Ente، للحذف، وسيتم حذف حسابك نهائيًا."),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "أرسل بريدًا إلكترونيًا إلى <warning>account-deletion@ente.io</warning> من عنوان بريدك الإلكتروني المسجل."),
        "deleteEmptyAlbums":
            MessageLookupByLibrary.simpleMessage("حذف الألبومات الفارغة"),
        "deleteEmptyAlbumsWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("حذف الألبومات الفارغة؟"),
        "deleteFromBoth":
            MessageLookupByLibrary.simpleMessage("الحذف من كليهما"),
        "deleteFromDevice":
            MessageLookupByLibrary.simpleMessage("الحذف من الجهاز"),
        "deleteFromEnte": MessageLookupByLibrary.simpleMessage("الحذف من Ente"),
        "deleteItemCount": m21,
        "deleteLocation": MessageLookupByLibrary.simpleMessage("حذف الموقع"),
        "deletePhotos": MessageLookupByLibrary.simpleMessage("حذف الصور"),
        "deleteProgress": m22,
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
            "تفتقد إلى ميزة أساسية أحتاجها"),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
            "التطبيق أو ميزة معينة لا تعمل كما هو متوقع"),
        "deleteReason3":
            MessageLookupByLibrary.simpleMessage("وجدت خدمة أخرى أفضل"),
        "deleteReason4": MessageLookupByLibrary.simpleMessage("سببي غير مدرج"),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
            "ستتم معالجة طلبك خلال 72 ساعة."),
        "deleteSharedAlbum":
            MessageLookupByLibrary.simpleMessage("حذف الألبوم المشترك؟"),
        "deleteSharedAlbumDialogBody": MessageLookupByLibrary.simpleMessage(
            "سيتم حذف الألبوم للجميع.\n\nستفقد الوصول إلى الصور المشتركة في هذا الألبوم التي يملكها الآخرون."),
        "deselectAll": MessageLookupByLibrary.simpleMessage("إلغاء تحديد الكل"),
        "designedToOutlive":
            MessageLookupByLibrary.simpleMessage("مصممة لتدوم"),
        "details": MessageLookupByLibrary.simpleMessage("التفاصيل"),
        "developerSettings":
            MessageLookupByLibrary.simpleMessage("إعدادات المطور"),
        "developerSettingsWarning": MessageLookupByLibrary.simpleMessage(
            "هل أنت متأكد من رغبتك في تعديل إعدادات المطور؟"),
        "deviceCodeHint": MessageLookupByLibrary.simpleMessage("أدخل الرمز"),
        "deviceFilesAutoUploading": MessageLookupByLibrary.simpleMessage(
            "سيتم تحميل الملفات المضافة إلى ألبوم الجهاز هذا تلقائيًا إلى Ente."),
        "deviceLock": MessageLookupByLibrary.simpleMessage("قفل الجهاز"),
        "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
            "عطّل قفل شاشة الجهاز عندما يكون Ente قيد التشغيل في المقدمة ويقوم بالنسخ الاحتياطي.\nهذا الإجراء غير مطلوب عادةً، لكنه قد يسرّع إكمال التحميلات الكبيرة أو الاستيرادات الأولية للمكتبات الضخمة."),
        "deviceNotFound":
            MessageLookupByLibrary.simpleMessage("لم يتم العثور على الجهاز"),
        "didYouKnow": MessageLookupByLibrary.simpleMessage("هل تعلم؟"),
        "disableAutoLock":
            MessageLookupByLibrary.simpleMessage("تعطيل القفل التلقائي"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "لا يزال بإمكان المشاهدين التقاط لقطات شاشة أو حفظ نسخة من صورك باستخدام أدوات خارجية."),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("يرجى الملاحظة"),
        "disableLinkMessage": m23,
        "disableTwofactor":
            MessageLookupByLibrary.simpleMessage("تعطيل المصادقة الثنائية"),
        "disablingTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "جارٍ تعطيل المصادقة الثنائية..."),
        "discord": MessageLookupByLibrary.simpleMessage("Discord"),
        "discover": MessageLookupByLibrary.simpleMessage("اكتشاف"),
        "discover_babies": MessageLookupByLibrary.simpleMessage("الأطفال"),
        "discover_celebrations":
            MessageLookupByLibrary.simpleMessage("الاحتفالات"),
        "discover_food": MessageLookupByLibrary.simpleMessage("الطعام"),
        "discover_greenery":
            MessageLookupByLibrary.simpleMessage("المساحات الخضراء"),
        "discover_hills": MessageLookupByLibrary.simpleMessage("التلال"),
        "discover_identity": MessageLookupByLibrary.simpleMessage("الهوية"),
        "discover_memes": MessageLookupByLibrary.simpleMessage("الميمز"),
        "discover_notes": MessageLookupByLibrary.simpleMessage("الملاحظات"),
        "discover_pets":
            MessageLookupByLibrary.simpleMessage("الحيوانات الأليفة"),
        "discover_receipts": MessageLookupByLibrary.simpleMessage("الإيصالات"),
        "discover_screenshots":
            MessageLookupByLibrary.simpleMessage("لقطات الشاشة"),
        "discover_selfies": MessageLookupByLibrary.simpleMessage("صور السيلفي"),
        "discover_sunset": MessageLookupByLibrary.simpleMessage("غروب الشمس"),
        "discover_visiting_cards":
            MessageLookupByLibrary.simpleMessage("بطاقات الزيارة"),
        "discover_wallpapers": MessageLookupByLibrary.simpleMessage("الخلفيات"),
        "dismiss": MessageLookupByLibrary.simpleMessage("تجاهل"),
        "distanceInKMUnit": MessageLookupByLibrary.simpleMessage("كم"),
        "doNotSignOut":
            MessageLookupByLibrary.simpleMessage("عدم تسجيل الخروج"),
        "doThisLater": MessageLookupByLibrary.simpleMessage("لاحقًا"),
        "doYouWantToDiscardTheEditsYouHaveMade":
            MessageLookupByLibrary.simpleMessage(
                "هل تريد تجاهل التعديلات التي قمت بها؟"),
        "done": MessageLookupByLibrary.simpleMessage("تم"),
        "dontSave": MessageLookupByLibrary.simpleMessage("عدم الحفظ"),
        "doubleYourStorage": MessageLookupByLibrary.simpleMessage(
            "ضاعف مساحة التخزين الخاصة بك"),
        "download": MessageLookupByLibrary.simpleMessage("تنزيل"),
        "downloadFailed": MessageLookupByLibrary.simpleMessage("فشل التنزيل"),
        "downloading": MessageLookupByLibrary.simpleMessage("جارٍ التنزيل..."),
        "dropSupportEmail": m24,
        "duplicateFileCountWithStorageSaved": m25,
        "duplicateItemsGroup": m26,
        "edit": MessageLookupByLibrary.simpleMessage("تعديل"),
        "editLocation": MessageLookupByLibrary.simpleMessage("تعديل الموقع"),
        "editLocationTagTitle":
            MessageLookupByLibrary.simpleMessage("تعديل الموقع"),
        "editPerson": MessageLookupByLibrary.simpleMessage("تعديل الشخص"),
        "editTime": MessageLookupByLibrary.simpleMessage("تعديل الوقت"),
        "editsSaved": MessageLookupByLibrary.simpleMessage("تم حفظ التعديلات."),
        "editsToLocationWillOnlyBeSeenWithinEnte":
            MessageLookupByLibrary.simpleMessage(
                "ستكون التعديلات على الموقع مرئية فقط داخل Ente."),
        "eligible": MessageLookupByLibrary.simpleMessage("مؤهل"),
        "email": MessageLookupByLibrary.simpleMessage("البريد الإلكتروني"),
        "emailAlreadyRegistered": MessageLookupByLibrary.simpleMessage(
            "البريد الإلكتروني مُسجل من قبل."),
        "emailChangedTo": m27,
        "emailDoesNotHaveEnteAccount": m28,
        "emailNoEnteAccount": m29,
        "emailNotRegistered":
            MessageLookupByLibrary.simpleMessage("البريد الإلكتروني غير مسجل."),
        "emailVerificationToggle": MessageLookupByLibrary.simpleMessage(
            "تأكيد عنوان البريد الإلكتروني"),
        "emailYourLogs": MessageLookupByLibrary.simpleMessage(
            "إرسال سجلاتك عبر البريد الإلكتروني"),
        "embracingThem": m30,
        "emergencyContacts":
            MessageLookupByLibrary.simpleMessage("جهات اتصال الطوارئ"),
        "empty": MessageLookupByLibrary.simpleMessage("إفراغ"),
        "emptyTrash":
            MessageLookupByLibrary.simpleMessage("إفراغ سلة المهملات؟"),
        "enable": MessageLookupByLibrary.simpleMessage("تمكين"),
        "enableMLIndexingDesc": MessageLookupByLibrary.simpleMessage(
            "يدعم Ente تعلم الآلة على الجهاز للتعرف على الوجوه والبحث السحري وميزات البحث المتقدم الأخرى."),
        "enableMachineLearningBanner": MessageLookupByLibrary.simpleMessage(
            "قم بتمكين تعلم الآلة للبحث السحري والتعرف على الوجوه."),
        "enableMaps": MessageLookupByLibrary.simpleMessage("تمكين الخرائط"),
        "enableMapsDesc": MessageLookupByLibrary.simpleMessage(
            "سيؤدي هذا إلى عرض صورك على خريطة العالم.\n\nتستضيف هذه الخريطة OpenStreetMap، ولا تتم مشاركة المواقع الدقيقة لصورك أبدًا.\n\nيمكنك تعطيل هذه الميزة في أي وقت من الإعدادات."),
        "enabled": MessageLookupByLibrary.simpleMessage("مُمكّن"),
        "encryptingBackup": MessageLookupByLibrary.simpleMessage(
            "جارٍ تشفير النسخة الاحتياطية..."),
        "encryption": MessageLookupByLibrary.simpleMessage("التشفير"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("مفاتيح التشفير"),
        "endpointUpdatedMessage": MessageLookupByLibrary.simpleMessage(
            "تم تحديث نقطة النهاية بنجاح."),
        "endtoendEncryptedByDefault": MessageLookupByLibrary.simpleMessage(
            "تشفير من طرف إلى طرف بشكل افتراضي"),
        "enteCanEncryptAndPreserveFilesOnlyIfYouGrant":
            MessageLookupByLibrary.simpleMessage(
                "يمكن لـ Ente تشفير وحفظ الملفات فقط إذا منحت الإذن بالوصول إليها."),
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
            "Ente <i>بحاجة إلى إذن</i> لحفظ صورك"),
        "enteSubscriptionPitch": MessageLookupByLibrary.simpleMessage(
            "يحفظ Ente ذكرياتك، بحيث تظل دائمًا متاحة لك حتى لو فقدت جهازك."),
        "enteSubscriptionShareWithFamily": MessageLookupByLibrary.simpleMessage(
            "يمكنك أيضًا إضافة أفراد عائلتك إلى خطتك."),
        "enterAlbumName":
            MessageLookupByLibrary.simpleMessage("أدخل اسم الألبوم"),
        "enterCode": MessageLookupByLibrary.simpleMessage("أدخل الرمز"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
            "أدخل الرمز المقدم من صديقك للمطالبة بمساحة تخزين مجانية لكما."),
        "enterDateOfBirth":
            MessageLookupByLibrary.simpleMessage("تاريخ الميلاد (اختياري)"),
        "enterEmail":
            MessageLookupByLibrary.simpleMessage("أدخل البريد الإلكتروني"),
        "enterFileName": MessageLookupByLibrary.simpleMessage("أدخل اسم الملف"),
        "enterName": MessageLookupByLibrary.simpleMessage("أدخل الاسم"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "أدخل كلمة مرور جديدة يمكننا استخدامها لتشفير بياناتك"),
        "enterPassword":
            MessageLookupByLibrary.simpleMessage("أدخل كلمة المرور"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "أدخل كلمة مرور يمكننا استخدامها لتشفير بياناتك"),
        "enterPersonName":
            MessageLookupByLibrary.simpleMessage("أدخل اسم الشخص"),
        "enterPin": MessageLookupByLibrary.simpleMessage("أدخل رمز PIN"),
        "enterReferralCode":
            MessageLookupByLibrary.simpleMessage("أدخل رمز الإحالة"),
        "enterThe6digitCodeFromnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "أدخل الرمز المكون من 6 أرقام من\n تطبيق المصادقة الخاص بك"),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
            "يرجى إدخال عنوان بريد إلكتروني صالح."),
        "enterYourEmailAddress":
            MessageLookupByLibrary.simpleMessage("أدخل عنوان بريدك الإلكتروني"),
        "enterYourPassword":
            MessageLookupByLibrary.simpleMessage("أدخل كلمة المرور"),
        "enterYourRecoveryKey":
            MessageLookupByLibrary.simpleMessage("أدخل مفتاح الاسترداد"),
        "error": MessageLookupByLibrary.simpleMessage("خطأ"),
        "everywhere": MessageLookupByLibrary.simpleMessage("في كل مكان"),
        "exif": MessageLookupByLibrary.simpleMessage("EXIF"),
        "existingUser": MessageLookupByLibrary.simpleMessage("مستخدم حالي"),
        "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
            "انتهت صلاحية هذا الرابط. يرجى اختيار وقت انتهاء صلاحية جديد أو تعطيل انتهاء صلاحية الرابط."),
        "exportLogs": MessageLookupByLibrary.simpleMessage("تصدير السجلات"),
        "exportYourData": MessageLookupByLibrary.simpleMessage("تصدير بياناتك"),
        "extraPhotosFound":
            MessageLookupByLibrary.simpleMessage("تم العثور على صور إضافية"),
        "extraPhotosFoundFor": m31,
        "faceNotClusteredYet": MessageLookupByLibrary.simpleMessage(
            "لم يتم تجميع الوجه بعد، يرجى العودة لاحقًا"),
        "faceRecognition":
            MessageLookupByLibrary.simpleMessage("التعرف على الوجوه"),
        "faces": MessageLookupByLibrary.simpleMessage("الوجوه"),
        "failed": MessageLookupByLibrary.simpleMessage("فشل"),
        "failedToApplyCode":
            MessageLookupByLibrary.simpleMessage("فشل تطبيق الرمز"),
        "failedToCancel": MessageLookupByLibrary.simpleMessage("فشل الإلغاء"),
        "failedToDownloadVideo":
            MessageLookupByLibrary.simpleMessage("فشل تنزيل الفيديو"),
        "failedToFetchActiveSessions":
            MessageLookupByLibrary.simpleMessage("فشل جلب الجلسات النشطة."),
        "failedToFetchOriginalForEdit": MessageLookupByLibrary.simpleMessage(
            "فشل جلب النسخة الأصلية للتعديل."),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
            "تعذر جلب تفاصيل الإحالة. يرجى المحاولة مرة أخرى لاحقًا."),
        "failedToLoadAlbums":
            MessageLookupByLibrary.simpleMessage("فشل تحميل الألبومات"),
        "failedToPlayVideo":
            MessageLookupByLibrary.simpleMessage("فشل تشغيل الفيديو."),
        "failedToRefreshStripeSubscription":
            MessageLookupByLibrary.simpleMessage("فشل تحديث الاشتراك."),
        "failedToRenew": MessageLookupByLibrary.simpleMessage("فشل التجديد"),
        "failedToVerifyPaymentStatus":
            MessageLookupByLibrary.simpleMessage("فشل التحقق من حالة الدفع."),
        "familyPlanOverview": MessageLookupByLibrary.simpleMessage(
            "أضف 5 أفراد من عائلتك إلى خطتك الحالية دون دفع رسوم إضافية.\n\nيحصل كل فرد على مساحة خاصة به، ولا يمكنهم رؤية ملفات بعضهم البعض إلا إذا تمت مشاركتها.\n\nالخطط العائلية متاحة للعملاء الذين لديهم اشتراك Ente مدفوع.\n\nاشترك الآن للبدء!"),
        "familyPlanPortalTitle":
            MessageLookupByLibrary.simpleMessage("العائلة"),
        "familyPlans": MessageLookupByLibrary.simpleMessage("الخطط العائلية"),
        "faq": MessageLookupByLibrary.simpleMessage("الأسئلة الشائعة"),
        "faqs": MessageLookupByLibrary.simpleMessage("الأسئلة الشائعة"),
        "favorite": MessageLookupByLibrary.simpleMessage("المفضلة"),
        "feastingWithThem": m32,
        "feedback": MessageLookupByLibrary.simpleMessage("ملاحظات"),
        "file": MessageLookupByLibrary.simpleMessage("ملف"),
        "fileFailedToSaveToGallery":
            MessageLookupByLibrary.simpleMessage("فشل حفظ الملف في المعرض."),
        "fileInfoAddDescHint":
            MessageLookupByLibrary.simpleMessage("إضافة وصف..."),
        "fileNotUploadedYet":
            MessageLookupByLibrary.simpleMessage("لم يتم تحميل الملف بعد"),
        "fileSavedToGallery":
            MessageLookupByLibrary.simpleMessage("تم حفظ الملف في المعرض."),
        "fileTypes": MessageLookupByLibrary.simpleMessage("أنواع الملفات"),
        "fileTypesAndNames":
            MessageLookupByLibrary.simpleMessage("أنواع وأسماء الملفات"),
        "filesBackedUpFromDevice": m33,
        "filesBackedUpInAlbum": m34,
        "filesDeleted": MessageLookupByLibrary.simpleMessage("تم حذف الملفات."),
        "filesSavedToGallery":
            MessageLookupByLibrary.simpleMessage("تم حفظ الملفات في المعرض."),
        "findPeopleByName": MessageLookupByLibrary.simpleMessage(
            "البحث عن الأشخاص بسرعة بالاسم"),
        "findThemQuickly":
            MessageLookupByLibrary.simpleMessage("اعثر عليهم بسرعة"),
        "flip": MessageLookupByLibrary.simpleMessage("قلب"),
        "food": MessageLookupByLibrary.simpleMessage("متعة الطهي"),
        "forYourMemories": MessageLookupByLibrary.simpleMessage("لذكرياتك"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("نسيت كلمة المرور؟"),
        "foundFaces":
            MessageLookupByLibrary.simpleMessage("الوجوه التي تم العثور عليها"),
        "freeStorageClaimed": MessageLookupByLibrary.simpleMessage(
            "تم المطالبة بمساحة التخزين المجانية"),
        "freeStorageOnReferralSuccess": m35,
        "freeStorageUsable": MessageLookupByLibrary.simpleMessage(
            "مساحة تخزين مجانية متاحة للاستخدام"),
        "freeTrial": MessageLookupByLibrary.simpleMessage("تجربة مجانية"),
        "freeTrialValidTill": m36,
        "freeUpAccessPostDelete": m37,
        "freeUpAmount": m38,
        "freeUpDeviceSpace":
            MessageLookupByLibrary.simpleMessage("تحرير مساحة على الجهاز"),
        "freeUpDeviceSpaceDesc": MessageLookupByLibrary.simpleMessage(
            "وفر مساحة على جهازك عن طريق مسح الملفات التي تم نسخها احتياطيًا."),
        "freeUpSpace": MessageLookupByLibrary.simpleMessage("تحرير المساحة"),
        "freeUpSpaceSaving": m39,
        "gallery": MessageLookupByLibrary.simpleMessage("المعرض"),
        "galleryMemoryLimitInfo": MessageLookupByLibrary.simpleMessage(
            "يتم عرض ما يصل إلى 1000 ذكرى في المعرض."),
        "general": MessageLookupByLibrary.simpleMessage("عام"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "جارٍ إنشاء مفاتيح التشفير..."),
        "genericProgress": m40,
        "goToSettings":
            MessageLookupByLibrary.simpleMessage("الانتقال إلى الإعدادات"),
        "googlePlayId":
            MessageLookupByLibrary.simpleMessage("معرّف Google Play"),
        "grantFullAccessPrompt": MessageLookupByLibrary.simpleMessage(
            "يرجى السماح بالوصول إلى جميع الصور في تطبيق الإعدادات."),
        "grantPermission": MessageLookupByLibrary.simpleMessage("منح الإذن"),
        "greenery": MessageLookupByLibrary.simpleMessage("الحياة الخضراء"),
        "groupNearbyPhotos":
            MessageLookupByLibrary.simpleMessage("تجميع الصور القريبة"),
        "guestView": MessageLookupByLibrary.simpleMessage("عرض الضيف"),
        "guestViewEnablePreSteps": MessageLookupByLibrary.simpleMessage(
            "لتمكين عرض الضيف، يرجى إعداد رمز مرور الجهاز أو قفل الشاشة في إعدادات النظام."),
        "hearUsExplanation": MessageLookupByLibrary.simpleMessage(
            "نحن لا نتتبع عمليات تثبيت التطبيق. سيساعدنا إذا أخبرتنا أين وجدتنا!"),
        "hearUsWhereTitle":
            MessageLookupByLibrary.simpleMessage("كيف سمعت عن Ente؟ (اختياري)"),
        "help": MessageLookupByLibrary.simpleMessage("المساعدة"),
        "hidden": MessageLookupByLibrary.simpleMessage("المخفية"),
        "hide": MessageLookupByLibrary.simpleMessage("إخفاء"),
        "hideContent": MessageLookupByLibrary.simpleMessage("إخفاء المحتوى"),
        "hideContentDescriptionAndroid": MessageLookupByLibrary.simpleMessage(
            "يخفي محتوى التطبيق في مبدل التطبيقات ويعطل لقطات الشاشة."),
        "hideContentDescriptionIos": MessageLookupByLibrary.simpleMessage(
            "يخفي محتوى التطبيق في مبدل التطبيقات."),
        "hideSharedItemsFromHomeGallery": MessageLookupByLibrary.simpleMessage(
            "إخفاء العناصر المشتركة من معرض الصفحة الرئيسية"),
        "hiding": MessageLookupByLibrary.simpleMessage("جارٍ الإخفاء..."),
        "hikingWithThem": m41,
        "hostedAtOsmFrance":
            MessageLookupByLibrary.simpleMessage("مستضاف في OSM France"),
        "howItWorks": MessageLookupByLibrary.simpleMessage("كيف يعمل"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
            "يرجى الطلب منهم الضغط مطولًا على عنوان بريدهم الإلكتروني في شاشة الإعدادات، والتأكد من تطابق المعرّفات على كلا الجهازين."),
        "iOSGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "لم يتم إعداد المصادقة البيومترية على جهازك. يرجى تمكين Touch ID أو Face ID على هاتفك."),
        "iOSLockOut": MessageLookupByLibrary.simpleMessage(
            "تم تعطيل المصادقة البيومترية. يرجى قفل شاشتك وفتحها لتمكينها."),
        "iOSOkButton": MessageLookupByLibrary.simpleMessage("موافق"),
        "ignoreUpdate": MessageLookupByLibrary.simpleMessage("تجاهل"),
        "ignored": MessageLookupByLibrary.simpleMessage("تم التجاهل"),
        "ignoredFolderUploadReason": MessageLookupByLibrary.simpleMessage(
            "تم تجاهل تحميل بعض الملفات في هذا الألبوم لأنه تم حذفها مسبقًا من Ente."),
        "imageNotAnalyzed":
            MessageLookupByLibrary.simpleMessage("لم يتم تحليل الصورة"),
        "immediately": MessageLookupByLibrary.simpleMessage("فورًا"),
        "importing": MessageLookupByLibrary.simpleMessage("جارٍ الاستيراد..."),
        "incorrectCode": MessageLookupByLibrary.simpleMessage("رمز غير صحيح"),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("كلمة المرور غير صحيحة"),
        "incorrectRecoveryKey":
            MessageLookupByLibrary.simpleMessage("مفتاح الاسترداد غير صحيح."),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "مفتاح الاسترداد الذي أدخلته غير صحيح"),
        "incorrectRecoveryKeyTitle":
            MessageLookupByLibrary.simpleMessage("مفتاح الاسترداد غير صحيح"),
        "indexedItems":
            MessageLookupByLibrary.simpleMessage("العناصر المفهرسة"),
        "indexingIsPaused": MessageLookupByLibrary.simpleMessage(
            "الفهرسة متوقفة مؤقتًا. سيتم استئنافها تلقائيًا عندما يكون الجهاز جاهزًا."),
        "ineligible": MessageLookupByLibrary.simpleMessage("غير مؤهل"),
        "info": MessageLookupByLibrary.simpleMessage("معلومات"),
        "insecureDevice": MessageLookupByLibrary.simpleMessage("جهاز غير آمن"),
        "installManually":
            MessageLookupByLibrary.simpleMessage("التثبيت يدويًا"),
        "invalidEmailAddress": MessageLookupByLibrary.simpleMessage(
            "عنوان البريد الإلكتروني غير صالح"),
        "invalidEndpoint":
            MessageLookupByLibrary.simpleMessage("نقطة النهاية غير صالحة"),
        "invalidEndpointMessage": MessageLookupByLibrary.simpleMessage(
            "عذرًا، نقطة النهاية التي أدخلتها غير صالحة. يرجى إدخال نقطة نهاية صالحة والمحاولة مرة أخرى."),
        "invalidKey": MessageLookupByLibrary.simpleMessage("المفتاح غير صالح"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "مفتاح الاسترداد الذي أدخلته غير صالح. يرجى التأكد من أنه يحتوي على 24 كلمة، والتحقق من كتابة كل كلمة بشكل صحيح.\n\nإذا كنت تستخدم مفتاح استرداد قديمًا، تأكد من أنه مكون من 64 حرفًا، وتحقق من صحة كل حرف."),
        "invite": MessageLookupByLibrary.simpleMessage("دعوة"),
        "inviteToEnte": MessageLookupByLibrary.simpleMessage("دعوة إلى Ente"),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("ادعُ أصدقاءك"),
        "inviteYourFriendsToEnte":
            MessageLookupByLibrary.simpleMessage("ادعُ أصدقاءك إلى Ente"),
        "itLooksLikeSomethingWentWrongPleaseRetryAfterSome":
            MessageLookupByLibrary.simpleMessage(
                "يبدو أن خطأً ما قد حدث. يرجى المحاولة مرة أخرى بعد بعض الوقت. إذا استمر الخطأ، يرجى الاتصال بفريق الدعم لدينا."),
        "itemCount": m42,
        "itemsShowTheNumberOfDaysRemainingBeforePermanentDeletion":
            MessageLookupByLibrary.simpleMessage(
                "تعرض العناصر عدد الأيام المتبقية قبل الحذف الدائم."),
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
            "سيتم إزالة العناصر المحددة من هذا الألبوم."),
        "join": MessageLookupByLibrary.simpleMessage("انضمام"),
        "joinAlbum":
            MessageLookupByLibrary.simpleMessage("الانضمام إلى الألبوم"),
        "joinAlbumConfirmationDialogBody": MessageLookupByLibrary.simpleMessage(
            "الانضمام إلى ألبوم سيجعل بريدك الإلكتروني مرئيًا للمشاركين فيه."),
        "joinAlbumSubtext":
            MessageLookupByLibrary.simpleMessage("لعرض صورك وإضافتها"),
        "joinAlbumSubtextViewer": MessageLookupByLibrary.simpleMessage(
            "لإضافة هذا إلى الألبومات المشتركة"),
        "joinDiscord":
            MessageLookupByLibrary.simpleMessage("الانضمام إلى Discord"),
        "keepPhotos": MessageLookupByLibrary.simpleMessage("الاحتفاظ بالصور"),
        "kiloMeterUnit": MessageLookupByLibrary.simpleMessage("كم"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "يرجى مساعدتنا بهذه المعلومات"),
        "language": MessageLookupByLibrary.simpleMessage("اللغة"),
        "lastTimeWithThem": m43,
        "lastUpdated": MessageLookupByLibrary.simpleMessage("آخر تحديث"),
        "lastYearsTrip":
            MessageLookupByLibrary.simpleMessage("رحلة العام الماضي"),
        "leave": MessageLookupByLibrary.simpleMessage("مغادرة"),
        "leaveAlbum": MessageLookupByLibrary.simpleMessage("مغادرة الألبوم"),
        "leaveFamily":
            MessageLookupByLibrary.simpleMessage("مغادرة خطة العائلة"),
        "leaveSharedAlbum":
            MessageLookupByLibrary.simpleMessage("مغادرة الألبوم المشترك؟"),
        "left": MessageLookupByLibrary.simpleMessage("يسار"),
        "legacy": MessageLookupByLibrary.simpleMessage("جهات الاتصال الموثوقة"),
        "legacyAccounts":
            MessageLookupByLibrary.simpleMessage("الحسابات الموثوقة"),
        "legacyInvite": m44,
        "legacyPageDesc": MessageLookupByLibrary.simpleMessage(
            "تسمح جهات الاتصال الموثوقة لأشخاص معينين بالوصول إلى حسابك في حالة غيابك."),
        "legacyPageDesc2": MessageLookupByLibrary.simpleMessage(
            "يمكن لجهات الاتصال الموثوقة بدء استرداد الحساب، وإذا لم يتم حظر ذلك خلال 30 يومًا، يمكنهم إعادة تعيين كلمة المرور والوصول إلى حسابك."),
        "light": MessageLookupByLibrary.simpleMessage("فاتح"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("فاتح"),
        "link": MessageLookupByLibrary.simpleMessage("ربط"),
        "linkCopiedToClipboard":
            MessageLookupByLibrary.simpleMessage("تم نسخ الرابط إلى الحافظة."),
        "linkDeviceLimit": MessageLookupByLibrary.simpleMessage("حد الأجهزة"),
        "linkEmail":
            MessageLookupByLibrary.simpleMessage("ربط البريد الإلكتروني"),
        "linkEmailToContactBannerCaption":
            MessageLookupByLibrary.simpleMessage("لمشاركة أسرع"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("مفعّل"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("منتهي الصلاحية"),
        "linkExpiresOn": m45,
        "linkExpiry":
            MessageLookupByLibrary.simpleMessage("انتهاء صلاحية الرابط"),
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("انتهت صلاحية الرابط"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("أبدًا"),
        "linkPerson": MessageLookupByLibrary.simpleMessage("ربط الشخص"),
        "linkPersonCaption":
            MessageLookupByLibrary.simpleMessage("لتجربة مشاركة أفضل"),
        "linkPersonToEmail": m46,
        "linkPersonToEmailConfirmation": m47,
        "livePhotos": MessageLookupByLibrary.simpleMessage("الصور الحية"),
        "loadMessage1": MessageLookupByLibrary.simpleMessage(
            "يمكنك مشاركة اشتراكك مع عائلتك."),
        "loadMessage2": MessageLookupByLibrary.simpleMessage(
            "لقد حفظنا أكثر من 30 مليون ذكرى حتى الآن."),
        "loadMessage3": MessageLookupByLibrary.simpleMessage(
            "نحتفظ بـ 3 نسخ من بياناتك، إحداها في ملجأ للطوارئ تحت الأرض."),
        "loadMessage4": MessageLookupByLibrary.simpleMessage(
            "جميع تطبيقاتنا مفتوحة المصدر."),
        "loadMessage5": MessageLookupByLibrary.simpleMessage(
            "تم تدقيق شفرتنا المصدرية والتشفير الخاص بنا خارجيًا."),
        "loadMessage6": MessageLookupByLibrary.simpleMessage(
            "يمكنك مشاركة روابط ألبوماتك مع أحبائك."),
        "loadMessage7": MessageLookupByLibrary.simpleMessage(
            "تعمل تطبيقات الهاتف المحمول الخاصة بنا في الخلفية لتشفير أي صور جديدة تلتقطها ونسخها احتياطيًا."),
        "loadMessage8": MessageLookupByLibrary.simpleMessage(
            "web.ente.io لديه أداة تحميل رائعة."),
        "loadMessage9": MessageLookupByLibrary.simpleMessage(
            "نستخدم XChaCha20-Poly1305 لتشفير بياناتك بأمان."),
        "loadingExifData":
            MessageLookupByLibrary.simpleMessage("جارٍ تحميل بيانات EXIF..."),
        "loadingGallery":
            MessageLookupByLibrary.simpleMessage("جارٍ تحميل المعرض..."),
        "loadingMessage":
            MessageLookupByLibrary.simpleMessage("جارٍ تحميل صورك..."),
        "loadingModel":
            MessageLookupByLibrary.simpleMessage("جارٍ تحميل النماذج..."),
        "loadingYourPhotos":
            MessageLookupByLibrary.simpleMessage("جارٍ تحميل صورك..."),
        "localGallery": MessageLookupByLibrary.simpleMessage("المعرض المحلي"),
        "localIndexing":
            MessageLookupByLibrary.simpleMessage("الفهرسة المحلية"),
        "localSyncErrorMessage": MessageLookupByLibrary.simpleMessage(
            "يبدو أن خطأً ما قد حدث لأن مزامنة الصور المحلية تستغرق وقتًا أطول من المتوقع. يرجى التواصل مع فريق الدعم لدينا."),
        "location": MessageLookupByLibrary.simpleMessage("الموقع"),
        "locationName": MessageLookupByLibrary.simpleMessage("اسم الموقع"),
        "locationTagFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "تقوم علامة الموقع بتجميع جميع الصور التي تم التقاطها ضمن نصف قطر معين لصورة ما."),
        "locations": MessageLookupByLibrary.simpleMessage("المواقع"),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("قفل"),
        "lockscreen": MessageLookupByLibrary.simpleMessage("شاشة القفل"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("تسجيل الدخول"),
        "loggingOut":
            MessageLookupByLibrary.simpleMessage("جارٍ تسجيل الخروج..."),
        "loginSessionExpired":
            MessageLookupByLibrary.simpleMessage("انتهت صلاحية الجلسة."),
        "loginSessionExpiredDetails": MessageLookupByLibrary.simpleMessage(
            "انتهت صلاحية جلستك. يرجى تسجيل الدخول مرة أخرى."),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "بالنقر على تسجيل الدخول، أوافق على <u-terms>شروط الخدمة</u-terms> و <u-policy>سياسة الخصوصية</u-policy>"),
        "loginWithTOTP":
            MessageLookupByLibrary.simpleMessage("تسجيل الدخول باستخدام TOTP"),
        "logout": MessageLookupByLibrary.simpleMessage("تسجيل الخروج"),
        "logsDialogBody": MessageLookupByLibrary.simpleMessage(
            "سيؤدي هذا إلى إرسال السجلات لمساعدتنا في تصحيح مشكلتك. يرجى ملاحظة أنه سيتم تضمين أسماء الملفات للمساعدة في تتبع المشكلات المتعلقة بملفات معينة."),
        "longPressAnEmailToVerifyEndToEndEncryption":
            MessageLookupByLibrary.simpleMessage(
                "اضغط مطولاً على بريد إلكتروني للتحقق من التشفير من طرف إلى طرف."),
        "longpressOnAnItemToViewInFullscreen":
            MessageLookupByLibrary.simpleMessage(
                "اضغط مطولاً على عنصر لعرضه في وضع ملء الشاشة."),
        "loopVideoOff":
            MessageLookupByLibrary.simpleMessage("إيقاف تكرار الفيديو"),
        "loopVideoOn":
            MessageLookupByLibrary.simpleMessage("تشغيل تكرار الفيديو"),
        "lostDevice": MessageLookupByLibrary.simpleMessage("جهاز مفقود؟"),
        "machineLearning": MessageLookupByLibrary.simpleMessage("تعلم الآلة"),
        "magicSearch": MessageLookupByLibrary.simpleMessage("البحث السحري"),
        "magicSearchHint": MessageLookupByLibrary.simpleMessage(
            "يسمح البحث السحري بالبحث عن الصور حسب محتوياتها، مثل \'زهرة\'، \'سيارة حمراء\'، \'وثائق هوية\'"),
        "manage": MessageLookupByLibrary.simpleMessage("إدارة"),
        "manageDeviceStorage":
            MessageLookupByLibrary.simpleMessage("إدارة مساحة تخزين الجهاز"),
        "manageDeviceStorageDesc": MessageLookupByLibrary.simpleMessage(
            "مراجعة ومسح ذاكرة التخزين المؤقت المحلية."),
        "manageFamily": MessageLookupByLibrary.simpleMessage("إدارة العائلة"),
        "manageLink": MessageLookupByLibrary.simpleMessage("إدارة الرابط"),
        "manageParticipants":
            MessageLookupByLibrary.simpleMessage("إدارة المشاركين"),
        "manageSubscription":
            MessageLookupByLibrary.simpleMessage("إدارة الاشتراك"),
        "manualPairDesc": MessageLookupByLibrary.simpleMessage(
            "الإقران بالرمز السري يعمل مع أي شاشة ترغب في عرض ألبومك عليها."),
        "map": MessageLookupByLibrary.simpleMessage("الخريطة"),
        "maps": MessageLookupByLibrary.simpleMessage("الخرائط"),
        "mastodon": MessageLookupByLibrary.simpleMessage("Mastodon"),
        "matrix": MessageLookupByLibrary.simpleMessage("Matrix"),
        "me": MessageLookupByLibrary.simpleMessage("أنا"),
        "memoryCount": m48,
        "merchandise":
            MessageLookupByLibrary.simpleMessage("المنتجات الترويجية"),
        "mergeWithExisting":
            MessageLookupByLibrary.simpleMessage("الدمج مع شخص موجود"),
        "mergedPhotos": MessageLookupByLibrary.simpleMessage("الصور المدمجة"),
        "mlConsent": MessageLookupByLibrary.simpleMessage("تمكين تعلم الآلة"),
        "mlConsentConfirmation": MessageLookupByLibrary.simpleMessage(
            "أنا أفهم، وأرغب في تمكين تعلم الآلة"),
        "mlConsentDescription": MessageLookupByLibrary.simpleMessage(
            "إذا قمت بتمكين تعلم الآلة، سيقوم Ente باستخراج معلومات مثل هندسة الوجه من الملفات، بما في ذلك تلك التي تمت مشاركتها معك.\n\nسيحدث هذا على جهازك، وسيتم تشفير أي معلومات بيومترية تم إنشاؤها تشفيرًا تامًا من طرف إلى طرف."),
        "mlConsentPrivacy": MessageLookupByLibrary.simpleMessage(
            "يرجى النقر هنا لمزيد من التفاصيل حول هذه الميزة في سياسة الخصوصية الخاصة بنا"),
        "mlConsentTitle":
            MessageLookupByLibrary.simpleMessage("تمكين تعلم الآلة؟"),
        "mlIndexingDescription": MessageLookupByLibrary.simpleMessage(
            "يرجى ملاحظة أن تعلم الآلة سيؤدي إلى استهلاك أعلى لعرض النطاق الترددي والبطارية حتى تتم فهرسة جميع العناصر.\nنوصي باستخدام تطبيق سطح المكتب لإجراء الفهرسة بشكل أسرع. سيتم مزامنة جميع النتائج تلقائيًا."),
        "mobileWebDesktop": MessageLookupByLibrary.simpleMessage(
            "الهاتف المحمول، الويب، سطح المكتب"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("متوسطة"),
        "modifyYourQueryOrTrySearchingFor":
            MessageLookupByLibrary.simpleMessage(
                "قم بتعديل استعلامك، أو حاول البحث عن"),
        "moments": MessageLookupByLibrary.simpleMessage("اللحظات"),
        "month": MessageLookupByLibrary.simpleMessage("شهر"),
        "monthly": MessageLookupByLibrary.simpleMessage("شهريًا"),
        "moon": MessageLookupByLibrary.simpleMessage("في ضوء القمر"),
        "moreDetails":
            MessageLookupByLibrary.simpleMessage("المزيد من التفاصيل"),
        "mostRecent": MessageLookupByLibrary.simpleMessage("الأحدث"),
        "mostRelevant": MessageLookupByLibrary.simpleMessage("الأكثر صلة"),
        "mountains": MessageLookupByLibrary.simpleMessage("فوق التلال"),
        "moveItem": m49,
        "moveSelectedPhotosToOneDate": MessageLookupByLibrary.simpleMessage(
            "نقل الصور المحددة إلى تاريخ واحد"),
        "moveToAlbum": MessageLookupByLibrary.simpleMessage("نقل إلى ألبوم"),
        "moveToHiddenAlbum":
            MessageLookupByLibrary.simpleMessage("نقل إلى الألبوم المخفي"),
        "movedSuccessfullyTo": m50,
        "movedToTrash":
            MessageLookupByLibrary.simpleMessage("تم النقل إلى سلة المهملات"),
        "movingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "جارٍ نقل الملفات إلى الألبوم..."),
        "name": MessageLookupByLibrary.simpleMessage("الاسم"),
        "nameTheAlbum": MessageLookupByLibrary.simpleMessage("تسمية الألبوم"),
        "networkConnectionRefusedErr": MessageLookupByLibrary.simpleMessage(
            "تعذر الاتصال بـ Ente، يرجى المحاولة مرة أخرى بعد بعض الوقت. إذا استمر الخطأ، يرجى الاتصال بالدعم."),
        "networkHostLookUpErr": MessageLookupByLibrary.simpleMessage(
            "تعذر الاتصال بـ Ente، يرجى التحقق من إعدادات الشبكة والاتصال بالدعم إذا استمر الخطأ."),
        "never": MessageLookupByLibrary.simpleMessage("أبدًا"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("ألبوم جديد"),
        "newLocation": MessageLookupByLibrary.simpleMessage("موقع جديد"),
        "newPerson": MessageLookupByLibrary.simpleMessage("شخص جديد"),
        "newRange": MessageLookupByLibrary.simpleMessage("نطاق جديد"),
        "newToEnte": MessageLookupByLibrary.simpleMessage("جديد في Ente"),
        "newest": MessageLookupByLibrary.simpleMessage("الأحدث"),
        "next": MessageLookupByLibrary.simpleMessage("التالي"),
        "no": MessageLookupByLibrary.simpleMessage("لا"),
        "noAlbumsSharedByYouYet":
            MessageLookupByLibrary.simpleMessage("لم تشارك أي ألبومات بعد"),
        "noDeviceFound":
            MessageLookupByLibrary.simpleMessage("لم يتم العثور على جهاز."),
        "noDeviceLimit": MessageLookupByLibrary.simpleMessage("لا شيء"),
        "noDeviceThatCanBeDeleted": MessageLookupByLibrary.simpleMessage(
            "لا توجد ملفات على هذا الجهاز يمكن حذفها."),
        "noDuplicates":
            MessageLookupByLibrary.simpleMessage("✨ لا توجد ملفات مكررة"),
        "noEnteAccountExclamation":
            MessageLookupByLibrary.simpleMessage("لا يوجد حساب Ente!"),
        "noExifData":
            MessageLookupByLibrary.simpleMessage("لا توجد بيانات EXIF"),
        "noFacesFound":
            MessageLookupByLibrary.simpleMessage("لم يتم العثور على وجوه"),
        "noHiddenPhotosOrVideos": MessageLookupByLibrary.simpleMessage(
            "لا توجد صور أو مقاطع فيديو مخفية"),
        "noImagesWithLocation":
            MessageLookupByLibrary.simpleMessage("لا توجد صور تحتوي على موقع"),
        "noInternetConnection":
            MessageLookupByLibrary.simpleMessage("لا يوجد اتصال بالإنترنت"),
        "noPhotosAreBeingBackedUpRightNow":
            MessageLookupByLibrary.simpleMessage(
                "لا يتم نسخ أي صور احتياطيًا في الوقت الحالي."),
        "noPhotosFoundHere":
            MessageLookupByLibrary.simpleMessage("لم يتم العثور على صور هنا"),
        "noQuickLinksSelected":
            MessageLookupByLibrary.simpleMessage("لم يتم تحديد روابط سريعة."),
        "noRecoveryKey":
            MessageLookupByLibrary.simpleMessage("لا تملك مفتاح استرداد؟"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "نظرًا لطبيعة التشفير الكامل من طرف إلى طرف، لا يمكن فك تشفير بياناتك بدون كلمة المرور أو مفتاح الاسترداد الخاص بك."),
        "noResults": MessageLookupByLibrary.simpleMessage("لا توجد نتائج"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("لم يتم العثور على نتائج."),
        "noSuggestionsForPerson": m51,
        "noSystemLockFound":
            MessageLookupByLibrary.simpleMessage("لم يتم العثور على قفل نظام."),
        "notPersonLabel": m52,
        "notThisPerson": MessageLookupByLibrary.simpleMessage("ليس هذا الشخص؟"),
        "nothingSharedWithYouYet": MessageLookupByLibrary.simpleMessage(
            "لم تتم مشاركة أي شيء معك بعد"),
        "nothingToSeeHere":
            MessageLookupByLibrary.simpleMessage("لا يوجد شيء هنا! 👀"),
        "notifications": MessageLookupByLibrary.simpleMessage("الإشعارات"),
        "ok": MessageLookupByLibrary.simpleMessage("حسنًا"),
        "onDevice": MessageLookupByLibrary.simpleMessage("على الجهاز"),
        "onEnte": MessageLookupByLibrary.simpleMessage(
            "على <branding>Ente</branding>"),
        "onTheRoad":
            MessageLookupByLibrary.simpleMessage("على الطريق مرة أخرى"),
        "onlyFamilyAdminCanChangeCode": m53,
        "onlyThem": MessageLookupByLibrary.simpleMessage("هم فقط"),
        "oops": MessageLookupByLibrary.simpleMessage("عفوًا"),
        "oopsCouldNotSaveEdits":
            MessageLookupByLibrary.simpleMessage("عفوًا، تعذر حفظ التعديلات."),
        "oopsSomethingWentWrong":
            MessageLookupByLibrary.simpleMessage("عفوًا، حدث خطأ ما"),
        "openAlbumInBrowser":
            MessageLookupByLibrary.simpleMessage("فتح الألبوم في المتصفح"),
        "openAlbumInBrowserTitle": MessageLookupByLibrary.simpleMessage(
            "يرجى استخدام تطبيق الويب لإضافة صور إلى هذا الألبوم"),
        "openFile": MessageLookupByLibrary.simpleMessage("فتح الملف"),
        "openSettings": MessageLookupByLibrary.simpleMessage("فتح الإعدادات"),
        "openTheItem": MessageLookupByLibrary.simpleMessage("• افتح العنصر"),
        "openstreetmapContributors":
            MessageLookupByLibrary.simpleMessage("مساهمو OpenStreetMap"),
        "optionalAsShortAsYouLike":
            MessageLookupByLibrary.simpleMessage("اختياري، قصير كما تشاء..."),
        "orMergeWithExistingPerson":
            MessageLookupByLibrary.simpleMessage("أو الدمج مع شخص موجود"),
        "orPickAnExistingOne":
            MessageLookupByLibrary.simpleMessage("أو اختر واحدًا موجودًا"),
        "orPickFromYourContacts":
            MessageLookupByLibrary.simpleMessage("أو اختر من جهات اتصالك"),
        "pair": MessageLookupByLibrary.simpleMessage("إقران"),
        "pairWithPin":
            MessageLookupByLibrary.simpleMessage("الإقران بالرمز السري"),
        "pairingComplete":
            MessageLookupByLibrary.simpleMessage("اكتمل الإقران"),
        "panorama": MessageLookupByLibrary.simpleMessage("بانوراما"),
        "partyWithThem": m54,
        "passKeyPendingVerification":
            MessageLookupByLibrary.simpleMessage("التحقق لا يزال معلقًا."),
        "passkey": MessageLookupByLibrary.simpleMessage("مفتاح المرور"),
        "passkeyAuthTitle":
            MessageLookupByLibrary.simpleMessage("التحقق من مفتاح المرور"),
        "password": MessageLookupByLibrary.simpleMessage("كلمة المرور"),
        "passwordChangedSuccessfully":
            MessageLookupByLibrary.simpleMessage("تم تغيير كلمة المرور بنجاح."),
        "passwordLock": MessageLookupByLibrary.simpleMessage("قفل بكلمة مرور"),
        "passwordStrength": m55,
        "passwordStrengthInfo": MessageLookupByLibrary.simpleMessage(
            "يتم حساب قوة كلمة المرور مع الأخذ في الاعتبار طول كلمة المرور، والأحرف المستخدمة، وما إذا كانت كلمة المرور تظهر في قائمة أفضل 10,000 كلمة مرور شائعة الاستخدام."),
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "نحن لا نخزن كلمة المرور هذه، لذا إذا نسيتها، <underline>لا يمكننا المساعدة في فك تشفير بياناتك</underline>."),
        "paymentDetails": MessageLookupByLibrary.simpleMessage("تفاصيل الدفع"),
        "paymentFailed":
            MessageLookupByLibrary.simpleMessage("فشلت عملية الدفع"),
        "paymentFailedMessage": MessageLookupByLibrary.simpleMessage(
            "للأسف، فشلت عملية الدفع الخاصة بك. يرجى الاتصال بالدعم وسوف نساعدك!"),
        "paymentFailedTalkToProvider": m56,
        "pendingItems": MessageLookupByLibrary.simpleMessage("العناصر المعلقة"),
        "pendingSync": MessageLookupByLibrary.simpleMessage("المزامنة المعلقة"),
        "people": MessageLookupByLibrary.simpleMessage("الأشخاص"),
        "peopleUsingYourCode":
            MessageLookupByLibrary.simpleMessage("الأشخاص الذين يستخدمون رمزك"),
        "permDeleteWarning": MessageLookupByLibrary.simpleMessage(
            "سيتم حذف جميع العناصر في سلة المهملات نهائيًا.\n\nلا يمكن التراجع عن هذا الإجراء."),
        "permanentlyDelete": MessageLookupByLibrary.simpleMessage("حذف نهائي"),
        "permanentlyDeleteFromDevice":
            MessageLookupByLibrary.simpleMessage("حذف نهائي من الجهاز؟"),
        "personIsAge": m57,
        "personName": MessageLookupByLibrary.simpleMessage("اسم الشخص"),
        "personTurningAge": m58,
        "pets": MessageLookupByLibrary.simpleMessage("رفاق فروي"),
        "photoDescriptions":
            MessageLookupByLibrary.simpleMessage("أوصاف الصور"),
        "photoGridSize": MessageLookupByLibrary.simpleMessage("حجم شبكة الصور"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("صورة"),
        "photocountPhotos": m59,
        "photos": MessageLookupByLibrary.simpleMessage("الصور"),
        "photosAddedByYouWillBeRemovedFromTheAlbum":
            MessageLookupByLibrary.simpleMessage(
                "ستتم إزالة الصور التي أضفتها من الألبوم."),
        "photosCount": m60,
        "photosKeepRelativeTimeDifference":
            MessageLookupByLibrary.simpleMessage(
                "تحتفظ الصور بالفرق الزمني النسبي"),
        "pickCenterPoint":
            MessageLookupByLibrary.simpleMessage("اختيار نقطة المركز"),
        "pinAlbum": MessageLookupByLibrary.simpleMessage("تثبيت الألبوم"),
        "pinLock": MessageLookupByLibrary.simpleMessage("قفل برمز PIN"),
        "playOnTv":
            MessageLookupByLibrary.simpleMessage("تشغيل الألبوم على التلفزيون"),
        "playOriginal": MessageLookupByLibrary.simpleMessage("تشغيل الأصلي"),
        "playStoreFreeTrialValidTill": m61,
        "playStream": MessageLookupByLibrary.simpleMessage("تشغيل البث"),
        "playstoreSubscription":
            MessageLookupByLibrary.simpleMessage("اشتراك متجر Play"),
        "pleaseCheckYourInternetConnectionAndTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "يرجى التحقق من اتصال الإنترنت الخاص بك والمحاولة مرة أخرى."),
        "pleaseContactSupportAndWeWillBeHappyToHelp":
            MessageLookupByLibrary.simpleMessage(
                "يرجى التواصل مع support@ente.io وسنكون سعداء بمساعدتك!"),
        "pleaseContactSupportIfTheProblemPersists":
            MessageLookupByLibrary.simpleMessage(
                "يرجى الاتصال بالدعم إذا استمرت المشكلة."),
        "pleaseEmailUsAt": m62,
        "pleaseGrantPermissions":
            MessageLookupByLibrary.simpleMessage("يرجى منح الأذونات."),
        "pleaseLoginAgain":
            MessageLookupByLibrary.simpleMessage("يرجى تسجيل الدخول مرة أخرى."),
        "pleaseSelectQuickLinksToRemove": MessageLookupByLibrary.simpleMessage(
            "يرجى تحديد الروابط السريعة للإزالة."),
        "pleaseSendTheLogsTo": m63,
        "pleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("يرجى المحاولة مرة أخرى"),
        "pleaseVerifyTheCodeYouHaveEntered":
            MessageLookupByLibrary.simpleMessage(
                "يرجى التحقق من الرمز الذي أدخلته."),
        "pleaseWait": MessageLookupByLibrary.simpleMessage("يرجى الانتظار..."),
        "pleaseWaitDeletingAlbum": MessageLookupByLibrary.simpleMessage(
            "يرجى الانتظار، جارٍ حذف الألبوم"),
        "pleaseWaitForSometimeBeforeRetrying":
            MessageLookupByLibrary.simpleMessage(
                "يرجى الانتظار لبعض الوقت قبل إعادة المحاولة."),
        "pleaseWaitThisWillTakeAWhile": MessageLookupByLibrary.simpleMessage(
            "يرجى الانتظار، قد يستغرق هذا بعض الوقت."),
        "posingWithThem": m64,
        "preparingLogs":
            MessageLookupByLibrary.simpleMessage("جارٍ تحضير السجلات..."),
        "preserveMore": MessageLookupByLibrary.simpleMessage("حفظ المزيد"),
        "pressAndHoldToPlayVideo":
            MessageLookupByLibrary.simpleMessage("اضغط مطولاً لتشغيل الفيديو"),
        "pressAndHoldToPlayVideoDetailed": MessageLookupByLibrary.simpleMessage(
            "اضغط مطولاً على الصورة لتشغيل الفيديو"),
        "previous": MessageLookupByLibrary.simpleMessage("السابق"),
        "privacy": MessageLookupByLibrary.simpleMessage("الخصوصية"),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("سياسة الخصوصية"),
        "privateBackups":
            MessageLookupByLibrary.simpleMessage("نسخ احتياطية خاصة"),
        "privateSharing": MessageLookupByLibrary.simpleMessage("مشاركة خاصة"),
        "proceed": MessageLookupByLibrary.simpleMessage("متابعة"),
        "processed": MessageLookupByLibrary.simpleMessage("تمت المعالجة"),
        "processing": MessageLookupByLibrary.simpleMessage("المعالجة"),
        "processingImport": m65,
        "processingVideos":
            MessageLookupByLibrary.simpleMessage("معالجة مقاطع الفيديو"),
        "publicLinkCreated":
            MessageLookupByLibrary.simpleMessage("تم إنشاء الرابط العام."),
        "publicLinkEnabled":
            MessageLookupByLibrary.simpleMessage("تمكين الرابط العام"),
        "queued": MessageLookupByLibrary.simpleMessage("في قائمة الانتظار"),
        "quickLinks": MessageLookupByLibrary.simpleMessage("روابط سريعة"),
        "radius": MessageLookupByLibrary.simpleMessage("نصف القطر"),
        "raiseTicket": MessageLookupByLibrary.simpleMessage("فتح تذكرة دعم"),
        "rateTheApp": MessageLookupByLibrary.simpleMessage("تقييم التطبيق"),
        "rateUs": MessageLookupByLibrary.simpleMessage("تقييم التطبيق"),
        "rateUsOnStore": m66,
        "reassignMe":
            MessageLookupByLibrary.simpleMessage("إعادة تعيين \"أنا\""),
        "reassignedToName": m67,
        "reassigningLoading":
            MessageLookupByLibrary.simpleMessage("جارٍ إعادة التعيين..."),
        "recover": MessageLookupByLibrary.simpleMessage("استعادة"),
        "recoverAccount":
            MessageLookupByLibrary.simpleMessage("استعادة الحساب"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("استرداد"),
        "recoveryAccount":
            MessageLookupByLibrary.simpleMessage("استرداد الحساب"),
        "recoveryInitiated":
            MessageLookupByLibrary.simpleMessage("بدء الاسترداد"),
        "recoveryInitiatedDesc": m68,
        "recoveryKey": MessageLookupByLibrary.simpleMessage("مفتاح الاسترداد"),
        "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "تم نسخ مفتاح الاسترداد إلى الحافظة"),
        "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
            "إذا نسيت كلمة المرور الخاصة بك، فإن الطريقة الوحيدة لاستعادة بياناتك هي باستخدام هذا المفتاح."),
        "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
            "لا نحتفظ بنسخة من هذا المفتاح. يرجى حفظ المفتاح المكون من 24 كلمة في مكان آمن."),
        "recoveryKeySuccessBody": MessageLookupByLibrary.simpleMessage(
            "مفتاح الاسترداد الخاص بك صالح. شكرًا على التحقق.\n\nيرجى تذكر الاحتفاظ بنسخة احتياطية آمنة من مفتاح الاسترداد."),
        "recoveryKeyVerified": MessageLookupByLibrary.simpleMessage(
            "تم التحقق من مفتاح الاسترداد."),
        "recoveryKeyVerifyReason": MessageLookupByLibrary.simpleMessage(
            "مفتاح الاسترداد هو الطريقة الوحيدة لاستعادة صورك إذا نسيت كلمة المرور. يمكنك العثور عليه في الإعدادات > الحساب.\n\nالرجاء إدخال مفتاح الاسترداد هنا للتحقق من أنك حفظته بشكل صحيح."),
        "recoveryReady": m69,
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("تم الاسترداد بنجاح!"),
        "recoveryWarning": MessageLookupByLibrary.simpleMessage(
            "جهة اتصال موثوقة تحاول الوصول إلى حسابك"),
        "recoveryWarningBody": m70,
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "لا يمكن التحقق من كلمة المرور على جهازك الحالي، لكن يمكننا تعديلها لتعمل على جميع الأجهزة.\n\nسجّل الدخول باستخدام مفتاح الاسترداد، ثم أنشئ كلمة مرور جديدة (يمكنك اختيار نفس الكلمة السابقة إذا أردت)."),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("إعادة إنشاء كلمة المرور"),
        "reddit": MessageLookupByLibrary.simpleMessage("Reddit"),
        "reenterPassword":
            MessageLookupByLibrary.simpleMessage("إعادة إدخال كلمة المرور"),
        "reenterPin":
            MessageLookupByLibrary.simpleMessage("إعادة إدخال رمز PIN"),
        "referFriendsAnd2xYourPlan": MessageLookupByLibrary.simpleMessage(
            "أحِل الأصدقاء وضاعف خطتك مرتين"),
        "referralStep1":
            MessageLookupByLibrary.simpleMessage("1. أعطِ هذا الرمز لأصدقائك"),
        "referralStep2":
            MessageLookupByLibrary.simpleMessage("2. يشتركون في خطة مدفوعة"),
        "referralStep3": m71,
        "referrals": MessageLookupByLibrary.simpleMessage("الإحالات"),
        "referralsAreCurrentlyPaused":
            MessageLookupByLibrary.simpleMessage("الإحالات متوقفة مؤقتًا"),
        "rejectRecovery": MessageLookupByLibrary.simpleMessage("رفض الاسترداد"),
        "remindToEmptyDeviceTrash": MessageLookupByLibrary.simpleMessage(
            "تذكر أيضًا إفراغ \"المحذوفة مؤخرًا\" من \"الإعدادات\" -> \"التخزين\" لاستعادة المساحة المحررة."),
        "remindToEmptyEnteTrash": MessageLookupByLibrary.simpleMessage(
            "تذكر أيضًا إفراغ \"سلة المهملات\" لاستعادة المساحة المحررة."),
        "remoteImages": MessageLookupByLibrary.simpleMessage("الصور عن بعد"),
        "remoteThumbnails":
            MessageLookupByLibrary.simpleMessage("الصور المصغرة عن بعد"),
        "remoteVideos":
            MessageLookupByLibrary.simpleMessage("مقاطع الفيديو عن بعد"),
        "remove": MessageLookupByLibrary.simpleMessage("إزالة"),
        "removeDuplicates":
            MessageLookupByLibrary.simpleMessage("إزالة النسخ المكررة"),
        "removeDuplicatesDesc": MessageLookupByLibrary.simpleMessage(
            "مراجعة وإزالة الملفات المتطابقة تمامًا."),
        "removeFromAlbum":
            MessageLookupByLibrary.simpleMessage("إزالة من الألبوم"),
        "removeFromAlbumTitle":
            MessageLookupByLibrary.simpleMessage("إزالة من الألبوم؟"),
        "removeFromFavorite":
            MessageLookupByLibrary.simpleMessage("إزالة من المفضلة"),
        "removeInvite": MessageLookupByLibrary.simpleMessage("إزالة الدعوة"),
        "removeLink": MessageLookupByLibrary.simpleMessage("إزالة الرابط"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("إزالة المشارك"),
        "removeParticipantBody": m72,
        "removePersonLabel":
            MessageLookupByLibrary.simpleMessage("إزالة تسمية الشخص"),
        "removePublicLink":
            MessageLookupByLibrary.simpleMessage("إزالة الرابط العام"),
        "removePublicLinks":
            MessageLookupByLibrary.simpleMessage("إزالة الروابط العامة"),
        "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
            "بعض العناصر التي تزيلها تمت إضافتها بواسطة أشخاص آخرين، وستفقد الوصول إليها."),
        "removeWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("إزالة؟"),
        "removeYourselfAsTrustedContact": MessageLookupByLibrary.simpleMessage(
            "إزالة نفسك كجهة اتصال موثوقة"),
        "removingFromFavorites":
            MessageLookupByLibrary.simpleMessage("جارٍ الإزالة من المفضلة..."),
        "rename": MessageLookupByLibrary.simpleMessage("إعادة تسمية"),
        "renameAlbum":
            MessageLookupByLibrary.simpleMessage("إعادة تسمية الألبوم"),
        "renameFile": MessageLookupByLibrary.simpleMessage("إعادة تسمية الملف"),
        "renewSubscription":
            MessageLookupByLibrary.simpleMessage("تجديد الاشتراك"),
        "renewsOn": m73,
        "reportABug": MessageLookupByLibrary.simpleMessage("الإبلاغ عن خطأ"),
        "reportBug": MessageLookupByLibrary.simpleMessage("الإبلاغ عن خطأ"),
        "resendEmail": MessageLookupByLibrary.simpleMessage(
            "إعادة إرسال البريد الإلكتروني"),
        "resetIgnoredFiles": MessageLookupByLibrary.simpleMessage(
            "إعادة تعيين الملفات المتجاهلة"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("إعادة تعيين كلمة المرور"),
        "resetPerson": MessageLookupByLibrary.simpleMessage("إزالة"),
        "resetToDefault":
            MessageLookupByLibrary.simpleMessage("إعادة التعيين إلى الافتراضي"),
        "restore": MessageLookupByLibrary.simpleMessage("استعادة"),
        "restoreToAlbum":
            MessageLookupByLibrary.simpleMessage("استعادة إلى الألبوم"),
        "restoringFiles":
            MessageLookupByLibrary.simpleMessage("جارٍ استعادة الملفات..."),
        "resumableUploads":
            MessageLookupByLibrary.simpleMessage("تحميلات قابلة للاستئناف"),
        "retry": MessageLookupByLibrary.simpleMessage("إعادة المحاولة"),
        "review": MessageLookupByLibrary.simpleMessage("مراجعة"),
        "reviewDeduplicateItems": MessageLookupByLibrary.simpleMessage(
            "يرجى مراجعة وحذف العناصر التي تعتقد أنها مكررة."),
        "reviewSuggestions":
            MessageLookupByLibrary.simpleMessage("مراجعة الاقتراحات"),
        "right": MessageLookupByLibrary.simpleMessage("يمين"),
        "roadtripWithThem": m74,
        "rotate": MessageLookupByLibrary.simpleMessage("تدوير"),
        "rotateLeft": MessageLookupByLibrary.simpleMessage("تدوير لليسار"),
        "rotateRight": MessageLookupByLibrary.simpleMessage("تدوير لليمين"),
        "safelyStored": MessageLookupByLibrary.simpleMessage("مخزنة بأمان"),
        "save": MessageLookupByLibrary.simpleMessage("حفظ"),
        "saveChangesBeforeLeavingQuestion":
            MessageLookupByLibrary.simpleMessage("حفظ التغييرات قبل المغادرة؟"),
        "saveCollage": MessageLookupByLibrary.simpleMessage("حفظ الكولاج"),
        "saveCopy": MessageLookupByLibrary.simpleMessage("حفظ نسخة"),
        "saveKey": MessageLookupByLibrary.simpleMessage("حفظ المفتاح"),
        "savePerson": MessageLookupByLibrary.simpleMessage("حفظ الشخص"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "احفظ مفتاح الاسترداد إذا لم تكن قد فعلت ذلك بالفعل."),
        "saving": MessageLookupByLibrary.simpleMessage("جارٍ الحفظ..."),
        "savingEdits":
            MessageLookupByLibrary.simpleMessage("جارٍ حفظ التعديلات..."),
        "scanCode": MessageLookupByLibrary.simpleMessage("مسح الرمز"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "امسح هذا الباركود باستخدام\nتطبيق المصادقة الخاص بك"),
        "search": MessageLookupByLibrary.simpleMessage("بحث"),
        "searchAlbumsEmptySection":
            MessageLookupByLibrary.simpleMessage("الألبومات"),
        "searchByAlbumNameHint":
            MessageLookupByLibrary.simpleMessage("اسم الألبوم"),
        "searchByExamples": MessageLookupByLibrary.simpleMessage(
            "• أسماء الألبومات (مثل \"الكاميرا\")\n• أنواع الملفات (مثل \"مقاطع الفيديو\"، \".gif\")\n• السنوات والأشهر (مثل \"2022\"، \"يناير\")\n• العطلات (مثل \"عيد الميلاد\")\n• أوصاف الصور (مثل \"#مرح\")"),
        "searchCaptionEmptySection": MessageLookupByLibrary.simpleMessage(
            "أضف أوصافًا مثل \"#رحلة\" في معلومات الصورة للعثور عليها بسرعة هنا."),
        "searchDatesEmptySection": MessageLookupByLibrary.simpleMessage(
            "ابحث حسب تاريخ أو شهر أو سنة."),
        "searchDiscoverEmptySection": MessageLookupByLibrary.simpleMessage(
            "سيتم عرض الصور هنا بمجرد اكتمال المعالجة والمزامنة."),
        "searchFaceEmptySection": MessageLookupByLibrary.simpleMessage(
            "سيتم عرض الأشخاص هنا بمجرد الانتهاء من الفهرسة."),
        "searchFileTypesAndNamesEmptySection":
            MessageLookupByLibrary.simpleMessage("أنواع وأسماء الملفات"),
        "searchHint1":
            MessageLookupByLibrary.simpleMessage("بحث سريع على الجهاز"),
        "searchHint2":
            MessageLookupByLibrary.simpleMessage("تواريخ الصور، الأوصاف"),
        "searchHint3": MessageLookupByLibrary.simpleMessage(
            "الألبومات، أسماء الملفات، والأنواع"),
        "searchHint4": MessageLookupByLibrary.simpleMessage("الموقع"),
        "searchHint5": MessageLookupByLibrary.simpleMessage(
            "قريبًا: الوجوه والبحث السحري ✨"),
        "searchLocationEmptySection": MessageLookupByLibrary.simpleMessage(
            "تجميع الصور الملتقطة ضمن نصف قطر معين لصورة ما."),
        "searchPeopleEmptySection": MessageLookupByLibrary.simpleMessage(
            "ادعُ الأشخاص، وسترى جميع الصور التي شاركوها هنا."),
        "searchPersonsEmptySection": MessageLookupByLibrary.simpleMessage(
            "سيتم عرض الأشخاص هنا بمجرد اكتمال المعالجة والمزامنة."),
        "searchSectionsLengthMismatch": m75,
        "security": MessageLookupByLibrary.simpleMessage("الأمان"),
        "seePublicAlbumLinksInApp": MessageLookupByLibrary.simpleMessage(
            "رؤية روابط الألبومات العامة في التطبيق"),
        "selectALocation": MessageLookupByLibrary.simpleMessage("تحديد موقع"),
        "selectALocationFirst":
            MessageLookupByLibrary.simpleMessage("حدد موقعًا أولاً"),
        "selectAlbum": MessageLookupByLibrary.simpleMessage("تحديد ألبوم"),
        "selectAll": MessageLookupByLibrary.simpleMessage("تحديد الكل"),
        "selectAllShort": MessageLookupByLibrary.simpleMessage("الكل"),
        "selectCoverPhoto":
            MessageLookupByLibrary.simpleMessage("تحديد صورة الغلاف"),
        "selectDate": MessageLookupByLibrary.simpleMessage("تحديد التاريخ"),
        "selectFoldersForBackup": MessageLookupByLibrary.simpleMessage(
            "تحديد المجلدات للنسخ الاحتياطي"),
        "selectItemsToAdd":
            MessageLookupByLibrary.simpleMessage("تحديد العناصر للإضافة"),
        "selectLanguage": MessageLookupByLibrary.simpleMessage("اختر اللغة"),
        "selectMailApp":
            MessageLookupByLibrary.simpleMessage("تحديد تطبيق البريد"),
        "selectMorePhotos":
            MessageLookupByLibrary.simpleMessage("تحديد المزيد من الصور"),
        "selectOneDateAndTime":
            MessageLookupByLibrary.simpleMessage("تحديد تاريخ ووقت واحد"),
        "selectOneDateAndTimeForAll": MessageLookupByLibrary.simpleMessage(
            "تحديد تاريخ ووقت واحد للجميع"),
        "selectPersonToLink":
            MessageLookupByLibrary.simpleMessage("تحديد الشخص للربط"),
        "selectReason": MessageLookupByLibrary.simpleMessage("اختر سببًا"),
        "selectStartOfRange":
            MessageLookupByLibrary.simpleMessage("تحديد بداية النطاق"),
        "selectTime": MessageLookupByLibrary.simpleMessage("تحديد الوقت"),
        "selectYourFace": MessageLookupByLibrary.simpleMessage("حدد وجهك"),
        "selectYourPlan": MessageLookupByLibrary.simpleMessage("اختر خطتك"),
        "selectedFilesAreNotOnEnte": MessageLookupByLibrary.simpleMessage(
            "الملفات المحددة ليست موجودة على Ente."),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
                "سيتم تشفير المجلدات المحددة ونسخها احتياطيًا"),
        "selectedItemsWillBeDeletedFromAllAlbumsAndMoved":
            MessageLookupByLibrary.simpleMessage(
                "سيتم حذف العناصر المحددة من جميع الألبومات ونقلها إلى سلة المهملات."),
        "selectedItemsWillBeRemovedFromThisPerson":
            MessageLookupByLibrary.simpleMessage(
                "سيتم إزالة العناصر المحددة من هذا الشخص، ولكن لن يتم حذفها من مكتبتك."),
        "selectedPhotos": m76,
        "selectedPhotosWithYours": m77,
        "selfiesWithThem": m78,
        "send": MessageLookupByLibrary.simpleMessage("إرسال"),
        "sendEmail":
            MessageLookupByLibrary.simpleMessage("إرسال بريد إلكتروني"),
        "sendInvite": MessageLookupByLibrary.simpleMessage("إرسال دعوة"),
        "sendLink": MessageLookupByLibrary.simpleMessage("إرسال الرابط"),
        "serverEndpoint":
            MessageLookupByLibrary.simpleMessage("نقطة نهاية الخادم"),
        "sessionExpired":
            MessageLookupByLibrary.simpleMessage("انتهت صلاحية الجلسة"),
        "sessionIdMismatch":
            MessageLookupByLibrary.simpleMessage("عدم تطابق معرّف الجلسة"),
        "setAPassword": MessageLookupByLibrary.simpleMessage("تعيين كلمة مرور"),
        "setAs": MessageLookupByLibrary.simpleMessage("تعيين كـ"),
        "setCover": MessageLookupByLibrary.simpleMessage("تعيين كغلاف"),
        "setLabel": MessageLookupByLibrary.simpleMessage("تعيين"),
        "setNewPassword":
            MessageLookupByLibrary.simpleMessage("تعيين كلمة مرور جديدة"),
        "setNewPin": MessageLookupByLibrary.simpleMessage("تعيين رمز PIN جديد"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("تعيين كلمة المرور"),
        "setRadius": MessageLookupByLibrary.simpleMessage("تعيين نصف القطر"),
        "setupComplete": MessageLookupByLibrary.simpleMessage("اكتمل الإعداد"),
        "share": MessageLookupByLibrary.simpleMessage("مشاركة"),
        "shareALink": MessageLookupByLibrary.simpleMessage("مشاركة رابط"),
        "shareAlbumHint": MessageLookupByLibrary.simpleMessage(
            "افتح ألبومًا وانقر على زر المشاركة في الزاوية اليمنى العليا للمشاركة."),
        "shareAnAlbumNow":
            MessageLookupByLibrary.simpleMessage("شارك ألبومًا الآن"),
        "shareLink": MessageLookupByLibrary.simpleMessage("مشاركة الرابط"),
        "shareMyVerificationID": m79,
        "shareOnlyWithThePeopleYouWant": MessageLookupByLibrary.simpleMessage(
            "شارك فقط مع الأشخاص الذين تريدهم."),
        "shareTextConfirmOthersVerificationID": m80,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "قم بتنزيل تطبيق Ente حتى نتمكن من مشاركة الصور ومقاطع الفيديو بالجودة الأصلية بسهولة.\n\nhttps://ente.io"),
        "shareTextReferralCode": m81,
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
            "المشاركة مع غير مستخدمي Ente"),
        "shareWithPeopleSectionTitle": m82,
        "shareYourFirstAlbum":
            MessageLookupByLibrary.simpleMessage("شارك ألبومك الأول"),
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
            "أنشئ ألبومات مشتركة وتعاونية مع مستخدمي Ente الآخرين، بما في ذلك المستخدمين ذوي الاشتراكات المجانية."),
        "sharedByMe":
            MessageLookupByLibrary.simpleMessage("تمت مشاركتها بواسطتي"),
        "sharedByYou":
            MessageLookupByLibrary.simpleMessage("تمت مشاركتها بواسطتك"),
        "sharedPhotoNotifications": MessageLookupByLibrary.simpleMessage(
            "إشعارات الصور المشتركة الجديدة"),
        "sharedPhotoNotificationsExplanation": MessageLookupByLibrary.simpleMessage(
            "تلقّ إشعارات عندما يضيف شخص ما صورة إلى ألبوم مشترك أنت جزء منه."),
        "sharedWith": m83,
        "sharedWithMe":
            MessageLookupByLibrary.simpleMessage("تمت مشاركتها معي"),
        "sharedWithYou":
            MessageLookupByLibrary.simpleMessage("تمت مشاركتها معك"),
        "sharing": MessageLookupByLibrary.simpleMessage("جارٍ المشاركة..."),
        "shiftDatesAndTime":
            MessageLookupByLibrary.simpleMessage("تغيير التواريخ والوقت"),
        "showMemories": MessageLookupByLibrary.simpleMessage("عرض الذكريات"),
        "showPerson": MessageLookupByLibrary.simpleMessage("إظهار الشخص"),
        "signOutFromOtherDevices": MessageLookupByLibrary.simpleMessage(
            "تسجيل الخروج من الأجهزة الأخرى"),
        "signOutOtherBody": MessageLookupByLibrary.simpleMessage(
            "إذا كنت تعتقد أن شخصًا ما قد يعرف كلمة مرورك، يمكنك إجبار جميع الأجهزة الأخرى التي تستخدم حسابك على تسجيل الخروج."),
        "signOutOtherDevices": MessageLookupByLibrary.simpleMessage(
            "تسجيل الخروج من الأجهزة الأخرى"),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "أوافق على <u-terms>شروط الخدمة</u-terms> و<u-policy>سياسة الخصوصية</u-policy>"),
        "singleFileDeleteFromDevice": m84,
        "singleFileDeleteHighlight": MessageLookupByLibrary.simpleMessage(
            "سيتم حذفه من جميع الألبومات."),
        "singleFileInBothLocalAndRemote": m85,
        "singleFileInRemoteOnly": m86,
        "skip": MessageLookupByLibrary.simpleMessage("تخط"),
        "social": MessageLookupByLibrary.simpleMessage("التواصل الاجتماعي"),
        "someItemsAreInBothEnteAndYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "بعض العناصر موجودة في Ente وعلى جهازك."),
        "someOfTheFilesYouAreTryingToDeleteAre":
            MessageLookupByLibrary.simpleMessage(
                "بعض الملفات التي تحاول حذفها متوفرة فقط على جهازك ولا يمكن استردادها إذا تم حذفها."),
        "someoneSharingAlbumsWithYouShouldSeeTheSameId":
            MessageLookupByLibrary.simpleMessage(
                "يجب أن يرى أي شخص يشارك ألبومات معك نفس معرّف التحقق على جهازه."),
        "somethingWentWrong":
            MessageLookupByLibrary.simpleMessage("حدث خطأ ما"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "حدث خطأ ما، يرجى المحاولة مرة أخرى"),
        "sorry": MessageLookupByLibrary.simpleMessage("عفوًا"),
        "sorryCouldNotAddToFavorites": MessageLookupByLibrary.simpleMessage(
            "عذرًا، تعذرت الإضافة إلى المفضلة!"),
        "sorryCouldNotRemoveFromFavorites":
            MessageLookupByLibrary.simpleMessage(
                "عذرًا، تعذرت الإزالة من المفضلة!"),
        "sorryTheCodeYouveEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "عذرًا، الرمز الذي أدخلته غير صحيح."),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "عذرًا، لم نتمكن من إنشاء مفاتيح آمنة على هذا الجهاز.\n\nيرجى التسجيل من جهاز مختلف."),
        "sort": MessageLookupByLibrary.simpleMessage("فرز"),
        "sortAlbumsBy": MessageLookupByLibrary.simpleMessage("فرز حسب"),
        "sortNewestFirst": MessageLookupByLibrary.simpleMessage("الأحدث أولاً"),
        "sortOldestFirst": MessageLookupByLibrary.simpleMessage("الأقدم أولاً"),
        "sparkleSuccess": MessageLookupByLibrary.simpleMessage("✨ نجاح"),
        "sportsWithThem": m87,
        "spotlightOnThem": m88,
        "spotlightOnYourself":
            MessageLookupByLibrary.simpleMessage("تسليط الضوء عليك"),
        "startAccountRecoveryTitle":
            MessageLookupByLibrary.simpleMessage("بدء الاسترداد"),
        "startBackup":
            MessageLookupByLibrary.simpleMessage("بدء النسخ الاحتياطي"),
        "status": MessageLookupByLibrary.simpleMessage("الحالة"),
        "stopCastingBody":
            MessageLookupByLibrary.simpleMessage("هل تريد إيقاف البث؟"),
        "stopCastingTitle": MessageLookupByLibrary.simpleMessage("إيقاف البث"),
        "storage": MessageLookupByLibrary.simpleMessage("التخزين"),
        "storageBreakupFamily": MessageLookupByLibrary.simpleMessage("العائلة"),
        "storageBreakupYou": MessageLookupByLibrary.simpleMessage("أنت"),
        "storageInGB": m89,
        "storageLimitExceeded":
            MessageLookupByLibrary.simpleMessage("تم تجاوز حد التخزين."),
        "storageUsageInfo": m90,
        "streamDetails": MessageLookupByLibrary.simpleMessage("تفاصيل البث"),
        "strongStrength": MessageLookupByLibrary.simpleMessage("قوية"),
        "subAlreadyLinkedErrMessage": m91,
        "subWillBeCancelledOn": m92,
        "subscribe": MessageLookupByLibrary.simpleMessage("اشتراك"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
            "المشاركة متاحة فقط للاشتراكات المدفوعة النشطة."),
        "subscription": MessageLookupByLibrary.simpleMessage("الاشتراك"),
        "success": MessageLookupByLibrary.simpleMessage("تم بنجاح"),
        "successfullyArchived":
            MessageLookupByLibrary.simpleMessage("تمت الأرشفة بنجاح."),
        "successfullyHid":
            MessageLookupByLibrary.simpleMessage("تم الإخفاء بنجاح."),
        "successfullyUnarchived":
            MessageLookupByLibrary.simpleMessage("تم إلغاء الأرشفة بنجاح."),
        "successfullyUnhid":
            MessageLookupByLibrary.simpleMessage("تم الإظهار بنجاح."),
        "suggestFeatures": MessageLookupByLibrary.simpleMessage("اقتراح ميزة"),
        "sunrise": MessageLookupByLibrary.simpleMessage("على الأفق"),
        "support": MessageLookupByLibrary.simpleMessage("الدعم"),
        "syncProgress": m93,
        "syncStopped": MessageLookupByLibrary.simpleMessage("توقفت المزامنة"),
        "syncing": MessageLookupByLibrary.simpleMessage("جارٍ المزامنة..."),
        "systemTheme": MessageLookupByLibrary.simpleMessage("النظام"),
        "tapToCopy": MessageLookupByLibrary.simpleMessage("انقر للنسخ"),
        "tapToEnterCode":
            MessageLookupByLibrary.simpleMessage("انقر لإدخال الرمز"),
        "tapToUnlock": MessageLookupByLibrary.simpleMessage("انقر لفتح القفل"),
        "tapToUpload": MessageLookupByLibrary.simpleMessage("انقر للتحميل"),
        "tapToUploadIsIgnoredDue": m94,
        "tempErrorContactSupportIfPersists": MessageLookupByLibrary.simpleMessage(
            "يبدو أن خطأً ما قد حدث. يرجى المحاولة مرة أخرى بعد بعض الوقت. إذا استمر الخطأ، يرجى الاتصال بفريق الدعم لدينا."),
        "terminate": MessageLookupByLibrary.simpleMessage("إنهاء"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("إنهاء الجَلسةِ؟"),
        "terms": MessageLookupByLibrary.simpleMessage("الشروط"),
        "termsOfServicesTitle":
            MessageLookupByLibrary.simpleMessage("شروط الخدمة"),
        "thankYou": MessageLookupByLibrary.simpleMessage("شكرًا لك"),
        "thankYouForSubscribing":
            MessageLookupByLibrary.simpleMessage("شكرًا لاشتراكك!"),
        "theDownloadCouldNotBeCompleted":
            MessageLookupByLibrary.simpleMessage("تعذر إكمال التنزيل."),
        "theLinkYouAreTryingToAccessHasExpired":
            MessageLookupByLibrary.simpleMessage(
                "انتهت صلاحية الرابط الذي تحاول الوصول إليه."),
        "theRecoveryKeyYouEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "مفتاح الاسترداد الذي أدخلته غير صحيح."),
        "theme": MessageLookupByLibrary.simpleMessage("المظهر"),
        "theseItemsWillBeDeletedFromYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "سيتم حذف هذه العناصر من جهازك."),
        "theyAlsoGetXGb": m95,
        "theyWillBeDeletedFromAllAlbums": MessageLookupByLibrary.simpleMessage(
            "سيتم حذفها من جميع الألبومات."),
        "thisActionCannotBeUndone": MessageLookupByLibrary.simpleMessage(
            "لا يمكن التراجع عن هذا الإجراء."),
        "thisAlbumAlreadyHDACollaborativeLink":
            MessageLookupByLibrary.simpleMessage(
                "هذا الألبوم لديه رابط تعاوني بالفعل."),
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "يمكن استخدام هذا المفتاح لاستعادة حسابك إذا فقدت جهاز المصادقة الثنائية."),
        "thisDevice": MessageLookupByLibrary.simpleMessage("هذا الجهاز"),
        "thisEmailIsAlreadyInUse": MessageLookupByLibrary.simpleMessage(
            "هذا البريد الإلكتروني مستخدم بالفعل."),
        "thisImageHasNoExifData": MessageLookupByLibrary.simpleMessage(
            "لا تحتوي هذه الصورة على بيانات EXIF."),
        "thisIsMeExclamation": MessageLookupByLibrary.simpleMessage("هذا أنا!"),
        "thisIsPersonVerificationId": m96,
        "thisIsYourVerificationId": MessageLookupByLibrary.simpleMessage(
            "هذا هو معرّف التحقق الخاص بك"),
        "thisWeekThroughTheYears":
            MessageLookupByLibrary.simpleMessage("هذا الأسبوع عبر السنين"),
        "thisWeekXYearsAgo": m97,
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "سيؤدي هذا إلى تسجيل خروجك من الجهاز التالي:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "سيؤدي هذا إلى تسجيل خروجك من هذا الجهاز."),
        "thisWillMakeTheDateAndTimeOfAllSelected":
            MessageLookupByLibrary.simpleMessage(
                "سيجعل هذا تاريخ ووقت جميع الصور المحددة متماثلاً."),
        "thisWillRemovePublicLinksOfAllSelectedQuickLinks":
            MessageLookupByLibrary.simpleMessage(
                "سيؤدي هذا إلى إزالة الروابط العامة لجميع الروابط السريعة المحددة."),
        "throughTheYears": m98,
        "toEnableAppLockPleaseSetupDevicePasscodeOrScreen":
            MessageLookupByLibrary.simpleMessage(
                "لتمكين قفل التطبيق، يرجى إعداد رمز مرور الجهاز أو قفل الشاشة في إعدادات النظام."),
        "toHideAPhotoOrVideo":
            MessageLookupByLibrary.simpleMessage("لإخفاء صورة أو مقطع فيديو:"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "لإعادة تعيين كلمة المرور، يرجى التحقق من بريدك الإلكتروني أولاً."),
        "todaysLogs": MessageLookupByLibrary.simpleMessage("سجلات اليوم"),
        "tooManyIncorrectAttempts": MessageLookupByLibrary.simpleMessage(
            "محاولات غير صحيحة كثيرة جدًا."),
        "total": MessageLookupByLibrary.simpleMessage("المجموع"),
        "totalSize": MessageLookupByLibrary.simpleMessage("الحجم الإجمالي"),
        "trash": MessageLookupByLibrary.simpleMessage("سلة المهملات"),
        "trashDaysLeft": m99,
        "trim": MessageLookupByLibrary.simpleMessage("قص"),
        "tripInYear": m100,
        "tripToLocation": m101,
        "trustedContacts":
            MessageLookupByLibrary.simpleMessage("جهات الاتصال الموثوقة"),
        "trustedInviteBody": m102,
        "tryAgain": MessageLookupByLibrary.simpleMessage("المحاولة مرة أخرى"),
        "turnOnBackupForAutoUpload": MessageLookupByLibrary.simpleMessage(
            "قم بتشغيل النسخ الاحتياطي لتحميل الملفات المضافة إلى مجلد الجهاز هذا تلقائيًا إلى Ente."),
        "twitter": MessageLookupByLibrary.simpleMessage("X (Twitter سابقًا)"),
        "twoMonthsFreeOnYearlyPlans": MessageLookupByLibrary.simpleMessage(
            "شهرين مجانيين على الخطط السنوية."),
        "twofactor": MessageLookupByLibrary.simpleMessage("المصادقة الثنائية"),
        "twofactorAuthenticationHasBeenDisabled":
            MessageLookupByLibrary.simpleMessage("تم تعطيل المصادقة الثنائية."),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage("المصادقة الثنائية"),
        "twofactorAuthenticationSuccessfullyReset":
            MessageLookupByLibrary.simpleMessage(
                "تمت إعادة تعيين المصادقة الثنائية بنجاح."),
        "twofactorSetup":
            MessageLookupByLibrary.simpleMessage("إعداد المصادقة الثنائية"),
        "typeOfGallerGallerytypeIsNotSupportedForRename": m103,
        "unarchive": MessageLookupByLibrary.simpleMessage("إلغاء الأرشفة"),
        "unarchiveAlbum":
            MessageLookupByLibrary.simpleMessage("إلغاء أرشفة الألبوم"),
        "unarchiving":
            MessageLookupByLibrary.simpleMessage("جارٍ إلغاء الأرشفة..."),
        "unavailableReferralCode":
            MessageLookupByLibrary.simpleMessage("عذرًا، هذا الرمز غير متوفر."),
        "uncategorized": MessageLookupByLibrary.simpleMessage("غير مصنف"),
        "unhide": MessageLookupByLibrary.simpleMessage("إظهار"),
        "unhideToAlbum":
            MessageLookupByLibrary.simpleMessage("إظهار في الألبوم"),
        "unhiding": MessageLookupByLibrary.simpleMessage("جارٍ إظهار..."),
        "unhidingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "جارٍ إظهار الملفات في الألبوم..."),
        "unlock": MessageLookupByLibrary.simpleMessage("فتح"),
        "unpinAlbum":
            MessageLookupByLibrary.simpleMessage("إلغاء تثبيت الألبوم"),
        "unselectAll": MessageLookupByLibrary.simpleMessage("إلغاء تحديد الكل"),
        "update": MessageLookupByLibrary.simpleMessage("تحديث"),
        "updateAvailable": MessageLookupByLibrary.simpleMessage("يتوفر تحديث"),
        "updatingFolderSelection":
            MessageLookupByLibrary.simpleMessage("جارٍ تحديث تحديد المجلد..."),
        "upgrade": MessageLookupByLibrary.simpleMessage("ترقية"),
        "uploadIsIgnoredDueToIgnorereason": m104,
        "uploadingFilesToAlbum": MessageLookupByLibrary.simpleMessage(
            "جارٍ تحميل الملفات إلى الألبوم..."),
        "uploadingMultipleMemories": m105,
        "uploadingSingleMemory":
            MessageLookupByLibrary.simpleMessage("جارٍ حفظ ذكرى واحدة..."),
        "upto50OffUntil4thDec": MessageLookupByLibrary.simpleMessage(
            "خصم يصل إلى 50%، حتى 4 ديسمبر."),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
            "مساحة التخزين القابلة للاستخدام مقيدة بخطتك الحالية.\nالمساحة التخزينية الزائدة التي تمت المطالبة بها ستصبح قابلة للاستخدام تلقائيًا عند ترقية خطتك."),
        "useAsCover": MessageLookupByLibrary.simpleMessage("استخدام كغلاف"),
        "useDifferentPlayerInfo": MessageLookupByLibrary.simpleMessage(
            "هل تواجه مشكلة في تشغيل هذا الفيديو؟ اضغط مطولاً هنا لتجربة مشغل مختلف."),
        "usePublicLinksForPeopleNotOnEnte":
            MessageLookupByLibrary.simpleMessage(
                "استخدم الروابط العامة للأشخاص غير المسجلين في Ente."),
        "useRecoveryKey":
            MessageLookupByLibrary.simpleMessage("استخدام مفتاح الاسترداد"),
        "useSelectedPhoto":
            MessageLookupByLibrary.simpleMessage("استخدام الصورة المحددة"),
        "usedSpace": MessageLookupByLibrary.simpleMessage("المساحة المستخدمة"),
        "validTill": m106,
        "verificationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "فشل التحقق، يرجى المحاولة مرة أخرى."),
        "verificationId": MessageLookupByLibrary.simpleMessage("معرّف التحقق"),
        "verify": MessageLookupByLibrary.simpleMessage("التحقق"),
        "verifyEmail":
            MessageLookupByLibrary.simpleMessage("التحقق من البريد الإلكتروني"),
        "verifyEmailID": m107,
        "verifyIDLabel": MessageLookupByLibrary.simpleMessage("تحقق"),
        "verifyPasskey":
            MessageLookupByLibrary.simpleMessage("التحقق من مفتاح المرور"),
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("التحقق من كلمة المرور"),
        "verifying": MessageLookupByLibrary.simpleMessage("جارٍ التحقق..."),
        "verifyingRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "جارٍ التحقق من مفتاح الاسترداد..."),
        "videoInfo": MessageLookupByLibrary.simpleMessage("معلومات الفيديو"),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("فيديو"),
        "videoStreaming": MessageLookupByLibrary.simpleMessage("بث الفيديو"),
        "videos": MessageLookupByLibrary.simpleMessage("مقاطع الفيديو"),
        "viewActiveSessions":
            MessageLookupByLibrary.simpleMessage("عرض الجلسات النشطة"),
        "viewAddOnButton": MessageLookupByLibrary.simpleMessage("عرض الإضافات"),
        "viewAll": MessageLookupByLibrary.simpleMessage("عرض الكل"),
        "viewAllExifData":
            MessageLookupByLibrary.simpleMessage("عرض جميع بيانات EXIF"),
        "viewLargeFiles":
            MessageLookupByLibrary.simpleMessage("الملفات الكبيرة"),
        "viewLargeFilesDesc": MessageLookupByLibrary.simpleMessage(
            "عرض الملفات التي تستهلك أكبر قدر من مساحة التخزين."),
        "viewLogs": MessageLookupByLibrary.simpleMessage("عرض السجلات"),
        "viewRecoveryKey":
            MessageLookupByLibrary.simpleMessage("عرض مفتاح الاسترداد"),
        "viewer": MessageLookupByLibrary.simpleMessage("مشاهد"),
        "viewersSuccessfullyAdded": m108,
        "visitWebToManage": MessageLookupByLibrary.simpleMessage(
            "يرجى زيارة web.ente.io لإدارة اشتراكك."),
        "waitingForVerification":
            MessageLookupByLibrary.simpleMessage("في انتظار التحقق..."),
        "waitingForWifi":
            MessageLookupByLibrary.simpleMessage("في انتظار شبكة Wi-Fi..."),
        "warning": MessageLookupByLibrary.simpleMessage("تحذير"),
        "weAreOpenSource":
            MessageLookupByLibrary.simpleMessage("نحن مفتوحو المصدر!"),
        "weDontSupportEditingPhotosAndAlbumsThatYouDont":
            MessageLookupByLibrary.simpleMessage(
                "لا ندعم تعديل الصور والألبومات التي لا تملكها بعد."),
        "weHaveSendEmailTo": m109,
        "weakStrength": MessageLookupByLibrary.simpleMessage("ضعيفة"),
        "welcomeBack": MessageLookupByLibrary.simpleMessage("أهلاً بعودتك!"),
        "whatsNew": MessageLookupByLibrary.simpleMessage("ما الجديد"),
        "whyAddTrustContact": MessageLookupByLibrary.simpleMessage(
            "يمكن لجهة الاتصال الموثوقة المساعدة في استعادة بياناتك."),
        "yearShort": MessageLookupByLibrary.simpleMessage("سنة"),
        "yearly": MessageLookupByLibrary.simpleMessage("سنويًا"),
        "yearsAgo": m110,
        "yes": MessageLookupByLibrary.simpleMessage("نعم"),
        "yesCancel": MessageLookupByLibrary.simpleMessage("نعم، إلغاء"),
        "yesConvertToViewer":
            MessageLookupByLibrary.simpleMessage("نعم، التحويل إلى مشاهد"),
        "yesDelete": MessageLookupByLibrary.simpleMessage("نعم، حذف"),
        "yesDiscardChanges":
            MessageLookupByLibrary.simpleMessage("نعم، تجاهل التغييرات"),
        "yesLogout": MessageLookupByLibrary.simpleMessage("نعم، تسجيل الخروج"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("نعم، إزالة"),
        "yesRenew": MessageLookupByLibrary.simpleMessage("نعم، تجديد"),
        "yesResetPerson":
            MessageLookupByLibrary.simpleMessage("نعم، إعادة تعيين الشخص"),
        "you": MessageLookupByLibrary.simpleMessage("أنت"),
        "youAndThem": m111,
        "youAreOnAFamilyPlan":
            MessageLookupByLibrary.simpleMessage("أنت مشترك في خطة عائلية!"),
        "youAreOnTheLatestVersion":
            MessageLookupByLibrary.simpleMessage("أنت تستخدم أحدث إصدار."),
        "youCanAtMaxDoubleYourStorage": MessageLookupByLibrary.simpleMessage(
            "* يمكنك مضاعفة مساحة التخزين الخاصة بك بحد أقصى"),
        "youCanManageYourLinksInTheShareTab":
            MessageLookupByLibrary.simpleMessage(
                "يمكنك إدارة روابطك في علامة تبويب المشاركة."),
        "youCanTrySearchingForADifferentQuery":
            MessageLookupByLibrary.simpleMessage(
                "يمكنك محاولة البحث عن استعلام مختلف."),
        "youCannotDowngradeToThisPlan": MessageLookupByLibrary.simpleMessage(
            "لا يمكنك الترقية إلى هذه الخطة."),
        "youCannotShareWithYourself":
            MessageLookupByLibrary.simpleMessage("لا يمكنك المشاركة مع نفسك."),
        "youDontHaveAnyArchivedItems": MessageLookupByLibrary.simpleMessage(
            "لا توجد لديك أي عناصر مؤرشفة."),
        "youHaveSuccessfullyFreedUp": m112,
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("تم حذف حسابك بنجاح."),
        "yourMap": MessageLookupByLibrary.simpleMessage("خريطتك"),
        "yourPlanWasSuccessfullyDowngraded":
            MessageLookupByLibrary.simpleMessage("تم تخفيض خطتك بنجاح."),
        "yourPlanWasSuccessfullyUpgraded":
            MessageLookupByLibrary.simpleMessage("تمت ترقية خطتك بنجاح."),
        "yourPurchaseWasSuccessful":
            MessageLookupByLibrary.simpleMessage("تم الشراء بنجاح."),
        "yourStorageDetailsCouldNotBeFetched":
            MessageLookupByLibrary.simpleMessage(
                "تعذر جلب تفاصيل التخزين الخاصة بك."),
        "yourSubscriptionHasExpired":
            MessageLookupByLibrary.simpleMessage("انتهت صلاحية اشتراكك."),
        "yourSubscriptionWasUpdatedSuccessfully":
            MessageLookupByLibrary.simpleMessage("تم تحديث اشتراكك بنجاح."),
        "yourVerificationCodeHasExpired": MessageLookupByLibrary.simpleMessage(
            "انتهت صلاحية رمز التحقق الخاص بك."),
        "youveNoDuplicateFilesThatCanBeCleared":
            MessageLookupByLibrary.simpleMessage(
                "لا توجد لديك أي ملفات مكررة يمكن مسحها."),
        "youveNoFilesInThisAlbumThatCanBeDeleted":
            MessageLookupByLibrary.simpleMessage(
                "لا توجد لديك ملفات في هذا الألبوم يمكن حذفها."),
        "zoomOutToSeePhotos":
            MessageLookupByLibrary.simpleMessage("قم بالتصغير لرؤية الصور")
      };
}
