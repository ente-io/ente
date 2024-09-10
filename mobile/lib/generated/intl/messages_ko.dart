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

  static String m0(count) =>
      "${Intl.plural(count, zero: 'Add collaborator', one: 'Add collaborator', other: 'Add collaborators')}";

  static String m1(count) =>
      "${Intl.plural(count, zero: 'Add viewer', one: 'Add viewer', other: 'Add viewers')}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("다시 오신 것을 환영합니다!"),
        "addCollaborators": m0,
        "addToHiddenAlbum":
            MessageLookupByLibrary.simpleMessage("Add to hidden album"),
        "addViewers": m1,
        "appLock": MessageLookupByLibrary.simpleMessage("App lock"),
        "askDeleteReason":
            MessageLookupByLibrary.simpleMessage("계정을 삭제하는 가장 큰 이유가 무엇인가요?"),
        "autoLock": MessageLookupByLibrary.simpleMessage("Auto lock"),
        "autoLockFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "Time after which the app locks after being put in the background"),
        "cancel": MessageLookupByLibrary.simpleMessage("닫기"),
        "changeLocationOfSelectedItems": MessageLookupByLibrary.simpleMessage(
            "Change location of selected items?"),
        "clusteringProgress":
            MessageLookupByLibrary.simpleMessage("Clustering progress"),
        "collect": MessageLookupByLibrary.simpleMessage("Collect"),
        "collectPhotos": MessageLookupByLibrary.simpleMessage("Collect photos"),
        "collectPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Create a link where your friends can upload photos in original quality."),
        "confirmAccountDeletion":
            MessageLookupByLibrary.simpleMessage("계정 삭제 확인"),
        "contacts": MessageLookupByLibrary.simpleMessage("Contacts"),
        "createCollaborativeLink":
            MessageLookupByLibrary.simpleMessage("Create collaborative link"),
        "deleteAccount": MessageLookupByLibrary.simpleMessage("계정 삭제"),
        "deleteAccountPermanentlyButton":
            MessageLookupByLibrary.simpleMessage("계정을 영구적으로 삭제"),
        "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
            "This account is linked to other ente apps, if you use any.\\n\\nYour uploaded data, across all ente apps, will be scheduled for deletion, and your account will be permanently deleted."),
        "descriptions": MessageLookupByLibrary.simpleMessage("Descriptions"),
        "deviceLock": MessageLookupByLibrary.simpleMessage("Device lock"),
        "editLocation": MessageLookupByLibrary.simpleMessage("Edit location"),
        "editsToLocationWillOnlyBeSeenWithinEnte":
            MessageLookupByLibrary.simpleMessage(
                "Edits to location will only be seen within Ente"),
        "email": MessageLookupByLibrary.simpleMessage("이메일"),
        "enterPersonName":
            MessageLookupByLibrary.simpleMessage("Enter person name"),
        "enterPin": MessageLookupByLibrary.simpleMessage("Enter PIN"),
        "enterValidEmail":
            MessageLookupByLibrary.simpleMessage("올바른 이메일 주소를 입력하세요."),
        "enterYourEmailAddress":
            MessageLookupByLibrary.simpleMessage("이메일을 입력하세요"),
        "faceRecognition":
            MessageLookupByLibrary.simpleMessage("Face recognition"),
        "feedback": MessageLookupByLibrary.simpleMessage("피드백"),
        "fileTypes": MessageLookupByLibrary.simpleMessage("File types"),
        "foundFaces": MessageLookupByLibrary.simpleMessage("Found faces"),
        "guestView": MessageLookupByLibrary.simpleMessage("Guest view"),
        "guestViewEnablePreSteps": MessageLookupByLibrary.simpleMessage(
            "To enable guest view, please setup device passcode or screen lock in your system settings."),
        "hideContent": MessageLookupByLibrary.simpleMessage("Hide content"),
        "hideContentDescriptionAndroid": MessageLookupByLibrary.simpleMessage(
            "Hides app content in the app switcher and disables screenshots"),
        "hideContentDescriptionIos": MessageLookupByLibrary.simpleMessage(
            "Hides app content in the app switcher"),
        "immediately": MessageLookupByLibrary.simpleMessage("Immediately"),
        "indexingIsPaused": MessageLookupByLibrary.simpleMessage(
            "Indexing is paused, will automatically resume when device is ready"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("잘못된 이메일 주소"),
        "joinDiscord": MessageLookupByLibrary.simpleMessage("Join Discord"),
        "localSyncErrorMessage": MessageLookupByLibrary.simpleMessage(
            "Looks like something went wrong since local photos sync is taking more time than expected. Please reach out to our support team"),
        "locations": MessageLookupByLibrary.simpleMessage("Locations"),
        "longPressAnEmailToVerifyEndToEndEncryption":
            MessageLookupByLibrary.simpleMessage(
                "Long press an email to verify end to end encryption."),
        "modifyYourQueryOrTrySearchingFor":
            MessageLookupByLibrary.simpleMessage(
                "Modify your query, or try searching for"),
        "moveToHiddenAlbum":
            MessageLookupByLibrary.simpleMessage("Move to hidden album"),
        "nameTheAlbum": MessageLookupByLibrary.simpleMessage("Name the album"),
        "next": MessageLookupByLibrary.simpleMessage("Next"),
        "noQuickLinksSelected":
            MessageLookupByLibrary.simpleMessage("No quick links selected"),
        "noSystemLockFound":
            MessageLookupByLibrary.simpleMessage("No system lock found"),
        "passwordLock": MessageLookupByLibrary.simpleMessage("Password lock"),
        "passwordStrengthInfo": MessageLookupByLibrary.simpleMessage(
            "Password strength is calculated considering the length of the password, used characters, and whether or not the password appears in the top 10,000 most used passwords"),
        "pinLock": MessageLookupByLibrary.simpleMessage("PIN lock"),
        "pleaseSelectQuickLinksToRemove": MessageLookupByLibrary.simpleMessage(
            "Please select quick links to remove"),
        "reenterPassword":
            MessageLookupByLibrary.simpleMessage("Re-enter password"),
        "reenterPin": MessageLookupByLibrary.simpleMessage("Re-enter PIN"),
        "removePersonLabel":
            MessageLookupByLibrary.simpleMessage("Remove person label"),
        "removePublicLinks":
            MessageLookupByLibrary.simpleMessage("Remove public links"),
        "search": MessageLookupByLibrary.simpleMessage("Search"),
        "selectALocation":
            MessageLookupByLibrary.simpleMessage("Select a location"),
        "selectALocationFirst":
            MessageLookupByLibrary.simpleMessage("Select a location first"),
        "setNewPassword":
            MessageLookupByLibrary.simpleMessage("Set new password"),
        "setNewPin": MessageLookupByLibrary.simpleMessage("Set new PIN"),
        "showPerson": MessageLookupByLibrary.simpleMessage("Show person"),
        "tapToUnlock": MessageLookupByLibrary.simpleMessage("Tap to unlock"),
        "thisWillRemovePublicLinksOfAllSelectedQuickLinks":
            MessageLookupByLibrary.simpleMessage(
                "This will remove public links of all selected quick links."),
        "toEnableAppLockPleaseSetupDevicePasscodeOrScreen":
            MessageLookupByLibrary.simpleMessage(
                "To enable app lock, please setup device passcode or screen lock in your system settings."),
        "tooManyIncorrectAttempts":
            MessageLookupByLibrary.simpleMessage("Too many incorrect attempts"),
        "verify": MessageLookupByLibrary.simpleMessage("인증"),
        "yourAccountHasBeenDeleted":
            MessageLookupByLibrary.simpleMessage("계정이 삭제되었습니다."),
        "yourMap": MessageLookupByLibrary.simpleMessage("Your map")
      };
}
