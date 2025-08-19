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
  String get addInformation => 'Add information';

  @override
  String get addInformationDialogSubtitle =>
      'Choose the type of information you want to add';

  @override
  String get physicalDocument => 'Physical document';

  @override
  String get physicalDocumentDescription =>
      'Save information about documents and items in the real world.';

  @override
  String get emergencyContact => 'Emergency contact';

  @override
  String get emergencyContactDescription =>
      'Save information about important contacts.';

  @override
  String get accountCredential => 'Account credential';

  @override
  String get accountCredentialDescription =>
      'Save information about your important account credentials.';
}
