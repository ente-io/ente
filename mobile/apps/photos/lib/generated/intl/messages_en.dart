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

  static String m0(title) => "${title} (Me)";

  static String m1(count) =>
      "${Intl.plural(count, zero: 'Add collaborator', one: 'Add collaborator', other: 'Add collaborators')}";

  static String m2(count) =>
      "${Intl.plural(count, one: 'Add item', other: 'Add items')}";

  static String m3(storageAmount, endDate) =>
      "Your ${storageAmount} add-on is valid till ${endDate}";

  static String m4(count) =>
      "${Intl.plural(count, zero: 'Add viewer', one: 'Add viewer', other: 'Add viewers')}";

  static String m5(emailOrName) => "Added by ${emailOrName}";

  static String m6(albumName) => "Added successfully to  ${albumName}";

  static String m7(name) => "Admiring ${name}";

  static String m8(count) =>
      "${Intl.plural(count, zero: 'No Participants', one: '1 Participant', other: '${count} Participants')}";

  static String m9(versionValue) => "Version: ${versionValue}";

  static String m10(freeAmount, storageUnit) =>
      "${freeAmount} ${storageUnit} free";

  static String m11(name) => "Beautiful views with ${name}";

  static String m12(paymentProvider) =>
      "Please cancel your existing subscription from ${paymentProvider} first";

  static String m13(user) =>
      "${user} will not be able to add more photos to this album\n\nThey will still be able to remove existing photos added by them";

  static String m14(isFamilyMember, storageAmountInGb) =>
      "${Intl.select(isFamilyMember, {
            'true': 'Your family has claimed ${storageAmountInGb} GB so far',
            'false': 'You have claimed ${storageAmountInGb} GB so far',
            'other': 'You have claimed ${storageAmountInGb} GB so far!',
          })}";

  static String m15(albumName) => "Collaborative link created for ${albumName}";

  static String m16(count) =>
      "${Intl.plural(count, zero: 'Added 0 collaborator', one: 'Added 1 collaborator', other: 'Added ${count} collaborators')}";

  static String m17(email, numOfDays) =>
      "You are about to add ${email} as a trusted contact. They will be able to recover your account if you are absent for ${numOfDays} days.";

  static String m18(familyAdminEmail) =>
      "Please contact <green>${familyAdminEmail}</green> to manage your subscription";

  static String m19(provider) =>
      "Please contact us at support@ente.io to manage your ${provider} subscription.";

  static String m20(endpoint) => "Connected to ${endpoint}";

  static String m21(count) =>
      "${Intl.plural(count, one: 'Delete ${count} item', other: 'Delete ${count} items')}";

  static String m22(count) =>
      "Also delete the photos (and videos) present in these ${count} albums from <bold>all</bold> other albums they are part of?";

  static String m23(currentlyDeleting, totalCount) =>
      "Deleting ${currentlyDeleting} / ${totalCount}";

  static String m24(albumName) =>
      "This will remove the public link for accessing \"${albumName}\".";

  static String m25(supportEmail) =>
      "Please drop an email to ${supportEmail} from your registered email address";

  static String m26(count, storageSaved) =>
      "You have cleaned up ${Intl.plural(count, one: '${count} duplicate file', other: '${count} duplicate files')}, saving (${storageSaved}!)";

  static String m27(count, formattedSize) =>
      "${count} files, ${formattedSize} each";

  static String m28(name) => "This email is already linked to ${name}.";

  static String m29(newEmail) => "Email changed to ${newEmail}";

  static String m30(email) => "${email} does not have an Ente account.";

  static String m31(email) =>
      "${email} does not have an Ente account.\n\nSend them an invite to share photos.";

  static String m32(name) => "Embracing ${name}";

  static String m33(text) => "Extra photos found for ${text}";

  static String m34(name) => "Feasting with ${name}";

  static String m35(count, formattedNumber) =>
      "${Intl.plural(count, one: '1 file', other: '${formattedNumber} files')} on this device have been backed up safely";

  static String m36(count, formattedNumber) =>
      "${Intl.plural(count, one: '1 file', other: '${formattedNumber} files')} in this album has been backed up safely";

  static String m37(storageAmountInGB) =>
      "${storageAmountInGB} GB each time someone signs up for a paid plan and applies your code";

  static String m38(endDate) => "Free trial valid till ${endDate}";

  static String m39(count) =>
      "You can still access ${Intl.plural(count, one: 'it', other: 'them')} on Ente as long as you have an active subscription";

  static String m40(sizeInMBorGB) => "Free up ${sizeInMBorGB}";

  static String m41(count, formattedSize) =>
      "${Intl.plural(count, one: 'It can be deleted from the device to free up ${formattedSize}', other: 'They can be deleted from the device to free up ${formattedSize}')}";

  static String m42(currentlyProcessing, totalCount) =>
      "Processing ${currentlyProcessing} / ${totalCount}";

  static String m43(name) => "Hiking with ${name}";

  static String m44(count) =>
      "${Intl.plural(count, one: '${count} item', other: '${count} items')}";

  static String m45(name) => "Last time with ${name}";

  static String m46(email) =>
      "${email} has invited you to be a trusted contact";

  static String m47(expiryTime) => "Link will expire on ${expiryTime}";

  static String m48(email) => "Link person to ${email}";

  static String m49(personName, email) =>
      "This will link ${personName} to ${email}";

  static String m50(count, formattedCount) =>
      "${Intl.plural(count, zero: 'no memories', one: '${formattedCount} memory', other: '${formattedCount} memories')}";

  static String m51(count) =>
      "${Intl.plural(count, one: 'Move item', other: 'Move items')}";

  static String m52(albumName) => "Moved successfully to ${albumName}";

  static String m53(personName) => "No suggestions for ${personName}";

  static String m54(name) => "Not ${name}?";

  static String m55(familyAdminEmail) =>
      "Please contact ${familyAdminEmail} to change your code.";

  static String m56(name) => "Party with ${name}";

  static String m57(passwordStrengthValue) =>
      "Password strength: ${passwordStrengthValue}";

  static String m58(providerName) =>
      "Please talk to ${providerName} support if you were charged";

  static String m59(name, age) => "${name} is ${age}!";

  static String m60(name, age) => "${name} turning ${age} soon";

  static String m61(count) =>
      "${Intl.plural(count, zero: 'No photos', one: '1 photo', other: '${count} photos')}";

  static String m62(count) =>
      "${Intl.plural(count, zero: '0 photos', one: '1 photo', other: '${count} photos')}";

  static String m63(endDate) =>
      "Free trial valid till ${endDate}.\nYou can choose a paid plan afterwards.";

  static String m64(toEmail) => "Please email us at ${toEmail}";

  static String m65(toEmail) => "Please send the logs to \n${toEmail}";

  static String m66(name) => "Posing with ${name}";

  static String m67(folderName) => "Processing ${folderName}...";

  static String m68(storeName) => "Rate us on ${storeName}";

  static String m69(name) => "Reassigned you to ${name}";

  static String m70(days, email) =>
      "You can access the account after ${days} days. A notification will be sent to ${email}.";

  static String m71(email) =>
      "You can now recover ${email}\'s account by setting a new password.";

  static String m72(email) => "${email} is trying to recover your account.";

  static String m73(storageInGB) =>
      "3. Both of you get ${storageInGB} GB* free";

  static String m74(userEmail) =>
      "${userEmail} will be removed from this shared album\n\nAny photos added by them will also be removed from the album";

  static String m75(endDate) => "Subscription renews on ${endDate}";

  static String m76(name) => "Road trip with ${name}";

  static String m77(count) =>
      "${Intl.plural(count, one: '${count} result found', other: '${count} results found')}";

  static String m78(snapshotLength, searchLength) =>
      "Sections length mismatch: ${snapshotLength} != ${searchLength}";

  static String m79(count) => "${count} selected";

  static String m80(count) => "${count} selected";

  static String m81(count, yourCount) =>
      "${count} selected (${yourCount} yours)";

  static String m82(name) => "Selfies with ${name}";

  static String m83(verificationID) =>
      "Here\'s my verification ID: ${verificationID} for ente.io.";

  static String m84(verificationID) =>
      "Hey, can you confirm that this is your ente.io verification ID: ${verificationID}";

  static String m85(referralCode, referralStorageInGB) =>
      "Ente referral code: ${referralCode} \n\nApply it in Settings → General → Referrals to get ${referralStorageInGB} GB free after you signup for a paid plan\n\nhttps://ente.io";

  static String m86(numberOfPeople) =>
      "${Intl.plural(numberOfPeople, zero: 'Share with specific people', one: 'Shared with 1 person', other: 'Shared with ${numberOfPeople} people')}";

  static String m87(emailIDs) => "Shared with ${emailIDs}";

  static String m88(fileType) =>
      "This ${fileType} will be deleted from your device.";

  static String m89(fileType) =>
      "This ${fileType} is in both Ente and your device.";

  static String m90(fileType) => "This ${fileType} will be deleted from Ente.";

  static String m91(name) => "Sports with ${name}";

  static String m92(name) => "Spotlight on ${name}";

  static String m93(storageAmountInGB) => "${storageAmountInGB} GB";

  static String m94(
          usedAmount, usedStorageUnit, totalAmount, totalStorageUnit) =>
      "${usedAmount} ${usedStorageUnit} of ${totalAmount} ${totalStorageUnit} used";

  static String m95(id) =>
      "Your ${id} is already linked to another Ente account.\nIf you would like to use your ${id} with this account, please contact our support\'\'";

  static String m96(endDate) =>
      "Your subscription will be cancelled on ${endDate}";

  static String m97(completed, total) =>
      "${completed}/${total} memories preserved";

  static String m98(ignoreReason) =>
      "Tap to upload, upload is currently ignored due to ${ignoreReason}";

  static String m99(storageAmountInGB) =>
      "They also get ${storageAmountInGB} GB";

  static String m100(email) => "This is ${email}\'s Verification ID";

  static String m101(count) =>
      "${Intl.plural(count, one: 'This week, ${count} year ago', other: 'This week, ${count} years ago')}";

  static String m102(dateFormat) => "${dateFormat} through the years";

  static String m103(count) =>
      "${Intl.plural(count, zero: 'Soon', one: '1 day', other: '${count} days')}";

  static String m104(year) => "Trip in ${year}";

  static String m105(location) => "Trip to ${location}";

  static String m106(email) =>
      "You have been invited to be a legacy contact by ${email}.";

  static String m107(galleryType) =>
      "Type of gallery ${galleryType} is not supported for rename";

  static String m108(ignoreReason) =>
      "Upload is ignored due to ${ignoreReason}";

  static String m109(count) => "Preserving ${count} memories...";

  static String m110(endDate) => "Valid till ${endDate}";

  static String m111(email) => "Verify ${email}";

  static String m112(name) => "View ${name} to unlink";

  static String m113(count) =>
      "${Intl.plural(count, zero: 'Added 0 viewers', one: 'Added 1 viewer', other: 'Added ${count} viewers')}";

  static String m114(email) => "We have sent a mail to <green>${email}</green>";

  static String m115(name) => "Wish ${name} a happy birthday! 🎉";

  static String m116(count) =>
      "${Intl.plural(count, one: '${count} year ago', other: '${count} years ago')}";

  static String m117(name) => "You and ${name}";

  static String m118(storageSaved) =>
      "You have successfully freed up ${storageSaved}!";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aNewVersionOfEnteIsAvailable": MessageLookupByLibrary.simpleMessage(
            "A new version of Ente is available."),
        "about": MessageLookupByLibrary.simpleMessage("About"),
        "acceptTrustInvite":
            MessageLookupByLibrary.simpleMessage("Accept Invite"),
        "account": MessageLookupByLibrary.simpleMessage("Account"),
        "accountIsAlreadyConfigured": MessageLookupByLibrary.simpleMessage(
            "Account is already configured."),
        "accountOwnerPersonAppbarTitle": m0,
        "accountWelcomeBack":
            MessageLookupByLibrary.simpleMessage("Welcome back!"),
        "ackPasswordLostWarning": MessageLookupByLibrary.simpleMessage(
            "I understand that if I lose my password, I may lose my data since my data is <underline>end-to-end encrypted</underline>."),
        "actionNotSupportedOnFavouritesAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Action not supported on Favourites album"),
        "activeSessions":
            MessageLookupByLibrary.simpleMessage("Active sessions"),
        "add": MessageLookupByLibrary.simpleMessage("Add"),
        "addAName": MessageLookupByLibrary.simpleMessage("Add a name"),
        "addANewEmail": MessageLookupByLibrary.simpleMessage("Add a new email"),
        "addAlbumWidgetPrompt": MessageLookupByLibrary.simpleMessage(
            "Add an album widget to your homescreen and come back here to customize."),
        "addCollaborator":
            MessageLookupByLibrary.simpleMessage("Add collaborator"),
        "addCollaborators": m1,
        "addFiles": MessageLookupByLibrary.simpleMessage("Add Files"),
        "addFromDevice":
            MessageLookupByLibrary.simpleMessage("Add from device"),
        "addItem": m2,
        "addLocation": MessageLookupByLibrary.simpleMessage("Add location"),
        "addLocationButton": MessageLookupByLibrary.simpleMessage("Add"),
        "addMemoriesWidgetPrompt": MessageLookupByLibrary.simpleMessage(
            "Add a memories widget to your homescreen and come back here to customize."),
        "addMore": MessageLookupByLibrary.simpleMessage("Add more"),
        "addName": MessageLookupByLibrary.simpleMessage("Add name"),
        "addNameOrMerge":
            MessageLookupByLibrary.simpleMessage("Add name or merge"),
        "addNew": MessageLookupByLibrary.simpleMessage("Add new"),
        "addNewPerson": MessageLookupByLibrary.simpleMessage("Add new person"),
        "addOnPageSubtitle":
            MessageLookupByLibrary.simpleMessage("Details of add-ons"),
        "addOnValidTill": m3,
        "addOns": MessageLookupByLibrary.simpleMessage("Add-ons"),
        "addParticipants":
            MessageLookupByLibrary.simpleMessage("Add participants"),
        "addPeopleWidgetPrompt": MessageLookupByLibrary.simpleMessage(
            "Add a people widget to your homescreen and come back here to customize."),
        "addPhotos": MessageLookupByLibrary.simpleMessage("Add photos"),
        "addSelected": MessageLookupByLibrary.simpleMessage("Add selected"),
        "addToAlbum": MessageLookupByLibrary.simpleMessage("Add to album"),
        "addToEnte": MessageLookupByLibrary.simpleMessage("Add to Ente"),
        "addToHiddenAlbum":
            MessageLookupByLibrary.simpleMessage("Add to hidden album"),
        "addTrustedContact":
            MessageLookupByLibrary.simpleMessage("Add Trusted Contact"),
        "addViewer": MessageLookupByLibrary.simpleMessage("Add viewer"),
        "addViewers": m4,
        "addYourPhotosNow":
            MessageLookupByLibrary.simpleMessage("Add your photos now"),
        "addedAs": MessageLookupByLibrary.simpleMessage("Added as"),
        "addedBy": m5,
        "addedSuccessfullyTo": m6,
        "addingPhotos": MessageLookupByLibrary.simpleMessage("Adding photos"),
        "addingToFavorites":
            MessageLookupByLibrary.simpleMessage("Adding to favorites..."),
        "admiringThem": m7,
        "advanced": MessageLookupByLibrary.simpleMessage("Advanced"),
        "advancedSettings": MessageLookupByLibrary.simpleMessage("Advanced"),
        "after1Day": MessageLookupByLibrary.simpleMessage("After 1 day"),
        "after1Hour": MessageLookupByLibrary.simpleMessage("After 1 hour"),
        "after1Month": MessageLookupByLibrary.simpleMessage("After 1 month"),
        "after1Week": MessageLookupByLibrary.simpleMessage("After 1 week"),
        "after1Year": MessageLookupByLibrary.simpleMessage("After 1 year"),
        "albumOwner": MessageLookupByLibrary.simpleMessage("Owner"),
        "albumParticipantsCount": m8,
        "albumTitle": MessageLookupByLibrary.simpleMessage("Album title"),
        "albumUpdated": MessageLookupByLibrary.simpleMessage("Album updated"),
        "albums": MessageLookupByLibrary.simpleMessage("Albums"),
        "albumsWidgetDesc": MessageLookupByLibrary.simpleMessage(
            "Select the albums you wish to see on your homescreen."),
        "allClear": MessageLookupByLibrary.simpleMessage("✨ All clear"),
        "allMemoriesPreserved":
            MessageLookupByLibrary.simpleMessage("All memories preserved"),
        "allPersonGroupingWillReset": MessageLookupByLibrary.simpleMessage(
            "All groupings for this person will be reset, and you will lose all suggestions made for this person"),
        "allUnnamedGroupsWillBeMergedIntoTheSelectedPerson":
            MessageLookupByLibrary.simpleMessage(
                "All unnamed groups will be merged into the selected person. This can still be undone from the suggestions history overview of the person."),
        "allWillShiftRangeBasedOnFirst": MessageLookupByLibrary.simpleMessage(
            "This is the first in the group. Other selected photos will automatically shift based on this new date"),
        "allow": MessageLookupByLibrary.simpleMessage("Allow"),
        "allowAddPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Allow people with the link to also add photos to the shared album."),
        "allowAddingPhotos":
            MessageLookupByLibrary.simpleMessage("Allow adding photos"),
        "allowAppToOpenSharedAlbumLinks": MessageLookupByLibrary.simpleMessage(
            "Allow app to open shared album links"),
        "allowDownloads":
            MessageLookupByLibrary.simpleMessage("Allow downloads"),
        "allowPeopleToAddPhotos":
            MessageLookupByLibrary.simpleMessage("Allow people to add photos"),
        "allowPermBody": MessageLookupByLibrary.simpleMessage(
            "Please allow access to your photos from Settings so Ente can display and backup your library."),
        "allowPermTitle":
            MessageLookupByLibrary.simpleMessage("Allow access to photos"),
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
        "appIcon": MessageLookupByLibrary.simpleMessage("App icon"),
        "appLock": MessageLookupByLibrary.simpleMessage("App lock"),
        "appLockDescriptions": MessageLookupByLibrary.simpleMessage(
            "Choose between your device\'s default lock screen and a custom lock screen with a PIN or password."),
        "appVersion": m9,
        "appleId": MessageLookupByLibrary.simpleMessage("Apple ID"),
        "apply": MessageLookupByLibrary.simpleMessage("Apply"),
        "applyCodeTitle": MessageLookupByLibrary.simpleMessage("Apply code"),
        "appstoreSubscription":
            MessageLookupByLibrary.simpleMessage("AppStore subscription"),
        "archive": MessageLookupByLibrary.simpleMessage("Archive"),
        "archiveAlbum": MessageLookupByLibrary.simpleMessage("Archive album"),
        "archiving": MessageLookupByLibrary.simpleMessage("Archiving..."),
        "areThey": MessageLookupByLibrary.simpleMessage("Are they "),
        "areYouSureRemoveThisFaceFromPerson":
            MessageLookupByLibrary.simpleMessage(
                "Are you sure you want to remove this face from this person?"),
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
        "areYouSureYouWantToIgnoreThesePersons":
            MessageLookupByLibrary.simpleMessage(
                "Are you sure you want to ignore these persons?"),
        "areYouSureYouWantToIgnoreThisPerson":
            MessageLookupByLibrary.simpleMessage(
                "Are you sure you want to ignore this person?"),
        "areYouSureYouWantToLogout": MessageLookupByLibrary.simpleMessage(
            "Are you sure you want to logout?"),
        "areYouSureYouWantToMergeThem": MessageLookupByLibrary.simpleMessage(
            "Are you sure you want to merge them?"),
        "areYouSureYouWantToRenew": MessageLookupByLibrary.simpleMessage(
            "Are you sure you want to renew?"),
        "areYouSureYouWantToResetThisPerson":
            MessageLookupByLibrary.simpleMessage(
                "Are you sure you want to reset this person?"),
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
        "authToManageLegacy": MessageLookupByLibrary.simpleMessage(
            "Please authenticate to manage your trusted contacts"),
        "authToViewPasskey": MessageLookupByLibrary.simpleMessage(
            "Please authenticate to view your passkey"),
        "authToViewTrashedFiles": MessageLookupByLibrary.simpleMessage(
            "Please authenticate to view your trashed files"),
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
        "autoAddPeople":
            MessageLookupByLibrary.simpleMessage("Auto-add people"),
        "autoCastDialogBody": MessageLookupByLibrary.simpleMessage(
            "You\'ll see available Cast devices here."),
        "autoCastiOSPermission": MessageLookupByLibrary.simpleMessage(
            "Make sure Local Network permissions are turned on for the Ente Photos app, in Settings."),
        "autoLock": MessageLookupByLibrary.simpleMessage("Auto lock"),
        "autoLockFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "Time after which the app locks after being put in the background"),
        "autoLogoutMessage": MessageLookupByLibrary.simpleMessage(
            "Due to technical glitch, you have been logged out. Our apologies for the inconvenience."),
        "autoPair": MessageLookupByLibrary.simpleMessage("Auto pair"),
        "autoPairDesc": MessageLookupByLibrary.simpleMessage(
            "Auto pair works only with devices that support Chromecast."),
        "available": MessageLookupByLibrary.simpleMessage("Available"),
        "availableStorageSpace": m10,
        "backedUpFolders":
            MessageLookupByLibrary.simpleMessage("Backed up folders"),
        "backgroundWithThem": m11,
        "backup": MessageLookupByLibrary.simpleMessage("Backup"),
        "backupFailed": MessageLookupByLibrary.simpleMessage("Backup failed"),
        "backupFile": MessageLookupByLibrary.simpleMessage("Backup file"),
        "backupOverMobileData":
            MessageLookupByLibrary.simpleMessage("Backup over mobile data"),
        "backupSettings":
            MessageLookupByLibrary.simpleMessage("Backup settings"),
        "backupStatus": MessageLookupByLibrary.simpleMessage("Backup status"),
        "backupStatusDescription": MessageLookupByLibrary.simpleMessage(
            "Items that have been backed up will show up here"),
        "backupVideos": MessageLookupByLibrary.simpleMessage("Backup videos"),
        "beach": MessageLookupByLibrary.simpleMessage("Sand and sea"),
        "birthday": MessageLookupByLibrary.simpleMessage("Birthday"),
        "birthdayNotifications":
            MessageLookupByLibrary.simpleMessage("Birthday notifications"),
        "birthdays": MessageLookupByLibrary.simpleMessage("Birthdays"),
        "blackFridaySale":
            MessageLookupByLibrary.simpleMessage("Black Friday Sale"),
        "blog": MessageLookupByLibrary.simpleMessage("Blog"),
        "cLDesc1": MessageLookupByLibrary.simpleMessage(
            "On the back of video streaming beta, and work on resumable uploads and downloads, we have now increased the file upload limit to 10GB. This is now available in both desktop and mobile apps."),
        "cLDesc2": MessageLookupByLibrary.simpleMessage(
            "Background uploads are now supported on iOS as well, in addition to Android devices. No need to open the app to backup your latest photos and videos."),
        "cLDesc3": MessageLookupByLibrary.simpleMessage(
            "We have made significant improvements to our memories experience, including autoplay, swipe to next memory and a lot more."),
        "cLDesc4": MessageLookupByLibrary.simpleMessage(
            "Along with a bunch of under the hood improvements, now its much easier to see all detected faces, provide feedback on similar faces, and add/remove faces from a single photo."),
        "cLDesc5": MessageLookupByLibrary.simpleMessage(
            "You will now receive an opt-out notification for all the birthdays your have saved on Ente, along with a collection of their best photos."),
        "cLDesc6": MessageLookupByLibrary.simpleMessage(
            "No more waiting for uploads/downloads to complete before you can close the app. All uploads and downloads now have the ability to be paused midway, and resume from where you left off."),
        "cLTitle1":
            MessageLookupByLibrary.simpleMessage("Uploading Large Video Files"),
        "cLTitle2": MessageLookupByLibrary.simpleMessage("Background Upload"),
        "cLTitle3": MessageLookupByLibrary.simpleMessage("Autoplay Memories"),
        "cLTitle4":
            MessageLookupByLibrary.simpleMessage("Improved Face Recognition"),
        "cLTitle5":
            MessageLookupByLibrary.simpleMessage("Birthday Notifications"),
        "cLTitle6": MessageLookupByLibrary.simpleMessage(
            "Resumable Uploads and Downloads"),
        "cachedData": MessageLookupByLibrary.simpleMessage("Cached data"),
        "calculating": MessageLookupByLibrary.simpleMessage("Calculating..."),
        "canNotOpenBody": MessageLookupByLibrary.simpleMessage(
            "Sorry, this album cannot be opened in the app."),
        "canNotOpenTitle":
            MessageLookupByLibrary.simpleMessage("Cannot open this album"),
        "canNotUploadToAlbumsOwnedByOthers":
            MessageLookupByLibrary.simpleMessage(
                "Can not upload to albums owned by others"),
        "canOnlyCreateLinkForFilesOwnedByYou":
            MessageLookupByLibrary.simpleMessage(
                "Can only create link for files owned by you"),
        "canOnlyRemoveFilesOwnedByYou": MessageLookupByLibrary.simpleMessage(
            "Can only remove files owned by you"),
        "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
        "cancelAccountRecovery":
            MessageLookupByLibrary.simpleMessage("Cancel recovery"),
        "cancelAccountRecoveryBody": MessageLookupByLibrary.simpleMessage(
            "Are you sure you want to cancel recovery?"),
        "cancelOtherSubscription": m12,
        "cancelSubscription":
            MessageLookupByLibrary.simpleMessage("Cancel subscription"),
        "cannotAddMorePhotosAfterBecomingViewer": m13,
        "cannotDeleteSharedFiles":
            MessageLookupByLibrary.simpleMessage("Cannot delete shared files"),
        "castAlbum": MessageLookupByLibrary.simpleMessage("Cast album"),
        "castIPMismatchBody": MessageLookupByLibrary.simpleMessage(
            "Please make sure you are on the same network as the TV."),
        "castIPMismatchTitle":
            MessageLookupByLibrary.simpleMessage("Failed to cast album"),
        "castInstruction": MessageLookupByLibrary.simpleMessage(
            "Visit cast.ente.io on the device you want to pair.\n\nEnter the code below to play the album on your TV."),
        "centerPoint": MessageLookupByLibrary.simpleMessage("Center point"),
        "change": MessageLookupByLibrary.simpleMessage("Change"),
        "changeEmail": MessageLookupByLibrary.simpleMessage("Change email"),
        "changeLocationOfSelectedItems": MessageLookupByLibrary.simpleMessage(
            "Change location of selected items?"),
        "changePassword":
            MessageLookupByLibrary.simpleMessage("Change password"),
        "changePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Change password"),
        "changePermissions":
            MessageLookupByLibrary.simpleMessage("Change permissions?"),
        "changeYourReferralCode":
            MessageLookupByLibrary.simpleMessage("Change your referral code"),
        "checkForUpdates":
            MessageLookupByLibrary.simpleMessage("Check for updates"),
        "checkInboxAndSpamFolder": MessageLookupByLibrary.simpleMessage(
            "Please check your inbox (and spam) to complete verification"),
        "checkStatus": MessageLookupByLibrary.simpleMessage("Check status"),
        "checking": MessageLookupByLibrary.simpleMessage("Checking..."),
        "checkingModels":
            MessageLookupByLibrary.simpleMessage("Checking models..."),
        "city": MessageLookupByLibrary.simpleMessage("In the city"),
        "claimFreeStorage":
            MessageLookupByLibrary.simpleMessage("Claim free storage"),
        "claimMore": MessageLookupByLibrary.simpleMessage("Claim more!"),
        "claimed": MessageLookupByLibrary.simpleMessage("Claimed"),
        "claimedStorageSoFar": m14,
        "cleanUncategorized":
            MessageLookupByLibrary.simpleMessage("Clean Uncategorized"),
        "cleanUncategorizedDescription": MessageLookupByLibrary.simpleMessage(
            "Remove all files from Uncategorized that are present in other albums"),
        "clearCaches": MessageLookupByLibrary.simpleMessage("Clear caches"),
        "clearIndexes": MessageLookupByLibrary.simpleMessage("Clear indexes"),
        "click": MessageLookupByLibrary.simpleMessage("• Click"),
        "clickOnTheOverflowMenu": MessageLookupByLibrary.simpleMessage(
            "• Click on the overflow menu"),
        "clickToInstallOurBestVersionYet": MessageLookupByLibrary.simpleMessage(
            "Click to install our best version yet"),
        "close": MessageLookupByLibrary.simpleMessage("Close"),
        "clubByCaptureTime":
            MessageLookupByLibrary.simpleMessage("Club by capture time"),
        "clubByFileName":
            MessageLookupByLibrary.simpleMessage("Club by file name"),
        "clusteringProgress":
            MessageLookupByLibrary.simpleMessage("Clustering progress"),
        "codeAppliedPageTitle":
            MessageLookupByLibrary.simpleMessage("Code applied"),
        "codeChangeLimitReached": MessageLookupByLibrary.simpleMessage(
            "Sorry, you\'ve reached the limit of code changes."),
        "codeCopiedToClipboard":
            MessageLookupByLibrary.simpleMessage("Code copied to clipboard"),
        "codeUsedByYou":
            MessageLookupByLibrary.simpleMessage("Code used by you"),
        "collabLinkSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Create a link to allow people to add and view photos in your shared album without needing an Ente app or account. Great for collecting event photos."),
        "collaborativeLink":
            MessageLookupByLibrary.simpleMessage("Collaborative link"),
        "collaborativeLinkCreatedFor": m15,
        "collaborator": MessageLookupByLibrary.simpleMessage("Collaborator"),
        "collaboratorsCanAddPhotosAndVideosToTheSharedAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Collaborators can add photos and videos to the shared album."),
        "collaboratorsSuccessfullyAdded": m16,
        "collageLayout": MessageLookupByLibrary.simpleMessage("Layout"),
        "collageSaved":
            MessageLookupByLibrary.simpleMessage("Collage saved to gallery"),
        "collect": MessageLookupByLibrary.simpleMessage("Collect"),
        "collectEventPhotos":
            MessageLookupByLibrary.simpleMessage("Collect event photos"),
        "collectPhotos": MessageLookupByLibrary.simpleMessage("Collect photos"),
        "collectPhotosDescription": MessageLookupByLibrary.simpleMessage(
            "Create a link where your friends can upload photos in original quality."),
        "color": MessageLookupByLibrary.simpleMessage("Color"),
        "configuration": MessageLookupByLibrary.simpleMessage("Configuration"),
        "confirm": MessageLookupByLibrary.simpleMessage("Confirm"),
        "confirm2FADisable": MessageLookupByLibrary.simpleMessage(
            "Are you sure you want to disable two-factor authentication?"),
        "confirmAccountDeletion":
            MessageLookupByLibrary.simpleMessage("Confirm Account Deletion"),
        "confirmAddingTrustedContact": m17,
        "confirmDeletePrompt": MessageLookupByLibrary.simpleMessage(
            "Yes, I want to permanently delete this account and its data across all apps."),
        "confirmPassword":
            MessageLookupByLibrary.simpleMessage("Confirm password"),
        "confirmPlanChange":
            MessageLookupByLibrary.simpleMessage("Confirm plan change"),
        "confirmRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Confirm recovery key"),
        "confirmYourRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Confirm your recovery key"),
        "connectToDevice":
            MessageLookupByLibrary.simpleMessage("Connect to device"),
        "contactFamilyAdmin": m18,
        "contactSupport":
            MessageLookupByLibrary.simpleMessage("Contact support"),
        "contactToManageSubscription": m19,
        "contacts": MessageLookupByLibrary.simpleMessage("Contacts"),
        "contents": MessageLookupByLibrary.simpleMessage("Contents"),
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
        "createCollaborativeLink":
            MessageLookupByLibrary.simpleMessage("Create collaborative link"),
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
        "crop": MessageLookupByLibrary.simpleMessage("Crop"),
        "curatedMemories":
            MessageLookupByLibrary.simpleMessage("Curated memories"),
        "currentUsageIs":
            MessageLookupByLibrary.simpleMessage("Current usage is "),
        "currentlyRunning":
            MessageLookupByLibrary.simpleMessage("currently running"),
        "custom": MessageLookupByLibrary.simpleMessage("Custom"),
        "customEndpoint": m20,
        "darkTheme": MessageLookupByLibrary.simpleMessage("Dark"),
        "dayToday": MessageLookupByLibrary.simpleMessage("Today"),
        "dayYesterday": MessageLookupByLibrary.simpleMessage("Yesterday"),
        "declineTrustInvite":
            MessageLookupByLibrary.simpleMessage("Decline Invite"),
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
            "This account is linked to other Ente apps, if you use any. Your uploaded data, across all Ente apps, will be scheduled for deletion, and your account will be permanently deleted."),
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
            MessageLookupByLibrary.simpleMessage("Delete from Ente"),
        "deleteItemCount": m21,
        "deleteLocation":
            MessageLookupByLibrary.simpleMessage("Delete location"),
        "deleteMultipleAlbumDialog": m22,
        "deletePhotos": MessageLookupByLibrary.simpleMessage("Delete photos"),
        "deleteProgress": m23,
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
        "developerSettings":
            MessageLookupByLibrary.simpleMessage("Developer settings"),
        "developerSettingsWarning": MessageLookupByLibrary.simpleMessage(
            "Are you sure that you want to modify Developer settings?"),
        "deviceCodeHint":
            MessageLookupByLibrary.simpleMessage("Enter the code"),
        "deviceFilesAutoUploading": MessageLookupByLibrary.simpleMessage(
            "Files added to this device album will automatically get uploaded to Ente."),
        "deviceLock": MessageLookupByLibrary.simpleMessage("Device lock"),
        "deviceLockExplanation": MessageLookupByLibrary.simpleMessage(
            "Disable the device screen lock when Ente is in the foreground and there is a backup in progress. This is normally not needed, but may help big uploads and initial imports of large libraries complete faster."),
        "deviceNotFound":
            MessageLookupByLibrary.simpleMessage("Device not found"),
        "didYouKnow": MessageLookupByLibrary.simpleMessage("Did you know?"),
        "different": MessageLookupByLibrary.simpleMessage("Different"),
        "disableAutoLock":
            MessageLookupByLibrary.simpleMessage("Disable auto lock"),
        "disableDownloadWarningBody": MessageLookupByLibrary.simpleMessage(
            "Viewers can still take screenshots or save a copy of your photos using external tools"),
        "disableDownloadWarningTitle":
            MessageLookupByLibrary.simpleMessage("Please note"),
        "disableLinkMessage": m24,
        "disableTwofactor":
            MessageLookupByLibrary.simpleMessage("Disable two-factor"),
        "disablingTwofactorAuthentication":
            MessageLookupByLibrary.simpleMessage(
                "Disabling two-factor authentication..."),
        "discord": MessageLookupByLibrary.simpleMessage("Discord"),
        "discover": MessageLookupByLibrary.simpleMessage("Discover"),
        "discover_babies": MessageLookupByLibrary.simpleMessage("Babies"),
        "discover_celebrations":
            MessageLookupByLibrary.simpleMessage("Celebrations"),
        "discover_food": MessageLookupByLibrary.simpleMessage("Food"),
        "discover_greenery": MessageLookupByLibrary.simpleMessage("Greenery"),
        "discover_hills": MessageLookupByLibrary.simpleMessage("Hills"),
        "discover_identity": MessageLookupByLibrary.simpleMessage("Identity"),
        "discover_memes": MessageLookupByLibrary.simpleMessage("Memes"),
        "discover_notes": MessageLookupByLibrary.simpleMessage("Notes"),
        "discover_pets": MessageLookupByLibrary.simpleMessage("Pets"),
        "discover_receipts": MessageLookupByLibrary.simpleMessage("Receipts"),
        "discover_screenshots":
            MessageLookupByLibrary.simpleMessage("Screenshots"),
        "discover_selfies": MessageLookupByLibrary.simpleMessage("Selfies"),
        "discover_sunset": MessageLookupByLibrary.simpleMessage("Sunset"),
        "discover_visiting_cards":
            MessageLookupByLibrary.simpleMessage("Visiting Cards"),
        "discover_wallpapers":
            MessageLookupByLibrary.simpleMessage("Wallpapers"),
        "dismiss": MessageLookupByLibrary.simpleMessage("Dismiss"),
        "distanceInKMUnit": MessageLookupByLibrary.simpleMessage("km"),
        "doNotSignOut": MessageLookupByLibrary.simpleMessage("Do not sign out"),
        "doThisLater": MessageLookupByLibrary.simpleMessage("Do this later"),
        "doYouWantToDiscardTheEditsYouHaveMade":
            MessageLookupByLibrary.simpleMessage(
                "Do you want to discard the edits you have made?"),
        "done": MessageLookupByLibrary.simpleMessage("Done"),
        "dontSave": MessageLookupByLibrary.simpleMessage("Don\'t save"),
        "doubleYourStorage":
            MessageLookupByLibrary.simpleMessage("Double your storage"),
        "download": MessageLookupByLibrary.simpleMessage("Download"),
        "downloadFailed":
            MessageLookupByLibrary.simpleMessage("Download failed"),
        "downloading": MessageLookupByLibrary.simpleMessage("Downloading..."),
        "dropSupportEmail": m25,
        "duplicateFileCountWithStorageSaved": m26,
        "duplicateItemsGroup": m27,
        "edit": MessageLookupByLibrary.simpleMessage("Edit"),
        "editAutoAddPeople":
            MessageLookupByLibrary.simpleMessage("Edit auto-add people"),
        "editEmailAlreadyLinked": m28,
        "editLocation": MessageLookupByLibrary.simpleMessage("Edit location"),
        "editLocationTagTitle":
            MessageLookupByLibrary.simpleMessage("Edit location"),
        "editPerson": MessageLookupByLibrary.simpleMessage("Edit person"),
        "editTime": MessageLookupByLibrary.simpleMessage("Edit time"),
        "editsSaved": MessageLookupByLibrary.simpleMessage("Edits saved"),
        "editsToLocationWillOnlyBeSeenWithinEnte":
            MessageLookupByLibrary.simpleMessage(
                "Edits to location will only be seen within Ente"),
        "eligible": MessageLookupByLibrary.simpleMessage("eligible"),
        "email": MessageLookupByLibrary.simpleMessage("Email"),
        "emailAlreadyRegistered":
            MessageLookupByLibrary.simpleMessage("Email already registered."),
        "emailChangedTo": m29,
        "emailDoesNotHaveEnteAccount": m30,
        "emailNoEnteAccount": m31,
        "emailNotRegistered":
            MessageLookupByLibrary.simpleMessage("Email not registered."),
        "emailVerificationToggle":
            MessageLookupByLibrary.simpleMessage("Email verification"),
        "emailYourLogs":
            MessageLookupByLibrary.simpleMessage("Email your logs"),
        "embracingThem": m32,
        "emergencyContacts":
            MessageLookupByLibrary.simpleMessage("Emergency Contacts"),
        "empty": MessageLookupByLibrary.simpleMessage("Empty"),
        "emptyTrash": MessageLookupByLibrary.simpleMessage("Empty trash?"),
        "enable": MessageLookupByLibrary.simpleMessage("Enable"),
        "enableMLIndexingDesc": MessageLookupByLibrary.simpleMessage(
            "Ente supports on-device machine learning for face recognition, magic search and other advanced search features"),
        "enableMachineLearningBanner": MessageLookupByLibrary.simpleMessage(
            "Enable machine learning for magic search and face recognition"),
        "enableMaps": MessageLookupByLibrary.simpleMessage("Enable Maps"),
        "enableMapsDesc": MessageLookupByLibrary.simpleMessage(
            "This will show your photos on a world map.\n\nThis map is hosted by Open Street Map, and the exact locations of your photos are never shared.\n\nYou can disable this feature anytime from Settings."),
        "enabled": MessageLookupByLibrary.simpleMessage("Enabled"),
        "encryptingBackup":
            MessageLookupByLibrary.simpleMessage("Encrypting backup..."),
        "encryption": MessageLookupByLibrary.simpleMessage("Encryption"),
        "encryptionKeys":
            MessageLookupByLibrary.simpleMessage("Encryption keys"),
        "endpointUpdatedMessage": MessageLookupByLibrary.simpleMessage(
            "Endpoint updated successfully"),
        "endtoendEncryptedByDefault": MessageLookupByLibrary.simpleMessage(
            "End-to-end encrypted by default"),
        "enteCanEncryptAndPreserveFilesOnlyIfYouGrant":
            MessageLookupByLibrary.simpleMessage(
                "Ente can encrypt and preserve files only if you grant access to them"),
        "entePhotosPerm": MessageLookupByLibrary.simpleMessage(
            "Ente <i>needs permission to</i> preserve your photos"),
        "enteSubscriptionPitch": MessageLookupByLibrary.simpleMessage(
            "Ente preserves your memories, so they\'re always available to you, even if you lose your device."),
        "enteSubscriptionShareWithFamily": MessageLookupByLibrary.simpleMessage(
            "Your family can be added to your plan as well."),
        "enterAlbumName":
            MessageLookupByLibrary.simpleMessage("Enter album name"),
        "enterCode": MessageLookupByLibrary.simpleMessage("Enter code"),
        "enterCodeDescription": MessageLookupByLibrary.simpleMessage(
            "Enter the code provided by your friend to claim free storage for both of you"),
        "enterDateOfBirth":
            MessageLookupByLibrary.simpleMessage("Birthday (optional)"),
        "enterEmail": MessageLookupByLibrary.simpleMessage("Enter email"),
        "enterFileName":
            MessageLookupByLibrary.simpleMessage("Enter file name"),
        "enterName": MessageLookupByLibrary.simpleMessage("Enter name"),
        "enterNewPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Enter a new password we can use to encrypt your data"),
        "enterPassword": MessageLookupByLibrary.simpleMessage("Enter password"),
        "enterPasswordToEncrypt": MessageLookupByLibrary.simpleMessage(
            "Enter a password we can use to encrypt your data"),
        "enterPersonName":
            MessageLookupByLibrary.simpleMessage("Enter person name"),
        "enterPin": MessageLookupByLibrary.simpleMessage("Enter PIN"),
        "enterReferralCode":
            MessageLookupByLibrary.simpleMessage("Enter referral code"),
        "enterThe6digitCodeFromnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Enter the 6-digit code from\nyour authenticator app"),
        "enterValidEmail": MessageLookupByLibrary.simpleMessage(
            "Please enter a valid email address."),
        "enterYourEmailAddress":
            MessageLookupByLibrary.simpleMessage("Enter your email address"),
        "enterYourNewEmailAddress": MessageLookupByLibrary.simpleMessage(
            "Enter your new email address"),
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
        "extraPhotosFound":
            MessageLookupByLibrary.simpleMessage("Extra photos found"),
        "extraPhotosFoundFor": m33,
        "faceNotClusteredYet": MessageLookupByLibrary.simpleMessage(
            "Face not clustered yet, please come back later"),
        "faceRecognition":
            MessageLookupByLibrary.simpleMessage("Face recognition"),
        "faceThumbnailGenerationFailed": MessageLookupByLibrary.simpleMessage(
            "Unable to generate face thumbnails"),
        "faces": MessageLookupByLibrary.simpleMessage("Faces"),
        "failed": MessageLookupByLibrary.simpleMessage("Failed"),
        "failedToApplyCode":
            MessageLookupByLibrary.simpleMessage("Failed to apply code"),
        "failedToCancel":
            MessageLookupByLibrary.simpleMessage("Failed to cancel"),
        "failedToDownloadVideo":
            MessageLookupByLibrary.simpleMessage("Failed to download video"),
        "failedToFetchActiveSessions": MessageLookupByLibrary.simpleMessage(
            "Failed to fetch active sessions"),
        "failedToFetchOriginalForEdit": MessageLookupByLibrary.simpleMessage(
            "Failed to fetch original for edit"),
        "failedToFetchReferralDetails": MessageLookupByLibrary.simpleMessage(
            "Unable to fetch referral details. Please try again later."),
        "failedToLoadAlbums":
            MessageLookupByLibrary.simpleMessage("Failed to load albums"),
        "failedToPlayVideo":
            MessageLookupByLibrary.simpleMessage("Failed to play video"),
        "failedToRefreshStripeSubscription":
            MessageLookupByLibrary.simpleMessage(
                "Failed to refresh subscription"),
        "failedToRenew":
            MessageLookupByLibrary.simpleMessage("Failed to renew"),
        "failedToVerifyPaymentStatus": MessageLookupByLibrary.simpleMessage(
            "Failed to verify payment status"),
        "familyPlanOverview": MessageLookupByLibrary.simpleMessage(
            "Add 5 family members to your existing plan without paying extra.\n\nEach member gets their own private space, and cannot see each other\'s files unless they\'re shared.\n\nFamily plans are available to customers who have a paid Ente subscription.\n\nSubscribe now to get started!"),
        "familyPlanPortalTitle": MessageLookupByLibrary.simpleMessage("Family"),
        "familyPlans": MessageLookupByLibrary.simpleMessage("Family plans"),
        "faq": MessageLookupByLibrary.simpleMessage("FAQ"),
        "faqs": MessageLookupByLibrary.simpleMessage("FAQs"),
        "favorite": MessageLookupByLibrary.simpleMessage("Favorite"),
        "feastingWithThem": m34,
        "feedback": MessageLookupByLibrary.simpleMessage("Feedback"),
        "file": MessageLookupByLibrary.simpleMessage("File"),
        "fileAnalysisFailed":
            MessageLookupByLibrary.simpleMessage("Unable to analyze file"),
        "fileFailedToSaveToGallery": MessageLookupByLibrary.simpleMessage(
            "Failed to save file to gallery"),
        "fileInfoAddDescHint":
            MessageLookupByLibrary.simpleMessage("Add a description..."),
        "fileNotUploadedYet":
            MessageLookupByLibrary.simpleMessage("File not uploaded yet"),
        "fileSavedToGallery":
            MessageLookupByLibrary.simpleMessage("File saved to gallery"),
        "fileTypes": MessageLookupByLibrary.simpleMessage("File types"),
        "fileTypesAndNames":
            MessageLookupByLibrary.simpleMessage("File types and names"),
        "filesBackedUpFromDevice": m35,
        "filesBackedUpInAlbum": m36,
        "filesDeleted": MessageLookupByLibrary.simpleMessage("Files deleted"),
        "filesSavedToGallery":
            MessageLookupByLibrary.simpleMessage("Files saved to gallery"),
        "findPeopleByName":
            MessageLookupByLibrary.simpleMessage("Find people quickly by name"),
        "findThemQuickly":
            MessageLookupByLibrary.simpleMessage("Find them quickly"),
        "flip": MessageLookupByLibrary.simpleMessage("Flip"),
        "food": MessageLookupByLibrary.simpleMessage("Culinary delight"),
        "forYourMemories":
            MessageLookupByLibrary.simpleMessage("for your memories"),
        "forgotPassword":
            MessageLookupByLibrary.simpleMessage("Forgot password"),
        "foundFaces": MessageLookupByLibrary.simpleMessage("Found faces"),
        "freeStorageClaimed":
            MessageLookupByLibrary.simpleMessage("Free storage claimed"),
        "freeStorageOnReferralSuccess": m37,
        "freeStorageUsable":
            MessageLookupByLibrary.simpleMessage("Free storage usable"),
        "freeTrial": MessageLookupByLibrary.simpleMessage("Free trial"),
        "freeTrialValidTill": m38,
        "freeUpAccessPostDelete": m39,
        "freeUpAmount": m40,
        "freeUpDeviceSpace":
            MessageLookupByLibrary.simpleMessage("Free up device space"),
        "freeUpDeviceSpaceDesc": MessageLookupByLibrary.simpleMessage(
            "Save space on your device by clearing files that have been already backed up."),
        "freeUpSpace": MessageLookupByLibrary.simpleMessage("Free up space"),
        "freeUpSpaceSaving": m41,
        "gallery": MessageLookupByLibrary.simpleMessage("Gallery"),
        "galleryMemoryLimitInfo": MessageLookupByLibrary.simpleMessage(
            "Up to 1000 memories shown in gallery"),
        "general": MessageLookupByLibrary.simpleMessage("General"),
        "generatingEncryptionKeys": MessageLookupByLibrary.simpleMessage(
            "Generating encryption keys..."),
        "genericProgress": m42,
        "gettingReady": MessageLookupByLibrary.simpleMessage("Getting ready"),
        "goToSettings": MessageLookupByLibrary.simpleMessage("Go to settings"),
        "googlePlayId": MessageLookupByLibrary.simpleMessage("Google Play ID"),
        "grantFullAccessPrompt": MessageLookupByLibrary.simpleMessage(
            "Please allow access to all photos in the Settings app"),
        "grantPermission":
            MessageLookupByLibrary.simpleMessage("Grant permission"),
        "greenery": MessageLookupByLibrary.simpleMessage("The green life"),
        "groupNearbyPhotos":
            MessageLookupByLibrary.simpleMessage("Group nearby photos"),
        "guestView": MessageLookupByLibrary.simpleMessage("Guest view"),
        "guestViewEnablePreSteps": MessageLookupByLibrary.simpleMessage(
            "To enable guest view, please setup device passcode or screen lock in your system settings."),
        "happyBirthday":
            MessageLookupByLibrary.simpleMessage("Happy birthday! 🥳"),
        "hearUsExplanation": MessageLookupByLibrary.simpleMessage(
            "We don\'t track app installs. It\'d help if you told us where you found us!"),
        "hearUsWhereTitle": MessageLookupByLibrary.simpleMessage(
            "How did you hear about Ente? (optional)"),
        "help": MessageLookupByLibrary.simpleMessage("Help"),
        "hidden": MessageLookupByLibrary.simpleMessage("Hidden"),
        "hide": MessageLookupByLibrary.simpleMessage("Hide"),
        "hideContent": MessageLookupByLibrary.simpleMessage("Hide content"),
        "hideContentDescriptionAndroid": MessageLookupByLibrary.simpleMessage(
            "Hides app content in the app switcher and disables screenshots"),
        "hideContentDescriptionIos": MessageLookupByLibrary.simpleMessage(
            "Hides app content in the app switcher"),
        "hideSharedItemsFromHomeGallery": MessageLookupByLibrary.simpleMessage(
            "Hide shared items from home gallery"),
        "hiding": MessageLookupByLibrary.simpleMessage("Hiding..."),
        "hikingWithThem": m43,
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
        "ignore": MessageLookupByLibrary.simpleMessage("Ignore"),
        "ignoreUpdate": MessageLookupByLibrary.simpleMessage("Ignore"),
        "ignored": MessageLookupByLibrary.simpleMessage("ignored"),
        "ignoredFolderUploadReason": MessageLookupByLibrary.simpleMessage(
            "Some files in this album are ignored from upload because they had previously been deleted from Ente."),
        "imageNotAnalyzed":
            MessageLookupByLibrary.simpleMessage("Image not analyzed"),
        "immediately": MessageLookupByLibrary.simpleMessage("Immediately"),
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
        "indexedItems": MessageLookupByLibrary.simpleMessage("Indexed items"),
        "indexingPausedStatusDescription": MessageLookupByLibrary.simpleMessage(
            "Indexing is paused. It will automatically resume when the device is ready. The device is considered ready when its battery level, battery health, and thermal status are within a healthy range."),
        "ineligible": MessageLookupByLibrary.simpleMessage("Ineligible"),
        "info": MessageLookupByLibrary.simpleMessage("Info"),
        "insecureDevice":
            MessageLookupByLibrary.simpleMessage("Insecure device"),
        "installManually":
            MessageLookupByLibrary.simpleMessage("Install manually"),
        "invalidEmailAddress":
            MessageLookupByLibrary.simpleMessage("Invalid email address"),
        "invalidEndpoint":
            MessageLookupByLibrary.simpleMessage("Invalid endpoint"),
        "invalidEndpointMessage": MessageLookupByLibrary.simpleMessage(
            "Sorry, the endpoint you entered is invalid. Please enter a valid endpoint and try again."),
        "invalidKey": MessageLookupByLibrary.simpleMessage("Invalid key"),
        "invalidRecoveryKey": MessageLookupByLibrary.simpleMessage(
            "The recovery key you entered is not valid. Please make sure it contains 24 words, and check the spelling of each.\n\nIf you entered an older recovery code, make sure it is 64 characters long, and check each of them."),
        "invite": MessageLookupByLibrary.simpleMessage("Invite"),
        "inviteToEnte": MessageLookupByLibrary.simpleMessage("Invite to Ente"),
        "inviteYourFriends":
            MessageLookupByLibrary.simpleMessage("Invite your friends"),
        "inviteYourFriendsToEnte":
            MessageLookupByLibrary.simpleMessage("Invite your friends to Ente"),
        "itLooksLikeSomethingWentWrongPleaseRetryAfterSome":
            MessageLookupByLibrary.simpleMessage(
                "It looks like something went wrong. Please retry after some time. If the error persists, please contact our support team."),
        "itemCount": m44,
        "itemsShowTheNumberOfDaysRemainingBeforePermanentDeletion":
            MessageLookupByLibrary.simpleMessage(
                "Items show the number of days remaining before permanent deletion"),
        "itemsWillBeRemovedFromAlbum": MessageLookupByLibrary.simpleMessage(
            "Selected items will be removed from this album"),
        "join": MessageLookupByLibrary.simpleMessage("Join"),
        "joinAlbum": MessageLookupByLibrary.simpleMessage("Join album"),
        "joinAlbumConfirmationDialogBody": MessageLookupByLibrary.simpleMessage(
            "Joining an album will make your email visible to its participants."),
        "joinAlbumSubtext":
            MessageLookupByLibrary.simpleMessage("to view and add your photos"),
        "joinAlbumSubtextViewer": MessageLookupByLibrary.simpleMessage(
            "to add this to shared albums"),
        "joinDiscord": MessageLookupByLibrary.simpleMessage("Join Discord"),
        "keepPhotos": MessageLookupByLibrary.simpleMessage("Keep Photos"),
        "kiloMeterUnit": MessageLookupByLibrary.simpleMessage("km"),
        "kindlyHelpUsWithThisInformation": MessageLookupByLibrary.simpleMessage(
            "Kindly help us with this information"),
        "language": MessageLookupByLibrary.simpleMessage("Language"),
        "lastTimeWithThem": m45,
        "lastUpdated": MessageLookupByLibrary.simpleMessage("Last updated"),
        "lastYearsTrip":
            MessageLookupByLibrary.simpleMessage("Last year\'s trip"),
        "leave": MessageLookupByLibrary.simpleMessage("Leave"),
        "leaveAlbum": MessageLookupByLibrary.simpleMessage("Leave album"),
        "leaveFamily": MessageLookupByLibrary.simpleMessage("Leave family"),
        "leaveSharedAlbum":
            MessageLookupByLibrary.simpleMessage("Leave shared album?"),
        "left": MessageLookupByLibrary.simpleMessage("Left"),
        "legacy": MessageLookupByLibrary.simpleMessage("Legacy"),
        "legacyAccounts":
            MessageLookupByLibrary.simpleMessage("Legacy accounts"),
        "legacyInvite": m46,
        "legacyPageDesc": MessageLookupByLibrary.simpleMessage(
            "Legacy allows trusted contacts to access your account in your absence."),
        "legacyPageDesc2": MessageLookupByLibrary.simpleMessage(
            "Trusted contacts can initiate account recovery, and if not blocked within 30 days, reset your password and access your account."),
        "light": MessageLookupByLibrary.simpleMessage("Light"),
        "lightTheme": MessageLookupByLibrary.simpleMessage("Light"),
        "link": MessageLookupByLibrary.simpleMessage("Link"),
        "linkCopiedToClipboard":
            MessageLookupByLibrary.simpleMessage("Link copied to clipboard"),
        "linkDeviceLimit": MessageLookupByLibrary.simpleMessage("Device limit"),
        "linkEmail": MessageLookupByLibrary.simpleMessage("Link email"),
        "linkEmailToContactBannerCaption":
            MessageLookupByLibrary.simpleMessage("for faster sharing"),
        "linkEnabled": MessageLookupByLibrary.simpleMessage("Enabled"),
        "linkExpired": MessageLookupByLibrary.simpleMessage("Expired"),
        "linkExpiresOn": m47,
        "linkExpiry": MessageLookupByLibrary.simpleMessage("Link expiry"),
        "linkHasExpired":
            MessageLookupByLibrary.simpleMessage("Link has expired"),
        "linkNeverExpires": MessageLookupByLibrary.simpleMessage("Never"),
        "linkPerson": MessageLookupByLibrary.simpleMessage("Link person"),
        "linkPersonCaption": MessageLookupByLibrary.simpleMessage(
            "for better sharing experience"),
        "linkPersonToEmail": m48,
        "linkPersonToEmailConfirmation": m49,
        "livePhotos": MessageLookupByLibrary.simpleMessage("Live Photos"),
        "loadMessage1": MessageLookupByLibrary.simpleMessage(
            "You can share your subscription with your family"),
        "loadMessage2": MessageLookupByLibrary.simpleMessage(
            "We have preserved over 200 million memories so far"),
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
        "loadingModel":
            MessageLookupByLibrary.simpleMessage("Downloading models..."),
        "loadingYourPhotos":
            MessageLookupByLibrary.simpleMessage("Loading your photos..."),
        "localGallery": MessageLookupByLibrary.simpleMessage("Local gallery"),
        "localIndexing": MessageLookupByLibrary.simpleMessage("Local indexing"),
        "localSyncErrorMessage": MessageLookupByLibrary.simpleMessage(
            "Looks like something went wrong since local photos sync is taking more time than expected. Please reach out to our support team"),
        "location": MessageLookupByLibrary.simpleMessage("Location"),
        "locationName": MessageLookupByLibrary.simpleMessage("Location name"),
        "locationTagFeatureDescription": MessageLookupByLibrary.simpleMessage(
            "A location tag groups all photos that were taken within some radius of a photo"),
        "locations": MessageLookupByLibrary.simpleMessage("Locations"),
        "lockButtonLabel": MessageLookupByLibrary.simpleMessage("Lock"),
        "lockscreen": MessageLookupByLibrary.simpleMessage("Lockscreen"),
        "logInLabel": MessageLookupByLibrary.simpleMessage("Log in"),
        "loggingOut": MessageLookupByLibrary.simpleMessage("Logging out..."),
        "loginSessionExpired":
            MessageLookupByLibrary.simpleMessage("Session expired"),
        "loginSessionExpiredDetails": MessageLookupByLibrary.simpleMessage(
            "Your session has expired. Please login again."),
        "loginTerms": MessageLookupByLibrary.simpleMessage(
            "By clicking log in, I agree to the <u-terms>terms of service</u-terms> and <u-policy>privacy policy</u-policy>"),
        "loginWithTOTP":
            MessageLookupByLibrary.simpleMessage("Login with TOTP"),
        "logout": MessageLookupByLibrary.simpleMessage("Logout"),
        "logsDialogBody": MessageLookupByLibrary.simpleMessage(
            "This will send across logs to help us debug your issue. Please note that file names will be included to help track issues with specific files."),
        "longPressAnEmailToVerifyEndToEndEncryption":
            MessageLookupByLibrary.simpleMessage(
                "Long press an email to verify end to end encryption."),
        "longpressOnAnItemToViewInFullscreen":
            MessageLookupByLibrary.simpleMessage(
                "Long-press on an item to view in full-screen"),
        "lookBackOnYourMemories": MessageLookupByLibrary.simpleMessage(
            "Look back on your memories 🌄"),
        "loopVideoOff": MessageLookupByLibrary.simpleMessage("Loop video off"),
        "loopVideoOn": MessageLookupByLibrary.simpleMessage("Loop video on"),
        "lostDevice": MessageLookupByLibrary.simpleMessage("Lost device?"),
        "machineLearning":
            MessageLookupByLibrary.simpleMessage("Machine learning"),
        "magicSearch": MessageLookupByLibrary.simpleMessage("Magic search"),
        "magicSearchHint": MessageLookupByLibrary.simpleMessage(
            "Magic search allows to search photos by their contents, e.g. \'flower\', \'red car\', \'identity documents\'"),
        "manage": MessageLookupByLibrary.simpleMessage("Manage"),
        "manageDeviceStorage":
            MessageLookupByLibrary.simpleMessage("Manage device cache"),
        "manageDeviceStorageDesc": MessageLookupByLibrary.simpleMessage(
            "Review and clear local cache storage."),
        "manageFamily": MessageLookupByLibrary.simpleMessage("Manage Family"),
        "manageLink": MessageLookupByLibrary.simpleMessage("Manage link"),
        "manageParticipants": MessageLookupByLibrary.simpleMessage("Manage"),
        "manageSubscription":
            MessageLookupByLibrary.simpleMessage("Manage subscription"),
        "manualPairDesc": MessageLookupByLibrary.simpleMessage(
            "Pair with PIN works with any screen you wish to view your album on."),
        "map": MessageLookupByLibrary.simpleMessage("Map"),
        "maps": MessageLookupByLibrary.simpleMessage("Maps"),
        "mastodon": MessageLookupByLibrary.simpleMessage("Mastodon"),
        "matrix": MessageLookupByLibrary.simpleMessage("Matrix"),
        "me": MessageLookupByLibrary.simpleMessage("Me"),
        "memories": MessageLookupByLibrary.simpleMessage("Memories"),
        "memoriesWidgetDesc": MessageLookupByLibrary.simpleMessage(
            "Select the kind of memories you wish to see on your homescreen."),
        "memoryCount": m50,
        "merchandise": MessageLookupByLibrary.simpleMessage("Merchandise"),
        "merge": MessageLookupByLibrary.simpleMessage("Merge"),
        "mergeWithExisting":
            MessageLookupByLibrary.simpleMessage("Merge with existing"),
        "mergedPhotos": MessageLookupByLibrary.simpleMessage("Merged photos"),
        "mlConsent":
            MessageLookupByLibrary.simpleMessage("Enable machine learning"),
        "mlConsentConfirmation": MessageLookupByLibrary.simpleMessage(
            "I understand, and wish to enable machine learning"),
        "mlConsentDescription": MessageLookupByLibrary.simpleMessage(
            "If you enable machine learning, Ente will extract information like face geometry from files, including those shared with you.\n\nThis will happen on your device, and any generated biometric information will be end-to-end encrypted."),
        "mlConsentPrivacy": MessageLookupByLibrary.simpleMessage(
            "Please click here for more details about this feature in our privacy policy"),
        "mlConsentTitle":
            MessageLookupByLibrary.simpleMessage("Enable machine learning?"),
        "mlIndexingDescription": MessageLookupByLibrary.simpleMessage(
            "Please note that machine learning will result in a higher bandwidth and battery usage until all items are indexed. Consider using the desktop app for faster indexing, all results will be synced automatically."),
        "mobileWebDesktop":
            MessageLookupByLibrary.simpleMessage("Mobile, Web, Desktop"),
        "moderateStrength": MessageLookupByLibrary.simpleMessage("Moderate"),
        "modifyYourQueryOrTrySearchingFor":
            MessageLookupByLibrary.simpleMessage(
                "Modify your query, or try searching for"),
        "moments": MessageLookupByLibrary.simpleMessage("Moments"),
        "month": MessageLookupByLibrary.simpleMessage("month"),
        "monthly": MessageLookupByLibrary.simpleMessage("Monthly"),
        "moon": MessageLookupByLibrary.simpleMessage("In the moonlight"),
        "moreDetails": MessageLookupByLibrary.simpleMessage("More details"),
        "mostRecent": MessageLookupByLibrary.simpleMessage("Most recent"),
        "mostRelevant": MessageLookupByLibrary.simpleMessage("Most relevant"),
        "mountains": MessageLookupByLibrary.simpleMessage("Over the hills"),
        "moveItem": m51,
        "moveSelectedPhotosToOneDate": MessageLookupByLibrary.simpleMessage(
            "Move selected photos to one date"),
        "moveToAlbum": MessageLookupByLibrary.simpleMessage("Move to album"),
        "moveToHiddenAlbum":
            MessageLookupByLibrary.simpleMessage("Move to hidden album"),
        "movedSuccessfullyTo": m52,
        "movedToTrash": MessageLookupByLibrary.simpleMessage("Moved to trash"),
        "movingFilesToAlbum":
            MessageLookupByLibrary.simpleMessage("Moving files to album..."),
        "name": MessageLookupByLibrary.simpleMessage("Name"),
        "nameTheAlbum": MessageLookupByLibrary.simpleMessage("Name the album"),
        "networkConnectionRefusedErr": MessageLookupByLibrary.simpleMessage(
            "Unable to connect to Ente, please retry after sometime. If the error persists, please contact support."),
        "networkHostLookUpErr": MessageLookupByLibrary.simpleMessage(
            "Unable to connect to Ente, please check your network settings and contact support if the error persists."),
        "never": MessageLookupByLibrary.simpleMessage("Never"),
        "newAlbum": MessageLookupByLibrary.simpleMessage("New album"),
        "newLocation": MessageLookupByLibrary.simpleMessage("New location"),
        "newPerson": MessageLookupByLibrary.simpleMessage("New person"),
        "newPhotosEmoji": MessageLookupByLibrary.simpleMessage(" new 📸"),
        "newRange": MessageLookupByLibrary.simpleMessage("New range"),
        "newToEnte": MessageLookupByLibrary.simpleMessage("New to Ente"),
        "newest": MessageLookupByLibrary.simpleMessage("Newest"),
        "next": MessageLookupByLibrary.simpleMessage("Next"),
        "no": MessageLookupByLibrary.simpleMessage("No"),
        "noAlbumsSharedByYouYet":
            MessageLookupByLibrary.simpleMessage("No albums shared by you yet"),
        "noDeviceFound":
            MessageLookupByLibrary.simpleMessage("No device found"),
        "noDeviceLimit": MessageLookupByLibrary.simpleMessage("None"),
        "noDeviceThatCanBeDeleted": MessageLookupByLibrary.simpleMessage(
            "You\'ve no files on this device that can be deleted"),
        "noDuplicates": MessageLookupByLibrary.simpleMessage("✨ No duplicates"),
        "noEnteAccountExclamation":
            MessageLookupByLibrary.simpleMessage("No Ente account!"),
        "noExifData": MessageLookupByLibrary.simpleMessage("No EXIF data"),
        "noFacesFound": MessageLookupByLibrary.simpleMessage("No faces found"),
        "noHiddenPhotosOrVideos":
            MessageLookupByLibrary.simpleMessage("No hidden photos or videos"),
        "noImagesWithLocation":
            MessageLookupByLibrary.simpleMessage("No images with location"),
        "noInternetConnection":
            MessageLookupByLibrary.simpleMessage("No internet connection"),
        "noPhotosAreBeingBackedUpRightNow":
            MessageLookupByLibrary.simpleMessage(
                "No photos are being backed up right now"),
        "noPhotosFoundHere":
            MessageLookupByLibrary.simpleMessage("No photos found here"),
        "noQuickLinksSelected":
            MessageLookupByLibrary.simpleMessage("No quick links selected"),
        "noRecoveryKey":
            MessageLookupByLibrary.simpleMessage("No recovery key?"),
        "noRecoveryKeyNoDecryption": MessageLookupByLibrary.simpleMessage(
            "Due to the nature of our end-to-end encryption protocol, your data cannot be decrypted without your password or recovery key"),
        "noResults": MessageLookupByLibrary.simpleMessage("No results"),
        "noResultsFound":
            MessageLookupByLibrary.simpleMessage("No results found"),
        "noSuggestionsForPerson": m53,
        "noSystemLockFound":
            MessageLookupByLibrary.simpleMessage("No system lock found"),
        "notPersonLabel": m54,
        "notThisPerson":
            MessageLookupByLibrary.simpleMessage("Not this person?"),
        "nothingSharedWithYouYet":
            MessageLookupByLibrary.simpleMessage("Nothing shared with you yet"),
        "nothingToSeeHere":
            MessageLookupByLibrary.simpleMessage("Nothing to see here! 👀"),
        "notifications": MessageLookupByLibrary.simpleMessage("Notifications"),
        "ok": MessageLookupByLibrary.simpleMessage("Ok"),
        "onDevice": MessageLookupByLibrary.simpleMessage("On device"),
        "onEnte": MessageLookupByLibrary.simpleMessage(
            "On <branding>ente</branding>"),
        "onTheRoad": MessageLookupByLibrary.simpleMessage("On the road again"),
        "onThisDay": MessageLookupByLibrary.simpleMessage("On this day"),
        "onThisDayMemories":
            MessageLookupByLibrary.simpleMessage("On this day memories"),
        "onThisDayNotificationExplanation": MessageLookupByLibrary.simpleMessage(
            "Receive reminders about memories from this day in previous years."),
        "onlyFamilyAdminCanChangeCode": m55,
        "onlyThem": MessageLookupByLibrary.simpleMessage("Only them"),
        "oops": MessageLookupByLibrary.simpleMessage("Oops"),
        "oopsCouldNotSaveEdits":
            MessageLookupByLibrary.simpleMessage("Oops, could not save edits"),
        "oopsSomethingWentWrong":
            MessageLookupByLibrary.simpleMessage("Oops, something went wrong"),
        "openAlbumInBrowser":
            MessageLookupByLibrary.simpleMessage("Open album in browser"),
        "openAlbumInBrowserTitle": MessageLookupByLibrary.simpleMessage(
            "Please use the web app to add photos to this album"),
        "openFile": MessageLookupByLibrary.simpleMessage("Open file"),
        "openSettings": MessageLookupByLibrary.simpleMessage("Open Settings"),
        "openTheItem": MessageLookupByLibrary.simpleMessage("• Open the item"),
        "openstreetmapContributors":
            MessageLookupByLibrary.simpleMessage("OpenStreetMap contributors"),
        "optionalAsShortAsYouLike": MessageLookupByLibrary.simpleMessage(
            "Optional, as short as you like..."),
        "orMergeWithExistingPerson":
            MessageLookupByLibrary.simpleMessage("Or merge with existing"),
        "orPickAnExistingOne":
            MessageLookupByLibrary.simpleMessage("Or pick an existing one"),
        "orPickFromYourContacts":
            MessageLookupByLibrary.simpleMessage("or pick from your contacts"),
        "otherDetectedFaces":
            MessageLookupByLibrary.simpleMessage("Other detected faces"),
        "pair": MessageLookupByLibrary.simpleMessage("Pair"),
        "pairWithPin": MessageLookupByLibrary.simpleMessage("Pair with PIN"),
        "pairingComplete":
            MessageLookupByLibrary.simpleMessage("Pairing complete"),
        "panorama": MessageLookupByLibrary.simpleMessage("Panorama"),
        "partyWithThem": m56,
        "passKeyPendingVerification": MessageLookupByLibrary.simpleMessage(
            "Verification is still pending"),
        "passkey": MessageLookupByLibrary.simpleMessage("Passkey"),
        "passkeyAuthTitle":
            MessageLookupByLibrary.simpleMessage("Passkey verification"),
        "password": MessageLookupByLibrary.simpleMessage("Password"),
        "passwordChangedSuccessfully": MessageLookupByLibrary.simpleMessage(
            "Password changed successfully"),
        "passwordLock": MessageLookupByLibrary.simpleMessage("Password lock"),
        "passwordStrength": m57,
        "passwordStrengthInfo": MessageLookupByLibrary.simpleMessage(
            "Password strength is calculated considering the length of the password, used characters, and whether or not the password appears in the top 10,000 most used passwords"),
        "passwordWarning": MessageLookupByLibrary.simpleMessage(
            "We don\'t store this password, so if you forget, <underline>we cannot decrypt your data</underline>"),
        "pastYearsMemories":
            MessageLookupByLibrary.simpleMessage("Past years\' memories"),
        "paymentDetails":
            MessageLookupByLibrary.simpleMessage("Payment details"),
        "paymentFailed": MessageLookupByLibrary.simpleMessage("Payment failed"),
        "paymentFailedMessage": MessageLookupByLibrary.simpleMessage(
            "Unfortunately your payment failed. Please contact support and we\'ll help you out!"),
        "paymentFailedTalkToProvider": m58,
        "pendingItems": MessageLookupByLibrary.simpleMessage("Pending items"),
        "pendingSync": MessageLookupByLibrary.simpleMessage("Pending sync"),
        "people": MessageLookupByLibrary.simpleMessage("People"),
        "peopleUsingYourCode":
            MessageLookupByLibrary.simpleMessage("People using your code"),
        "peopleWidgetDesc": MessageLookupByLibrary.simpleMessage(
            "Select the people you wish to see on your homescreen."),
        "permDeleteWarning": MessageLookupByLibrary.simpleMessage(
            "All items in trash will be permanently deleted\n\nThis action cannot be undone"),
        "permanentlyDelete":
            MessageLookupByLibrary.simpleMessage("Permanently delete"),
        "permanentlyDeleteFromDevice": MessageLookupByLibrary.simpleMessage(
            "Permanently delete from device?"),
        "personIsAge": m59,
        "personName": MessageLookupByLibrary.simpleMessage("Person name"),
        "personTurningAge": m60,
        "pets": MessageLookupByLibrary.simpleMessage("Furry companions"),
        "photoDescriptions":
            MessageLookupByLibrary.simpleMessage("Photo descriptions"),
        "photoGridSize":
            MessageLookupByLibrary.simpleMessage("Photo grid size"),
        "photoSmallCase": MessageLookupByLibrary.simpleMessage("photo"),
        "photocountPhotos": m61,
        "photos": MessageLookupByLibrary.simpleMessage("Photos"),
        "photosAddedByYouWillBeRemovedFromTheAlbum":
            MessageLookupByLibrary.simpleMessage(
                "Photos added by you will be removed from the album"),
        "photosCount": m62,
        "photosKeepRelativeTimeDifference":
            MessageLookupByLibrary.simpleMessage(
                "Photos keep relative time difference"),
        "pickCenterPoint":
            MessageLookupByLibrary.simpleMessage("Pick center point"),
        "pinAlbum": MessageLookupByLibrary.simpleMessage("Pin album"),
        "pinLock": MessageLookupByLibrary.simpleMessage("PIN lock"),
        "playOnTv": MessageLookupByLibrary.simpleMessage("Play album on TV"),
        "playOriginal": MessageLookupByLibrary.simpleMessage("Play original"),
        "playStoreFreeTrialValidTill": m63,
        "playStream": MessageLookupByLibrary.simpleMessage("Play stream"),
        "playstoreSubscription":
            MessageLookupByLibrary.simpleMessage("PlayStore subscription"),
        "pleaseCheckYourInternetConnectionAndTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Please check your internet connection and try again."),
        "pleaseContactSupportAndWeWillBeHappyToHelp":
            MessageLookupByLibrary.simpleMessage(
                "Please contact support@ente.io and we will be happy to help!"),
        "pleaseContactSupportIfTheProblemPersists":
            MessageLookupByLibrary.simpleMessage(
                "Please contact support if the problem persists"),
        "pleaseEmailUsAt": m64,
        "pleaseGrantPermissions":
            MessageLookupByLibrary.simpleMessage("Please grant permissions"),
        "pleaseLoginAgain":
            MessageLookupByLibrary.simpleMessage("Please login again"),
        "pleaseSelectQuickLinksToRemove": MessageLookupByLibrary.simpleMessage(
            "Please select quick links to remove"),
        "pleaseSendTheLogsTo": m65,
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
        "pleaseWaitThisWillTakeAWhile": MessageLookupByLibrary.simpleMessage(
            "Please wait, this will take a while."),
        "posingWithThem": m66,
        "preparingLogs":
            MessageLookupByLibrary.simpleMessage("Preparing logs..."),
        "preserveMore": MessageLookupByLibrary.simpleMessage("Preserve more"),
        "pressAndHoldToPlayVideo": MessageLookupByLibrary.simpleMessage(
            "Press and hold to play video"),
        "pressAndHoldToPlayVideoDetailed": MessageLookupByLibrary.simpleMessage(
            "Press and hold on the image to  play video"),
        "previous": MessageLookupByLibrary.simpleMessage("Previous"),
        "privacy": MessageLookupByLibrary.simpleMessage("Privacy"),
        "privacyPolicyTitle":
            MessageLookupByLibrary.simpleMessage("Privacy Policy"),
        "privateBackups":
            MessageLookupByLibrary.simpleMessage("Private backups"),
        "privateSharing":
            MessageLookupByLibrary.simpleMessage("Private sharing"),
        "proceed": MessageLookupByLibrary.simpleMessage("Proceed"),
        "processed": MessageLookupByLibrary.simpleMessage("Processed"),
        "processing": MessageLookupByLibrary.simpleMessage("Processing"),
        "processingImport": m67,
        "processingVideos":
            MessageLookupByLibrary.simpleMessage("Processing videos"),
        "publicLinkCreated":
            MessageLookupByLibrary.simpleMessage("Public link created"),
        "publicLinkEnabled":
            MessageLookupByLibrary.simpleMessage("Public link enabled"),
        "questionmark": MessageLookupByLibrary.simpleMessage("?"),
        "queued": MessageLookupByLibrary.simpleMessage("Queued"),
        "quickLinks": MessageLookupByLibrary.simpleMessage("Quick links"),
        "radius": MessageLookupByLibrary.simpleMessage("Radius"),
        "raiseTicket": MessageLookupByLibrary.simpleMessage("Raise ticket"),
        "rateTheApp": MessageLookupByLibrary.simpleMessage("Rate the app"),
        "rateUs": MessageLookupByLibrary.simpleMessage("Rate us"),
        "rateUsOnStore": m68,
        "reassignMe": MessageLookupByLibrary.simpleMessage("Reassign \"Me\""),
        "reassignedToName": m69,
        "reassigningLoading":
            MessageLookupByLibrary.simpleMessage("Reassigning..."),
        "receiveRemindersOnBirthdays": MessageLookupByLibrary.simpleMessage(
            "Receive reminders when it\'s someone\'s birthday. Tapping on the notification will take you to photos of the birthday person."),
        "recover": MessageLookupByLibrary.simpleMessage("Recover"),
        "recoverAccount":
            MessageLookupByLibrary.simpleMessage("Recover account"),
        "recoverButton": MessageLookupByLibrary.simpleMessage("Recover"),
        "recoveryAccount":
            MessageLookupByLibrary.simpleMessage("Recover account"),
        "recoveryInitiated":
            MessageLookupByLibrary.simpleMessage("Recovery initiated"),
        "recoveryInitiatedDesc": m70,
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
        "recoveryReady": m71,
        "recoverySuccessful":
            MessageLookupByLibrary.simpleMessage("Recovery successful!"),
        "recoveryWarning": MessageLookupByLibrary.simpleMessage(
            "A trusted contact is trying to access your account"),
        "recoveryWarningBody": m72,
        "recreatePasswordBody": MessageLookupByLibrary.simpleMessage(
            "The current device is not powerful enough to verify your password, but we can regenerate in a way that works with all devices.\n\nPlease login using your recovery key and regenerate your password (you can use the same one again if you wish)."),
        "recreatePasswordTitle":
            MessageLookupByLibrary.simpleMessage("Recreate password"),
        "reddit": MessageLookupByLibrary.simpleMessage("Reddit"),
        "reenterPassword":
            MessageLookupByLibrary.simpleMessage("Re-enter password"),
        "reenterPin": MessageLookupByLibrary.simpleMessage("Re-enter PIN"),
        "referFriendsAnd2xYourPlan": MessageLookupByLibrary.simpleMessage(
            "Refer friends and 2x your plan"),
        "referralStep1": MessageLookupByLibrary.simpleMessage(
            "1. Give this code to your friends"),
        "referralStep2": MessageLookupByLibrary.simpleMessage(
            "2. They sign up for a paid plan"),
        "referralStep3": m73,
        "referrals": MessageLookupByLibrary.simpleMessage("Referrals"),
        "referralsAreCurrentlyPaused": MessageLookupByLibrary.simpleMessage(
            "Referrals are currently paused"),
        "rejectRecovery":
            MessageLookupByLibrary.simpleMessage("Reject recovery"),
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
        "removeDuplicatesDesc": MessageLookupByLibrary.simpleMessage(
            "Review and remove files that are exact duplicates."),
        "removeFromAlbum":
            MessageLookupByLibrary.simpleMessage("Remove from album"),
        "removeFromAlbumTitle":
            MessageLookupByLibrary.simpleMessage("Remove from album?"),
        "removeFromFavorite":
            MessageLookupByLibrary.simpleMessage("Remove from favorites"),
        "removeInvite": MessageLookupByLibrary.simpleMessage("Remove invite"),
        "removeLink": MessageLookupByLibrary.simpleMessage("Remove link"),
        "removeParticipant":
            MessageLookupByLibrary.simpleMessage("Remove participant"),
        "removeParticipantBody": m74,
        "removePersonLabel":
            MessageLookupByLibrary.simpleMessage("Remove person label"),
        "removePublicLink":
            MessageLookupByLibrary.simpleMessage("Remove public link"),
        "removePublicLinks":
            MessageLookupByLibrary.simpleMessage("Remove public links"),
        "removeShareItemsWarning": MessageLookupByLibrary.simpleMessage(
            "Some of the items you are removing were added by other people, and you will lose access to them"),
        "removeWithQuestionMark":
            MessageLookupByLibrary.simpleMessage("Remove?"),
        "removeYourselfAsTrustedContact": MessageLookupByLibrary.simpleMessage(
            "Remove yourself as trusted contact"),
        "removingFromFavorites":
            MessageLookupByLibrary.simpleMessage("Removing from favorites..."),
        "rename": MessageLookupByLibrary.simpleMessage("Rename"),
        "renameAlbum": MessageLookupByLibrary.simpleMessage("Rename album"),
        "renameFile": MessageLookupByLibrary.simpleMessage("Rename file"),
        "renewSubscription":
            MessageLookupByLibrary.simpleMessage("Renew subscription"),
        "renewsOn": m75,
        "reportABug": MessageLookupByLibrary.simpleMessage("Report a bug"),
        "reportBug": MessageLookupByLibrary.simpleMessage("Report bug"),
        "resendEmail": MessageLookupByLibrary.simpleMessage("Resend email"),
        "reset": MessageLookupByLibrary.simpleMessage("Reset"),
        "resetIgnoredFiles":
            MessageLookupByLibrary.simpleMessage("Reset ignored files"),
        "resetPasswordTitle":
            MessageLookupByLibrary.simpleMessage("Reset password"),
        "resetPerson": MessageLookupByLibrary.simpleMessage("Remove"),
        "resetToDefault":
            MessageLookupByLibrary.simpleMessage("Reset to default"),
        "restore": MessageLookupByLibrary.simpleMessage("Restore"),
        "restoreToAlbum":
            MessageLookupByLibrary.simpleMessage("Restore to album"),
        "restoringFiles":
            MessageLookupByLibrary.simpleMessage("Restoring files..."),
        "resumableUploads":
            MessageLookupByLibrary.simpleMessage("Resumable uploads"),
        "retry": MessageLookupByLibrary.simpleMessage("Retry"),
        "review": MessageLookupByLibrary.simpleMessage("Review"),
        "reviewDeduplicateItems": MessageLookupByLibrary.simpleMessage(
            "Please review and delete the items you believe are duplicates."),
        "reviewSuggestions":
            MessageLookupByLibrary.simpleMessage("Review suggestions"),
        "right": MessageLookupByLibrary.simpleMessage("Right"),
        "roadtripWithThem": m76,
        "rotate": MessageLookupByLibrary.simpleMessage("Rotate"),
        "rotateLeft": MessageLookupByLibrary.simpleMessage("Rotate left"),
        "rotateRight": MessageLookupByLibrary.simpleMessage("Rotate right"),
        "safelyStored": MessageLookupByLibrary.simpleMessage("Safely stored"),
        "same": MessageLookupByLibrary.simpleMessage("Same"),
        "sameperson": MessageLookupByLibrary.simpleMessage("Same person?"),
        "save": MessageLookupByLibrary.simpleMessage("Save"),
        "saveAsAnotherPerson":
            MessageLookupByLibrary.simpleMessage("Save as another person"),
        "saveChangesBeforeLeavingQuestion":
            MessageLookupByLibrary.simpleMessage(
                "Save changes before leaving?"),
        "saveCollage": MessageLookupByLibrary.simpleMessage("Save collage"),
        "saveCopy": MessageLookupByLibrary.simpleMessage("Save copy"),
        "saveKey": MessageLookupByLibrary.simpleMessage("Save key"),
        "savePerson": MessageLookupByLibrary.simpleMessage("Save person"),
        "saveYourRecoveryKeyIfYouHaventAlready":
            MessageLookupByLibrary.simpleMessage(
                "Save your recovery key if you haven\'t already"),
        "saving": MessageLookupByLibrary.simpleMessage("Saving..."),
        "savingEdits": MessageLookupByLibrary.simpleMessage("Saving edits..."),
        "scanCode": MessageLookupByLibrary.simpleMessage("Scan code"),
        "scanThisBarcodeWithnyourAuthenticatorApp":
            MessageLookupByLibrary.simpleMessage(
                "Scan this barcode with\nyour authenticator app"),
        "search": MessageLookupByLibrary.simpleMessage("Search"),
        "searchAlbumsEmptySection":
            MessageLookupByLibrary.simpleMessage("Albums"),
        "searchByAlbumNameHint":
            MessageLookupByLibrary.simpleMessage("Album name"),
        "searchByExamples": MessageLookupByLibrary.simpleMessage(
            "• Album names (e.g. \"Camera\")\n• Types of files (e.g. \"Videos\", \".gif\")\n• Years and months (e.g. \"2022\", \"January\")\n• Holidays (e.g. \"Christmas\")\n• Photo descriptions (e.g. “#fun”)"),
        "searchCaptionEmptySection": MessageLookupByLibrary.simpleMessage(
            "Add descriptions like \"#trip\" in photo info to quickly find them here"),
        "searchDatesEmptySection": MessageLookupByLibrary.simpleMessage(
            "Search by a date, month or year"),
        "searchDiscoverEmptySection": MessageLookupByLibrary.simpleMessage(
            "Images will be shown here once processing and syncing is complete"),
        "searchFaceEmptySection": MessageLookupByLibrary.simpleMessage(
            "People will be shown here once indexing is done"),
        "searchFileTypesAndNamesEmptySection":
            MessageLookupByLibrary.simpleMessage("File types and names"),
        "searchHint1":
            MessageLookupByLibrary.simpleMessage("Fast, on-device search"),
        "searchHint2":
            MessageLookupByLibrary.simpleMessage("Photo dates, descriptions"),
        "searchHint3": MessageLookupByLibrary.simpleMessage(
            "Albums, file names, and types"),
        "searchHint4": MessageLookupByLibrary.simpleMessage("Location"),
        "searchHint5": MessageLookupByLibrary.simpleMessage(
            "Coming soon: Faces & magic search ✨"),
        "searchLocationEmptySection": MessageLookupByLibrary.simpleMessage(
            "Group photos that are taken within some radius of a photo"),
        "searchPeopleEmptySection": MessageLookupByLibrary.simpleMessage(
            "Invite people, and you\'ll see all photos shared by them here"),
        "searchPersonsEmptySection": MessageLookupByLibrary.simpleMessage(
            "People will be shown here once processing and syncing is complete"),
        "searchResultCount": m77,
        "searchSectionsLengthMismatch": m78,
        "security": MessageLookupByLibrary.simpleMessage("Security"),
        "seePublicAlbumLinksInApp": MessageLookupByLibrary.simpleMessage(
            "See public album links in app"),
        "selectALocation":
            MessageLookupByLibrary.simpleMessage("Select a location"),
        "selectALocationFirst":
            MessageLookupByLibrary.simpleMessage("Select a location first"),
        "selectAlbum": MessageLookupByLibrary.simpleMessage("Select album"),
        "selectAll": MessageLookupByLibrary.simpleMessage("Select all"),
        "selectAllShort": MessageLookupByLibrary.simpleMessage("All"),
        "selectCoverPhoto":
            MessageLookupByLibrary.simpleMessage("Select cover photo"),
        "selectDate": MessageLookupByLibrary.simpleMessage("Select date"),
        "selectFoldersForBackup":
            MessageLookupByLibrary.simpleMessage("Select folders for backup"),
        "selectItemsToAdd":
            MessageLookupByLibrary.simpleMessage("Select items to add"),
        "selectLanguage":
            MessageLookupByLibrary.simpleMessage("Select Language"),
        "selectMailApp":
            MessageLookupByLibrary.simpleMessage("Select mail app"),
        "selectMorePhotos":
            MessageLookupByLibrary.simpleMessage("Select more photos"),
        "selectOneDateAndTime":
            MessageLookupByLibrary.simpleMessage("Select one date and time"),
        "selectOneDateAndTimeForAll": MessageLookupByLibrary.simpleMessage(
            "Select one date and time for all"),
        "selectPersonToLink":
            MessageLookupByLibrary.simpleMessage("Select person to link"),
        "selectReason": MessageLookupByLibrary.simpleMessage("Select reason"),
        "selectStartOfRange":
            MessageLookupByLibrary.simpleMessage("Select start of range"),
        "selectTime": MessageLookupByLibrary.simpleMessage("Select time"),
        "selectYourFace":
            MessageLookupByLibrary.simpleMessage("Select your face"),
        "selectYourPlan":
            MessageLookupByLibrary.simpleMessage("Select your plan"),
        "selectedAlbums": m79,
        "selectedFilesAreNotOnEnte": MessageLookupByLibrary.simpleMessage(
            "Selected files are not on Ente"),
        "selectedFoldersWillBeEncryptedAndBackedUp":
            MessageLookupByLibrary.simpleMessage(
                "Selected folders will be encrypted and backed up"),
        "selectedItemsWillBeDeletedFromAllAlbumsAndMoved":
            MessageLookupByLibrary.simpleMessage(
                "Selected items will be deleted from all albums and moved to trash."),
        "selectedItemsWillBeRemovedFromThisPerson":
            MessageLookupByLibrary.simpleMessage(
                "Selected items will be removed from this person, but not deleted from your library."),
        "selectedPhotos": m80,
        "selectedPhotosWithYours": m81,
        "selfiesWithThem": m82,
        "send": MessageLookupByLibrary.simpleMessage("Send"),
        "sendEmail": MessageLookupByLibrary.simpleMessage("Send email"),
        "sendInvite": MessageLookupByLibrary.simpleMessage("Send invite"),
        "sendLink": MessageLookupByLibrary.simpleMessage("Send link"),
        "serverEndpoint":
            MessageLookupByLibrary.simpleMessage("Server endpoint"),
        "sessionExpired":
            MessageLookupByLibrary.simpleMessage("Session expired"),
        "sessionIdMismatch":
            MessageLookupByLibrary.simpleMessage("Session ID mismatch"),
        "setAPassword": MessageLookupByLibrary.simpleMessage("Set a password"),
        "setAs": MessageLookupByLibrary.simpleMessage("Set as"),
        "setCover": MessageLookupByLibrary.simpleMessage("Set cover"),
        "setLabel": MessageLookupByLibrary.simpleMessage("Set"),
        "setNewPassword":
            MessageLookupByLibrary.simpleMessage("Set new password"),
        "setNewPin": MessageLookupByLibrary.simpleMessage("Set new PIN"),
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
        "shareMyVerificationID": m83,
        "shareOnlyWithThePeopleYouWant": MessageLookupByLibrary.simpleMessage(
            "Share only with the people you want"),
        "shareTextConfirmOthersVerificationID": m84,
        "shareTextRecommendUsingEnte": MessageLookupByLibrary.simpleMessage(
            "Download Ente so we can easily share original quality photos and videos\n\nhttps://ente.io"),
        "shareTextReferralCode": m85,
        "shareWithNonenteUsers":
            MessageLookupByLibrary.simpleMessage("Share with non-Ente users"),
        "shareWithPeopleSectionTitle": m86,
        "shareYourFirstAlbum":
            MessageLookupByLibrary.simpleMessage("Share your first album"),
        "sharedAlbumSectionDescription": MessageLookupByLibrary.simpleMessage(
            "Create shared and collaborative albums with other Ente users, including users on free plans."),
        "sharedByMe": MessageLookupByLibrary.simpleMessage("Shared by me"),
        "sharedByYou": MessageLookupByLibrary.simpleMessage("Shared by you"),
        "sharedPhotoNotifications":
            MessageLookupByLibrary.simpleMessage("New shared photos"),
        "sharedPhotoNotificationsExplanation": MessageLookupByLibrary.simpleMessage(
            "Receive notifications when someone adds a photo to a shared album that you\'re a part of"),
        "sharedWith": m87,
        "sharedWithMe": MessageLookupByLibrary.simpleMessage("Shared with me"),
        "sharedWithYou":
            MessageLookupByLibrary.simpleMessage("Shared with you"),
        "sharing": MessageLookupByLibrary.simpleMessage("Sharing..."),
        "shiftDatesAndTime":
            MessageLookupByLibrary.simpleMessage("Shift dates and time"),
        "shouldRemoveFilesSmartAlbumsDesc": MessageLookupByLibrary.simpleMessage(
            "Should the files related to the person that were previously selected in smart albums be removed?"),
        "showLessFaces":
            MessageLookupByLibrary.simpleMessage("Show less faces"),
        "showMemories": MessageLookupByLibrary.simpleMessage("Show memories"),
        "showMoreFaces":
            MessageLookupByLibrary.simpleMessage("Show more faces"),
        "showPerson": MessageLookupByLibrary.simpleMessage("Show person"),
        "signOutFromOtherDevices":
            MessageLookupByLibrary.simpleMessage("Sign out from other devices"),
        "signOutOtherBody": MessageLookupByLibrary.simpleMessage(
            "If you think someone might know your password, you can force all other devices using your account to sign out."),
        "signOutOtherDevices":
            MessageLookupByLibrary.simpleMessage("Sign out other devices"),
        "signUpTerms": MessageLookupByLibrary.simpleMessage(
            "I agree to the <u-terms>terms of service</u-terms> and <u-policy>privacy policy</u-policy>"),
        "singleFileDeleteFromDevice": m88,
        "singleFileDeleteHighlight": MessageLookupByLibrary.simpleMessage(
            "It will be deleted from all albums."),
        "singleFileInBothLocalAndRemote": m89,
        "singleFileInRemoteOnly": m90,
        "skip": MessageLookupByLibrary.simpleMessage("Skip"),
        "smartMemories": MessageLookupByLibrary.simpleMessage("Smart memories"),
        "social": MessageLookupByLibrary.simpleMessage("Social"),
        "someItemsAreInBothEnteAndYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "Some items are in both Ente and your device."),
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
        "sorryBackupFailedDesc": MessageLookupByLibrary.simpleMessage(
            "Sorry, we could not backup this file right now, we will retry later."),
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
        "sorryWeHadToPauseYourBackups": MessageLookupByLibrary.simpleMessage(
            "Sorry, we had to pause your backups"),
        "sort": MessageLookupByLibrary.simpleMessage("Sort"),
        "sortAlbumsBy": MessageLookupByLibrary.simpleMessage("Sort by"),
        "sortNewestFirst": MessageLookupByLibrary.simpleMessage("Newest first"),
        "sortOldestFirst": MessageLookupByLibrary.simpleMessage("Oldest first"),
        "sparkleSuccess": MessageLookupByLibrary.simpleMessage("✨ Success"),
        "sportsWithThem": m91,
        "spotlightOnThem": m92,
        "spotlightOnYourself":
            MessageLookupByLibrary.simpleMessage("Spotlight on yourself"),
        "startAccountRecoveryTitle":
            MessageLookupByLibrary.simpleMessage("Start recovery"),
        "startBackup": MessageLookupByLibrary.simpleMessage("Start backup"),
        "status": MessageLookupByLibrary.simpleMessage("Status"),
        "stopCastingBody": MessageLookupByLibrary.simpleMessage(
            "Do you want to stop casting?"),
        "stopCastingTitle":
            MessageLookupByLibrary.simpleMessage("Stop casting"),
        "storage": MessageLookupByLibrary.simpleMessage("Storage"),
        "storageBreakupFamily": MessageLookupByLibrary.simpleMessage("Family"),
        "storageBreakupYou": MessageLookupByLibrary.simpleMessage("You"),
        "storageInGB": m93,
        "storageLimitExceeded":
            MessageLookupByLibrary.simpleMessage("Storage limit exceeded"),
        "storageUsageInfo": m94,
        "streamDetails": MessageLookupByLibrary.simpleMessage("Stream details"),
        "strongStrength": MessageLookupByLibrary.simpleMessage("Strong"),
        "subAlreadyLinkedErrMessage": m95,
        "subWillBeCancelledOn": m96,
        "subscribe": MessageLookupByLibrary.simpleMessage("Subscribe"),
        "subscribeToEnableSharing": MessageLookupByLibrary.simpleMessage(
            "You need an active paid subscription to enable sharing."),
        "subscription": MessageLookupByLibrary.simpleMessage("Subscription"),
        "success": MessageLookupByLibrary.simpleMessage("Success"),
        "successfullyArchived":
            MessageLookupByLibrary.simpleMessage("Successfully archived"),
        "successfullyHid":
            MessageLookupByLibrary.simpleMessage("Successfully hid"),
        "successfullyUnarchived":
            MessageLookupByLibrary.simpleMessage("Successfully unarchived"),
        "successfullyUnhid":
            MessageLookupByLibrary.simpleMessage("Successfully unhid"),
        "suggestFeatures":
            MessageLookupByLibrary.simpleMessage("Suggest features"),
        "sunrise": MessageLookupByLibrary.simpleMessage("On the horizon"),
        "support": MessageLookupByLibrary.simpleMessage("Support"),
        "syncProgress": m97,
        "syncStopped": MessageLookupByLibrary.simpleMessage("Sync stopped"),
        "syncing": MessageLookupByLibrary.simpleMessage("Syncing..."),
        "systemTheme": MessageLookupByLibrary.simpleMessage("System"),
        "tapToCopy": MessageLookupByLibrary.simpleMessage("tap to copy"),
        "tapToEnterCode":
            MessageLookupByLibrary.simpleMessage("Tap to enter code"),
        "tapToUnlock": MessageLookupByLibrary.simpleMessage("Tap to unlock"),
        "tapToUpload": MessageLookupByLibrary.simpleMessage("Tap to upload"),
        "tapToUploadIsIgnoredDue": m98,
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
        "theLinkYouAreTryingToAccessHasExpired":
            MessageLookupByLibrary.simpleMessage(
                "The link you are trying to access has expired."),
        "thePersonGroupsWillNotBeDisplayed": MessageLookupByLibrary.simpleMessage(
            "The person groups will not be displayed in the people section anymore. Photos will remain untouched."),
        "thePersonWillNotBeDisplayed": MessageLookupByLibrary.simpleMessage(
            "The person will not be displayed in the people section anymore. Photos will remain untouched."),
        "theRecoveryKeyYouEnteredIsIncorrect":
            MessageLookupByLibrary.simpleMessage(
                "The recovery key you entered is incorrect"),
        "theme": MessageLookupByLibrary.simpleMessage("Theme"),
        "theseItemsWillBeDeletedFromYourDevice":
            MessageLookupByLibrary.simpleMessage(
                "These items will be deleted from your device."),
        "theyAlsoGetXGb": m99,
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
        "thisIsMeExclamation":
            MessageLookupByLibrary.simpleMessage("This is me!"),
        "thisIsPersonVerificationId": m100,
        "thisIsYourVerificationId": MessageLookupByLibrary.simpleMessage(
            "This is your Verification ID"),
        "thisWeekThroughTheYears":
            MessageLookupByLibrary.simpleMessage("This week through the years"),
        "thisWeekXYearsAgo": m101,
        "thisWillLogYouOutOfTheFollowingDevice":
            MessageLookupByLibrary.simpleMessage(
                "This will log you out of the following device:"),
        "thisWillLogYouOutOfThisDevice": MessageLookupByLibrary.simpleMessage(
            "This will log you out of this device!"),
        "thisWillMakeTheDateAndTimeOfAllSelected":
            MessageLookupByLibrary.simpleMessage(
                "This will make the date and time of all selected photos the same."),
        "thisWillRemovePublicLinksOfAllSelectedQuickLinks":
            MessageLookupByLibrary.simpleMessage(
                "This will remove public links of all selected quick links."),
        "throughTheYears": m102,
        "toEnableAppLockPleaseSetupDevicePasscodeOrScreen":
            MessageLookupByLibrary.simpleMessage(
                "To enable app lock, please setup device passcode or screen lock in your system settings."),
        "toHideAPhotoOrVideo":
            MessageLookupByLibrary.simpleMessage("To hide a photo or video"),
        "toResetVerifyEmail": MessageLookupByLibrary.simpleMessage(
            "To reset your password, please verify your email first."),
        "todaysLogs": MessageLookupByLibrary.simpleMessage("Today\'s logs"),
        "tooManyIncorrectAttempts":
            MessageLookupByLibrary.simpleMessage("Too many incorrect attempts"),
        "total": MessageLookupByLibrary.simpleMessage("total"),
        "totalSize": MessageLookupByLibrary.simpleMessage("Total size"),
        "trash": MessageLookupByLibrary.simpleMessage("Trash"),
        "trashDaysLeft": m103,
        "trim": MessageLookupByLibrary.simpleMessage("Trim"),
        "tripInYear": m104,
        "tripToLocation": m105,
        "trustedContacts":
            MessageLookupByLibrary.simpleMessage("Trusted contacts"),
        "trustedInviteBody": m106,
        "tryAgain": MessageLookupByLibrary.simpleMessage("Try again"),
        "turnOnBackupForAutoUpload": MessageLookupByLibrary.simpleMessage(
            "Turn on backup to automatically upload files added to this device folder to Ente."),
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
        "typeOfGallerGallerytypeIsNotSupportedForRename": m107,
        "unarchive": MessageLookupByLibrary.simpleMessage("Unarchive"),
        "unarchiveAlbum":
            MessageLookupByLibrary.simpleMessage("Unarchive album"),
        "unarchiving": MessageLookupByLibrary.simpleMessage("Unarchiving..."),
        "unavailableReferralCode": MessageLookupByLibrary.simpleMessage(
            "Sorry, this code is unavailable."),
        "uncategorized": MessageLookupByLibrary.simpleMessage("Uncategorized"),
        "unhide": MessageLookupByLibrary.simpleMessage("Unhide"),
        "unhideToAlbum":
            MessageLookupByLibrary.simpleMessage("Unhide to album"),
        "unhiding": MessageLookupByLibrary.simpleMessage("Unhiding..."),
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
        "uploadIsIgnoredDueToIgnorereason": m108,
        "uploadingFilesToAlbum":
            MessageLookupByLibrary.simpleMessage("Uploading files to album..."),
        "uploadingMultipleMemories": m109,
        "uploadingSingleMemory":
            MessageLookupByLibrary.simpleMessage("Preserving 1 memory..."),
        "upto50OffUntil4thDec": MessageLookupByLibrary.simpleMessage(
            "Upto 50% off, until 4th Dec."),
        "usableReferralStorageInfo": MessageLookupByLibrary.simpleMessage(
            "Usable storage is limited by your current plan. Excess claimed storage will automatically become usable when you upgrade your plan."),
        "useAsCover": MessageLookupByLibrary.simpleMessage("Use as cover"),
        "useDifferentPlayerInfo": MessageLookupByLibrary.simpleMessage(
            "Having trouble playing this video? Long press here to try a different player."),
        "usePublicLinksForPeopleNotOnEnte":
            MessageLookupByLibrary.simpleMessage(
                "Use public links for people not on Ente"),
        "useRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Use recovery key"),
        "useSelectedPhoto":
            MessageLookupByLibrary.simpleMessage("Use selected photo"),
        "usedSpace": MessageLookupByLibrary.simpleMessage("Used space"),
        "validTill": m110,
        "verificationFailedPleaseTryAgain":
            MessageLookupByLibrary.simpleMessage(
                "Verification failed, please try again"),
        "verificationId":
            MessageLookupByLibrary.simpleMessage("Verification ID"),
        "verify": MessageLookupByLibrary.simpleMessage("Verify"),
        "verifyEmail": MessageLookupByLibrary.simpleMessage("Verify email"),
        "verifyEmailID": m111,
        "verifyIDLabel": MessageLookupByLibrary.simpleMessage("Verify"),
        "verifyPasskey": MessageLookupByLibrary.simpleMessage("Verify passkey"),
        "verifyPassword":
            MessageLookupByLibrary.simpleMessage("Verify password"),
        "verifying": MessageLookupByLibrary.simpleMessage("Verifying..."),
        "verifyingRecoveryKey":
            MessageLookupByLibrary.simpleMessage("Verifying recovery key..."),
        "videoInfo": MessageLookupByLibrary.simpleMessage("Video Info"),
        "videoSmallCase": MessageLookupByLibrary.simpleMessage("video"),
        "videoStreaming":
            MessageLookupByLibrary.simpleMessage("Streamable videos"),
        "videos": MessageLookupByLibrary.simpleMessage("Videos"),
        "viewActiveSessions":
            MessageLookupByLibrary.simpleMessage("View active sessions"),
        "viewAddOnButton": MessageLookupByLibrary.simpleMessage("View add-ons"),
        "viewAll": MessageLookupByLibrary.simpleMessage("View all"),
        "viewAllExifData":
            MessageLookupByLibrary.simpleMessage("View all EXIF data"),
        "viewLargeFiles": MessageLookupByLibrary.simpleMessage("Large files"),
        "viewLargeFilesDesc": MessageLookupByLibrary.simpleMessage(
            "View files that are consuming the most amount of storage."),
        "viewLogs": MessageLookupByLibrary.simpleMessage("View logs"),
        "viewPersonToUnlink": m112,
        "viewRecoveryKey":
            MessageLookupByLibrary.simpleMessage("View recovery key"),
        "viewer": MessageLookupByLibrary.simpleMessage("Viewer"),
        "viewersSuccessfullyAdded": m113,
        "visitWebToManage": MessageLookupByLibrary.simpleMessage(
            "Please visit web.ente.io to manage your subscription"),
        "waitingForVerification":
            MessageLookupByLibrary.simpleMessage("Waiting for verification..."),
        "waitingForWifi":
            MessageLookupByLibrary.simpleMessage("Waiting for WiFi..."),
        "warning": MessageLookupByLibrary.simpleMessage("Warning"),
        "weAreOpenSource":
            MessageLookupByLibrary.simpleMessage("We are open source!"),
        "weDontSupportEditingPhotosAndAlbumsThatYouDont":
            MessageLookupByLibrary.simpleMessage(
                "We don\'t support editing photos and albums that you don\'t own yet"),
        "weHaveSendEmailTo": m114,
        "weakStrength": MessageLookupByLibrary.simpleMessage("Weak"),
        "welcomeBack": MessageLookupByLibrary.simpleMessage("Welcome back!"),
        "whatsNew": MessageLookupByLibrary.simpleMessage("What\'s new"),
        "whyAddTrustContact": MessageLookupByLibrary.simpleMessage(
            "Trusted contact can help in recovering your data."),
        "widgets": MessageLookupByLibrary.simpleMessage("Widgets"),
        "wishThemAHappyBirthday": m115,
        "yearShort": MessageLookupByLibrary.simpleMessage("yr"),
        "yearly": MessageLookupByLibrary.simpleMessage("Yearly"),
        "yearsAgo": m116,
        "yes": MessageLookupByLibrary.simpleMessage("Yes"),
        "yesCancel": MessageLookupByLibrary.simpleMessage("Yes, cancel"),
        "yesConvertToViewer":
            MessageLookupByLibrary.simpleMessage("Yes, convert to viewer"),
        "yesDelete": MessageLookupByLibrary.simpleMessage("Yes, delete"),
        "yesDiscardChanges":
            MessageLookupByLibrary.simpleMessage("Yes, discard changes"),
        "yesIgnore": MessageLookupByLibrary.simpleMessage("Yes, ignore"),
        "yesLogout": MessageLookupByLibrary.simpleMessage("Yes, logout"),
        "yesRemove": MessageLookupByLibrary.simpleMessage("Yes, remove"),
        "yesRenew": MessageLookupByLibrary.simpleMessage("Yes, Renew"),
        "yesResetPerson":
            MessageLookupByLibrary.simpleMessage("Yes, reset person"),
        "you": MessageLookupByLibrary.simpleMessage("You"),
        "youAndThem": m117,
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
        "youHaveSuccessfullyFreedUp": m118,
        "yourAccountHasBeenDeleted": MessageLookupByLibrary.simpleMessage(
            "Your account has been deleted"),
        "yourMap": MessageLookupByLibrary.simpleMessage("Your map"),
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
                "You don\'t have any duplicate files that can be cleared"),
        "youveNoFilesInThisAlbumThatCanBeDeleted":
            MessageLookupByLibrary.simpleMessage(
                "You\'ve no files in this album that can be deleted"),
        "zoomOutToSeePhotos":
            MessageLookupByLibrary.simpleMessage("Zoom out to see photos")
      };
}
