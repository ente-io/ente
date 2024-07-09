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
        "addCollaborators": m0,
        "addToHiddenAlbum":
            MessageLookupByLibrary.simpleMessage("Add to hidden album"),
        "addViewers": m1,
        "appLock": MessageLookupByLibrary.simpleMessage("App lock"),
        "changeLocationOfSelectedItems": MessageLookupByLibrary.simpleMessage(
            "Change location of selected items?"),
        "clusteringProgress":
            MessageLookupByLibrary.simpleMessage("Clustering progress"),
        "contacts": MessageLookupByLibrary.simpleMessage("Contacts"),
        "createCollaborativeLink":
            MessageLookupByLibrary.simpleMessage("Create collaborative link"),
        "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
            "This account is linked to other ente apps, if you use any.\\n\\nYour uploaded data, across all ente apps, will be scheduled for deletion, and your account will be permanently deleted."),
        "descriptions": MessageLookupByLibrary.simpleMessage("Descriptions"),
        "deviceLock": MessageLookupByLibrary.simpleMessage("Device lock"),
        "editLocation": MessageLookupByLibrary.simpleMessage("Edit location"),
        "editsToLocationWillOnlyBeSeenWithinEnte":
            MessageLookupByLibrary.simpleMessage(
                "Edits to location will only be seen within Ente"),
        "enterPersonName":
            MessageLookupByLibrary.simpleMessage("Enter person name"),
        "enterPin": MessageLookupByLibrary.simpleMessage("Enter PIN"),
        "faceRecognition":
            MessageLookupByLibrary.simpleMessage("Face recognition"),
        "fileTypes": MessageLookupByLibrary.simpleMessage("File types"),
        "foundFaces": MessageLookupByLibrary.simpleMessage("Found faces"),
        "indexingIsPaused": MessageLookupByLibrary.simpleMessage(
            "Indexing is paused, will automatically resume when device is ready"),
        "joinDiscord": MessageLookupByLibrary.simpleMessage("Join Discord"),
        "locations": MessageLookupByLibrary.simpleMessage("Locations"),
        "longPressAnEmailToVerifyEndToEndEncryption":
            MessageLookupByLibrary.simpleMessage(
                "Long press an email to verify end to end encryption."),
        "mlFunctions": MessageLookupByLibrary.simpleMessage("ML functions"),
        "modifyYourQueryOrTrySearchingFor":
            MessageLookupByLibrary.simpleMessage(
                "Modify your query, or try searching for"),
        "moveToHiddenAlbum":
            MessageLookupByLibrary.simpleMessage("Move to hidden album"),
        "next": MessageLookupByLibrary.simpleMessage("Next"),
        "noSystemLockFound":
            MessageLookupByLibrary.simpleMessage("No system lock found"),
        "passwordLock": MessageLookupByLibrary.simpleMessage("Password lock"),
        "pinLock": MessageLookupByLibrary.simpleMessage("PIN lock"),
        "reenterPassword":
            MessageLookupByLibrary.simpleMessage("Re-enter password"),
        "reenterPin": MessageLookupByLibrary.simpleMessage("Re-enter PIN"),
        "removePersonLabel":
            MessageLookupByLibrary.simpleMessage("Remove person label"),
        "search": MessageLookupByLibrary.simpleMessage("Search"),
        "selectALocation":
            MessageLookupByLibrary.simpleMessage("Select a location"),
        "selectALocationFirst":
            MessageLookupByLibrary.simpleMessage("Select a location first"),
        "setNewPassword":
            MessageLookupByLibrary.simpleMessage("Set new password"),
        "setNewPin": MessageLookupByLibrary.simpleMessage("Set new PIN"),
        "tapToUnlock": MessageLookupByLibrary.simpleMessage("Tap to unlock"),
        "toEnableAppLockPleaseSetupDevicePasscodeOrScreen":
            MessageLookupByLibrary.simpleMessage(
                "To enable app lock, please setup device passcode or screen lock in your system settings."),
        "tooManyIncorrectAttempts":
            MessageLookupByLibrary.simpleMessage("Too many incorrect attempts"),
        "yourMap": MessageLookupByLibrary.simpleMessage("Your map")
      };
}
