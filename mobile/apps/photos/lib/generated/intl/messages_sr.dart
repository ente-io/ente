// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a sr locale. All the
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
  String get localeName => 'sr';

  static String m8(count) =>
      "${Intl.plural(count, zero: 'Нека учесника', one: '1 учесник', other: '${count} учесника')}";

  static String m25(supportEmail) =>
      "Молимо Вас да пошаљете имејл на ${supportEmail} са Ваше регистроване адресе е-поште";

  static String m31(email) =>
      "${email} нема Енте налог.\n\nПошаљи им позивницу за дељење фотографија.";

  static String m47(expiryTime) => "Веза ће истећи ${expiryTime}";

  static String m50(count, formattedCount) =>
      "${Intl.plural(count, zero: 'нема сећања', one: '${formattedCount} сећање', other: '${formattedCount} сећања')}";

  static String m55(familyAdminEmail) =>
      "Молимо вас да контактирате ${familyAdminEmail} да бисте променили свој код.";

  static String m57(passwordStrengthValue) =>
      "Снага лозинке: ${passwordStrengthValue}";

  static String m80(count) => "${count} изабрано";

  static String m81(count, yourCount) =>
      "${count} изабрано (${yourCount} Ваше)";

  static String m83(verificationID) =>
      "Ево мог ИД-а за верификацију: ${verificationID} за ente.io.";

  static String m84(verificationID) =>
      "Здраво, можеш ли да потврдиш да је ово твој ente.io ИД за верификацију: ${verificationID}";

  static String m86(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Подели са одређеним особама', one: 'Подељено са 1 особом', other: 'Подељено са ${numberOfPeople} особа')}";

  static String m88(fileType) =>
      "Овај ${fileType} ће бити избрисан са твог уређаја.";

  static String m89(fileType) =>
      "Овај ${fileType} се налази и у Енте-у и на Вашем уређају.";

  static String m90(fileType) => "Овај ${fileType} ће бити избрисан из Енте-а.";

  static String m93(storageAmountInGB) => "${storageAmountInGB} ГБ";

  static String m100(email) => "Ово је ИД за верификацију корисника ${email}";

  static String m111(email) => "Верификуј ${email}";

  static String m114(email) => "Послали смо е-попту на <green>${email}</green>";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "accountWelcomeBack": MessageLookupByLibrary.simpleMessage(
          "Добродошли назад!",
        ),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
          "Разумем да ако изгубим лозинку, могу изгубити своје податке пошто су <underline>шифрирани од краја до краја</underline>.",
        ),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Активне сесије"),
        "advancedSettings": MessageLookupByLibrary.simpleMessage("Напредно"),
        "after1Day": MessageLookupByLibrary.simpleMessage("Након 1 дана"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("Након 1 сата"),
        "after1Month": MessageLookupByLibrary.simpleMessage("Након 1 месеца"),
        "after1Week": MessageLookupByLibrary.simpleMessage("Након 1 недеље"),
        "after1Year": MessageLookupByLibrary.simpleMessage("Након 1 године"),
        "albumParticipantsCount": m8,
        "albumUpdated": MessageLookupByLibrary.simpleMessage("Албум ажуриран"),
        "albums": MessageLookupByLibrary.simpleMessage("Албуми"),
        "apply": MessageLookupByLibrary.simpleMessage("Примени"),
        "applyCodeTitle": MessageLookupByLibrary.simpleMessage("Примени кôд"),
        "archive": MessageLookupByLibrary.simpleMessage("Архивирај"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
          "Који је главни разлог што бришете свој налог?",
        ),
        "authToViewTrashedFiles": MessageLookupByLibrary.simpleMessage(
          "Молимо вас да се аутентификујете да бисте видели датотеке у отпаду",
        ),
        "authToViewYourHiddenFiles": MessageLookupByLibrary.simpleMessage(
          "Молимо вас да се аутентификујете да бисте видели скривене датотеке",
        ),
        "cancel": MessageLookupByLibrary.simpleMessage("Откажи"),
        "change": MessageLookupByLibrary.simpleMessage("Измени"),
        "changeEmail": MessageLookupByLibrary.simpleMessage("Промени е-пошту"),
        "changePasswordTitle": MessageLookupByLibrary.simpleMessage(
          "Промени лозинку",
        ),
        "changeYourReferralCode": MessageLookupByLibrary.simpleMessage(
          "Промени свој реферални код",
        ),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
          "Молимо вас да проверите примљену пошту (и нежељену пошту) да бисте довршили верификацију",
        ),
        "codeAppliedPageTitle": MessageLookupByLibrary.simpleMessage(
          "Кôд примењен",
        ),
        "codeChangeLimitReached": MessageLookupByLibrary.simpleMessage(
          "Жао нам је, достигли сте максимум броја промена кôда.",
        ),
        "codeCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
          "Копирано у међуспремник",
        ),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
          "Креирајте везу која омогућава људима да додају и прегледају фотографије у вашем дељеном албуму без потребе за Енте апликацијом или налогом. Одлично за прикупљање фотографија са догађаја.",
        ),
        "collaborativeLink": MessageLookupByLibrary.simpleMessage(
          "Сарадничка веза",
        ),
        "collectPhotos": MessageLookupByLibrary.simpleMessage(
          "Прикупи фотографије",
        ),
        "confirm": MessageLookupByLibrary.simpleMessage("Потврди"),
        "confirmAccountDeletion": MessageLookupByLibrary.simpleMessage(
          "Потврдите брисање налога",
        ),
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
          "Да, желим трајно да избришем овај налог и све његове податке у свим апликацијама.",
        ),
        "confirmPassword": MessageLookupByLibrary.simpleMessage(
          "Потврдите лозинку",
        ),
        "contactSupport": MessageLookupByLibrary.simpleMessage(
          "Контактирати подршку",
        ),
        "continueLabel": MessageLookupByLibrary.simpleMessage("Настави"),
        "copyLink": MessageLookupByLibrary.simpleMessage("Копирај везу"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
          "Копирајте и налепите овај код \nу своју апликацију за аутентификацију",
        ),
        "createAccount": MessageLookupByLibrary.simpleMessage("Направи налог"),
        "createAlbumActionHint": MessageLookupByLibrary.simpleMessage(
          "Дуго притисните да бисте изабрали фотографије и кликните на + да бисте направили албум",
        ),
        "createNewAccount": MessageLookupByLibrary.simpleMessage(
          "Креирај нови налог",
        ),
        "createPublicLink": MessageLookupByLibrary.simpleMessage(
          "Креирај јавну везу",
        ),
        "custom": MessageLookupByLibrary.simpleMessage("Прилагођено"),
        "decrypting": MessageLookupByLibrary.simpleMessage("Дешифровање..."),
        "deleteAccount": MessageLookupByLibrary.simpleMessage("Обриши налог"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
          "Жао нам је што одлазите. Молимо вас да нам оставите повратне информације како бисмо могли да се побољшамо.",
        ),
        "deleteAccountPermanentlyButton": MessageLookupByLibrary.simpleMessage(
          "Трајно обриши налог",
        ),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
          "Молимо пошаљите имејл на <warning>account-deletion@ente.io</warning> са ваше регистроване адресе е-поште.",
        ),
        "deleteFromBoth": MessageLookupByLibrary.simpleMessage("Обриши са оба"),
        "deleteFromDevice": MessageLookupByLibrary.simpleMessage(
          "Обриши са уређаја",
        ),
        "deleteFromEnte":
            MessageLookupByLibrary.simpleMessage("Обриши са Енте-а"),
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
          "Недостаје важна функција која ми је потребна",
        ),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
          "Апликација или одређена функција не ради онако како мислим да би требало",
        ),
        "deleteReason3": MessageLookupByLibrary.simpleMessage(
          "Пронашао/ла сам други сервис који ми више одговара",
        ),
        "deleteReason4": MessageLookupByLibrary.simpleMessage(
          "Мој разлог није на листи",
        ),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
          "Ваш захтев ће бити обрађен у року од 72 сата.",
        ),
        "doThisLater":
            MessageLookupByLibrary.simpleMessage("Уради ово касније"),
        "done": MessageLookupByLibrary.simpleMessage("Готово"),
        "dropSupportEmail": m25,
        "email": MessageLookupByLibrary.simpleMessage("Е-пошта"),
        "emailAlreadyRegistered": MessageLookupByLibrary.simpleMessage(
          "Е-пошта је већ регистрована.",
        ),
        "emailNoEnteAccount": m31,
        "emailNotRegistered": MessageLookupByLibrary.simpleMessage(
          "Е-пошта није регистрована.",
        ),
        "encryption": MessageLookupByLibrary.simpleMessage("Шифровање"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Кључеви шифровања"),
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
          "Енте-у <i>је потребна дозвола да</i> сачува ваше фотографије",
        ),
        "enterCode": MessageLookupByLibrary.simpleMessage("Унесите кôд"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
          "Унеси код који ти је дао пријатељ да бисте обоје добили бесплатан простор за складиштење",
        ),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
          "Унесите нову лозинку коју можемо да користимо за шифровање ваших података",
        ),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
          "Унесите лозинку коју можемо да користимо за шифровање ваших података",
        ),
        "enterReferralCode": MessageLookupByLibrary.simpleMessage(
          "Унеси реферални код",
        ),
        "enterThe6digitCodeFromnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
          "Унесите 6-цифрени кôд из\nапликације за аутентификацију",
        ),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
          "Молимо унесите исправну адресу е-поште.",
        ),
        "enterYourEmailAddress": MessageLookupByLibrary.simpleMessage(
          "Унесите Вашу е-пошту",
        ),
        "enterYourNewEmailAddress": MessageLookupByLibrary.simpleMessage(
          "Унесите Вашу нову е-пошту",
        ),
        "enterYourPassword": MessageLookupByLibrary.simpleMessage(
          "Унесите лозинку",
        ),
        "enterYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
          "Унесите Ваш кључ за опоравак",
        ),
        "failedToApplyCode": MessageLookupByLibrary.simpleMessage(
          "Грешка у примењивању кôда",
        ),
        "failedToLoadAlbums": MessageLookupByLibrary.simpleMessage(
          "Грешка при учитавању албума",
        ),
        "feedback":
            MessageLookupByLibrary.simpleMessage("Повратне информације"),
        "forgotPassword": MessageLookupByLibrary.simpleMessage(
          "Заборавио сам лозинку",
        ),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
          "Генерисање кључева за шифровање...",
        ),
        "hidden": MessageLookupByLibrary.simpleMessage("Скривено"),
        "howItWorks": MessageLookupByLibrary.simpleMessage("Како ради"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
          "Молимо их да дуго притисну своју адресу е-поште на екрану за подешавања и провере да ли се ИД-ови на оба уређаја поклапају.",
        ),
        "importing": MessageLookupByLibrary.simpleMessage("Увоз...."),
        "incorrectPasswordTitle": MessageLookupByLibrary.simpleMessage(
          "Неисправна лозинка",
        ),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
          "Унети кључ за опоравак је натачан",
        ),
        "incorrectRecoveryKeyTitle": MessageLookupByLibrary.simpleMessage(
          "Нетачан кључ за опоравак",
        ),
        "insecureDevice": MessageLookupByLibrary.simpleMessage(
          "Уређај није сигуран",
        ),
        "invalidEmailAddress": MessageLookupByLibrary.simpleMessage(
          "Неисправна е-пошта",
        ),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
          "Љубазно вас молимо да нам помогнете са овим информацијама",
        ),
        "linkExpiresOn": m47,
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("Веза је истекла"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Пријави се"),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
          "Кликом на пријаву, прихватам <u-terms>услове сервиса</u-terms> и <u-policy>политику приватности</u-policy>",
        ),
        "manageLink": MessageLookupByLibrary.simpleMessage("Управљај везом"),
        "manageParticipants": MessageLookupByLibrary.simpleMessage("Управљај"),
        "memoryCount": m50,
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Средње"),
        "movedToTrash":
            MessageLookupByLibrary.simpleMessage("Премештено у смеће"),
        "never": MessageLookupByLibrary.simpleMessage("Никад"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("Нови албум"),
        "noRecoveryKey": MessageLookupByLibrary.simpleMessage(
          "Немате кључ за опоравак?",
        ),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
          "Због природе нашег протокола за крај-до-крај енкрипцију, ваши подаци не могу бити дешифровани без ваше лозинке или кључа за опоравак",
        ),
        "ok": MessageLookupByLibrary.simpleMessage("Ок"),
        "onlyFamilyAdminCanChangeCode": m55,
        "oops": MessageLookupByLibrary.simpleMessage("Упс!"),
        "password": MessageLookupByLibrary.simpleMessage("Лозинка"),
        "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
          "Лозинка је успешно промењена",
        ),
        "passwordStrength": m57,
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
          "Не чувамо ову лозинку, па ако је заборавите, <underline>не можемо дешифрирати ваше податке</underline>",
        ),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("слика"),
        "pleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("Пробајте поново"),
        "pleaseWait":
            MessageLookupByLibrary.simpleMessage("Молимо сачекајте..."),
        "privacyPolicyTitle": MessageLookupByLibrary.simpleMessage(
          "Политика приватности",
        ),
        "publicLinkEnabled": MessageLookupByLibrary.simpleMessage(
          "Јавна веза је укључена",
        ),
        "recover": MessageLookupByLibrary.simpleMessage("Опорави"),
        "recoverAccount":
            MessageLookupByLibrary.simpleMessage("Опоравак налога"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("Опорави"),
        "recoveryKey": MessageLookupByLibrary.simpleMessage("Кључ за опоравак"),
        "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
          "Кључ за опоравак је копиран у међуспремник",
        ),
        "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
          "Ако заборавите лозинку, једини начин на који можете повратити податке је са овим кључем.",
        ),
        "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
          "Не чувамо овај кључ, молимо да сачувате кључ од 24 речи на сигурном месту.",
        ),
        "recoverySuccessful": MessageLookupByLibrary.simpleMessage(
          "Опоравак успешан!",
        ),
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
          "Тренутни уређај није довољно моћан да потврди вашу лозинку, али можемо регенерирати на начин који ради са свим уређајима.\n\nПријавите се помоћу кључа за опоравак и обновите своју лозинку (можете поново користити исту ако желите).",
        ),
        "recreatePasswordTitle": MessageLookupByLibrary.simpleMessage(
          "Рекреирај лозинку",
        ),
        "removeLink": MessageLookupByLibrary.simpleMessage("Уклони везу"),
        "resendEmail": MessageLookupByLibrary.simpleMessage(
          "Поново пошаљи е-пошту",
        ),
        "resetPasswordTitle": MessageLookupByLibrary.simpleMessage(
          "Ресетуј лозинку",
        ),
        "saveKey": MessageLookupByLibrary.simpleMessage("Сачувај кључ"),
        "scanCode": MessageLookupByLibrary.simpleMessage("Скенирајте кôд"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
          "Скенирајте овај баркод \nсвојом апликацијом за аутентификацију",
        ),
        "selectReason":
            MessageLookupByLibrary.simpleMessage("Одаберите разлог"),
        "selectedPhotos": m80,
        "selectedPhotosWithYours": m81,
        "sendEmail": MessageLookupByLibrary.simpleMessage("Пошаљи е-пошту"),
        "sendInvite": MessageLookupByLibrary.simpleMessage("Пошаљи позивницу"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Пошаљи везу"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Постави лозинку"),
        "setupComplete": MessageLookupByLibrary.simpleMessage(
          "Постављање завршено",
        ),
        "shareALink": MessageLookupByLibrary.simpleMessage("Подели везу"),
        "shareMyVerificationID": m83,
        "shareTextConfirmOthersVerificationID": m84,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
          "Преузми Енте да бисмо лако делили фотографије и видео записе у оригиналном квалитету\n\nhttps://ente.io",
        ),
        "shareWithNonenteUsers": MessageLookupByLibrary.simpleMessage(
          "Пошаљи корисницима који немају Енте налог",
        ),
        "shareWithPeopleSectionTitle": m86,
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
          "Креирај дељене и заједничке албуме са другим Енте корисницима, укључујући и оне на бесплатним плановима.",
        ),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
          "Прихватам <u-terms>услове сервиса</u-terms> и <u-policy>политику приватности</u-policy>",
        ),
        "singleFileDeleteFromDevice": m88,
        "singleFileDeleteHighlight": MessageLookupByLibrary.simpleMessage(
          "Биће обрисано из свих албума.",
        ),
        "singleFileInBothLocalAndRemote": m89,
        "singleFileInRemoteOnly": m90,
        "someoneSharingAlbumsWithYouShouldSeeTheSameId":
            MessageLookupByLibrary.simpleMessage(
          "Особе које деле албуме с тобом би требале да виде исти ИД на свом уређају.",
        ),
        "somethingWentWrong": MessageLookupByLibrary.simpleMessage(
          "Нешто није у реду",
        ),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
          "Нешто је пошло наопако, покушајте поново",
        ),
        "sorry": MessageLookupByLibrary.simpleMessage("Извините"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
          "Извините, не можемо да генеришемо сигурне кључеве на овом уређају.\n\nМолимо пријавите се са другог уређаја.",
        ),
        "storageInGB": m93,
        "strongStrength": MessageLookupByLibrary.simpleMessage("Јако"),
        "tapToCopy":
            MessageLookupByLibrary.simpleMessage("питисните да копирате"),
        "tapToEnterCode": MessageLookupByLibrary.simpleMessage(
          "Пипните да бисте унели кôд",
        ),
        "terminate": MessageLookupByLibrary.simpleMessage("Прекини"),
        "terminateSession": MessageLookupByLibrary.simpleMessage(
          "Прекинути сесију?",
        ),
        "termsOfServicesTitle": MessageLookupByLibrary.simpleMessage("Услови"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("Овај уређај"),
        "thisIsPersonVerificationId": m100,
        "thisIsYourVerificationId": MessageLookupByLibrary.simpleMessage(
          "Ово је Ваш ИД за верификацију",
        ),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
          "Ово ће вас одјавити са овог уређаја:",
        ),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
          "Ово ће вас одјавити са овог уређаја!",
        ),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
          "Да бисте ресетовали лозинку, прво потврдите своју е-пошту.",
        ),
        "trash": MessageLookupByLibrary.simpleMessage("Смеће"),
        "twofactorSetup": MessageLookupByLibrary.simpleMessage(
          "Постављање двофакторске аутентификације",
        ),
        "unavailableReferralCode": MessageLookupByLibrary.simpleMessage(
          "Жао нам је, овај кôд није доступан.",
        ),
        "uncategorized":
            MessageLookupByLibrary.simpleMessage("Некатегоризовано"),
        "useRecoveryKey": MessageLookupByLibrary.simpleMessage(
          "Користи кључ за опоравак",
        ),
        "verificationId": MessageLookupByLibrary.simpleMessage(
          "ИД за верификацију",
        ),
        "verify": MessageLookupByLibrary.simpleMessage("Верификуј"),
        "verifyEmail":
            MessageLookupByLibrary.simpleMessage("Верификуј е-пошту"),
        "verifyEmailID": m111,
        "verifyPassword": MessageLookupByLibrary.simpleMessage(
          "Верификујте лозинку",
        ),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("видео"),
        "weHaveSendEmailTo": m114,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Слабо"),
        "welcomeBack":
            MessageLookupByLibrary.simpleMessage("Добродошли назад!"),
        "yesDelete": MessageLookupByLibrary.simpleMessage("Да, обриши"),
        "youCannotShareWithYourself": MessageLookupByLibrary.simpleMessage(
          "Не можеш делити сам са собом",
        ),
        "yourAccountHasBeenDeleted": MessageLookupByLibrary.simpleMessage(
          "Ваш налог је обрисан",
        ),
      };
}
