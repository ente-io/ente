// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a th locale. All the
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
  String get localeName => 'th';

  static String m13(count) => "${Intl.plural(count, other: 'เพิ่มรายการ')}";

  static String m19(versionValue) => "รุ่น: ${versionValue}";

  static String m28(count) =>
      "${Intl.plural(count, one: 'ลบ ${count} รายการ', other: 'ลบ ${count} รายการ')}";

  static String m29(currentlyDeleting, totalCount) =>
      "กำลังลบ ${currentlyDeleting} / ${totalCount}";

  static String m31(supportEmail) =>
      "กรุณาส่งอีเมลไปที่ ${supportEmail} จากที่อยู่อีเมลที่คุณลงทะเบียนไว้";

  static String m44(currentlyProcessing, totalCount) =>
      "กำลังประมวลผล ${currentlyProcessing} / ${totalCount}";

  static String m45(count) => "${Intl.plural(count, other: '${count} รายการ')}";

  static String m47(count) => "${Intl.plural(count, other: 'ย้ายรายการ')}";

  static String m0(personName) => "No suggestions for ${personName}";

  static String m6(passwordStrengthValue) =>
      "ความแข็งแรงของรหัสผ่าน: ${passwordStrengthValue}";

  static String m1(count) => "${count} photos";

  static String m2(snapshotLenght, searchLenght) =>
      "Sections length mismatch: ${snapshotLenght} != ${searchLenght}";

  static String m69(
          usedAmount, usedStorageUnit, totalAmount, totalStorageUnit) =>
      "ใช้ไป ${usedAmount} ${usedStorageUnit} จาก ${totalAmount} ${totalStorageUnit}";

  static String m3(ignoreReason) =>
      "Tap to upload, upload is currently ignored due to ${ignoreReason}";

  static String m4(galleryType) =>
      "Type of gallery ${galleryType} is not supported for rename";

  static String m5(ignoreReason) => "Upload is ignored due to ${ignoreReason}";

  static String m8(email) => "เราได้ส่งจดหมายไปยัง <green>${email}</green>";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "accountIsAlreadyConfigured": MessageLookupByLibrary.simpleMessage(
            "Account is already configured."),
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("ยินดีต้อนรับกลับมา!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "ฉันเข้าใจว่าหากฉันทำรหัสผ่านหาย ข้อมูลของฉันอาจสูญหายเนื่องจากข้อมูลของฉัน<underline>มีการเข้ารหัสจากต้นทางถึงปลายทาง</underline>"),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("เซสชันที่ใช้งานอยู่"),
        "add": MessageLookupByLibrary.simpleMessage("Add"),
        "addANewEmail": MessageLookupByLibrary.simpleMessage("เพิ่มอีเมลใหม่"),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("เพิ่มผู้ทำงานร่วมกัน"),
        "addFiles": MessageLookupByLibrary.simpleMessage("Add Files"),
        "addItem": m13,
        "addMore": MessageLookupByLibrary.simpleMessage("เพิ่มอีก"),
        "addNew": MessageLookupByLibrary.simpleMessage("Add new"),
        "addToAlbum": MessageLookupByLibrary.simpleMessage("เพิ่มไปยังอัลบั้ม"),
        "addViewer": MessageLookupByLibrary.simpleMessage("เพิ่มผู้ชม"),
        "after1Day": MessageLookupByLibrary.simpleMessage("หลังจาก 1 วัน"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("หลังจาก 1 ชั่วโมง"),
        "after1Month": MessageLookupByLibrary.simpleMessage("หลังจาก 1 เดือน"),
        "after1Week": MessageLookupByLibrary.simpleMessage("หลังจาก 1 สัปดาห์"),
        "after1Year": MessageLookupByLibrary.simpleMessage("หลังจาก 1 ปี"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("เจ้าของ"),
        "allowAddingPhotos":
            MessageLookupByLibrary.simpleMessage("อนุญาตให้เพิ่มรูปภาพ"),
        "allowDownloads":
            MessageLookupByLibrary.simpleMessage("อนุญาตให้ดาวน์โหลด"),
        "androidBiometricSuccess":
            MessageLookupByLibrary.simpleMessage("สำเร็จ"),
        "androidCancelButton": MessageLookupByLibrary.simpleMessage("ยกเลิก"),
        "appVersion": m19,
        "apply": MessageLookupByLibrary.simpleMessage("นำไปใช้"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "เหตุผลหลักที่คุณลบบัญชีคืออะไร?"),
        "authToViewYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "โปรดตรวจสอบสิทธิ์เพื่อดูคีย์การกู้คืนของคุณ"),
        "canOnlyCreateLinkForFilesOwnedByYou":
            MessageLookupByLibrary.simpleMessage(
                "สามารถสร้างลิงก์ได้เฉพาะไฟล์ที่คุณเป็นเจ้าของ"),
        "cancel": MessageLookupByLibrary.simpleMessage("ยกเลิก"),
        "castAlbum": MessageLookupByLibrary.simpleMessage("Cast album"),
        "changeEmail": MessageLookupByLibrary.simpleMessage("เปลี่ยนอีเมล"),
        "changeLogBackupStatusContent": MessageLookupByLibrary.simpleMessage(
            "We\\\'ve added a log of all the files that have been uploaded to Ente, including failures and queued."),
        "changeLogBackupStatusTitle":
            MessageLookupByLibrary.simpleMessage("Backup Status"),
        "changeLogDiscoverContent": MessageLookupByLibrary.simpleMessage(
            "Looking for photos of your id cards, notes, or even memes? Go to the search tab and check out Discover. Based on our semantic search, it\\\'s a place to find photos that might be important for you.\\n\\nOnly available if you have enabled Machine Learning."),
        "changeLogDiscoverTitle":
            MessageLookupByLibrary.simpleMessage("Discover"),
        "changeLogMagicSearchImprovementContent":
            MessageLookupByLibrary.simpleMessage(
                "We have improved magic search to become much faster, so you don\\\'t have to wait to find what you\\\'re looking for."),
        "changeLogMagicSearchImprovementTitle":
            MessageLookupByLibrary.simpleMessage("Magic Search Improvement"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("เปลี่ยนรหัสผ่าน"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "โปรดตรวจสอบกล่องจดหมาย (และสแปม) ของคุณ เพื่อยืนยันให้เสร็จสิ้น"),
        "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "คัดลอกรหัสไปยังคลิปบอร์ดแล้ว"),
        "collectPhotos": MessageLookupByLibrary.simpleMessage("รวบรวมรูปภาพ"),
        "color": MessageLookupByLibrary.simpleMessage("สี"),
        "confirm": MessageLookupByLibrary.simpleMessage("ยืนยัน"),
        "confirmAccountDeletion":
            MessageLookupByLibrary.simpleMessage("ยืนยันการลบบัญชี"),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("ยืนยันรหัสผ่าน"),
        "confirmRecoveryKey":
            MessageLookupByLibrary.simpleMessage("ยืนยันคีย์การกู้คืน"),
        "confirmYourRecoveryKey":
            MessageLookupByLibrary.simpleMessage("ยืนยันคีย์การกู้คืนของคุณ"),
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("ติดต่อฝ่ายสนับสนุน"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("ดำเนินการต่อ"),
        "copyLink": MessageLookupByLibrary.simpleMessage("คัดลอกลิงก์"),
        "createAccount": MessageLookupByLibrary.simpleMessage("สร้างบัญชี"),
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("สร้างบัญชีใหม่"),
        "createPublicLink":
            MessageLookupByLibrary.simpleMessage("สร้างลิงก์สาธารณะ"),
        "currentlyRunning":
            MessageLookupByLibrary.simpleMessage("currently running"),
        "custom": MessageLookupByLibrary.simpleMessage("กำหนดเอง"),
        "darkTheme": MessageLookupByLibrary.simpleMessage("มืด"),
        "decrypting": MessageLookupByLibrary.simpleMessage("กำลังถอดรหัส..."),
        "delete": MessageLookupByLibrary.simpleMessage("ลบ"),
        "deleteAccount": MessageLookupByLibrary.simpleMessage("ลบบัญชี"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "เราเสียใจที่เห็นคุณไป โปรดแบ่งปันความคิดเห็นของคุณเพื่อช่วยให้เราปรับปรุง"),
        "deleteAccountPermanentlyButton":
            MessageLookupByLibrary.simpleMessage("ลบบัญชีถาวร"),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "กรุณาส่งอีเมลไปที่ <warning>account-deletion@ente.io</warning> จากที่อยู่อีเมลที่คุณลงทะเบียนไว้"),
        "deleteEmptyAlbums":
            MessageLookupByLibrary.simpleMessage("ลบอัลบั้มที่ว่างเปล่า"),
        "deleteEmptyAlbumsWithQuestionMark":
            MessageLookupByLibrary.simpleMessage(
                "ลบอัลบั้มที่ว่างเปล่าหรือไม่?"),
        "deleteItemCount": m28,
        "deleteProgress": m29,
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
            "ขาดคุณสมบัติสำคัญที่ฉันต้องการ"),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
            "ตัวแอปหรือคุณสมบัติบางอย่างไม่ทำงานเหมือนที่ฉันคิดว่าควรจะเป็น"),
        "deleteReason3": MessageLookupByLibrary.simpleMessage(
            "ฉันเจอบริการอื่นที่ฉันชอบมากกว่า"),
        "deleteReason4":
            MessageLookupByLibrary.simpleMessage("เหตุผลของฉันไม่มีระบุไว้"),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
            "คำขอของคุณจะได้รับการดำเนินการภายใน 72 ชั่วโมง"),
        "doThisLater": MessageLookupByLibrary.simpleMessage("ทำในภายหลัง"),
        "dropSupportEmail": m31,
        "edit": MessageLookupByLibrary.simpleMessage("แก้ไข"),
        "editLocationTagTitle":
            MessageLookupByLibrary.simpleMessage("แก้ไขตำแหน่ง"),
        "eligible": MessageLookupByLibrary.simpleMessage("มีสิทธิ์"),
        "email": MessageLookupByLibrary.simpleMessage("อีเมล"),
        "enableMaps": MessageLookupByLibrary.simpleMessage("เปิดใช้งานแผนที่"),
        "encryption": MessageLookupByLibrary.simpleMessage("การเข้ารหัส"),
        "enterCode": MessageLookupByLibrary.simpleMessage("ป้อนรหัส"),
        "enterEmail": MessageLookupByLibrary.simpleMessage("ใส่อีเมล"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "ใส่รหัสผ่านใหม่ที่เราสามารถใช้เพื่อเข้ารหัสข้อมูลของคุณ"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "ใส่รหัสผ่านที่เราสามารถใช้เพื่อเข้ารหัสข้อมูลของคุณ"),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
            "โปรดใส่ที่อยู่อีเมลที่ถูกต้อง"),
        "enterYourEmailAddress":
            MessageLookupByLibrary.simpleMessage("ใส่ที่อยู่อีเมลของคุณ"),
        "enterYourPassword":
            MessageLookupByLibrary.simpleMessage("ใส่รหัสผ่านของคุณ"),
        "enterYourRecoveryKey":
            MessageLookupByLibrary.simpleMessage("ป้อนคีย์การกู้คืน"),
        "error": MessageLookupByLibrary.simpleMessage("Error"),
        "failedToFetchActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Failed to fetch active sessions"),
        "failedToPlayVideo":
            MessageLookupByLibrary.simpleMessage("Failed to play video"),
        "failedToRefreshStripeSubscription":
            MessageLookupByLibrary.simpleMessage(
                "Failed to refresh subscription"),
        "faq": MessageLookupByLibrary.simpleMessage("คำถามที่พบบ่อย"),
        "favorite": MessageLookupByLibrary.simpleMessage("ชื่นชอบ"),
        "feedback": MessageLookupByLibrary.simpleMessage("ความคิดเห็น"),
        "file": MessageLookupByLibrary.simpleMessage("File"),
        "fileInfoAddDescHint":
            MessageLookupByLibrary.simpleMessage("เพิ่มคำอธิบาย..."),
        "fileNotUploadedYet":
            MessageLookupByLibrary.simpleMessage("File not uploaded yet"),
        "forgotPassword": MessageLookupByLibrary.simpleMessage("ลืมรหัสผ่าน"),
        "freeTrial": MessageLookupByLibrary.simpleMessage("ทดลองใช้ฟรี"),
        "genericProgress": m44,
        "goToSettings": MessageLookupByLibrary.simpleMessage("ไปที่การตั้งค่า"),
        "hide": MessageLookupByLibrary.simpleMessage("ซ่อน"),
        "hostedAtOsmFrance":
            MessageLookupByLibrary.simpleMessage("โฮสต์ที่ OSM ฝรั่งเศส"),
        "howItWorks": MessageLookupByLibrary.simpleMessage("วิธีการทำงาน"),
        "iOSOkButton": MessageLookupByLibrary.simpleMessage("ตกลง"),
        "ignored": MessageLookupByLibrary.simpleMessage("ignored"),
        "imageNotAnalyzed":
            MessageLookupByLibrary.simpleMessage("Image not analyzed"),
        "importing": MessageLookupByLibrary.simpleMessage("กำลังนำเข้า...."),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("รหัสผ่านไม่ถูกต้อง"),
        "incorrectRecoveryKey":
            MessageLookupByLibrary.simpleMessage("คีย์การกู้คืนไม่ถูกต้อง"),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "คีย์การกู้คืนที่คุณป้อนไม่ถูกต้อง"),
        "incorrectRecoveryKeyTitle":
            MessageLookupByLibrary.simpleMessage("คีย์การกู้คืนไม่ถูกต้อง"),
        "info": MessageLookupByLibrary.simpleMessage("Info"),
        "insecureDevice":
            MessageLookupByLibrary.simpleMessage("อุปกรณ์ไม่ปลอดภัย"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("ที่อยู่อีเมลไม่ถูกต้อง"),
        "invalidKey": MessageLookupByLibrary.simpleMessage("รหัสไม่ถูกต้อง"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "คีย์การกู้คืนที่คุณป้อนไม่ถูกต้อง โปรดตรวจสอบให้แน่ใจว่ามี 24 คำ และตรวจสอบการสะกดของแต่ละคำ\n\nหากคุณป้อนรหัสกู้คืนที่เก่ากว่า ตรวจสอบให้แน่ใจว่ามีความยาว 64 ตัวอักษร และตรวจสอบแต่ละตัวอักษร"),
        "itemCount": m45,
        "kindlyHelpUsWithThisInformation":
            MessageLookupByLibrary.simpleMessage("กรุณาช่วยเราด้วยข้อมูลนี้"),
        "lastUpdated": MessageLookupByLibrary.simpleMessage("อัปเดตล่าสุด"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("สว่าง"),
        "linkCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "คัดลอกลิงก์ไปยังคลิปบอร์ดแล้ว"),
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("ลิงก์หมดอายุแล้ว"),
        "loadMessage9": MessageLookupByLibrary.simpleMessage(
            "เราใช้ Xchacha20Poly1305 เพื่อเข้ารหัสข้อมูลของคุณอย่างปลอดภัย"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("เข้าสู่ระบบ"),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "โดยการคลิกเข้าสู่ระบบ ฉันยอมรับ<u-terms>เงื่อนไขการให้บริการ</u-terms>และ<u-policy>นโยบายความเป็นส่วนตัว</u-policy>"),
        "manageParticipants": MessageLookupByLibrary.simpleMessage("จัดการ"),
        "map": MessageLookupByLibrary.simpleMessage("แผนที่"),
        "maps": MessageLookupByLibrary.simpleMessage("แผนที่"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("ปานกลาง"),
        "month": MessageLookupByLibrary.simpleMessage("month"),
        "monthly": MessageLookupByLibrary.simpleMessage("Monthly"),
        "moveItem": m47,
        "moveToAlbum": MessageLookupByLibrary.simpleMessage("ย้ายไปยังอัลบั้ม"),
        "name": MessageLookupByLibrary.simpleMessage("ชื่อ"),
        "newLocation": MessageLookupByLibrary.simpleMessage("New location"),
        "newest": MessageLookupByLibrary.simpleMessage("ใหม่สุด"),
        "noFacesFound": MessageLookupByLibrary.simpleMessage("No faces found"),
        "noInternetConnection":
            MessageLookupByLibrary.simpleMessage("No internet connection"),
        "noRecoveryKey":
            MessageLookupByLibrary.simpleMessage("ไม่มีคีย์การกู้คืน?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "เนื่องจากลักษณะของโปรโตคอลการเข้ารหัสตั้งแต่ต้นทางถึงปลายทางของเรา ข้อมูลของคุณจึงไม่สามารถถอดรหัสได้หากไม่มีรหัสผ่านหรือคีย์การกู้คืน"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("No results found"),
        "noSuggestionsForPerson": m0,
        "ok": MessageLookupByLibrary.simpleMessage("ตกลง"),
        "onEnte": MessageLookupByLibrary.simpleMessage(
            "บน <branding>ente</branding>"),
        "onlyThem": MessageLookupByLibrary.simpleMessage("Only them"),
        "oops": MessageLookupByLibrary.simpleMessage("อ๊ะ"),
        "oopsSomethingWentWrong":
            MessageLookupByLibrary.simpleMessage("อ๊ะ มีบางอย่างผิดพลาด"),
        "openstreetmapContributors":
            MessageLookupByLibrary.simpleMessage("ผู้มีส่วนร่วม OpenStreetMap"),
        "orPickAnExistingOne":
            MessageLookupByLibrary.simpleMessage("หรือเลือกที่มีอยู่แล้ว"),
        "password": MessageLookupByLibrary.simpleMessage("รหัสผ่าน"),
        "passwordChangedSuccessfully":
            MessageLookupByLibrary.simpleMessage("เปลี่ยนรหัสผ่านสำเร็จ"),
        "passwordStrength": m6,
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "เราไม่จัดเก็บรหัสผ่านนี้ ดังนั้นหากคุณลืม <underline>เราจะไม่สามารถถอดรหัสข้อมูลของคุณ</underline>"),
        "peopleUsingYourCode":
            MessageLookupByLibrary.simpleMessage("ผู้คนที่ใช้รหัสของคุณ"),
        "permanentlyDelete":
            MessageLookupByLibrary.simpleMessage("ลบอย่างถาวร"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("รูปภาพ"),
        "photosCount": m1,
        "pleaseCheckYourInternetConnectionAndTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Please check your internet connection and try again."),
        "pleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("กรุณาลองอีกครั้ง"),
        "pleaseWait": MessageLookupByLibrary.simpleMessage("กรุณารอสักครู่..."),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("นโยบายความเป็นส่วนตัว"),
        "publicLinkCreated":
            MessageLookupByLibrary.simpleMessage("สร้างลิงก์สาธารณะแล้ว"),
        "publicLinkEnabled":
            MessageLookupByLibrary.simpleMessage("เปิดใช้ลิงก์สาธารณะแล้ว"),
        "recover": MessageLookupByLibrary.simpleMessage("กู้คืน"),
        "recoverAccount": MessageLookupByLibrary.simpleMessage("กู้คืนบัญชี"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("กู้คืน"),
        "recoveryKey": MessageLookupByLibrary.simpleMessage("คีย์การกู้คืน"),
        "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "คัดลอกคีย์การกู้คืนไปยังคลิปบอร์ดแล้ว"),
        "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
            "หากคุณลืมรหัสผ่าน วิธีเดียวที่คุณสามารถกู้คืนข้อมูลของคุณได้คือการใช้คีย์นี้"),
        "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
            "เราไม่จัดเก็บคีย์นี้ โปรดบันทึกคีย์ 24 คำนี้ไว้ในที่ที่ปลอดภัย"),
        "recoveryKeySuccessBody": MessageLookupByLibrary.simpleMessage(
            "ยอดเยี่ยม! คีย์การกู้คืนของคุณถูกต้อง ขอบคุณสำหรับการยืนยัน\n\nโปรดอย่าลืมสำรองคีย์การกู้คืนของคุณไว้อย่างปลอดภัย"),
        "recoveryKeyVerified":
            MessageLookupByLibrary.simpleMessage("ยืนยันคีย์การกู้คืนแล้ว"),
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("กู้คืนสำเร็จ!"),
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "อุปกรณ์ปัจจุบันไม่ทรงพลังพอที่จะยืนยันรหัสผ่านของคุณ แต่เราสามารถสร้างใหม่ในลักษณะที่ใช้ได้กับอุปกรณ์ทั้งหมดได้\n\nกรุณาเข้าสู่ระบบโดยใช้คีย์การกู้คืนของคุณและสร้างรหัสผ่านใหม่ (คุณสามารถใช้รหัสเดิมอีกครั้งได้หากต้องการ)"),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("สร้างรหัสผ่านใหม่"),
        "resendEmail": MessageLookupByLibrary.simpleMessage("ส่งอีเมลอีกครั้ง"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("รีเซ็ตรหัสผ่าน"),
        "restore": MessageLookupByLibrary.simpleMessage(" กู้คืน"),
        "restoreToAlbum":
            MessageLookupByLibrary.simpleMessage("กู้คืนไปยังอัลบั้ม"),
        "save": MessageLookupByLibrary.simpleMessage("บันทึก"),
        "saveCopy": MessageLookupByLibrary.simpleMessage("บันทึกสำเนา"),
        "saveKey": MessageLookupByLibrary.simpleMessage("บันทึกคีย์"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "บันทึกคีย์การกู้คืนของคุณหากคุณยังไม่ได้ทำ"),
        "scanCode": MessageLookupByLibrary.simpleMessage("สแกนรหัส"),
        "searchSectionsLengthMismatch": m2,
        "selectAll": MessageLookupByLibrary.simpleMessage("เลือกทั้งหมด"),
        "selectAllShort": MessageLookupByLibrary.simpleMessage("All"),
        "selectCoverPhoto":
            MessageLookupByLibrary.simpleMessage("Select cover photo"),
        "selectMailApp":
            MessageLookupByLibrary.simpleMessage("Select mail app"),
        "selectReason": MessageLookupByLibrary.simpleMessage("เลือกเหตุผล"),
        "selectYourPlan":
            MessageLookupByLibrary.simpleMessage("Select your plan"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("ส่งอีเมล"),
        "sendLink": MessageLookupByLibrary.simpleMessage("ส่งลิงก์"),
        "sessionExpired":
            MessageLookupByLibrary.simpleMessage("Session expired"),
        "sessionIdMismatch":
            MessageLookupByLibrary.simpleMessage("Session ID mismatch"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("ตั้งรหัสผ่าน"),
        "setupComplete":
            MessageLookupByLibrary.simpleMessage("ตั้งค่าเสร็จสมบูรณ์"),
        "share": MessageLookupByLibrary.simpleMessage("แชร์"),
        "shareALink": MessageLookupByLibrary.simpleMessage("แชร์​ลิงก์"),
        "shareLink": MessageLookupByLibrary.simpleMessage("แชร์​ลิงก์"),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "ฉันยอมรับ<u-terms>เงื่อนไขการให้บริการ</u-terms>และ<u-policy>นโยบายความเป็นส่วนตัว</u-policy>"),
        "skip": MessageLookupByLibrary.simpleMessage("ข้าม"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "มีบางอย่างผิดพลาด โปรดลองอีกครั้ง"),
        "sorry": MessageLookupByLibrary.simpleMessage("ขออภัย"),
        "status": MessageLookupByLibrary.simpleMessage("สถานะ"),
        "storageBreakupFamily":
            MessageLookupByLibrary.simpleMessage("ครอบครัว"),
        "storageBreakupYou": MessageLookupByLibrary.simpleMessage("คุณ"),
        "storageUsageInfo": m69,
        "strongStrength": MessageLookupByLibrary.simpleMessage("แข็งแรง"),
        "subscription": MessageLookupByLibrary.simpleMessage("Subscription"),
        "syncStopped": MessageLookupByLibrary.simpleMessage("หยุดการซิงค์แล้ว"),
        "syncing": MessageLookupByLibrary.simpleMessage("กำลังซิงค์..."),
        "systemTheme": MessageLookupByLibrary.simpleMessage("ระบบ"),
        "tapToCopy": MessageLookupByLibrary.simpleMessage("แตะเพื่อคัดลอก"),
        "tapToEnterCode":
            MessageLookupByLibrary.simpleMessage("แตะเพื่อป้อนรหัส"),
        "tapToUpload": MessageLookupByLibrary.simpleMessage("Tap to upload"),
        "tapToUploadIsIgnoredDue": m3,
        "termsOfServicesTitle":
            MessageLookupByLibrary.simpleMessage("เงื่อนไข"),
        "theRecoveryKeyYouEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "คีย์การกู้คืนที่คุณป้อนไม่ถูกต้อง"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("อุปกรณ์นี้"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "เพื่อรีเซ็ตรหัสผ่านของคุณ โปรดยืนยันอีเมลของคุณก่อน"),
        "total": MessageLookupByLibrary.simpleMessage("รวม"),
        "trash": MessageLookupByLibrary.simpleMessage("ถังขยะ"),
        "tryAgain": MessageLookupByLibrary.simpleMessage("ลองอีกครั้ง"),
        "twofactorSetup":
            MessageLookupByLibrary.simpleMessage("การตั้งค่าสองปัจจัย"),
        "typeOfGallerGallerytypeIsNotSupportedForRename": m4,
        "unarchive": MessageLookupByLibrary.simpleMessage("เลิกเก็บถาวร"),
        "uncategorized": MessageLookupByLibrary.simpleMessage("ไม่มีหมวดหมู่"),
        "unhide": MessageLookupByLibrary.simpleMessage("เลิกซ่อน"),
        "unhideToAlbum":
            MessageLookupByLibrary.simpleMessage("เลิกซ่อนไปยังอัลบั้ม"),
        "unselectAll": MessageLookupByLibrary.simpleMessage("ไม่เลือกทั้งหมด"),
        "uploadIsIgnoredDueToIgnorereason": m5,
        "useRecoveryKey":
            MessageLookupByLibrary.simpleMessage("ใช้คีย์การกู้คืน"),
        "verify": MessageLookupByLibrary.simpleMessage("ยืนยัน"),
        "verifyEmail": MessageLookupByLibrary.simpleMessage("ยืนยันอีเมล"),
        "verifyIDLabel": MessageLookupByLibrary.simpleMessage("ยืนยัน"),
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("ยืนยันรหัสผ่าน"),
        "verifyingRecoveryKey":
            MessageLookupByLibrary.simpleMessage("กำลังยืนยันคีย์การกู้คืน..."),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("วิดีโอ"),
        "viewRecoveryKey":
            MessageLookupByLibrary.simpleMessage("ดูคีย์การกู้คืน"),
        "waitingForWifi":
            MessageLookupByLibrary.simpleMessage("กำลังรอ WiFi..."),
        "weHaveSendEmailTo": m8,
        "weakStrength": MessageLookupByLibrary.simpleMessage("อ่อน"),
        "welcomeBack":
            MessageLookupByLibrary.simpleMessage("ยินดีต้อนรับกลับมา!"),
        "yearShort": MessageLookupByLibrary.simpleMessage("yr"),
        "yearly": MessageLookupByLibrary.simpleMessage("Yearly"),
        "you": MessageLookupByLibrary.simpleMessage("คุณ"),
        "youCanManageYourLinksInTheShareTab":
            MessageLookupByLibrary.simpleMessage(
                "คุณสามารถจัดการลิงก์ของคุณได้ในแท็บแชร์"),
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("บัญชีของคุณถูกลบแล้ว"),
        "yourMap": MessageLookupByLibrary.simpleMessage("Your Map")
      };
}
