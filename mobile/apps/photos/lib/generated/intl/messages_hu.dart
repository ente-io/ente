// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a hu locale. All the
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
  String get localeName => 'hu';

  static String m115(name) => "Wish \$${name} a happy birthday! 🎉";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("Köszöntjük ismét!"),
        "askDeleteReason":
            MessageLookupByLibrary.simpleMessage("Miért törli a fiókját?"),
        "cancel": MessageLookupByLibrary.simpleMessage("Mégse"),
        "deleteAccount": MessageLookupByLibrary.simpleMessage("Fiók törlése"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "Sajnáljuk, hogy távozik. Kérjük, ossza meg velünk visszajelzéseit, hogy segítsen nekünk a fejlődésben."),
        "email": MessageLookupByLibrary.simpleMessage("E-mail"),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
            "Kérjük, adjon meg egy érvényes e-mail címet."),
        "enterYourEmailAddress":
            MessageLookupByLibrary.simpleMessage("Adja meg az e-mail címét"),
        "feedback": MessageLookupByLibrary.simpleMessage("Visszajelzés"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("Érvénytelen e-mail cím"),
        "verify": MessageLookupByLibrary.simpleMessage("Hitelesítés"),
        "wishThemAHappyBirthday": m115
      };
}
