// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a bg locale. All the
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
  String get localeName => 'bg';

  static String m0(personName) => "No suggestions for ${personName}";

  static String m1(count) => "${count} photos";

  static String m2(snapshotLenght, searchLenght) =>
      "Sections length mismatch: ${snapshotLenght} != ${searchLenght}";

  static String m3(ignoreReason) =>
      "Tap to upload, upload is currently ignored due to ${ignoreReason}";

  static String m4(galleryType) =>
      "Type of gallery ${galleryType} is not supported for rename";

  static String m5(ignoreReason) => "Upload is ignored due to ${ignoreReason}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "accountIsAlreadyConfigured": MessageLookupByLibrary.simpleMessage(
            "Account is already configured."),
        "add": MessageLookupByLibrary.simpleMessage("Add"),
        "addFiles": MessageLookupByLibrary.simpleMessage("Add Files"),
        "addNew": MessageLookupByLibrary.simpleMessage("Add new"),
        "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
        "castAlbum": MessageLookupByLibrary.simpleMessage("Cast album"),
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
        "currentlyRunning":
            MessageLookupByLibrary.simpleMessage("currently running"),
        "edit": MessageLookupByLibrary.simpleMessage("Edit"),
        "error": MessageLookupByLibrary.simpleMessage("Error"),
        "failedToFetchActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Failed to fetch active sessions"),
        "failedToPlayVideo":
            MessageLookupByLibrary.simpleMessage("Failed to play video"),
        "failedToRefreshStripeSubscription":
            MessageLookupByLibrary.simpleMessage(
                "Failed to refresh subscription"),
        "file": MessageLookupByLibrary.simpleMessage("File"),
        "fileNotUploadedYet":
            MessageLookupByLibrary.simpleMessage("File not uploaded yet"),
        "ignored": MessageLookupByLibrary.simpleMessage("ignored"),
        "imageNotAnalyzed":
            MessageLookupByLibrary.simpleMessage("Image not analyzed"),
        "info": MessageLookupByLibrary.simpleMessage("Info"),
        "month": MessageLookupByLibrary.simpleMessage("month"),
        "monthly": MessageLookupByLibrary.simpleMessage("Monthly"),
        "newLocation": MessageLookupByLibrary.simpleMessage("New location"),
        "noFacesFound": MessageLookupByLibrary.simpleMessage("No faces found"),
        "noInternetConnection":
            MessageLookupByLibrary.simpleMessage("No internet connection"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("No results found"),
        "noSuggestionsForPerson": m0,
        "ok": MessageLookupByLibrary.simpleMessage("OK"),
        "onlyThem": MessageLookupByLibrary.simpleMessage("Only them"),
        "oops": MessageLookupByLibrary.simpleMessage("Oops"),
        "photosCount": m1,
        "pleaseCheckYourInternetConnectionAndTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Please check your internet connection and try again."),
        "searchSectionsLengthMismatch": m2,
        "selectAll": MessageLookupByLibrary.simpleMessage("All"),
        "selectAllShort": MessageLookupByLibrary.simpleMessage("All"),
        "selectCoverPhoto":
            MessageLookupByLibrary.simpleMessage("Select cover photo"),
        "selectMailApp":
            MessageLookupByLibrary.simpleMessage("Select mail app"),
        "selectYourPlan":
            MessageLookupByLibrary.simpleMessage("Select your plan"),
        "sessionExpired":
            MessageLookupByLibrary.simpleMessage("Session expired"),
        "sessionIdMismatch":
            MessageLookupByLibrary.simpleMessage("Session ID mismatch"),
        "share": MessageLookupByLibrary.simpleMessage("Share"),
        "subscription": MessageLookupByLibrary.simpleMessage("Subscription"),
        "tapToUpload": MessageLookupByLibrary.simpleMessage("Tap to upload"),
        "tapToUploadIsIgnoredDue": m3,
        "typeOfGallerGallerytypeIsNotSupportedForRename": m4,
        "uploadIsIgnoredDueToIgnorereason": m5,
        "yearShort": MessageLookupByLibrary.simpleMessage("yr"),
        "yearly": MessageLookupByLibrary.simpleMessage("Yearly"),
        "yourMap": MessageLookupByLibrary.simpleMessage("Your Map")
      };
}
