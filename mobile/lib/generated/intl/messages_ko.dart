// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ko locale. All the
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
  String get localeName => 'ko';

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("다시 오신 것을 환영합니다!"),
        "askDeleteReason":
            MessageLookupByLibrary.simpleMessage("계정을 삭제하는 가장 큰 이유가 무엇인가요?"),
        "cancel": MessageLookupByLibrary.simpleMessage("닫기"),
        "confirmAccountDeletion":
            MessageLookupByLibrary.simpleMessage("계정 삭제 확인"),
        "deleteAccount": MessageLookupByLibrary.simpleMessage("계정 삭제"),
        "deleteAccountPermanentlyButton":
            MessageLookupByLibrary.simpleMessage("계정을 영구적으로 삭제"),
        "email": MessageLookupByLibrary.simpleMessage("이메일"),
        "enterValidEmail":
            MessageLookupByLibrary.simpleMessage("올바른 이메일 주소를 입력하세요."),
        "enterYourEmailAddress":
            MessageLookupByLibrary.simpleMessage("이메일을 입력하세요"),
        "feedback": MessageLookupByLibrary.simpleMessage("피드백"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("잘못된 이메일 주소"),
        "verify": MessageLookupByLibrary.simpleMessage("인증"),
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("계정이 삭제되었습니다.")
      };
}
