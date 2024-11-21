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

  static String m0(ignoreReason) =>
      "Tap to upload, upload is currently ignored due to ${ignoreReason}";

  static String m1(galleryType) =>
      "Type of gallery ${galleryType} is not supported for rename";

  static String m2(ignoreReason) => "Upload is ignored due to ${ignoreReason}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "accountIsAlreadyConfigured": MessageLookupByLibrary.simpleMessage(
            "Account is already configured."),
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("다시 오신 것을 환영합니다!"),
        "addFiles": MessageLookupByLibrary.simpleMessage("Add Files"),
        "askDeleteReason":
            MessageLookupByLibrary.simpleMessage("계정을 삭제하는 가장 큰 이유가 무엇인가요?"),
        "cancel": MessageLookupByLibrary.simpleMessage("닫기"),
        "castAlbum": MessageLookupByLibrary.simpleMessage("Cast album"),
        "confirmAccountDeletion":
            MessageLookupByLibrary.simpleMessage("계정 삭제 확인"),
        "deleteAccount": MessageLookupByLibrary.simpleMessage("계정 삭제"),
        "deleteAccountPermanentlyButton":
            MessageLookupByLibrary.simpleMessage("계정을 영구적으로 삭제"),
        "edit": MessageLookupByLibrary.simpleMessage("Edit"),
        "email": MessageLookupByLibrary.simpleMessage("이메일"),
        "enterValidEmail":
            MessageLookupByLibrary.simpleMessage("올바른 이메일 주소를 입력하세요."),
        "enterYourEmailAddress":
            MessageLookupByLibrary.simpleMessage("이메일을 입력하세요"),
        "error": MessageLookupByLibrary.simpleMessage("Error"),
        "failedToFetchActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Failed to fetch active sessions"),
        "failedToPlayVideo":
            MessageLookupByLibrary.simpleMessage("Failed to play video"),
        "failedToRefreshStripeSubscription":
            MessageLookupByLibrary.simpleMessage(
                "Failed to refresh subscription"),
        "feedback": MessageLookupByLibrary.simpleMessage("피드백"),
        "fileNotUploadedYet":
            MessageLookupByLibrary.simpleMessage("File not uploaded yet"),
        "imageNotAnalyzed":
            MessageLookupByLibrary.simpleMessage("Image not analyzed"),
        "info": MessageLookupByLibrary.simpleMessage("Info"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("잘못된 이메일 주소"),
        "noFacesFound": MessageLookupByLibrary.simpleMessage("No faces found"),
        "noInternetConnection":
            MessageLookupByLibrary.simpleMessage("No internet connection"),
        "ok": MessageLookupByLibrary.simpleMessage("OK"),
        "oops": MessageLookupByLibrary.simpleMessage("Oops"),
        "pleaseCheckYourInternetConnectionAndTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Please check your internet connection and try again."),
        "sessionExpired":
            MessageLookupByLibrary.simpleMessage("Session expired"),
        "sessionIdMismatch":
            MessageLookupByLibrary.simpleMessage("Session ID mismatch"),
        "share": MessageLookupByLibrary.simpleMessage("Share"),
        "tapToUpload": MessageLookupByLibrary.simpleMessage("Tap to upload"),
        "tapToUploadIsIgnoredDue": m0,
        "typeOfGallerGallerytypeIsNotSupportedForRename": m1,
        "uploadIsIgnoredDueToIgnorereason": m2,
        "verify": MessageLookupByLibrary.simpleMessage("인증"),
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("계정이 삭제되었습니다.")
      };
}
