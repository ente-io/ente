// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a hi locale. All the
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
  String get localeName => 'hi';

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
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("आपका पुनः स्वागत है"),
        "activeSessions": MessageLookupByLibrary.simpleMessage("एक्टिव सेशन"),
        "add": MessageLookupByLibrary.simpleMessage("Add"),
        "addFiles": MessageLookupByLibrary.simpleMessage("Add Files"),
        "addNew": MessageLookupByLibrary.simpleMessage("Add new"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "आपका अकाउंट हटाने का मुख्य कारण क्या है?"),
        "cancel": MessageLookupByLibrary.simpleMessage("रद्द करें"),
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
        "confirmAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "अकाउंट डिलीट करने की पुष्टि करें"),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("पासवर्ड की पुष्टि करें"),
        "createAccount": MessageLookupByLibrary.simpleMessage("अकाउंट बनायें"),
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("नया अकाउंट बनाएँ"),
        "currentlyRunning":
            MessageLookupByLibrary.simpleMessage("currently running"),
        "decrypting":
            MessageLookupByLibrary.simpleMessage("डिक्रिप्ट हो रहा है..."),
        "deleteAccount":
            MessageLookupByLibrary.simpleMessage("अकाउंट डिलीट करें"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "आपको जाता हुए देख कर हमें खेद है। कृपया हमें बेहतर बनने में सहायता के लिए अपनी प्रतिक्रिया साझा करें।"),
        "deleteAccountPermanentlyButton": MessageLookupByLibrary.simpleMessage(
            "अकाउंट स्थायी रूप से डिलीट करें"),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "कृपया <warning>account-deletion@ente.io</warning> पर अपने पंजीकृत ईमेल एड्रेस से ईमेल भेजें।"),
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
            "इसमें एक मुख्य विशेषता गायब है जिसकी मुझे आवश्यकता है"),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
            "यह ऐप या इसका कोई एक फीचर मेरे विचारानुसार काम नहीं करता है"),
        "deleteReason3": MessageLookupByLibrary.simpleMessage(
            "मुझे कहीं और कोई दूरी सेवा मिली जो मुझे बेहतर लगी"),
        "deleteReason4": MessageLookupByLibrary.simpleMessage(
            "मेरा कारण इस लिस्ट में नहीं है"),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
            "आपका अनुरोध 72 घंटों के भीतर संसाधित किया जाएगा।"),
        "edit": MessageLookupByLibrary.simpleMessage("Edit"),
        "email": MessageLookupByLibrary.simpleMessage("ईमेल"),
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
            "Ente को आपकी तस्वीरों को संरक्षित करने के लिए <i>अनुमति की आवश्यकता है</i>"),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
            "कृपया वैद्य ईमेल ऐड्रेस डालें"),
        "enterYourEmailAddress":
            MessageLookupByLibrary.simpleMessage("अपना ईमेल ऐड्रेस डालें"),
        "enterYourRecoveryKey":
            MessageLookupByLibrary.simpleMessage("अपनी रिकवरी कुंजी दर्ज करें"),
        "error": MessageLookupByLibrary.simpleMessage("Error"),
        "failedToFetchActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Failed to fetch active sessions"),
        "failedToPlayVideo":
            MessageLookupByLibrary.simpleMessage("Failed to play video"),
        "failedToRefreshStripeSubscription":
            MessageLookupByLibrary.simpleMessage(
                "Failed to refresh subscription"),
        "faceNotClusteredYet": MessageLookupByLibrary.simpleMessage(
            "Face not clustered yet, please come back later"),
        "feedback": MessageLookupByLibrary.simpleMessage("प्रतिपुष्टि"),
        "file": MessageLookupByLibrary.simpleMessage("File"),
        "fileNotUploadedYet":
            MessageLookupByLibrary.simpleMessage("File not uploaded yet"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("पासवर्ड भूल गए"),
        "ignored": MessageLookupByLibrary.simpleMessage("ignored"),
        "imageNotAnalyzed":
            MessageLookupByLibrary.simpleMessage("Image not analyzed"),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "आपके द्वारा दर्ज रिकवरी कुंजी ग़लत है"),
        "incorrectRecoveryKeyTitle":
            MessageLookupByLibrary.simpleMessage("रिकवरी कुंजी ग़लत है"),
        "info": MessageLookupByLibrary.simpleMessage("Info"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("अमान्य ईमेल ऐड्रेस"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "कृपया हमें इस जानकारी के लिए सहायता करें"),
        "month": MessageLookupByLibrary.simpleMessage("month"),
        "monthly": MessageLookupByLibrary.simpleMessage("Monthly"),
        "newLocation": MessageLookupByLibrary.simpleMessage("New location"),
        "noFacesFound": MessageLookupByLibrary.simpleMessage("No faces found"),
        "noInternetConnection":
            MessageLookupByLibrary.simpleMessage("No internet connection"),
        "noRecoveryKey":
            MessageLookupByLibrary.simpleMessage("रिकवरी कुंजी नहीं है?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "हमारे एंड-टू-एंड एन्क्रिप्शन प्रोटोकॉल की प्रकृति के कारण, आपके डेटा को आपके पासवर्ड या रिकवरी कुंजी के बिना डिक्रिप्ट नहीं किया जा सकता है"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("No results found"),
        "noSuggestionsForPerson": m0,
        "ok": MessageLookupByLibrary.simpleMessage("ठीक है"),
        "onlyThem": MessageLookupByLibrary.simpleMessage("Only them"),
        "oops": MessageLookupByLibrary.simpleMessage("ओह!"),
        "password": MessageLookupByLibrary.simpleMessage("पासवर्ड"),
        "photosCount": m1,
        "pleaseCheckYourInternetConnectionAndTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Please check your internet connection and try again."),
        "recoverButton": MessageLookupByLibrary.simpleMessage("पुनः प्राप्त"),
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("रिकवरी सफल हुई!"),
        "searchSectionsLengthMismatch": m2,
        "selectAll": MessageLookupByLibrary.simpleMessage("All"),
        "selectAllShort": MessageLookupByLibrary.simpleMessage("All"),
        "selectCoverPhoto":
            MessageLookupByLibrary.simpleMessage("Select cover photo"),
        "selectMailApp":
            MessageLookupByLibrary.simpleMessage("Select mail app"),
        "selectReason": MessageLookupByLibrary.simpleMessage("कारण चुनें"),
        "selectYourPlan":
            MessageLookupByLibrary.simpleMessage("Select your plan"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("ईमेल भेजें"),
        "sessionExpired":
            MessageLookupByLibrary.simpleMessage("Session expired"),
        "sessionIdMismatch":
            MessageLookupByLibrary.simpleMessage("Session ID mismatch"),
        "share": MessageLookupByLibrary.simpleMessage("Share"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "कुछ गड़बड़ हुई है। कृपया दोबारा प्रयास करें।"),
        "sorry": MessageLookupByLibrary.simpleMessage("क्षमा करें!"),
        "subscription": MessageLookupByLibrary.simpleMessage("Subscription"),
        "tapToUpload": MessageLookupByLibrary.simpleMessage("Tap to upload"),
        "tapToUploadIsIgnoredDue": m3,
        "terminate": MessageLookupByLibrary.simpleMessage("रद्द करें"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("सेशन रद्द करें?"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("यह डिवाइस"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "इससे आप इन डिवाइसों से लॉग आउट हो जाएँगे:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "इससे आप इस डिवाइस से लॉग आउट हो जाएँगे!"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "अपना पासवर्ड रीसेट करने के लिए, कृपया पहले अपना ईमेल सत्यापित करें।"),
        "typeOfGallerGallerytypeIsNotSupportedForRename": m4,
        "uploadIsIgnoredDueToIgnorereason": m5,
        "verify": MessageLookupByLibrary.simpleMessage("सत्यापित करें"),
        "verifyEmail":
            MessageLookupByLibrary.simpleMessage("ईमेल सत्यापित करें"),
        "yearShort": MessageLookupByLibrary.simpleMessage("yr"),
        "yearly": MessageLookupByLibrary.simpleMessage("Yearly"),
        "yourAccountHasBeenDeleted": MessageLookupByLibrary.simpleMessage(
            "आपका अकाउंट डिलीट कर दिया गया है"),
        "yourMap": MessageLookupByLibrary.simpleMessage("Your Map")
      };
}
