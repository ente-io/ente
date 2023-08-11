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

  static String m0(count) =>
      "${Intl.plural(count, one: 'Add item', other: 'Add items')}";

  static String m1(emailOrName) => "Added by ${emailOrName}";

  static String m2(albumName) => "Added successfully to  ${albumName}";

  static String m3(count) =>
      "${Intl.plural(count, zero: 'No Participants', one: '1 Participant', other: '${count} Participants')}";

  static String m4(versionValue) => "Version: ${versionValue}";

  static String m5(paymentProvider) =>
      "Please cancel your existing subscription from ${paymentProvider} first";

  static String m6(user) =>
      "${user} will not be able to add more photos to this album\n\nThey will still be able to remove existing photos added by them";

  static String m7(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true': 'Your family has claimed ${storageAmountInGb} GB so far',
            'false': 'You have claimed ${storageAmountInGb} GB so far',
            'other': 'You have claimed ${storageAmountInGb} GB so far!',
          })}";

  static String m8(albumName) => "Collaborative link created for ${albumName}";

  static String m9(familyAdminEmail) =>
      "Please contact <green>${familyAdminEmail}</green> to manage your subscription";

  static String m10(provider) =>
      "Please contact us at support@ente.io to manage your ${provider} subscription.";

  static String m62(count) =>
      "${Intl.plural(count, one: 'Delete ${count} item', other: 'Delete ${count} items')}";

  static String m11(currentlyDeleting, totalCount) =>
      "Deleting ${currentlyDeleting} / ${totalCount}";

  static String m12(albumName) =>
      "This will remove the public link for accessing \"${albumName}\".";

  static String m13(supportEmail) =>
      "Please drop an email to ${supportEmail} from your registered email address";

  static String m14(count, storageSaved) =>
      "Your have cleaned up ${Intl.plural(count, one: '${count} duplicate file', other: '${count} duplicate files')}, saving (${storageSaved}!)";

  static String m63(count, formattedSize) =>
      "${count} files, ${formattedSize} each";

  static String m15(newEmail) => "Email changed to ${newEmail}";

  static String m16(email) =>
      "${email} does not have an ente account.\n\nSend them an invite to share photos.";

  static String m17(count, formattedNumber) =>
      "${Intl.plural(count, one: '1 file', other: '${formattedNumber} files')} on this device have been backed up safely";

  static String m18(count, formattedNumber) =>
      "${Intl.plural(count, one: '1 file', other: '${formattedNumber} files')} in this album has been backed up safely";

  static String m19(storageAmountInGB) =>
      "${storageAmountInGB} GB each time someone signs up for a paid plan and applies your code";

  static String m20(freeAmount, storageUnit) =>
      "${freeAmount} ${storageUnit} free";

  static String m21(endDate) => "Free trial valid till ${endDate}";

  static String m22(count) =>
      "You can still access ${Intl.plural(count, one: 'it', other: 'them')} on ente as long as you have an active subscription";

  static String m23(sizeInMBorGB) => "Free up ${sizeInMBorGB}";

  static String m24(count, formattedSize) =>
      "${Intl.plural(count, one: 'It can be deleted from the device to free up ${formattedSize}', other: 'They can be deleted from the device to free up ${formattedSize}')}";

  static String m25(count) =>
      "${Intl.plural(count, one: '${count} item', other: '${count} items')}";

  static String m26(expiryTime) => "Link will expire on ${expiryTime}";

  static String m27(maxValue) =>
      "When set to the maximum (${maxValue}), the device limit will be relaxed to allow for temporary spikes of large number of viewers.";

  static String m28(count, formattedCount) =>
      "${Intl.plural(count, zero: 'no memories', one: '${formattedCount} memory', other: '${formattedCount} memories')}";

  static String m29(count) =>
      "${Intl.plural(count, one: 'Move item', other: 'Move items')}";

  static String m30(albumName) => "Moved successfully to ${albumName}";

  static String m31(passwordStrengthValue) =>
      "Password strength: ${passwordStrengthValue}";

  static String m32(providerName) =>
      "Please talk to ${providerName} support if you were charged";

  static String m33(reason) =>
      "Unfortunately your payment failed due to ${reason}";

  static String m64(endDate) =>
      "Free trial valid till ${endDate}.\nYou can choose a paid plan afterwards.";

  static String m34(toEmail) => "Please email us at ${toEmail}";

  static String m35(toEmail) => "Please send the logs to \n${toEmail}";

  static String m36(storeName) => "Rate us on ${storeName}";

  static String m37(storageInGB) =>
      "3. Both of you get ${storageInGB} GB* free";

  static String m38(userEmail) =>
      "${userEmail} will be removed from this shared album\n\nAny photos added by them will also be removed from the album";

  static String m39(endDate) => "Renews on ${endDate}";

  static String m40(count) => "${count} selected";

  static String m41(count, yourCount) =>
      "${count} selected (${yourCount} yours)";

  static String m42(verificationID) =>
      "Here\'s my verification ID: ${verificationID} for ente.io.";

  static String m43(verificationID) =>
      "Hey, can you confirm that this is your ente.io verification ID: ${verificationID}";

  static String m44(referralCode, referralStorageInGB) =>
      "ente referral code: ${referralCode} \n\nApply it in Settings → General → Referrals to get ${referralStorageInGB} GB free after you signup for a paid plan\n\nhttps://ente.io";

  static String m45(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Share with specific people', one: 'Shared with 1 person', other: 'Shared with ${numberOfPeople} people')}";

  static String m46(emailIDs) => "Shared with ${emailIDs}";

  static String m47(fileType) =>
      "This ${fileType} will be deleted from your device.";

  static String m48(fileType) =>
      "This ${fileType} is in both ente and your device.";

  static String m49(fileType) => "This ${fileType} will be deleted from ente.";

  static String m50(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m51(
          usedAmount, usedStorageUnit, totalAmount, totalStorageUnit) =>
      "${usedAmount} ${usedStorageUnit} of ${totalAmount} ${totalStorageUnit} used";

  static String m52(id) =>
      "Your ${id} is already linked to another ente account.\nIf you would like to use your ${id} with this account, please contact our support\'\'";

  static String m53(endDate) =>
      "Your subscription will be cancelled on ${endDate}";

  static String m54(completed, total) =>
      "${completed}/${total} memories preserved";

  static String m55(storageAmountInGB) =>
      "They also get ${storageAmountInGB} GB";

  static String m56(email) => "This is ${email}\'s Verification ID";

  static String m57(count) =>
      "${Intl.plural(count, zero: '', one: '1 day', other: '${count} days')}";

  static String m58(email) => "Verify ${email}";

  static String m59(email) => "We have sent a mail to <green>${email}</green>";

  static String m60(count) =>
      "${Intl.plural(count, one: '${count} year ago', other: '${count} years ago')}";

  static String m61(storageSaved) =>
      "You have successfully freed up ${storageSaved}!";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aNewVersionOfEnteIsAvailable": MessageLookupByLibrary.simpleMessage(
            "A new version of ente is available."),
        "about": MessageLookupByLibrary.simpleMessage("About"),
        "account": MessageLookupByLibrary.simpleMessage("Account"),
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("Welcome back!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "I understand that if I lose my password, I may lose my data since my data is <underline>end-to-end encrypted</underline>."),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Active sessions"),
        "addANewEmail": MessageLookupByLibrary.simpleMessage("Add a new email"),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("Add collaborator"),
        "addFromDevice":
            MessageLookupByLibrary.simpleMessage("Add from device"),
        "addItem": m0,
        "addLocation": MessageLookupByLibrary.simpleMessage("Add location"),
        "addLocationButton": MessageLookupByLibrary.simpleMessage("Add"),
        "addMore": MessageLookupByLibrary.simpleMessage("Add more"),
        "addPhotos": MessageLookupByLibrary.simpleMessage("Add photos"),
        "addSelected": MessageLookupByLibrary.simpleMessage("Add selected"),
        "addToAlbum": MessageLookupByLibrary.simpleMessage("Add to album"),
        "addToEnte": MessageLookupByLibrary.simpleMessage("Add to ente"),
        "addViewer": MessageLookupByLibrary.simpleMessage("Add viewer"),
        "addedAs": MessageLookupByLibrary.simpleMessage("Added as"),
        "addedBy": m1,
        "addedSuccessfullyTo": m2,
        "addingToFavorites":
            MessageLookupByLibrary.simpleMessage("Adding to favorites..."),
        "advanced": MessageLookupByLibrary.simpleMessage("Advanced"),
        "advancedSettings": MessageLookupByLibrary.simpleMessage("Advanced"),
        "after1Day": MessageLookupByLibrary.simpleMessage("After 1 day"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("After 1 hour"),
        "after1Month": MessageLookupByLibrary.simpleMessage("After 1 month"),
        "after1Week": MessageLookupByLibrary.simpleMessage("After 1 week"),
        "after1Year": MessageLookupByLibrary.simpleMessage("After 1 year"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("Owner"),
        "albumParticipantsCount": m3,
        "albumTitle": MessageLookupByLibrary.simpleMessage("Album title"),
        "albumUpdated": MessageLookupByLibrary.simpleMessage("Album updated"),
        "albums": MessageLookupByLibrary.simpleMessage("Albums"),
        "allClear": MessageLookupByLibrary.simpleMessage("✨ All clear"),
        "allMemoriesPreserved":
            MessageLookupByLibrary.simpleMessage("All memories preserved"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Allow people with the link to also add photos to the shared album."),
        "allowAddingPhotos":
            MessageLookupByLibrary.simpleMessage("Allow adding photos"),
        "allowDownloads":
            MessageLookupByLibrary.simpleMessage("Allow downloads"),
        "allowPeopleToAddPhotos":
            MessageLookupByLibrary.simpleMessage("Allow people to add photos"),
        "androidBiometricHint":
            MessageLookupByLibrary.simpleMessage("Verify identity"),
        "androidBiometricNotRecognized":
            MessageLookupByLibrary.simpleMessage("Not recognized. Try again."),
        "androidBiometricRequiredTitle":
            MessageLookupByLibrary.simpleMessage("Biometric required"),
        "androidBiometricSuccess":
            MessageLookupByLibrary.simpleMessage("Success"),
        "androidCancelButton": MessageLookupByLibrary.simpleMessage("Cancel"),
        "androidDeviceCredentialsRequiredTitle":
            MessageLookupByLibrary.simpleMessage("Device credentials required"),
        "androidDeviceCredentialsSetupDescription":
            MessageLookupByLibrary.simpleMessage("Device credentials required"),
        "androidGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "Biometric authentication is not set up on your device. Go to \'Settings > Security\' to add biometric authentication."),
        "androidIosWebDesktop":
            MessageLookupByLibrary.simpleMessage("Android, iOS, Web, Desktop"),
        "androidSignInTitle":
            MessageLookupByLibrary.simpleMessage("Authentication required"),
        "appVersion": m4,
        "appleId": MessageLookupByLibrary.simpleMessage("Apple ID"),
        "apply": MessageLookupByLibrary.simpleMessage("Apply"),
        "applyCodeTitle": MessageLookupByLibrary.simpleMessage("Apply code"),
        "appstoreSubscription":
            MessageLookupByLibrary.simpleMessage("AppStore subscription"),
        "archive": MessageLookupByLibrary.simpleMessage("Archive"),
        "archiveAlbum": MessageLookupByLibrary.simpleMessage("Archive album"),
        "archiving": MessageLookupByLibrary.simpleMessage("Archiving..."),
        "areYouSureThatYouWantToLeaveTheFamily":
            MessageLookupByLibrary.simpleMessage(
                "Are you sure that you want to leave the family plan?"),
        "areYouSureYouWantToCancel": MessageLookupByLibrary.simpleMessage(
            "Are you sure you want to cancel?"),
        "areYouSureYouWantToChangeYourPlan":
            MessageLookupByLibrary.simpleMessage(
                "Are you sure you want to change your plan?"),
        "areYouSureYouWantToExit": MessageLookupByLibrary.simpleMessage(
            "Are you sure you want to exit?"),
        "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
            "Are you sure you want to logout?"),
        "areYouSureYouWantToRenew": MessageLookupByLibrary.simpleMessage(
            "Are you sure you want to renew?"),
        "askCancelReason": MessageLookupByLibrary.simpleMessage(
            "Your subscription was cancelled. Would you like to share the reason?"),
        "askDeleteReason": MessageLookupByLibrary.simpleMessage(
            "What is the main reason you are deleting your account?"),
        "askYourLovedOnesToShare": MessageLookupByLibrary.simpleMessage(
            "Ask your loved ones to share"),
        "atAFalloutShelter":
            MessageLookupByLibrary.simpleMessage("at a fallout shelter"),
        "authToChangeEmailVerificationSetting":
            MessageLookupByLibrary.simpleMessage(
                "Please authenticate to change email verification"),
        "authToChangeLockscreenSetting": MessageLookupByLibrary.simpleMessage(
            "Please authenticate to change lockscreen setting"),
        "authToChangeYourEmail": MessageLookupByLibrary.simpleMessage(
            "Please authenticate to change your email"),
        "authToChangeYourPassword": MessageLookupByLibrary.simpleMessage(
            "Please authenticate to change your password"),
        "authToConfigureTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Please authenticate to configure two-factor authentication"),
        "authToInitiateAccountDeletion": MessageLookupByLibrary.simpleMessage(
            "Please authenticate to initiate account deletion"),
        "authToViewYourActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Please authenticate to view your active sessions"),
        "authToViewYourHiddenFiles": MessageLookupByLibrary.simpleMessage(
            "Please authenticate to view your hidden files"),
        "authToViewYourMemories": MessageLookupByLibrary.simpleMessage(
            "Please authenticate to view your memories"),
        "authToViewYourRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "Please authenticate to view your recovery key"),
        "authenticating":
            MessageLookupByLibrary.simpleMessage("Authenticating..."),
        "authenticationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Authentication failed, please try again"),
        "authenticationSuccessful":
            MessageLookupByLibrary.simpleMessage("Authentication successful!"),
        "available": MessageLookupByLibrary.simpleMessage("Available"),
        "backedUpFolders":
            MessageLookupByLibrary.simpleMessage("Backed up folders"),
        "backup": MessageLookupByLibrary.simpleMessage("Backup"),
        "backupFailed": MessageLookupByLibrary.simpleMessage("Backup failed"),
        "backupOverMobileData":
            MessageLookupByLibrary.simpleMessage("Backup over mobile data"),
        "backupSettings":
            MessageLookupByLibrary.simpleMessage("Backup settings"),
        "backupVideos": MessageLookupByLibrary.simpleMessage("Backup videos"),
        "blog": MessageLookupByLibrary.simpleMessage("Blog"),
        "cachedData": MessageLookupByLibrary.simpleMessage("Cached data"),
        "calculating": MessageLookupByLibrary.simpleMessage("Calculating..."),
        "canNotUploadToAlbumsOwnedByOthers":
            MessageLookupByLibrary.simpleMessage(
                "Can not upload to albums owned by others"),
        "canOnlyCreateLinkForFilesOwnedByYou":
            MessageLookupByLibrary.simpleMessage(
                "Can only create link for files owned by you"),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
            "Can only remove files owned by you"),
        "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
        "cancelOtherSubscription": m5,
        "cancelSubscription":
            MessageLookupByLibrary.simpleMessage("Cancel subscription"),
        "cannotAddMorePhotosAfterBecomingViewer": m6,
        "centerPoint": MessageLookupByLibrary.simpleMessage("Center point"),
        "changeEmail": MessageLookupByLibrary.simpleMessage("Change email"),
        "changePassword":
            MessageLookupByLibrary.simpleMessage("Change password"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Change password"),
        "changePermissions":
            MessageLookupByLibrary.simpleMessage("Change permissions?"),
        "checkForUpdates":
            MessageLookupByLibrary.simpleMessage("Check for updates"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Please check your inbox (and spam) to complete verification"),
        "checking": MessageLookupByLibrary.simpleMessage("Checking..."),
        "claimFreeStorage":
            MessageLookupByLibrary.simpleMessage("Claim free storage"),
        "claimMore": MessageLookupByLibrary.simpleMessage("Claim more!"),
        "claimed": MessageLookupByLibrary.simpleMessage("Claimed"),
        "claimedStorageSoFar": m7,
        "clearCaches": MessageLookupByLibrary.simpleMessage("Clear caches"),
        "click": MessageLookupByLibrary.simpleMessage("• Click"),
        "clickOnTheOverflowMenu": MessageLookupByLibrary.simpleMessage(
            "• Click on the overflow menu"),
        "close": MessageLookupByLibrary.simpleMessage("Close"),
        "clubByCaptureTime":
            MessageLookupByLibrary.simpleMessage("Club by capture time"),
        "clubByFileName":
            MessageLookupByLibrary.simpleMessage("Club by file name"),
        "codeAppliedPageTitle":
            MessageLookupByLibrary.simpleMessage("Code applied"),
        "codeCopiedToClipboard":
            MessageLookupByLibrary.simpleMessage("Code copied to clipboard"),
        "codeUsedByYou":
            MessageLookupByLibrary.simpleMessage("Code used by you"),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Create a link to allow people to add and view photos in your shared album without needing an ente app or account. Great for collecting event photos."),
        "collaborativeLink":
            MessageLookupByLibrary.simpleMessage("Collaborative link"),
        "collaborativeLinkCreatedFor": m8,
        "collaborator": MessageLookupByLibrary.simpleMessage("Collaborator"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Collaborators can add photos and videos to the shared album."),
        "collageLayout": MessageLookupByLibrary.simpleMessage("Layout"),
        "collageSaved":
            MessageLookupByLibrary.simpleMessage("Collage saved to gallery"),
        "collectEventPhotos":
            MessageLookupByLibrary.simpleMessage("Collect event photos"),
        "collectPhotos": MessageLookupByLibrary.simpleMessage("Collect photos"),
        "color": MessageLookupByLibrary.simpleMessage("Color"),
        "confirm": MessageLookupByLibrary.simpleMessage("Confirm"),
        "confirm2FADisable": MessageLookupByLibrary.simpleMessage(
            "Are you sure you want to disable two-factor authentication?"),
        "confirmAccountDeletion":
            MessageLookupByLibrary.simpleMessage("Confirm Account Deletion"),
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "Yes, I want to permanently delete this account and all its data."),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Confirm password"),
        "confirmPlanChange":
            MessageLookupByLibrary.simpleMessage("Confirm plan change"),
        "confirmRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Confirm recovery key"),
        "confirmYourRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Confirm your recovery key"),
        "contactFamilyAdmin": m9,
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("Contact support"),
        "contactToManageSubscription": m10,
        "continueLabel": MessageLookupByLibrary.simpleMessage("Continue"),
        "continueOnFreeTrial":
            MessageLookupByLibrary.simpleMessage("Continue on free trial"),
        "convertToAlbum":
            MessageLookupByLibrary.simpleMessage("Convert to album"),
        "copyEmailAddress":
            MessageLookupByLibrary.simpleMessage("Copy email address"),
        "copyLink": MessageLookupByLibrary.simpleMessage("Copy link"),
        "copypasteThisCodentoYourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Copy-paste this code\nto your authenticator app"),
        "couldNotBackUpTryLater": MessageLookupByLibrary.simpleMessage(
            "We could not backup your data.\nWe will retry later."),
        "couldNotFreeUpSpace":
            MessageLookupByLibrary.simpleMessage("Could not free up space"),
        "couldNotUpdateSubscription": MessageLookupByLibrary.simpleMessage(
            "Could not update subscription"),
        "count": MessageLookupByLibrary.simpleMessage("Count"),
        "crashReporting":
            MessageLookupByLibrary.simpleMessage("Crash reporting"),
        "create": MessageLookupByLibrary.simpleMessage("Create"),
        "createAccount": MessageLookupByLibrary.simpleMessage("Create account"),
        "createAlbumActionHint": MessageLookupByLibrary.simpleMessage(
            "Long press to select photos and click + to create an album"),
        "createCollage": MessageLookupByLibrary.simpleMessage("Create collage"),
        "createNewAccount":
            MessageLookupByLibrary.simpleMessage("Create new account"),
        "createOrSelectAlbum":
            MessageLookupByLibrary.simpleMessage("Create or select album"),
        "createPublicLink":
            MessageLookupByLibrary.simpleMessage("Create public link"),
        "creatingLink":
            MessageLookupByLibrary.simpleMessage("Creating link..."),
        "criticalUpdateAvailable":
            MessageLookupByLibrary.simpleMessage("Critical update available"),
        "currentUsageIs":
            MessageLookupByLibrary.simpleMessage("Current usage is "),
        "custom": MessageLookupByLibrary.simpleMessage("Custom"),
        "darkTheme": MessageLookupByLibrary.simpleMessage("Dark"),
        "dayToday": MessageLookupByLibrary.simpleMessage("Today"),
        "dayYesterday": MessageLookupByLibrary.simpleMessage("Yesterday"),
        "decrypting": MessageLookupByLibrary.simpleMessage("Decrypting..."),
        "decryptingVideo":
            MessageLookupByLibrary.simpleMessage("Decrypting video..."),
        "deduplicateFiles":
            MessageLookupByLibrary.simpleMessage("Deduplicate Files"),
        "delete": MessageLookupByLibrary.simpleMessage("Delete"),
        "deleteAccount": MessageLookupByLibrary.simpleMessage("Delete account"),
        "deleteAccountFeedbackPrompt": MessageLookupByLibrary.simpleMessage(
            "We are sorry to see you go. Please share your feedback to help us improve."),
        "deleteAccountPermanentlyButton":
            MessageLookupByLibrary.simpleMessage("Delete Account Permanently"),
        "deleteAlbum": MessageLookupByLibrary.simpleMessage("Delete album"),
        "deleteAlbumDialog": MessageLookupByLibrary.simpleMessage(
            "Also delete the photos (and videos) present in this album from <bold>all</bold> other albums they are part of?"),
        "deleteAlbumsDialogBody": MessageLookupByLibrary.simpleMessage(
            "This will delete all empty albums. This is useful when you want to reduce the clutter in your album list."),
        "deleteAll": MessageLookupByLibrary.simpleMessage("Delete All"),
        "deleteConfirmDialogBody": MessageLookupByLibrary.simpleMessage(
            "You are about to permanently delete your account and all its data.\nThis action is irreversible."),
        "deleteEmailRequest": MessageLookupByLibrary.simpleMessage(
            "Please send an email to <warning>account-deletion@ente.io</warning> from your registered email address."),
        "deleteEmptyAlbums":
            MessageLookupByLibrary.simpleMessage("Delete empty albums"),
        "deleteEmptyAlbumsWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Delete empty albums?"),
        "deleteFromBoth":
            MessageLookupByLibrary.simpleMessage("Delete from both"),
        "deleteFromDevice":
            MessageLookupByLibrary.simpleMessage("Delete from device"),
        "deleteFromEnte":
            MessageLookupByLibrary.simpleMessage("Delete from ente"),
        "deleteItemCount": m62,
        "deleteLocation":
            MessageLookupByLibrary.simpleMessage("Delete location"),
        "deletePhotos": MessageLookupByLibrary.simpleMessage("Delete photos"),
        "deleteProgress": m11,
        "deleteReason1": MessageLookupByLibrary.simpleMessage(
            "It’s missing a key feature that I need"),
        "deleteReason2": MessageLookupByLibrary.simpleMessage(
            "The app or a certain feature does not behave as I think it should"),
        "deleteReason3": MessageLookupByLibrary.simpleMessage(
            "I found another service that I like better"),
        "deleteReason4":
            MessageLookupByLibrary.simpleMessage("My reason isn’t listed"),
        "deleteRequestSLAText": MessageLookupByLibrary.simpleMessage(
            "Your request will be processed within 72 hours."),
        "deleteSharedAlbum":
            MessageLookupByLibrary.simpleMessage("Delete shared album?"),
        "deleteSharedAlbumDialogBody": MessageLookupByLibrary.simpleMessage(
            "The album will be deleted for everyone\n\nYou will lose access to shared photos in this album that are owned by others"),
        "deselectAll": MessageLookupByLibrary.simpleMessage("Deselect all"),
        "designedToOutlive":
            MessageLookupByLibrary.simpleMessage("Designed to outlive"),
        "details": MessageLookupByLibrary.simpleMessage("Details"),
        "devAccountChanged": MessageLookupByLibrary.simpleMessage(
            "The developer account we use to publish ente on App Store has changed. Because of this, you will need to login again.\n\nOur apologies for the inconvenience, but this was unavoidable."),
        "deviceFilesAutoUploading": MessageLookupByLibrary.simpleMessage(
            "Files added to this device album will automatically get uploaded to ente."),
        "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
            "Disable the device screen lock when ente is in the foreground and there is a backup in progress. This is normally not needed, but may help big uploads and initial imports of large libraries complete faster."),
        "didYouKnow": MessageLookupByLibrary.simpleMessage("Did you know?"),
        "disableAutoLock":
            MessageLookupByLibrary.simpleMessage("Disable auto lock"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "Viewers can still take screenshots or save a copy of your photos using external tools"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Please note"),
        "disableLinkMessage": m12,
        "disableTwofactor":
            MessageLookupByLibrary.simpleMessage("Disable two-factor"),
        "disablingTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Disabling two-factor authentication..."),
        "discord": MessageLookupByLibrary.simpleMessage("Discord"),
        "dismiss": MessageLookupByLibrary.simpleMessage("Dismiss"),
        "distanceInKMUnit": MessageLookupByLibrary.simpleMessage("km"),
        "doThisLater": MessageLookupByLibrary.simpleMessage("Do this later"),
        "doYouWantToDiscardTheEditsYouHaveMade":
            MessageLookupByLibrary.simpleMessage(
                "Do you want to discard the edits you have made?"),
        "done": MessageLookupByLibrary.simpleMessage("Done"),
        "doubleYourStorage":
            MessageLookupByLibrary.simpleMessage("Double your storage"),
        "download": MessageLookupByLibrary.simpleMessage("Download"),
        "downloadFailed":
            MessageLookupByLibrary.simpleMessage("Download failed"),
        "downloading": MessageLookupByLibrary.simpleMessage("Downloading..."),
        "dropSupportEmail": m13,
        "duplicateFileCountWithStorageSaved": m14,
        "duplicateItemsGroup": m63,
        "edit": MessageLookupByLibrary.simpleMessage("Edit"),
        "editLocationTagTitle":
            MessageLookupByLibrary.simpleMessage("Edit location"),
        "editsSaved": MessageLookupByLibrary.simpleMessage("Edits saved"),
        "eligible": MessageLookupByLibrary.simpleMessage("eligible"),
        "email": MessageLookupByLibrary.simpleMessage("Email"),
        "emailChangedTo": m15,
        "emailNoEnteAccount": m16,
        "emailVerificationToggle":
            MessageLookupByLibrary.simpleMessage("Email verification"),
        "emailYourLogs":
            MessageLookupByLibrary.simpleMessage("Email your logs"),
        "empty": MessageLookupByLibrary.simpleMessage("Empty"),
        "emptyTrash": MessageLookupByLibrary.simpleMessage("Empty trash?"),
        "enableMaps": MessageLookupByLibrary.simpleMessage("Enable Maps"),
        "enableMapsDesc": MessageLookupByLibrary.simpleMessage(
            "This will show your photos on a world map.\n\nThis map is hosted by Open Street Map, and the exact locations of your photos are never shared.\n\nYou can disable this feature anytime from Settings."),
        "encryptingBackup":
            MessageLookupByLibrary.simpleMessage("Encrypting backup..."),
        "encryption": MessageLookupByLibrary.simpleMessage("Encryption"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Encryption keys"),
        "endtoendEncryptedByDefault": MessageLookupByLibrary.simpleMessage(
            "End-to-end encrypted by default"),
        "enteCanEncryptAndPreserveFilesOnlyIfYouGrant":
            MessageLookupByLibrary.simpleMessage(
                "ente can encrypt and preserve files only if you grant access to them"),
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
            "ente <i>needs permission to</i> preserve your photos"),
        "enteSubscriptionPitch": MessageLookupByLibrary.simpleMessage(
            "ente preserves your memories, so they\'re always available to you, even if you lose your device."),
        "enteSubscriptionShareWithFamily": MessageLookupByLibrary.simpleMessage(
            "Your family can be added to your plan as well."),
        "enterAlbumName":
            MessageLookupByLibrary.simpleMessage("Enter album name"),
        "enterCode": MessageLookupByLibrary.simpleMessage("Enter code"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
            "Enter the code provided by your friend to claim free storage for both of you"),
        "enterEmail": MessageLookupByLibrary.simpleMessage("Enter email"),
        "enterFileName":
            MessageLookupByLibrary.simpleMessage("Enter file name"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Enter a new password we can use to encrypt your data"),
        "enterPassword": MessageLookupByLibrary.simpleMessage("Enter password"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Enter a password we can use to encrypt your data"),
        "enterReferralCode":
            MessageLookupByLibrary.simpleMessage("Enter referral code"),
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
        "error": MessageLookupByLibrary.simpleMessage("Error"),
        "everywhere": MessageLookupByLibrary.simpleMessage("everywhere"),
        "exif": MessageLookupByLibrary.simpleMessage("EXIF"),
        "existingUser": MessageLookupByLibrary.simpleMessage("Existing user"),
        "expiredLinkInfo": MessageLookupByLibrary.simpleMessage(
            "This link has expired. Please select a new expiry time or disable link expiry."),
        "exportLogs": MessageLookupByLibrary.simpleMessage("Export logs"),
        "exportYourData":
            MessageLookupByLibrary.simpleMessage("Export your data"),
        "failedToApplyCode":
            MessageLookupByLibrary.simpleMessage("Failed to apply code"),
        "failedToCancel":
            MessageLookupByLibrary.simpleMessage("Failed to cancel"),
        "failedToDownloadVideo":
            MessageLookupByLibrary.simpleMessage("Failed to download video"),
        "failedToFetchOriginalForEdit": MessageLookupByLibrary.simpleMessage(
            "Failed to fetch original for edit"),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
            "Unable to fetch referral details. Please try again later."),
        "failedToLoadAlbums":
            MessageLookupByLibrary.simpleMessage("Failed to load albums"),
        "failedToRenew":
            MessageLookupByLibrary.simpleMessage("Failed to renew"),
        "failedToVerifyPaymentStatus": MessageLookupByLibrary.simpleMessage(
            "Failed to verify payment status"),
        "familyPlanOverview": MessageLookupByLibrary.simpleMessage(
            "Add 5 family members to your existing plan without paying extra.\n\nEach member gets their own private space, and cannot see each other\'s files unless they\'re shared.\n\nFamily plans are available to customers who have a paid ente subscription.\n\nSubscribe now to get started!"),
        "familyPlanPortalTitle": MessageLookupByLibrary.simpleMessage("Family"),
        "familyPlans": MessageLookupByLibrary.simpleMessage("Family plans"),
        "faq": MessageLookupByLibrary.simpleMessage("FAQ"),
        "faqs": MessageLookupByLibrary.simpleMessage("FAQs"),
        "favorite": MessageLookupByLibrary.simpleMessage("Favorite"),
        "feedback": MessageLookupByLibrary.simpleMessage("Feedback"),
        "fileFailedToSaveToGallery": MessageLookupByLibrary.simpleMessage(
            "Failed to save file to gallery"),
        "fileInfoAddDescHint":
            MessageLookupByLibrary.simpleMessage("Add a description..."),
        "fileSavedToGallery":
            MessageLookupByLibrary.simpleMessage("File saved to gallery"),
        "filesBackedUpFromDevice": m17,
        "filesBackedUpInAlbum": m18,
        "filesDeleted": MessageLookupByLibrary.simpleMessage("Files deleted"),
        "flip": MessageLookupByLibrary.simpleMessage("Flip"),
        "forYourMemories":
            MessageLookupByLibrary.simpleMessage("for your memories"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Forgot password"),
        "freeStorageClaimed":
            MessageLookupByLibrary.simpleMessage("Free storage claimed"),
        "freeStorageOnReferralSuccess": m19,
        "freeStorageSpace": m20,
        "freeStorageUsable":
            MessageLookupByLibrary.simpleMessage("Free storage usable"),
        "freeTrial": MessageLookupByLibrary.simpleMessage("Free trial"),
        "freeTrialValidTill": m21,
        "freeUpAccessPostDelete": m22,
        "freeUpAmount": m23,
        "freeUpDeviceSpace":
            MessageLookupByLibrary.simpleMessage("Free up device space"),
        "freeUpSpace": MessageLookupByLibrary.simpleMessage("Free up space"),
        "freeUpSpaceSaving": m24,
        "galleryMemoryLimitInfo": MessageLookupByLibrary.simpleMessage(
            "Up to 1000 memories shown in gallery"),
        "general": MessageLookupByLibrary.simpleMessage("General"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Generating encryption keys..."),
        "goToSettings": MessageLookupByLibrary.simpleMessage("Go to settings"),
        "googlePlayId": MessageLookupByLibrary.simpleMessage("Google Play ID"),
        "grantPermission":
            MessageLookupByLibrary.simpleMessage("Grant permission"),
        "groupNearbyPhotos":
            MessageLookupByLibrary.simpleMessage("Group nearby photos"),
        "hidden": MessageLookupByLibrary.simpleMessage("Hidden"),
        "hide": MessageLookupByLibrary.simpleMessage("Hide"),
        "hostedAtOsmFrance":
            MessageLookupByLibrary.simpleMessage("Hosted at OSM France"),
        "howItWorks": MessageLookupByLibrary.simpleMessage("How it works"),
        "howToViewShareeVerificationID": MessageLookupByLibrary.simpleMessage(
            "Please ask them to long-press their email address on the settings screen, and verify that the IDs on both devices match."),
        "iOSGoToSettingsDescription": MessageLookupByLibrary.simpleMessage(
            "Biometric authentication is not set up on your device. Please either enable Touch ID or Face ID on your phone."),
        "iOSLockOut": MessageLookupByLibrary.simpleMessage(
            "Biometric authentication is disabled. Please lock and unlock your screen to enable it."),
        "iOSOkButton": MessageLookupByLibrary.simpleMessage("OK"),
        "ignoreUpdate": MessageLookupByLibrary.simpleMessage("Ignore"),
        "ignoredFolderUploadReason": MessageLookupByLibrary.simpleMessage(
            "Some files in this album are ignored from upload because they had previously been deleted from ente."),
        "importing": MessageLookupByLibrary.simpleMessage("Importing...."),
        "incorrectCode": MessageLookupByLibrary.simpleMessage("Incorrect code"),
        "incorrectPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Incorrect password"),
        "incorrectRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Incorrect recovery key"),
        "incorrectRecoveryKeyBody": MessageLookupByLibrary.simpleMessage(
            "The recovery key you entered is incorrect"),
        "incorrectRecoveryKeyTitle":
            MessageLookupByLibrary.simpleMessage("Incorrect recovery key"),
        "insecureDevice":
            MessageLookupByLibrary.simpleMessage("Insecure device"),
        "installManually":
            MessageLookupByLibrary.simpleMessage("Install manually"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("Invalid email address"),
        "invalidKey": MessageLookupByLibrary.simpleMessage("Invalid key"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "The recovery key you entered is not valid. Please make sure it contains 24 words, and check the spelling of each.\n\nIf you entered an older recovery code, make sure it is 64 characters long, and check each of them."),
        "invite": MessageLookupByLibrary.simpleMessage("Invite"),
        "inviteToEnte": MessageLookupByLibrary.simpleMessage("Invite to ente"),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("Invite your friends"),
        "inviteYourFriendsToEnte":
            MessageLookupByLibrary.simpleMessage("Invite your friends to ente"),
        "itLooksLikeSomethingWentWrongPleaseRetryAfterSome":
            MessageLookupByLibrary.simpleMessage(
                "It looks like something went wrong. Please retry after some time. If the error persists, please contact our support team."),
        "itemCount": m25,
        "itemsShowTheNumberOfDaysRemainingBeforePermanentDeletion":
            MessageLookupByLibrary.simpleMessage(
                "Items show the number of days remaining before permanent deletion"),
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
            "Selected items will be removed from this album"),
        "keepPhotos": MessageLookupByLibrary.simpleMessage("Keep Photos"),
        "kiloMeterUnit": MessageLookupByLibrary.simpleMessage("km"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "Kindly help us with this information"),
        "language": MessageLookupByLibrary.simpleMessage("Language"),
        "lastUpdated": MessageLookupByLibrary.simpleMessage("Last updated"),
        "leave": MessageLookupByLibrary.simpleMessage("Leave"),
        "leaveAlbum": MessageLookupByLibrary.simpleMessage("Leave album"),
        "leaveFamily": MessageLookupByLibrary.simpleMessage("Leave family"),
        "leaveSharedAlbum":
            MessageLookupByLibrary.simpleMessage("Leave shared album?"),
        "light": MessageLookupByLibrary.simpleMessage("Light"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("Light"),
        "linkCopiedToClipboard":
            MessageLookupByLibrary.simpleMessage("Link copied to clipboard"),
        "linkDeviceLimit": MessageLookupByLibrary.simpleMessage("Device limit"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Enabled"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Expired"),
        "linkExpiresOn": m26,
        "linkExpiry": MessageLookupByLibrary.simpleMessage("Link expiry"),
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("Link has expired"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Never"),
        "loadMessage1": MessageLookupByLibrary.simpleMessage(
            "You can share your subscription with your family"),
        "loadMessage2": MessageLookupByLibrary.simpleMessage(
            "We have preserved over 10 million memories so far"),
        "loadMessage3": MessageLookupByLibrary.simpleMessage(
            "We keep 3 copies of your data, one in an underground fallout shelter"),
        "loadMessage4": MessageLookupByLibrary.simpleMessage(
            "All our apps are open source"),
        "loadMessage5": MessageLookupByLibrary.simpleMessage(
            "Our source code and cryptography have been externally audited"),
        "loadMessage6": MessageLookupByLibrary.simpleMessage(
            "You can share links to your albums with your loved ones"),
        "loadMessage7": MessageLookupByLibrary.simpleMessage(
            "Our mobile apps run in the background to encrypt and backup any new photos you click"),
        "loadMessage8": MessageLookupByLibrary.simpleMessage(
            "web.ente.io has a slick uploader"),
        "loadMessage9": MessageLookupByLibrary.simpleMessage(
            "We use Xchacha20Poly1305 to safely encrypt your data"),
        "loadingExifData":
            MessageLookupByLibrary.simpleMessage("Loading EXIF data..."),
        "loadingGallery":
            MessageLookupByLibrary.simpleMessage("Loading gallery..."),
        "loadingMessage":
            MessageLookupByLibrary.simpleMessage("Loading your photos..."),
        "localGallery": MessageLookupByLibrary.simpleMessage("Local gallery"),
        "location": MessageLookupByLibrary.simpleMessage("Location"),
        "locationName": MessageLookupByLibrary.simpleMessage("Location name"),
        "locationTagFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "A location tag groups all photos that were taken within some radius of a photo"),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Lock"),
        "lockScreenEnablePreSteps": MessageLookupByLibrary.simpleMessage(
            "To enable lockscreen, please setup device passcode or screen lock in your system settings."),
        "lockscreen": MessageLookupByLibrary.simpleMessage("Lockscreen"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Log in"),
        "loggingOut": MessageLookupByLibrary.simpleMessage("Logging out..."),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "By clicking log in, I agree to the <u-terms>terms of service</u-terms> and <u-policy>privacy policy</u-policy>"),
        "logout": MessageLookupByLibrary.simpleMessage("Logout"),
        "logsDialogBody": MessageLookupByLibrary.simpleMessage(
            "This will send across logs to help us debug your issue. Please note that file names will be included to help track issues with specific files."),
        "longpressOnAnItemToViewInFullscreen":
            MessageLookupByLibrary.simpleMessage(
                "Long-press on an item to view in full-screen"),
        "lostDevice": MessageLookupByLibrary.simpleMessage("Lost device?"),
        "manage": MessageLookupByLibrary.simpleMessage("Manage"),
        "manageDeviceStorage":
            MessageLookupByLibrary.simpleMessage("Manage device storage"),
        "manageFamily": MessageLookupByLibrary.simpleMessage("Manage Family"),
        "manageLink": MessageLookupByLibrary.simpleMessage("Manage link"),
        "manageParticipants": MessageLookupByLibrary.simpleMessage("Manage"),
        "manageSubscription":
            MessageLookupByLibrary.simpleMessage("Manage subscription"),
        "map": MessageLookupByLibrary.simpleMessage("Map"),
        "maps": MessageLookupByLibrary.simpleMessage("Maps"),
        "mastodon": MessageLookupByLibrary.simpleMessage("Mastodon"),
        "matrix": MessageLookupByLibrary.simpleMessage("Matrix"),
        "maxDeviceLimitSpikeHandling": m27,
        "memoryCount": m28,
        "merchandise": MessageLookupByLibrary.simpleMessage("Merchandise"),
        "mobileWebDesktop":
            MessageLookupByLibrary.simpleMessage("Mobile, Web, Desktop"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Moderate"),
        "monthly": MessageLookupByLibrary.simpleMessage("Monthly"),
        "moveItem": m29,
        "moveToAlbum": MessageLookupByLibrary.simpleMessage("Move to album"),
        "movedSuccessfullyTo": m30,
        "movedToTrash": MessageLookupByLibrary.simpleMessage("Moved to trash"),
        "movingFilesToAlbum":
            MessageLookupByLibrary.simpleMessage("Moving files to album..."),
        "name": MessageLookupByLibrary.simpleMessage("Name"),
        "never": MessageLookupByLibrary.simpleMessage("Never"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("New album"),
        "newToEnte": MessageLookupByLibrary.simpleMessage("New to ente"),
        "newest": MessageLookupByLibrary.simpleMessage("Newest"),
        "no": MessageLookupByLibrary.simpleMessage("No"),
        "noAlbumsSharedByYouYet":
            MessageLookupByLibrary.simpleMessage("No albums shared by you yet"),
        "noDeviceThatCanBeDeleted": MessageLookupByLibrary.simpleMessage(
            "You\'ve no files on this device that can be deleted"),
        "noDuplicates": MessageLookupByLibrary.simpleMessage("✨ No duplicates"),
        "noExifData": MessageLookupByLibrary.simpleMessage("No EXIF data"),
        "noHiddenPhotosOrVideos":
            MessageLookupByLibrary.simpleMessage("No hidden photos or videos"),
        "noImagesWithLocation":
            MessageLookupByLibrary.simpleMessage("No images with location"),
        "noPhotosAreBeingBackedUpRightNow":
            MessageLookupByLibrary.simpleMessage(
                "No photos are being backed up right now"),
        "noPhotosFoundHere":
            MessageLookupByLibrary.simpleMessage("No photos found here"),
        "noRecoveryKey":
            MessageLookupByLibrary.simpleMessage("No recovery key?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "Due to the nature of our end-to-end encryption protocol, your data cannot be decrypted without your password or recovery key"),
        "noResults": MessageLookupByLibrary.simpleMessage("No results"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("No results found"),
        "nothingSharedWithYouYet":
            MessageLookupByLibrary.simpleMessage("Nothing shared with you yet"),
        "nothingToSeeHere":
            MessageLookupByLibrary.simpleMessage("Nothing to see here! 👀"),
        "notifications": MessageLookupByLibrary.simpleMessage("Notifications"),
        "ok": MessageLookupByLibrary.simpleMessage("Ok"),
        "onDevice": MessageLookupByLibrary.simpleMessage("On device"),
        "onEnte": MessageLookupByLibrary.simpleMessage(
            "On <branding>ente</branding>"),
        "oops": MessageLookupByLibrary.simpleMessage("Oops"),
        "oopsCouldNotSaveEdits":
            MessageLookupByLibrary.simpleMessage("Oops, could not save edits"),
        "oopsSomethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Oops, something went wrong"),
        "openTheItem": MessageLookupByLibrary.simpleMessage("• Open the item"),
        "openstreetmapContributors":
            MessageLookupByLibrary.simpleMessage("OpenStreetMap contributors"),
        "optionalAsShortAsYouLike": MessageLookupByLibrary.simpleMessage(
            "Optional, as short as you like..."),
        "orPickAnExistingOne":
            MessageLookupByLibrary.simpleMessage("Or pick an existing one"),
        "password": MessageLookupByLibrary.simpleMessage("Password"),
        "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
            "Password changed successfully"),
        "passwordLock": MessageLookupByLibrary.simpleMessage("Password lock"),
        "passwordStrength": m31,
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "We don\'t store this password, so if you forget, <underline>we cannot decrypt your data</underline>"),
        "paymentDetails":
            MessageLookupByLibrary.simpleMessage("Payment details"),
        "paymentFailed": MessageLookupByLibrary.simpleMessage("Payment failed"),
        "paymentFailedTalkToProvider": m32,
        "paymentFailedWithReason": m33,
        "pendingSync": MessageLookupByLibrary.simpleMessage("Pending sync"),
        "peopleUsingYourCode":
            MessageLookupByLibrary.simpleMessage("People using your code"),
        "permDeleteWarning": MessageLookupByLibrary.simpleMessage(
            "All items in trash will be permanently deleted\n\nThis action cannot be undone"),
        "permanentlyDelete":
            MessageLookupByLibrary.simpleMessage("Permanently delete"),
        "permanentlyDeleteFromDevice": MessageLookupByLibrary.simpleMessage(
            "Permanently delete from device?"),
        "photoGridSize":
            MessageLookupByLibrary.simpleMessage("Photo grid size"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("photo"),
        "photosAddedByYouWillBeRemovedFromTheAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Photos added by you will be removed from the album"),
        "pickCenterPoint":
            MessageLookupByLibrary.simpleMessage("Pick center point"),
        "pinAlbum": MessageLookupByLibrary.simpleMessage("Pin album"),
        "playStoreFreeTrialValidTill": m64,
        "playstoreSubscription":
            MessageLookupByLibrary.simpleMessage("PlayStore subscription"),
        "pleaseContactSupportAndWeWillBeHappyToHelp":
            MessageLookupByLibrary.simpleMessage(
                "Please contact support@ente.io and we will be happy to help!"),
        "pleaseContactSupportIfTheProblemPersists":
            MessageLookupByLibrary.simpleMessage(
                "Please contact support if the problem persists"),
        "pleaseEmailUsAt": m34,
        "pleaseGrantPermissions":
            MessageLookupByLibrary.simpleMessage("Please grant permissions"),
        "pleaseLoginAgain":
            MessageLookupByLibrary.simpleMessage("Please login again"),
        "pleaseSendTheLogsTo": m35,
        "pleaseTryAgain":
            MessageLookupByLibrary.simpleMessage("Please try again"),
        "pleaseVerifyTheCodeYouHaveEntered":
            MessageLookupByLibrary.simpleMessage(
                "Please verify the code you have entered"),
        "pleaseWait": MessageLookupByLibrary.simpleMessage("Please wait..."),
        "pleaseWaitDeletingAlbum":
            MessageLookupByLibrary.simpleMessage("Please wait, deleting album"),
        "pleaseWaitForSometimeBeforeRetrying":
            MessageLookupByLibrary.simpleMessage(
                "Please wait for sometime before retrying"),
        "preparingLogs":
            MessageLookupByLibrary.simpleMessage("Preparing logs..."),
        "preserveMore": MessageLookupByLibrary.simpleMessage("Preserve more"),
        "pressAndHoldToPlayVideo": MessageLookupByLibrary.simpleMessage(
            "Press and hold to play video"),
        "privacy": MessageLookupByLibrary.simpleMessage("Privacy"),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("Privacy Policy"),
        "privateBackups":
            MessageLookupByLibrary.simpleMessage("Private backups"),
        "privateSharing":
            MessageLookupByLibrary.simpleMessage("Private sharing"),
        "publicLinkCreated":
            MessageLookupByLibrary.simpleMessage("Public link created"),
        "publicLinkEnabled":
            MessageLookupByLibrary.simpleMessage("Public link enabled"),
        "quickLinks": MessageLookupByLibrary.simpleMessage("Quick links"),
        "radius": MessageLookupByLibrary.simpleMessage("Radius"),
        "raiseTicket": MessageLookupByLibrary.simpleMessage("Raise ticket"),
        "rateTheApp": MessageLookupByLibrary.simpleMessage("Rate the app"),
        "rateUs": MessageLookupByLibrary.simpleMessage("Rate us"),
        "rateUsOnStore": m36,
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
            "Your recovery key is the only way to recover your photos if you forget your password. You can find your recovery key in Settings > Security.\n\nPlease enter your recovery key here to verify that you have saved it correctly."),
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("Recovery successful!"),
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "The current device is not powerful enough to verify your password, but we can regenerate in a way that works with all devices.\n\nPlease login using your recovery key and regenerate your password (you can use the same one again if you wish)."),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Recreate password"),
        "reddit": MessageLookupByLibrary.simpleMessage("Reddit"),
        "referFriendsAnd2xYourPlan": MessageLookupByLibrary.simpleMessage(
            "Refer friends and 2x your plan"),
        "referralStep1": MessageLookupByLibrary.simpleMessage(
            "1. Give this code to your friends"),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
            "2. They sign up for a paid plan"),
        "referralStep3": m37,
        "referrals": MessageLookupByLibrary.simpleMessage("Referrals"),
        "referralsAreCurrentlyPaused": MessageLookupByLibrary.simpleMessage(
            "Referrals are currently paused"),
        "remindToEmptyDeviceTrash": MessageLookupByLibrary.simpleMessage(
            "Also empty \"Recently Deleted\" from \"Settings\" -> \"Storage\" to claim the freed space"),
        "remindToEmptyEnteTrash": MessageLookupByLibrary.simpleMessage(
            "Also empty your \"Trash\" to claim the freed up space"),
        "remoteImages": MessageLookupByLibrary.simpleMessage("Remote images"),
        "remoteThumbnails":
            MessageLookupByLibrary.simpleMessage("Remote thumbnails"),
        "remoteVideos": MessageLookupByLibrary.simpleMessage("Remote videos"),
        "remove": MessageLookupByLibrary.simpleMessage("Remove"),
        "removeDuplicates":
            MessageLookupByLibrary.simpleMessage("Remove duplicates"),
        "removeFromAlbum":
            MessageLookupByLibrary.simpleMessage("Remove from album"),
        "removeFromAlbumTitle":
            MessageLookupByLibrary.simpleMessage("Remove from album?"),
        "removeFromFavorite":
            MessageLookupByLibrary.simpleMessage("Remove from favorite"),
        "removeLink": MessageLookupByLibrary.simpleMessage("Remove link"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("Remove participant"),
        "removeParticipantBody": m38,
        "removePublicLink":
            MessageLookupByLibrary.simpleMessage("Remove public link"),
        "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
            "Some of the items you are removing were added by other people, and you will lose access to them"),
        "removeWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Remove?"),
        "removingFromFavorites":
            MessageLookupByLibrary.simpleMessage("Removing from favorites..."),
        "rename": MessageLookupByLibrary.simpleMessage("Rename"),
        "renameAlbum": MessageLookupByLibrary.simpleMessage("Rename album"),
        "renameFile": MessageLookupByLibrary.simpleMessage("Rename file"),
        "renewSubscription":
            MessageLookupByLibrary.simpleMessage("Renew subscription"),
        "renewsOn": m39,
        "reportABug": MessageLookupByLibrary.simpleMessage("Report a bug"),
        "reportBug": MessageLookupByLibrary.simpleMessage("Report bug"),
        "resendEmail": MessageLookupByLibrary.simpleMessage("Resend email"),
        "resetIgnoredFiles":
            MessageLookupByLibrary.simpleMessage("Reset ignored files"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Reset password"),
        "resetToDefault":
            MessageLookupByLibrary.simpleMessage("Reset to default"),
        "restore": MessageLookupByLibrary.simpleMessage("Restore"),
        "restoreToAlbum":
            MessageLookupByLibrary.simpleMessage("Restore to album"),
        "restoringFiles":
            MessageLookupByLibrary.simpleMessage("Restoring files..."),
        "retry": MessageLookupByLibrary.simpleMessage("Retry"),
        "reviewDeduplicateItems": MessageLookupByLibrary.simpleMessage(
            "Please review and delete the items you believe are duplicates."),
        "rotateLeft": MessageLookupByLibrary.simpleMessage("Rotate left"),
        "rotateRight": MessageLookupByLibrary.simpleMessage("Rotate right"),
        "safelyStored": MessageLookupByLibrary.simpleMessage("Safely stored"),
        "save": MessageLookupByLibrary.simpleMessage("Save"),
        "saveCollage": MessageLookupByLibrary.simpleMessage("Save collage"),
        "saveCopy": MessageLookupByLibrary.simpleMessage("Save copy"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Save key"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "Save your recovery key if you haven\'t already"),
        "saving": MessageLookupByLibrary.simpleMessage("Saving..."),
        "scanCode": MessageLookupByLibrary.simpleMessage("Scan code"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Scan this barcode with\nyour authenticator app"),
        "searchByAlbumNameHint":
            MessageLookupByLibrary.simpleMessage("Album name"),
        "searchByExamples": MessageLookupByLibrary.simpleMessage(
            "• Album names (e.g. \"Camera\")\n• Types of files (e.g. \"Videos\", \".gif\")\n• Years and months (e.g. \"2022\", \"January\")\n• Holidays (e.g. \"Christmas\")\n• Photo descriptions (e.g. “#fun”)"),
        "searchHintText": MessageLookupByLibrary.simpleMessage(
            "Albums, months, days, years, ..."),
        "security": MessageLookupByLibrary.simpleMessage("Security"),
        "selectAlbum": MessageLookupByLibrary.simpleMessage("Select album"),
        "selectAll": MessageLookupByLibrary.simpleMessage("Select all"),
        "selectFoldersForBackup":
            MessageLookupByLibrary.simpleMessage("Select folders for backup"),
        "selectItemsToAdd":
            MessageLookupByLibrary.simpleMessage("Select items to add"),
        "selectLanguage":
            MessageLookupByLibrary.simpleMessage("Select Language"),
        "selectReason": MessageLookupByLibrary.simpleMessage("Select reason"),
        "selectYourPlan":
            MessageLookupByLibrary.simpleMessage("Select your plan"),
        "selectedFilesAreNotOnEnte": MessageLookupByLibrary.simpleMessage(
            "Selected files are not on ente"),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
                "Selected folders will be encrypted and backed up"),
        "selectedItemsWillBeDeletedFromAllAlbumsAndMoved":
            MessageLookupByLibrary.simpleMessage(
                "Selected items will be deleted from all albums and moved to trash."),
        "selectedPhotos": m40,
        "selectedPhotosWithYours": m41,
        "send": MessageLookupByLibrary.simpleMessage("Send"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("Send email"),
        "sendInvite": MessageLookupByLibrary.simpleMessage("Send invite"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Send link"),
        "sessionExpired":
            MessageLookupByLibrary.simpleMessage("Session expired"),
        "setAPassword": MessageLookupByLibrary.simpleMessage("Set a password"),
        "setAs": MessageLookupByLibrary.simpleMessage("Set as"),
        "setCover": MessageLookupByLibrary.simpleMessage("Set cover"),
        "setLabel": MessageLookupByLibrary.simpleMessage("Set"),
        "setPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Set password"),
        "setRadius": MessageLookupByLibrary.simpleMessage("Set radius"),
        "setupComplete": MessageLookupByLibrary.simpleMessage("Setup complete"),
        "share": MessageLookupByLibrary.simpleMessage("Share"),
        "shareALink": MessageLookupByLibrary.simpleMessage("Share a link"),
        "shareAlbumHint": MessageLookupByLibrary.simpleMessage(
            "Open an album and tap the share button on the top right to share."),
        "shareAnAlbumNow":
            MessageLookupByLibrary.simpleMessage("Share an album now"),
        "shareLink": MessageLookupByLibrary.simpleMessage("Share link"),
        "shareMyVerificationID": m42,
        "shareOnlyWithThePeopleYouWant": MessageLookupByLibrary.simpleMessage(
            "Share only with the people you want"),
        "shareTextConfirmOthersVerificationID": m43,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "Download ente so we can easily share original quality photos and videos\n\nhttps://ente.io"),
        "shareTextReferralCode": m44,
        "shareWithNonenteUsers":
            MessageLookupByLibrary.simpleMessage("Share with non-ente users"),
        "shareWithPeopleSectionTitle": m45,
        "shareYourFirstAlbum":
            MessageLookupByLibrary.simpleMessage("Share your first album"),
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Create shared and collaborative albums with other ente users, including users on free plans."),
        "sharedByMe": MessageLookupByLibrary.simpleMessage("Shared by me"),
        "sharedByYou": MessageLookupByLibrary.simpleMessage("Shared by you"),
        "sharedPhotoNotifications":
            MessageLookupByLibrary.simpleMessage("New shared photos"),
        "sharedPhotoNotificationsExplanation": MessageLookupByLibrary.simpleMessage(
            "Receive notifications when someone adds a photo to a shared album that you\'re a part of"),
        "sharedWith": m46,
        "sharedWithMe": MessageLookupByLibrary.simpleMessage("Shared with me"),
        "sharedWithYou":
            MessageLookupByLibrary.simpleMessage("Shared with you"),
        "sharing": MessageLookupByLibrary.simpleMessage("Sharing..."),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "I agree to the <u-terms>terms of service</u-terms> and <u-policy>privacy policy</u-policy>"),
        "singleFileDeleteFromDevice": m47,
        "singleFileDeleteHighlight": MessageLookupByLibrary.simpleMessage(
            "It will be deleted from all albums."),
        "singleFileInBothLocalAndRemote": m48,
        "singleFileInRemoteOnly": m49,
        "skip": MessageLookupByLibrary.simpleMessage("Skip"),
        "social": MessageLookupByLibrary.simpleMessage("Social"),
        "someItemsAreInBothEnteAndYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "Some items are in both ente and your device."),
        "someOfTheFilesYouAreTryingToDeleteAre":
            MessageLookupByLibrary.simpleMessage(
                "Some of the files you are trying to delete are only available on your device and cannot be recovered if deleted"),
        "someoneSharingAlbumsWithYouShouldSeeTheSameId":
            MessageLookupByLibrary.simpleMessage(
                "Someone sharing albums with you should see the same ID on their device."),
        "somethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Something went wrong"),
        "somethingWentWrongPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Something went wrong, please try again"),
        "sorry": MessageLookupByLibrary.simpleMessage("Sorry"),
        "sorryCouldNotAddToFavorites": MessageLookupByLibrary.simpleMessage(
            "Sorry, could not add to favorites!"),
        "sorryCouldNotRemoveFromFavorites":
            MessageLookupByLibrary.simpleMessage(
                "Sorry, could not remove from favorites!"),
        "sorryTheCodeYouveEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "Sorry, the code you\'ve entered is incorrect"),
        "sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease":
            MessageLookupByLibrary.simpleMessage(
                "Sorry, we could not generate secure keys on this device.\n\nplease sign up from a different device."),
        "sortAlbumsBy": MessageLookupByLibrary.simpleMessage("Sort by"),
        "sortNewestFirst": MessageLookupByLibrary.simpleMessage("Newest first"),
        "sortOldestFirst": MessageLookupByLibrary.simpleMessage("Oldest first"),
        "sparkleSuccess": MessageLookupByLibrary.simpleMessage("✨ Success"),
        "startBackup": MessageLookupByLibrary.simpleMessage("Start backup"),
        "storage": MessageLookupByLibrary.simpleMessage("Storage"),
        "storageBreakupFamily": MessageLookupByLibrary.simpleMessage("Family"),
        "storageBreakupYou": MessageLookupByLibrary.simpleMessage("You"),
        "storageInGB": m50,
        "storageLimitExceeded":
            MessageLookupByLibrary.simpleMessage("Storage limit exceeded"),
        "storageUsageInfo": m51,
        "strongStrength": MessageLookupByLibrary.simpleMessage("Strong"),
        "subAlreadyLinkedErrMessage": m52,
        "subWillBeCancelledOn": m53,
        "subscribe": MessageLookupByLibrary.simpleMessage("Subscribe"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
            "Looks like your subscription has expired. Please subscribe to enable sharing."),
        "subscription": MessageLookupByLibrary.simpleMessage("Subscription"),
        "success": MessageLookupByLibrary.simpleMessage("Success"),
        "successfullyArchived":
            MessageLookupByLibrary.simpleMessage("Successfully archived"),
        "successfullyUnarchived":
            MessageLookupByLibrary.simpleMessage("Successfully unarchived"),
        "suggestFeatures":
            MessageLookupByLibrary.simpleMessage("Suggest features"),
        "support": MessageLookupByLibrary.simpleMessage("Support"),
        "syncProgress": m54,
        "syncStopped": MessageLookupByLibrary.simpleMessage("Sync stopped"),
        "syncing": MessageLookupByLibrary.simpleMessage("Syncing..."),
        "systemTheme": MessageLookupByLibrary.simpleMessage("System"),
        "tapToCopy": MessageLookupByLibrary.simpleMessage("tap to copy"),
        "tapToEnterCode":
            MessageLookupByLibrary.simpleMessage("Tap to enter code"),
        "tempErrorContactSupportIfPersists": MessageLookupByLibrary.simpleMessage(
            "It looks like something went wrong. Please retry after some time. If the error persists, please contact our support team."),
        "terminate": MessageLookupByLibrary.simpleMessage("Terminate"),
        "terminateSession":
            MessageLookupByLibrary.simpleMessage("Terminate session?"),
        "terms": MessageLookupByLibrary.simpleMessage("Terms"),
        "termsOfServicesTitle": MessageLookupByLibrary.simpleMessage("Terms"),
        "thankYou": MessageLookupByLibrary.simpleMessage("Thank you"),
        "thankYouForSubscribing":
            MessageLookupByLibrary.simpleMessage("Thank you for subscribing!"),
        "theDownloadCouldNotBeCompleted": MessageLookupByLibrary.simpleMessage(
            "The download could not be completed"),
        "theRecoveryKeyYouEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "The recovery key you entered is incorrect"),
        "theme": MessageLookupByLibrary.simpleMessage("Theme"),
        "theseItemsWillBeDeletedFromYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "These items will be deleted from your device."),
        "theyAlsoGetXGb": m55,
        "theyWillBeDeletedFromAllAlbums": MessageLookupByLibrary.simpleMessage(
            "They will be deleted from all albums."),
        "thisActionCannotBeUndone": MessageLookupByLibrary.simpleMessage(
            "This action cannot be undone"),
        "thisAlbumAlreadyHDACollaborativeLink":
            MessageLookupByLibrary.simpleMessage(
                "This album already has a collaborative link"),
        "thisCanBeUsedToRecoverYourAccountIfYou":
            MessageLookupByLibrary.simpleMessage(
                "This can be used to recover your account if you lose your second factor"),
        "thisDevice": MessageLookupByLibrary.simpleMessage("This device"),
        "thisEmailIsAlreadyInUse": MessageLookupByLibrary.simpleMessage(
            "This email is already in use"),
        "thisImageHasNoExifData":
            MessageLookupByLibrary.simpleMessage("This image has no exif data"),
        "thisIsPersonVerificationId": m56,
        "thisIsYourVerificationId": MessageLookupByLibrary.simpleMessage(
            "This is your Verification ID"),
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "This will log you out of the following device:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "This will log you out of this device!"),
        "time": MessageLookupByLibrary.simpleMessage("Time"),
        "toHideAPhotoOrVideo":
            MessageLookupByLibrary.simpleMessage("To hide a photo or video"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "To reset your password, please verify your email first."),
        "todaysLogs": MessageLookupByLibrary.simpleMessage("Today\'s logs"),
        "total": MessageLookupByLibrary.simpleMessage("total"),
        "totalSize": MessageLookupByLibrary.simpleMessage("Total size"),
        "trash": MessageLookupByLibrary.simpleMessage("Trash"),
        "trashDaysLeft": m57,
        "tryAgain": MessageLookupByLibrary.simpleMessage("Try again"),
        "turnOnBackupForAutoUpload": MessageLookupByLibrary.simpleMessage(
            "Turn on backup to automatically upload files added to this device folder to ente."),
        "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
        "twoMonthsFreeOnYearlyPlans": MessageLookupByLibrary.simpleMessage(
            "2 months free on yearly plans"),
        "twofactor": MessageLookupByLibrary.simpleMessage("Two-factor"),
        "twofactorAuthenticationHasBeenDisabled":
            MessageLookupByLibrary.simpleMessage(
                "Two-factor authentication has been disabled"),
        "twofactorAuthenticationPageTitle":
            MessageLookupByLibrary.simpleMessage("Two-factor authentication"),
        "twofactorAuthenticationSuccessfullyReset":
            MessageLookupByLibrary.simpleMessage(
                "Two-factor authentication successfully reset"),
        "twofactorSetup":
            MessageLookupByLibrary.simpleMessage("Two-factor setup"),
        "unarchive": MessageLookupByLibrary.simpleMessage("Unarchive"),
        "unarchiveAlbum":
            MessageLookupByLibrary.simpleMessage("Unarchive album"),
        "unarchiving": MessageLookupByLibrary.simpleMessage("Unarchiving..."),
        "uncategorized": MessageLookupByLibrary.simpleMessage("Uncategorized"),
        "unhide": MessageLookupByLibrary.simpleMessage("Unhide"),
        "unhideToAlbum":
            MessageLookupByLibrary.simpleMessage("Unhide to album"),
        "unhidingFilesToAlbum":
            MessageLookupByLibrary.simpleMessage("Unhiding files to album"),
        "unlock": MessageLookupByLibrary.simpleMessage("Unlock"),
        "unpinAlbum": MessageLookupByLibrary.simpleMessage("Unpin album"),
        "unselectAll": MessageLookupByLibrary.simpleMessage("Unselect all"),
        "update": MessageLookupByLibrary.simpleMessage("Update"),
        "updateAvailable":
            MessageLookupByLibrary.simpleMessage("Update available"),
        "updatingFolderSelection": MessageLookupByLibrary.simpleMessage(
            "Updating folder selection..."),
        "upgrade": MessageLookupByLibrary.simpleMessage("Upgrade"),
        "uploadingFilesToAlbum":
            MessageLookupByLibrary.simpleMessage("Uploading files to album..."),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
            "Usable storage is limited by your current plan. Excess claimed storage will automatically become usable when you upgrade your plan."),
        "usePublicLinksForPeopleNotOnEnte":
            MessageLookupByLibrary.simpleMessage(
                "Use public links for people not on ente"),
        "useRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Use recovery key"),
        "useSelectedPhoto":
            MessageLookupByLibrary.simpleMessage("Use selected photo"),
        "usedSpace": MessageLookupByLibrary.simpleMessage("Used space"),
        "verificationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Verification failed, please try again"),
        "verificationId":
            MessageLookupByLibrary.simpleMessage("Verification ID"),
        "verify": MessageLookupByLibrary.simpleMessage("Verify"),
        "verifyEmail": MessageLookupByLibrary.simpleMessage("Verify email"),
        "verifyEmailID": m58,
        "verifyIDLabel": MessageLookupByLibrary.simpleMessage("Verify"),
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Verify password"),
        "verifying": MessageLookupByLibrary.simpleMessage("Verifying..."),
        "verifyingRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Verifying recovery key..."),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("video"),
        "viewActiveSessions":
            MessageLookupByLibrary.simpleMessage("View active sessions"),
        "viewAll": MessageLookupByLibrary.simpleMessage("View all"),
        "viewAllExifData":
            MessageLookupByLibrary.simpleMessage("View all EXIF data"),
        "viewLogs": MessageLookupByLibrary.simpleMessage("View logs"),
        "viewRecoveryKey":
            MessageLookupByLibrary.simpleMessage("View recovery key"),
        "viewer": MessageLookupByLibrary.simpleMessage("Viewer"),
        "visitWebToManage": MessageLookupByLibrary.simpleMessage(
            "Please visit web.ente.io to manage your subscription"),
        "weAreOpenSource":
            MessageLookupByLibrary.simpleMessage("We are open source!"),
        "weDontSupportEditingPhotosAndAlbumsThatYouDont":
            MessageLookupByLibrary.simpleMessage(
                "We don\'t support editing photos and albums that you don\'t own yet"),
        "weHaveSendEmailTo": m59,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Weak"),
        "welcomeBack": MessageLookupByLibrary.simpleMessage("Welcome back!"),
        "yearly": MessageLookupByLibrary.simpleMessage("Yearly"),
        "yearsAgo": m60,
        "yes": MessageLookupByLibrary.simpleMessage("Yes"),
        "yesCancel": MessageLookupByLibrary.simpleMessage("Yes, cancel"),
        "yesConvertToViewer":
            MessageLookupByLibrary.simpleMessage("Yes, convert to viewer"),
        "yesDelete": MessageLookupByLibrary.simpleMessage("Yes, delete"),
        "yesDiscardChanges":
            MessageLookupByLibrary.simpleMessage("Yes, discard changes"),
        "yesLogout": MessageLookupByLibrary.simpleMessage("Yes, logout"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("Yes, remove"),
        "yesRenew": MessageLookupByLibrary.simpleMessage("Yes, Renew"),
        "you": MessageLookupByLibrary.simpleMessage("You"),
        "youAreOnAFamilyPlan":
            MessageLookupByLibrary.simpleMessage("You are on a family plan!"),
        "youAreOnTheLatestVersion": MessageLookupByLibrary.simpleMessage(
            "You are on the latest version"),
        "youCanAtMaxDoubleYourStorage": MessageLookupByLibrary.simpleMessage(
            "* You can at max double your storage"),
        "youCanManageYourLinksInTheShareTab":
            MessageLookupByLibrary.simpleMessage(
                "You can manage your links in the share tab."),
        "youCanTrySearchingForADifferentQuery":
            MessageLookupByLibrary.simpleMessage(
                "You can try searching for a different query."),
        "youCannotDowngradeToThisPlan": MessageLookupByLibrary.simpleMessage(
            "You cannot downgrade to this plan"),
        "youCannotShareWithYourself": MessageLookupByLibrary.simpleMessage(
            "You cannot share with yourself"),
        "youDontHaveAnyArchivedItems": MessageLookupByLibrary.simpleMessage(
            "You don\'t have any archived items."),
        "youHaveSuccessfullyFreedUp": m61,
        "yourAccountHasBeenDeleted": MessageLookupByLibrary.simpleMessage(
            "Your account has been deleted"),
        "yourPlanWasSuccessfullyDowngraded":
            MessageLookupByLibrary.simpleMessage(
                "Your plan was successfully downgraded"),
        "yourPlanWasSuccessfullyUpgraded": MessageLookupByLibrary.simpleMessage(
            "Your plan was successfully upgraded"),
        "yourPurchaseWasSuccessful": MessageLookupByLibrary.simpleMessage(
            "Your purchase was successful"),
        "yourStorageDetailsCouldNotBeFetched":
            MessageLookupByLibrary.simpleMessage(
                "Your storage details could not be fetched"),
        "yourSubscriptionHasExpired": MessageLookupByLibrary.simpleMessage(
            "Your subscription has expired"),
        "yourSubscriptionWasUpdatedSuccessfully":
            MessageLookupByLibrary.simpleMessage(
                "Your subscription was updated successfully"),
        "yourVerificationCodeHasExpired": MessageLookupByLibrary.simpleMessage(
            "Your verification code has expired"),
        "youveNoDuplicateFilesThatCanBeCleared":
            MessageLookupByLibrary.simpleMessage(
                "You\'ve no duplicate files that can be cleared"),
        "youveNoFilesInThisAlbumThatCanBeDeleted":
            MessageLookupByLibrary.simpleMessage(
                "You\'ve no files in this album that can be deleted"),
        "zoomOutToSeePhotos":
            MessageLookupByLibrary.simpleMessage("Zoom out to see photos")
      };
}
