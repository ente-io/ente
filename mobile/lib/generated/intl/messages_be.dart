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
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Актыўныя сеансы"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "Якая асноўная прычына выдалення вашага ўліковага запісу?"),
        "cancel": MessageLookupByLibrary.simpleMessage("Скасаваць"),
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
        "email": MessageLookupByLibrary.simpleMessage("Электронная пошта"),
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
        "enterYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Увядзіце свой ключ аднаўлення"),
        "feedback": MessageLookupByLibrary.simpleMessage("Водгук"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Забыліся пароль"),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "Вы ўвялі памылковы ключ аднаўлення"),
        "incorrectRecoveryKeyTitle":
            MessageLookupByLibrary.simpleMessage("Няправільны ключ аднаўлення"),
        "invalidEmailAddress": MessageLookupByLibrary.simpleMessage(
            "Памылковы адрас электроннай пошты"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "Калі ласка, дапамажыце нам з гэтай інфармацыяй"),
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
        "recoverButton": MessageLookupByLibrary.simpleMessage("Аднавіць"),
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("Паспяховае аднаўленне!"),
        "resendEmail":
            MessageLookupByLibrary.simpleMessage("Адправіць ліст яшчэ раз"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Скінуць пароль"),
        "selectReason":
            MessageLookupByLibrary.simpleMessage("Выберыце прычыну"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("Адправіць ліст"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Задаць пароль"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Нешта пайшло не так. Паспрабуйце яшчэ раз"),
        "sorry": MessageLookupByLibrary.simpleMessage("Прабачце"),
        "strongStrength": MessageLookupByLibrary.simpleMessage("Надзейны"),
        "tapToEnterCode":
            MessageLookupByLibrary.simpleMessage("Націсніце, каб увесці код"),
        "terminate": MessageLookupByLibrary.simpleMessage("Перарваць"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("Перарваць сеанс?"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("Гэта прылада"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "Гэта дзеянне завяршыць сеанс на наступнай прыладзе:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "Гэта дзеянне завяршыць сеанс на вашай прыладзе!"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "Праверце электронную пошту, каб скінуць свой пароль."),
        "verify": MessageLookupByLibrary.simpleMessage("Праверыць"),
        "verifyEmail":
            MessageLookupByLibrary.simpleMessage("Праверыць электронную пошту"),
        "weHaveSendEmailTo": m1,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Ненадзейны"),
        "yourAccountHasBeenDeleted": MessageLookupByLibrary.simpleMessage(
            "Ваш уліковы запіс быў выдалены")
      };
}
