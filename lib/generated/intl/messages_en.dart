// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
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
  String get localeName => 'en';

  static String m0(user) =>
      "${user} will not be able to add more photos to this album\n\nThey will still be able to remove existing photos added by them";

  static String m1(supportEmail) =>
      "Please drop an email to ${supportEmail} from your registered email address";

  static String m2(expiryTime) => "Link will expire on ${expiryTime}";

  static String m3(passwordStrengthValue) =>
      "Password strength: ${passwordStrengthValue}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("Welcome back!"),
        "ackPasswordLostWarningPart1": MessageLookupByLibrary.simpleMessage(
            "I understand that if I lose my password, I may lose my data since my data is "),
        "ackPasswordLostWarningPart2":
            MessageLookupByLibrary.simpleMessage(" with ente"),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Active sessions"),
        "addANewEmail": MessageLookupByLibrary.simpleMessage("Add a new email"),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("Add collaborator"),
        "addMore": MessageLookupByLibrary.simpleMessage("Add more"),
        "addViewer": MessageLookupByLibrary.simpleMessage("Add viewer"),
        "addedAs": MessageLookupByLibrary.simpleMessage("Added as"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("Owner"),
        "albumUpdated": MessageLookupByLibrary.simpleMessage("Album updated"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Allow people with the link to also add photos to the shared album."),
        "allowAddingPhotos":
            MessageLookupByLibrary.simpleMessage("Allow adding photos"),
        "allowDownloads":
            MessageLookupByLibrary.simpleMessage("Allow downloads"),
        "and": MessageLookupByLibrary.simpleMessage("and"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "What is the main reason you are deleting your account?"),
        "byClickingLogInIAgreeToThe": MessageLookupByLibrary.simpleMessage(
            "By clicking log in, I agree to the"),
        "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
        "cannotAddMorePhotosAfterBecomingViewer": m0,
        "changeEmail": MessageLookupByLibrary.simpleMessage("Change email"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Change password"),
        "changePermissions":
            MessageLookupByLibrary.simpleMessage("Change permissions?"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Please check your inbox (and spam) to complete verification"),
        "codeCopiedToClipboard":
            MessageLookupByLibrary.simpleMessage("Code copied to clipboard"),
        "collaborator": MessageLookupByLibrary.simpleMessage("Collaborator"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Collaborators can add photos and videos to the shared album."),
        "confirm": MessageLookupByLibrary.simpleMessage("Confirm"),
        "confirmAccountDeletion":
            MessageLookupByLibrary.simpleMessage("Confirm Account Deletion"),
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "Yes, I want to permanently delete this account and all its data."),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Confirm password"),
        "confirmRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Confirm recovery key"),
        "confirmYourRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Confirm your recovery key"),
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("Contact support"),
        "continueLabel": MessageLookupByLibrary.simpleMessage("Continue"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Copy-paste this code\nto your authenticator app"),
        "createAccount": MessageLookupByLibrary.simpleMessage("Create account"),
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("Create new account"),
        "decrypting": MessageLookupByLibrary.simpleMessage("Decrypting..."),
        "deleteAccount": MessageLookupByLibrary.simpleMessage("Delete account"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "We are sorry to see you go. Please share your feedback to help us improve."),
        "deleteAccountPermanentlyButton":
            MessageLookupByLibrary.simpleMessage("Delete Account Permanently"),
        "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
            "You are about to permanently delete your account and all its data.\nThis action is irreversible."),
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
            "It’s missing a key feature that I need"),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
            "The app or a certain feature does not \nbehave as I think it should"),
        "deleteReason3": MessageLookupByLibrary.simpleMessage(
            "I found another service that I like better"),
        "deleteReason4":
            MessageLookupByLibrary.simpleMessage("My reason isn’t listed"),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
            "Your request will be processed within 72 hours."),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "Viewers can still take screenshots or save a copy of your photos using external tools"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Please note"),
        "doThisLater": MessageLookupByLibrary.simpleMessage("Do this later"),
        "dropSupportEmail": m1,
        "email": MessageLookupByLibrary.simpleMessage("Email"),
        "encryption": MessageLookupByLibrary.simpleMessage("Encryption"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Encryption keys"),
        "endToEndEncrypted":
            MessageLookupByLibrary.simpleMessage("end-to-end encrypted"),
        "enterCode": MessageLookupByLibrary.simpleMessage("Enter code"),
        "enterEmail": MessageLookupByLibrary.simpleMessage("Enter email"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Enter a new password we can use to encrypt your data"),
        "enterPassword": MessageLookupByLibrary.simpleMessage("Enter password"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Enter a password we can use to encrypt your data"),
        "enterThe6digitCodeFromnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Enter the 6-digit code from\nyour authenticator app"),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
            "Please enter a valid email address."),
        "enterYourEmailAddress":
            MessageLookupByLibrary.simpleMessage("Enter your email address"),
        "enterYourPassword":
            MessageLookupByLibrary.simpleMessage("Enter your password"),
        "enterYourRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Enter your recovery key"),
        "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
            "This link has expired. Please select a new expiry time or disable link expiry."),
        "feedback": MessageLookupByLibrary.simpleMessage("Feedback"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Forgot password"),
        "fromYourRegisteredEmailAddress": MessageLookupByLibrary.simpleMessage(
            "from your registered email address."),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Generating encryption keys..."),
        "howItWorks": MessageLookupByLibrary.simpleMessage("How it works"),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Incorrect password"),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "The recovery key you entered is incorrect"),
        "incorrectRecoveryKeyTitle":
            MessageLookupByLibrary.simpleMessage("Incorrect recovery key"),
        "insecureDevice":
            MessageLookupByLibrary.simpleMessage("Insecure device"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("Invalid email address"),
        "invalidKey": MessageLookupByLibrary.simpleMessage("Invalid key"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "The recovery key you entered is not valid. Please make sure it "),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "Kindly help us with this information"),
        "linkDeviceLimit": MessageLookupByLibrary.simpleMessage("Device limit"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Enabled"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Expired"),
        "linkExpiresOn": m2,
        "linkExpiry": MessageLookupByLibrary.simpleMessage("Link expiry"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Never"),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Lock"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Log in"),
        "lostDevice": MessageLookupByLibrary.simpleMessage("Lost device?"),
        "manage": MessageLookupByLibrary.simpleMessage("Manage"),
        "manageLink": MessageLookupByLibrary.simpleMessage("Manage link"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Moderate"),
        "noPasswordWarningPart1": MessageLookupByLibrary.simpleMessage(
            "We don\'t store this password, so if you forget,"),
        "noPasswordWarningPart2":
            MessageLookupByLibrary.simpleMessage("we cannot decrypt your data"),
        "noRecoveryKey":
            MessageLookupByLibrary.simpleMessage("No recovery key?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "Due to the nature of our end-to-end encryption protocol, your data cannot be decrypted without your password or recovery key"),
        "ok": MessageLookupByLibrary.simpleMessage("Ok"),
        "oops": MessageLookupByLibrary.simpleMessage("Oops"),
        "orPickAnExistingOne":
            MessageLookupByLibrary.simpleMessage("Or pick an existing one"),
        "password": MessageLookupByLibrary.simpleMessage("Password"),
        "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
            "Password changed successfully"),
        "passwordLock": MessageLookupByLibrary.simpleMessage("Password lock"),
        "passwordStrength": m3,
        "pleaseSendAnEmailTo":
            MessageLookupByLibrary.simpleMessage("Please send an email to"),
        "pleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("Please try again"),
        "pleaseWait": MessageLookupByLibrary.simpleMessage("Please wait..."),
        "privacyPolicy": MessageLookupByLibrary.simpleMessage("privacy policy"),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("Privacy Policy"),
        "recover": MessageLookupByLibrary.simpleMessage("Recover"),
        "recoverAccount":
            MessageLookupByLibrary.simpleMessage("Recover account"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("Recover"),
        "recoveryKey": MessageLookupByLibrary.simpleMessage("Recovery key"),
        "recoveryKeyCopiedToClipboard": MessageLookupByLibrary.simpleMessage(
            "Recovery key copied to clipboard"),
        "recoveryKeyOnForgotPassword": MessageLookupByLibrary.simpleMessage(
            "If you forget your password, the only way you can recover your data is with this key."),
        "recoveryKeySaveDescription": MessageLookupByLibrary.simpleMessage(
            "We don\'t store this key, please save this 24 word key in a safe place."),
        "recoveryKeySuccessBody": MessageLookupByLibrary.simpleMessage(
            "Great! Your recovery key is valid. Thank you for verifying.\n\nPlease remember to keep your recovery key safely backed up."),
        "recoveryKeyVerified":
            MessageLookupByLibrary.simpleMessage("Recovery key verified"),
        "recoveryKeyVerifyReason": MessageLookupByLibrary.simpleMessage(
            "Your recovery key is the only way to recover your photos if you forget your password. You can find your recovery key in Settings > Account.\n\nPlease enter your recovery key here to verify that you have saved it correctly."),
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("Recovery successful!"),
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "The current device is not powerful enough to verify your "),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Recreate password"),
        "remove": MessageLookupByLibrary.simpleMessage("Remove"),
        "removeLink": MessageLookupByLibrary.simpleMessage("Remove link"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("Remove participant"),
        "resendEmail": MessageLookupByLibrary.simpleMessage("Resend email"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Reset password"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Save key"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "Save your recovery key if you haven\'t already"),
        "scanCode": MessageLookupByLibrary.simpleMessage("Scan code"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Scan this barcode with\nyour authenticator app"),
        "selectReason": MessageLookupByLibrary.simpleMessage("Select reason"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("Send email"),
        "setAPassword": MessageLookupByLibrary.simpleMessage("Set a password"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Set password"),
        "setupComplete": MessageLookupByLibrary.simpleMessage("Setup complete"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Something went wrong, please try again"),
        "sorry": MessageLookupByLibrary.simpleMessage("Sorry"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "Sorry, we could not generate secure keys on this device.\n\nplease sign up from a different device."),
        "strongStrength": MessageLookupByLibrary.simpleMessage("Strong"),
        "tapToCopy": MessageLookupByLibrary.simpleMessage("tap to copy"),
        "tapToEnterCode":
            MessageLookupByLibrary.simpleMessage("Tap to enter code"),
        "terminate": MessageLookupByLibrary.simpleMessage("Terminate"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("Terminate session?"),
        "termsAgreePart1":
            MessageLookupByLibrary.simpleMessage("I agree to the "),
        "termsOfService":
            MessageLookupByLibrary.simpleMessage("terms of service"),
        "termsOfServicesTitle": MessageLookupByLibrary.simpleMessage("Terms"),
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "This can be used to recover your account if you lose your second factor"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("This device"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "This will log you out of the following device:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "This will log you out of this device!"),
        "tryAgain": MessageLookupByLibrary.simpleMessage("Try again"),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage("Two-factor authentication"),
        "twofactorSetup":
            MessageLookupByLibrary.simpleMessage("Two-factor setup"),
        "useRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Use recovery key"),
        "verify": MessageLookupByLibrary.simpleMessage("Verify"),
        "verifyEmail": MessageLookupByLibrary.simpleMessage("Verify email"),
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Verify password"),
        "verifyingRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Verifying recovery key..."),
        "viewRecoveryKey":
            MessageLookupByLibrary.simpleMessage("View recovery key"),
        "viewer": MessageLookupByLibrary.simpleMessage("Viewer"),
        "weakStrength": MessageLookupByLibrary.simpleMessage("Weak"),
        "welcomeBack": MessageLookupByLibrary.simpleMessage("Welcome back!"),
        "weveSentAMailTo":
            MessageLookupByLibrary.simpleMessage("We\'ve sent a mail to"),
        "yesConvertToViewer":
            MessageLookupByLibrary.simpleMessage("Yes, convert to viewer"),
        "you": MessageLookupByLibrary.simpleMessage("You"),
        "yourAccountHasBeenDeleted": MessageLookupByLibrary.simpleMessage(
            "Your account has been deleted")
      };
}
