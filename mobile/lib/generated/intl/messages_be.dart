// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a be locale. All the
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
  String get localeName => 'be';

  static String m0(passwordStrengthValue) =>
      "Надзейнасць пароля: ${passwordStrengthValue}";

  static String m1(email) =>
      "Ліст адпраўлены на электронную пошту <green>${email}</green>";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("З вяртаннем!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "Я ўсведамляю, што калі я страчу свой пароль, то я магу згубіць свае даныя, бо мае даныя абаронены <underline>скразным шыфраваннем</underline>."),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Актыўныя сеансы"),
        "allPersonGroupingWillReset": MessageLookupByLibrary.simpleMessage(
            "All groupings for this person will be reset, and you will lose all suggestions made for this person"),
        "areYouSureYouWantToResetThisPerson":
            MessageLookupByLibrary.simpleMessage(
                "Are you sure you want to reset this person?"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "Якая асноўная прычына выдалення вашага ўліковага запісу?"),
        "cancel": MessageLookupByLibrary.simpleMessage("Скасаваць"),
        "changeEmail": MessageLookupByLibrary.simpleMessage(
            "Змяніць адрас электроннай пошты"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Змяніць пароль"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Праверце свае ўваходныя лісты (і спам) для завяршэння праверкі"),
        "confirmAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Пацвердзіць выдаленне ўліковага запісу"),
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "Так. Я хачу незваротна выдаліць гэты ўліковы запіс і яго даныя ва ўсіх праграмах."),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Пацвердзіць пароль"),
        "contactSupport": MessageLookupByLibrary.simpleMessage(
            "Звярніцеся ў службу падтрымкі"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("Працягнуць"),
        "createAccount":
            MessageLookupByLibrary.simpleMessage("Стварыць уліковы запіс"),
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("Стварыць новы ўліковы запіс"),
        "decrypting": MessageLookupByLibrary.simpleMessage("Расшыфроўка..."),
        "deleteAccount":
            MessageLookupByLibrary.simpleMessage("Выдаліць уліковы запіс"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "Нам шкада, што вы выдаляеце свой уліковы запіс. Абагуліце з намі водгук, каб дапамагчы нам палепшыць сэрвіс."),
        "deleteAccountPermanentlyButton": MessageLookupByLibrary.simpleMessage(
            "Незваротна выдаліць уліковы запіс"),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "Адпраўце ліст на <warning>account-deletion@ente.io</warning> з вашага зарэгістраванага адраса электроннай пошты."),
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
            "У вас адсутнічае важная функцыя, якая мне неабходна"),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
            "Праграма або пэўная функцыя не паводзіць сябе так, як павінна"),
        "deleteReason3": MessageLookupByLibrary.simpleMessage(
            "Я знайшоў больш прывабны сэрвіс"),
        "deleteReason4":
            MessageLookupByLibrary.simpleMessage("Прычына адсутнічае ў спісе"),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
            "Ваш запыт будзе апрацаваны цягам 72 гадзін."),
        "doThisLater":
            MessageLookupByLibrary.simpleMessage("Зрабіць гэта пазней"),
        "email": MessageLookupByLibrary.simpleMessage("Электронная пошта"),
        "encryption": MessageLookupByLibrary.simpleMessage("Шыфраванне"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Ключы шыфравання"),
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
            "Праграме <i>неабходны доступ</i> для захавання вашых фатаграфій"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Увядзіце новы пароль, каб мы маглі выкарыстаць яго для расшыфроўкі вашых даных"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Увядзіце пароль, каб мы маглі выкарыстаць яго для расшыфроўкі вашых даных"),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
            "Увядзіце сапраўдны адрас электронная пошты."),
        "enterYourEmailAddress": MessageLookupByLibrary.simpleMessage(
            "Увядзіце свой адрас электроннай пошты"),
        "enterYourPassword":
            MessageLookupByLibrary.simpleMessage("Увядзіце свой пароль"),
        "enterYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Увядзіце свой ключ аднаўлення"),
        "feedback": MessageLookupByLibrary.simpleMessage("Водгук"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Забыліся пароль"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Генерацыя ключоў шыфравання..."),
        "howItWorks": MessageLookupByLibrary.simpleMessage("Як гэта працуе"),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Няправільны пароль"),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "Вы ўвялі памылковы ключ аднаўлення"),
        "incorrectRecoveryKeyTitle":
            MessageLookupByLibrary.simpleMessage("Няправільны ключ аднаўлення"),
        "insecureDevice":
            MessageLookupByLibrary.simpleMessage("Небяспечная прылада"),
        "invalidEmailAddress": MessageLookupByLibrary.simpleMessage(
            "Памылковы адрас электроннай пошты"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "Калі ласка, дапамажыце нам з гэтай інфармацыяй"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Увайсці"),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "Націскаючы ўвайсці, я пагаджаюся з <u-terms>умовамі абслугоўвання</u-terms> і <u-policy>палітыкай прыватнасці</u-policy>"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Умераны"),
        "noRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Няма ключа аднаўлення?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "Вашы даныя не могуць быць расшыфраваны без пароля або ключа аднаўлення па прычыне архітэктуры наша пратакола скразнога шыфравання"),
        "ok": MessageLookupByLibrary.simpleMessage("Добра"),
        "oops": MessageLookupByLibrary.simpleMessage("Вой"),
        "password": MessageLookupByLibrary.simpleMessage("Пароль"),
        "passwordChangedSuccessfully":
            MessageLookupByLibrary.simpleMessage("Пароль паспяхова зменены"),
        "passwordStrength": m0,
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "Мы не захоўваем гэты пароль і <underline>мы не зможам расшыфраваць вашы даныя</underline>, калі вы забудзеце яго"),
        "pleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("Паспрабуйце яшчэ раз"),
        "pleaseWait": MessageLookupByLibrary.simpleMessage("Пачакайце..."),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("Палітыка прыватнасці"),
        "recover": MessageLookupByLibrary.simpleMessage("Аднавіць"),
        "recoverAccount":
            MessageLookupByLibrary.simpleMessage("Аднавіць уліковы запіс"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("Аднавіць"),
        "recoveryKey": MessageLookupByLibrary.simpleMessage("Ключ аднаўлення"),
        "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Ключ аднаўлення скапіяваны ў буфер абмену"),
        "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
            "Адзіным спосабам аднавіць вашы даныя з\'яўляецца гэты ключ, калі вы забылі свой пароль."),
        "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
            "Захавайце гэты ключ, які складаецца з 24 слоў, у наедзеным месцы. Ён не захоўваецца на нашым серверы."),
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("Паспяховае аднаўленне!"),
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "У бягучай прылады недастаткова вылічальнай здольнасці для праверкі вашага паролю, але мы можам регенерыраваць яго, бо гэта працуе з усімі прыладамі.\n\nУвайдзіце, выкарыстоўваючы свой ключа аднаўлення і регенерыруйце свой пароль (калі хочаце, то можаце выбраць папярэдні пароль)."),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Стварыць пароль паўторна"),
        "resendEmail":
            MessageLookupByLibrary.simpleMessage("Адправіць ліст яшчэ раз"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Скінуць пароль"),
        "resetPerson": MessageLookupByLibrary.simpleMessage("Reset person"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Захаваць ключ"),
        "selectReason":
            MessageLookupByLibrary.simpleMessage("Выберыце прычыну"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("Адправіць ліст"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Задаць пароль"),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "Я пагаджаюся з <u-terms>умовамі абслугоўвання</u-terms> і <u-policy>палітыкай прыватнасці</u-policy>"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Нешта пайшло не так. Паспрабуйце яшчэ раз"),
        "sorry": MessageLookupByLibrary.simpleMessage("Прабачце"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "Немагчыма згенерыраваць ключы бяспекі на гэтай прыладзе.\n\nЗарэгіструйцеся з іншай прылады."),
        "strongStrength": MessageLookupByLibrary.simpleMessage("Надзейны"),
        "tapToEnterCode":
            MessageLookupByLibrary.simpleMessage("Націсніце, каб увесці код"),
        "terminate": MessageLookupByLibrary.simpleMessage("Перарваць"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("Перарваць сеанс?"),
        "termsOfServicesTitle": MessageLookupByLibrary.simpleMessage("Умовы"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("Гэта прылада"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Гэта дзеянне завяршыць сеанс на наступнай прыладзе:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Гэта дзеянне завяршыць сеанс на вашай прыладзе!"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "Праверце электронную пошту, каб скінуць свой пароль."),
        "useRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Выкарыстоўваць ключ аднаўлення"),
        "verify": MessageLookupByLibrary.simpleMessage("Праверыць"),
        "verifyEmail":
            MessageLookupByLibrary.simpleMessage("Праверыць электронную пошту"),
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Праверыць пароль"),
        "weHaveSendEmailTo": m1,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Ненадзейны"),
        "welcomeBack": MessageLookupByLibrary.simpleMessage("З вяртаннем!"),
        "yesResetPerson":
            MessageLookupByLibrary.simpleMessage("Yes, reset person"),
        "yourAccountHasBeenDeleted": MessageLookupByLibrary.simpleMessage(
            "Ваш уліковы запіс быў выдалены")
      };
}
