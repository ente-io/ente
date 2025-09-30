// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get onBoardingBody => 'Securely backup your documents';

  @override
  String get newUser => 'New to Ente';

  @override
  String get existingUser => 'Existing User';

  @override
  String get developerSettings => 'Developer settings';

  @override
  String get yes => 'Yes';

  @override
  String get developerSettingsWarning =>
      'Are you sure that you want to modify Developer settings?';

  @override
  String get serverEndpoint => 'Server endpoint';

  @override
  String get endpointUpdatedMessage => 'Endpoint updated successfully';

  @override
  String get invalidEndpoint => 'Invalid endpoint';

  @override
  String get invalidEndpointMessage =>
      'Sorry, the endpoint you entered is invalid. Please enter a valid endpoint and try again.';

  @override
  String get saveAction => 'Save';

  @override
  String get untitled => 'Untitled';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get noFilesFound => 'No files here';

  @override
  String get addFiles => 'Add Files';

  @override
  String get name => 'Name';

  @override
  String get date => 'Date';

  @override
  String get pleaseWait => 'Please wait...';

  @override
  String get downloading => 'Downloading...';

  @override
  String downloadingProgress(int percentage) {
    return 'Downloading... $percentage%';
  }

  @override
  String get downloadFailed => 'Download Failed';

  @override
  String get failedToDownloadOrDecrypt => 'Failed to download or decrypt file';

  @override
  String get errorOpeningFile => 'Error opening file';

  @override
  String errorOpeningFileMessage(String error) {
    return 'Error opening file: $error';
  }

  @override
  String couldNotOpenFile(String error) {
    return 'Could not open file: $error';
  }

  @override
  String minutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String hoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String get yesterday => 'Yesterday';

  @override
  String daysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get collectionRenamedSuccessfully => 'Collection renamed successfully';

  @override
  String failedToRenameCollection(String error) {
    return 'Failed to rename collection: $error';
  }

  @override
  String get collectionCannotBeDeleted => 'This collection cannot be deleted';

  @override
  String get deleteCollection => 'Delete collection';

  @override
  String deleteCollectionConfirmation(String collectionName) {
    return 'Are you sure you want to delete \"$collectionName\"?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get collectionDeletedSuccessfully => 'Collection deleted successfully';

  @override
  String failedToDeleteCollection(String error) {
    return 'Failed to delete collection: $error';
  }

  @override
  String get collections => 'Collections';

  @override
  String get retry => 'Retry';

  @override
  String failedToSyncTrash(String error) {
    return 'Failed to sync trash: $error';
  }

  @override
  String get pleaseSelectAtLeastOneCollection =>
      'Please select at least one collection';

  @override
  String get unknownItemType => 'Unknown item type';

  @override
  String get fileDeletedSuccessfully => 'File deleted successfully';

  @override
  String failedToDeleteFile(String error) {
    return 'Failed to delete file: $error';
  }

  @override
  String get fileUpdatedSuccessfully => 'File updated successfully!';

  @override
  String failedToUpdateFile(String error) {
    return 'Failed to update file: $error';
  }

  @override
  String get noChangesWereMade => 'No changes were made';

  @override
  String get noCollectionsAvailableForRestore =>
      'No collections available for restore';

  @override
  String get trashClearedSuccessfully => 'Trash cleared successfully';

  @override
  String failedToClearTrash(String error) {
    return 'Failed to clear trash: $error';
  }

  @override
  String get trash => 'Trash';

  @override
  String deletedPermanently(String fileName) {
    return 'Deleted \"$fileName\" permanently';
  }

  @override
  String failedToRestoreFile(String fileName, String error) {
    return 'Failed to restore \"$fileName\": $error';
  }

  @override
  String get createNewCollection => 'Create new collection';

  @override
  String get create => 'Create';

  @override
  String get renameCollection => 'Rename collection';

  @override
  String get save => 'Save';

  @override
  String get deleteFile => 'Delete File';

  @override
  String deleteFileConfirmation(String fileName) {
    return 'Are you sure you want to delete \"$fileName\"?';
  }

  @override
  String get noCollectionsFound => 'No collections found';

  @override
  String get createYourFirstCollection =>
      'Create your first collection to get started';

  @override
  String get createCollection => 'Create Collection';

  @override
  String get nothingYet => 'Nothing yet';

  @override
  String get uploadYourFirstDocument =>
      'Upload your first document to get started';

  @override
  String get uploadDocument => 'Upload Document';

  @override
  String items(int count) {
    return '$count items';
  }

  @override
  String files(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
      zero: 'no files',
    );
    return '$_temp0';
  }

  @override
  String get createCollectionTooltip => 'Create collection';

  @override
  String get uploadDocumentTooltip => 'Upload document';

  @override
  String get restore => 'Restore';

  @override
  String restoreFile(String fileName) {
    return 'Restore $fileName';
  }

  @override
  String get noCollectionsAvailable => 'No collections available';

  @override
  String get emptyTrash => 'Empty trash';

  @override
  String get emptyTrashTooltip => 'Empty trash';

  @override
  String get emptyTrashConfirmation =>
      'Are you sure you want to permanently delete all items in trash? This action cannot be undone.';

  @override
  String get fileTitle => 'File title';

  @override
  String get note => 'Note';

  @override
  String get optionalNote => 'Optional note';

  @override
  String get upload => 'Upload';

  @override
  String get documentsHint => 'Documents';

  @override
  String get searchHint => 'Search...';

  @override
  String noCollectionsFoundForQuery(String query) {
    return 'No collections found for \"$query\"';
  }

  @override
  String get uncategorized => 'Uncategorized';

  @override
  String get syncingTrash => 'Syncing trash...';

  @override
  String get restoring => 'Restoring...';

  @override
  String restoredFileToCollection(String fileName, String collectionName) {
    return 'Restored \"$fileName\" to \"$collectionName\"';
  }

  @override
  String get clearingTrash => 'Clearing trash...';

  @override
  String get trashIsEmpty => 'Trash is empty';

  @override
  String get share => 'Share';

  @override
  String get shareLink => 'Share link';

  @override
  String get creatingShareLink => 'Creating link...';

  @override
  String get shareThisLink => 'Anyone with this link can access your file.';

  @override
  String get copyLink => 'Copy link';

  @override
  String get deleteLink => 'Delete link';

  @override
  String get close => 'Close';

  @override
  String get linkCopiedToClipboard => 'Link copied to clipboard';

  @override
  String get deleteShareLink => 'Delete link';

  @override
  String get deleteShareLinkDialogTitle => 'Delete link?';

  @override
  String get deleteShareLinkConfirmation =>
      'People with this link will no longer be able to access the file.';

  @override
  String get deletingShareLink => 'Deleting link...';

  @override
  String get shareLinkDeletedSuccessfully => 'Link deleted successfully';

  @override
  String get failedToCreateShareLink => 'Failed to create link';

  @override
  String get failedToDeleteShareLink => 'Failed to delete link';

  @override
  String get deletingFile => 'Deleting file...';

  @override
  String get changeEmail => 'Change email';

  @override
  String get authToChangeYourEmail =>
      'Please authenticate to change your email';

  @override
  String get changePasswordTitle => 'Change password';

  @override
  String get authToChangeYourPassword =>
      'Please authenticate to change your password';

  @override
  String get recoveryKey => 'Recovery key';

  @override
  String get ok => 'Ok';

  @override
  String get logout => 'Logout';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get areYouSureYouWantToLogout => 'Are you sure you want to logout?';

  @override
  String get yesLogout => 'Yes, logout';

  @override
  String get changePassword => 'Change password';

  @override
  String get authToViewYourRecoveryKey =>
      'Please authenticate to view your recovery key';

  @override
  String get account => 'Account';

  @override
  String get security => 'Security';

  @override
  String get emailVerificationToggle => 'Email verification';

  @override
  String get authToChangeEmailVerificationSetting =>
      'Please authenticate to change email verification';

  @override
  String get passkey => 'Passkey';

  @override
  String get authenticateGeneric => 'Please authenticate';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get appLock => 'App lock';

  @override
  String get warning => 'Warning';

  @override
  String get appLockOfflineModeWarning =>
      'You have chosen to proceed without backups. If you forget your applock, you will be locked out from accessing your data.';

  @override
  String get authToChangeLockscreenSetting =>
      'Please authenticate to change lockscreen setting';

  @override
  String get authToViewPasskey => 'Please authenticate to view passkey';

  @override
  String get theme => 'Theme';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get systemTheme => 'System';

  @override
  String get settings => 'Settings';

  @override
  String get about => 'About';

  @override
  String get weAreOpenSource => 'We are open source!';

  @override
  String get privacy => 'Privacy';

  @override
  String get terms => 'Terms';

  @override
  String get termsOfServicesTitle => 'Terms';

  @override
  String get support => 'Support';

  @override
  String get contactSupport => 'Contact support';

  @override
  String get help => 'Help';

  @override
  String get suggestFeatures => 'Suggest features';

  @override
  String get reportABug => 'Report a bug';

  @override
  String get reportBug => 'Report bug';

  @override
  String get social => 'Social';

  @override
  String rateUsOnStore(Object storeName) {
    return 'Rate us on $storeName';
  }

  @override
  String get blog => 'Blog';

  @override
  String get merchandise => 'Merchandise';

  @override
  String get twitter => 'Twitter';

  @override
  String get mastodon => 'Mastodon';

  @override
  String get matrix => 'Matrix';

  @override
  String get discord => 'Discord';

  @override
  String get reddit => 'Reddit';

  @override
  String get information => 'Information';

  @override
  String get saveInformation => 'Save information';

  @override
  String get informationDescription =>
      'Save important information that can be shared and passed down to loved ones.';

  @override
  String get personalNote => 'Personal note';

  @override
  String get personalNoteDescription => 'Save important notes or thoughts';

  @override
  String get physicalRecords => 'Physical records';

  @override
  String get physicalRecordsDescription =>
      'Save the real-world locations of important items';

  @override
  String get accountCredentials => 'Account credentials';

  @override
  String get accountCredentialsDescription =>
      'Securely store login details for important accounts';

  @override
  String get emergencyContact => 'Emergency contact';

  @override
  String get emergencyContactDescription =>
      'Save details of people to contact in emergencies';

  @override
  String get noteName => 'Title';

  @override
  String get noteNameHint => 'Give your note a meaningful title';

  @override
  String get noteContent => 'Content';

  @override
  String get noteContentHint =>
      'Write down important thoughts, instructions, or memories you want to preserve';

  @override
  String get recordName => 'Record name';

  @override
  String get recordNameHint => 'Name of the real-world item';

  @override
  String get recordLocation => 'Location';

  @override
  String get recordLocationHint =>
      'Where can this item be found? (e.g., \'Safety deposit box at First Bank, Box #123\')';

  @override
  String get recordNotes => 'Notes';

  @override
  String get recordNotesHint =>
      'Any additional details about accessing or understanding this record';

  @override
  String get credentialName => 'Account name';

  @override
  String get credentialNameHint => 'Name of the service or account';

  @override
  String get username => 'Username';

  @override
  String get usernameHint => 'Login username or email address';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Account password';

  @override
  String get credentialNotes => 'Additional notes';

  @override
  String get credentialNotesHint =>
      'Recovery methods, security questions, or other important details';

  @override
  String get contactName => 'Contact name';

  @override
  String get contactNameHint => 'Full name of the emergency contact';

  @override
  String get contactDetails => 'Contact details';

  @override
  String get contactDetailsHint =>
      'Phone number, email, or other contact information';

  @override
  String get contactNotes => 'Message for contact';

  @override
  String get contactNotesHint =>
      'Important information to share with this person when they are contacted';

  @override
  String get saveRecord => 'Save';

  @override
  String get recordSavedSuccessfully => 'Record saved successfully';

  @override
  String get failedToSaveRecord => 'Failed to save record';

  @override
  String get pleaseEnterNoteName => 'Please enter a title';

  @override
  String get pleaseEnterNoteContent => 'Please enter content';

  @override
  String get pleaseEnterRecordName => 'Please enter a record name';

  @override
  String get pleaseEnterLocation => 'Please enter a location';

  @override
  String get pleaseEnterAccountName => 'Please enter an account name';

  @override
  String get pleaseEnterUsername => 'Please enter a username';

  @override
  String get pleaseEnterPassword => 'Please enter a password';

  @override
  String get pleaseEnterContactName => 'Please enter a contact name';

  @override
  String get pleaseEnterContactDetails => 'Please enter contact details';

  @override
  String get allowDownloads => 'Allow downloads';

  @override
  String get sharedByYou => 'Shared by you';

  @override
  String get sharedWithYou => 'Shared with you';

  @override
  String get manageLink => 'Manage link';

  @override
  String get linkExpiry => 'Link expiry';

  @override
  String get linkNeverExpires => 'Never';

  @override
  String get linkExpired => 'Expired';

  @override
  String get linkEnabled => 'Enabled';

  @override
  String get setAPassword => 'Set a password';

  @override
  String get lockButtonLabel => 'Lock';

  @override
  String get enterPassword => 'Enter password';

  @override
  String get removeLink => 'Remove link';

  @override
  String get sendLink => 'Send link';

  @override
  String get setPasswordTitle => 'Set password';

  @override
  String get resetPasswordTitle => 'Reset password';

  @override
  String get allowAddingFiles => 'Allow adding files';

  @override
  String get disableDownloadWarningTitle => 'Please note';

  @override
  String get disableDownloadWarningBody =>
      'Viewers can still take screenshots or save a copy of your files using external tools.';

  @override
  String get allowAddFilesDescription =>
      'Allow people with the link to also add files to the shared collection.';

  @override
  String get after1Hour => 'After 1 hour';

  @override
  String get after1Day => 'After 1 day';

  @override
  String get after1Week => 'After 1 week';

  @override
  String get after1Month => 'After 1 month';

  @override
  String get after1Year => 'After 1 year';

  @override
  String get never => 'Never';

  @override
  String get custom => 'Custom';

  @override
  String get selectTime => 'Select time';

  @override
  String get selectDate => 'Select date';

  @override
  String get previous => 'Previous';

  @override
  String get done => 'Done';

  @override
  String get next => 'Next';

  @override
  String get noDeviceLimit => 'None';

  @override
  String get linkDeviceLimit => 'Device limit';

  @override
  String get expiredLinkInfo =>
      'This link has expired. Please select a new expiry time or disable link expiry.';

  @override
  String linkExpiresOn(Object expiryTime) {
    return 'Link will expire on $expiryTime';
  }

  @override
  String shareWithPeopleSectionTitle(int numberOfPeople) {
    String _temp0 = intl.Intl.pluralLogic(
      numberOfPeople,
      locale: localeName,
      other: 'Shared with $numberOfPeople people',
      one: 'Shared with 1 person',
      zero: 'Share with specific people',
    );
    return '$_temp0';
  }

  @override
  String get linkHasExpired => 'Link has expired';

  @override
  String get publicLinkEnabled => 'Public link enabled';

  @override
  String get shareALink => 'Share a link';

  @override
  String get addViewer => 'Add viewer';

  @override
  String get addCollaborator => 'Add collaborator';

  @override
  String get addANewEmail => 'Add a new email';

  @override
  String get orPickAnExistingOne => 'Or pick an existing one';

  @override
  String get sharedCollectionSectionDescription =>
      'Create shared and collaborative collections with other Ente users, including users on free plans.';

  @override
  String get createPublicLink => 'Create public link';

  @override
  String get addParticipants => 'Add participants';

  @override
  String get add => 'Add';

  @override
  String get collaboratorsCanAddFilesToTheSharedCollection =>
      'Collaborators can add files to the shared collection.';

  @override
  String get enterEmail => 'Enter email';

  @override
  String viewersSuccessfullyAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count viewers',
      one: 'Added 1 viewer',
      zero: 'Added 0 viewers',
    );
    return '$_temp0';
  }

  @override
  String collaboratorsSuccessfullyAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count collaborators',
      one: 'Added 1 collaborator',
      zero: 'Added 0 collaborator',
    );
    return '$_temp0';
  }

  @override
  String addViewers(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add viewers',
      one: 'Add viewer',
      zero: 'Add viewer',
    );
    return '$_temp0';
  }

  @override
  String addCollaborators(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add collaborators',
      one: 'Add collaborator',
      zero: 'Add collaborator',
    );
    return '$_temp0';
  }

  @override
  String get longPressAnEmailToVerifyEndToEndEncryption =>
      'Long press an email to verify end to end encryption.';

  @override
  String get sharing => 'Sharing...';

  @override
  String get invalidEmailAddress => 'Invalid email address';

  @override
  String get enterValidEmail => 'Please enter a valid email address.';

  @override
  String get oops => 'Oops';

  @override
  String get youCannotShareWithYourself => 'You cannot share with yourself';

  @override
  String get inviteToEnte => 'Invite to Ente';

  @override
  String get sendInvite => 'Send invite';

  @override
  String get shareTextRecommendUsingEnte =>
      'Download Ente so we can easily share original quality files\n\nhttps://ente.io';

  @override
  String get thisIsYourVerificationId => 'This is your Verification ID';

  @override
  String get someoneSharingAlbumsWithYouShouldSeeTheSameId =>
      'Someone sharing albums with you should see the same ID on their device.';

  @override
  String get howToViewShareeVerificationID =>
      'Please ask them to long-press their email address on the settings screen, and verify that the IDs on both devices match.';

  @override
  String thisIsPersonVerificationId(String email) {
    return 'This is $email\'s Verification ID';
  }

  @override
  String get verificationId => 'Verification ID';

  @override
  String verifyEmailID(Object email) {
    return 'Verify $email';
  }

  @override
  String emailNoEnteAccount(Object email) {
    return '$email does not have an Ente account.\n\nSend them an invite to share files.';
  }

  @override
  String shareMyVerificationID(Object verificationID) {
    return 'Here\'s my verification ID: $verificationID for ente.io.';
  }

  @override
  String shareTextConfirmOthersVerificationID(Object verificationID) {
    return 'Hey, can you confirm that this is your ente.io verification ID: $verificationID';
  }

  @override
  String get passwordLock => 'Password lock';

  @override
  String get manage => 'Manage';

  @override
  String get addedAs => 'Added as';

  @override
  String get removeParticipant => 'Remove participant';

  @override
  String get yesConvertToViewer => 'Yes, convert to viewer';

  @override
  String get changePermissions => 'Change permissions';

  @override
  String cannotAddMoreFilesAfterBecomingViewer(String name) {
    return '$name will no longer be able to add files to the collection after becoming a viewer.';
  }

  @override
  String get removeWithQuestionMark => 'Remove?';

  @override
  String removeParticipantBody(Object userEmail) {
    return '$userEmail will be removed from this shared collection\n\nAny files added by them will also be removed from the collection';
  }

  @override
  String get yesRemove => 'Yes, remove';

  @override
  String get remove => 'Remove';

  @override
  String get viewer => 'Viewer';

  @override
  String get collaborator => 'Collaborator';

  @override
  String get collaboratorsCanAddFilesToTheSharedAlbum =>
      'Collaborators can add files to the shared collection.';

  @override
  String albumParticipantsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Participants',
      one: '1 Participant',
      zero: 'No Participants',
    );
    return '$_temp0';
  }

  @override
  String get addMore => 'Add more';

  @override
  String get you => 'You';

  @override
  String get albumOwner => 'Owner';

  @override
  String typeOfCollectionTypeIsNotSupportedForRename(String collectionType) {
    return 'Type of collection $collectionType is not supported for rename';
  }

  @override
  String get leaveCollection => 'Leave collection';

  @override
  String get filesAddedByYouWillBeRemovedFromTheCollection =>
      'Files added by you will be removed from the collection';

  @override
  String get leaveSharedCollection => 'Leave shared collection?';

  @override
  String get noSystemLockFound => 'No system lock found';

  @override
  String get toEnableAppLockPleaseSetupDevicePasscodeOrScreen =>
      'To enable app lock, please setup device passcode or screen lock in your system settings.';

  @override
  String get legacy => 'Legacy';

  @override
  String get authToManageLegacy =>
      'Please authenticate to manage your trusted contacts';

  @override
  String get uploadError => 'Upload Error';

  @override
  String get tryAdjustingYourSearchQuery => 'Try adjusting your search query';

  @override
  String noFilesFoundForQuery(String query) {
    return 'No files found for \"$query\"';
  }

  @override
  String get deselectAll => 'Deselect All';

  @override
  String get selectAll => 'Select All';

  @override
  String get unnamedCollection => 'Unnamed Collection';

  @override
  String get enteLocker => 'ente Locker';

  @override
  String uploadedFilesProgress(int completed, int total) {
    return 'Uploaded $completed/$total files...';
  }

  @override
  String uploadedFilesProgressWithError(
      int completed, int total, String error) {
    return 'Uploaded $completed/$total files... ($error)';
  }

  @override
  String get noCollectionsAvailableForSelection => 'No collections available';

  @override
  String get createCollectionButton => 'Create collection';

  @override
  String get collectionButtonLabel => 'Collection';

  @override
  String get hideWindow => 'Hide Window';

  @override
  String get showWindow => 'Show Window';

  @override
  String get exitApp => 'Exit App';

  @override
  String get lockerLogs => 'Locker logs';
}
