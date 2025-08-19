import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @onBoardingBody.
  ///
  /// In en, this message translates to:
  /// **'Securely backup your documents'**
  String get onBoardingBody;

  /// No description provided for @newUser.
  ///
  /// In en, this message translates to:
  /// **'New to Ente'**
  String get newUser;

  /// No description provided for @existingUser.
  ///
  /// In en, this message translates to:
  /// **'Existing User'**
  String get existingUser;

  /// No description provided for @developerSettings.
  ///
  /// In en, this message translates to:
  /// **'Developer settings'**
  String get developerSettings;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @developerSettingsWarning.
  ///
  /// In en, this message translates to:
  /// **'Are you sure that you want to modify Developer settings?'**
  String get developerSettingsWarning;

  /// No description provided for @serverEndpoint.
  ///
  /// In en, this message translates to:
  /// **'Server endpoint'**
  String get serverEndpoint;

  /// No description provided for @endpointUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Endpoint updated successfully'**
  String get endpointUpdatedMessage;

  /// No description provided for @invalidEndpoint.
  ///
  /// In en, this message translates to:
  /// **'Invalid endpoint'**
  String get invalidEndpoint;

  /// No description provided for @invalidEndpointMessage.
  ///
  /// In en, this message translates to:
  /// **'Sorry, the endpoint you entered is invalid. Please enter a valid endpoint and try again.'**
  String get invalidEndpointMessage;

  /// No description provided for @saveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveAction;

  /// No description provided for @untitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitled;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @noFilesFound.
  ///
  /// In en, this message translates to:
  /// **'No files here'**
  String get noFilesFound;

  /// No description provided for @addFiles.
  ///
  /// In en, this message translates to:
  /// **'Add Files'**
  String get addFiles;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get pleaseWait;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading...'**
  String get downloading;

  /// Download progress message
  ///
  /// In en, this message translates to:
  /// **'Downloading... {percentage}%'**
  String downloadingProgress(int percentage);

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download Failed'**
  String get downloadFailed;

  /// No description provided for @failedToDownloadOrDecrypt.
  ///
  /// In en, this message translates to:
  /// **'Failed to download or decrypt file'**
  String get failedToDownloadOrDecrypt;

  /// No description provided for @errorOpeningFile.
  ///
  /// In en, this message translates to:
  /// **'Error opening file'**
  String get errorOpeningFile;

  /// Error message when opening a file fails
  ///
  /// In en, this message translates to:
  /// **'Error opening file: {error}'**
  String errorOpeningFileMessage(String error);

  /// Error message when file cannot be opened
  ///
  /// In en, this message translates to:
  /// **'Could not open file: {error}'**
  String couldNotOpenFile(String error);

  /// Time format for minutes ago
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgo(int minutes);

  /// Time format for hours ago
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(int hours);

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// Time format for days ago
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String daysAgo(int days);

  /// No description provided for @collectionRenamedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Collection renamed successfully'**
  String get collectionRenamedSuccessfully;

  /// Error message when collection rename fails
  ///
  /// In en, this message translates to:
  /// **'Failed to rename collection: {error}'**
  String failedToRenameCollection(String error);

  /// No description provided for @collectionCannotBeDeleted.
  ///
  /// In en, this message translates to:
  /// **'This collection cannot be deleted'**
  String get collectionCannotBeDeleted;

  /// No description provided for @deleteCollection.
  ///
  /// In en, this message translates to:
  /// **'Delete collection'**
  String get deleteCollection;

  /// Confirmation message for deleting a collection
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{collectionName}\"?'**
  String deleteCollectionConfirmation(String collectionName);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @collectionDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Collection deleted successfully'**
  String get collectionDeletedSuccessfully;

  /// Error message when collection deletion fails
  ///
  /// In en, this message translates to:
  /// **'Failed to delete collection: {error}'**
  String failedToDeleteCollection(String error);

  /// No description provided for @collections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get collections;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Error message when trash sync fails
  ///
  /// In en, this message translates to:
  /// **'Failed to sync trash: {error}'**
  String failedToSyncTrash(String error);

  /// No description provided for @pleaseSelectAtLeastOneCollection.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one collection'**
  String get pleaseSelectAtLeastOneCollection;

  /// No description provided for @unknownItemType.
  ///
  /// In en, this message translates to:
  /// **'Unknown item type'**
  String get unknownItemType;

  /// No description provided for @fileDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'File deleted successfully'**
  String get fileDeletedSuccessfully;

  /// Error message when file deletion fails
  ///
  /// In en, this message translates to:
  /// **'Failed to delete file: {error}'**
  String failedToDeleteFile(String error);

  /// No description provided for @fileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'File updated successfully!'**
  String get fileUpdatedSuccessfully;

  /// Error message when file update fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update file: {error}'**
  String failedToUpdateFile(String error);

  /// No description provided for @noChangesWereMade.
  ///
  /// In en, this message translates to:
  /// **'No changes were made'**
  String get noChangesWereMade;

  /// No description provided for @noCollectionsAvailableForRestore.
  ///
  /// In en, this message translates to:
  /// **'No collections available for restore'**
  String get noCollectionsAvailableForRestore;

  /// No description provided for @trashClearedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Trash cleared successfully'**
  String get trashClearedSuccessfully;

  /// Error message when clearing trash fails
  ///
  /// In en, this message translates to:
  /// **'Failed to clear trash: {error}'**
  String failedToClearTrash(String error);

  /// No description provided for @trash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get trash;

  /// Message when file is permanently deleted from trash
  ///
  /// In en, this message translates to:
  /// **'Deleted \"{fileName}\" permanently'**
  String deletedPermanently(String fileName);

  /// Error message when file restoration fails
  ///
  /// In en, this message translates to:
  /// **'Failed to restore \"{fileName}\": {error}'**
  String failedToRestoreFile(String fileName, String error);

  /// No description provided for @createNewCollection.
  ///
  /// In en, this message translates to:
  /// **'Create new collection'**
  String get createNewCollection;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @renameCollection.
  ///
  /// In en, this message translates to:
  /// **'Rename collection'**
  String get renameCollection;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @deleteFile.
  ///
  /// In en, this message translates to:
  /// **'Delete File'**
  String get deleteFile;

  /// Confirmation message for file deletion
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{fileName}\"?'**
  String deleteFileConfirmation(String fileName);

  /// No description provided for @noCollectionsFound.
  ///
  /// In en, this message translates to:
  /// **'No collections found'**
  String get noCollectionsFound;

  /// No description provided for @createYourFirstCollection.
  ///
  /// In en, this message translates to:
  /// **'Create your first collection to get started'**
  String get createYourFirstCollection;

  /// No description provided for @createCollection.
  ///
  /// In en, this message translates to:
  /// **'Create Collection'**
  String get createCollection;

  /// No description provided for @nothingYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet'**
  String get nothingYet;

  /// No description provided for @uploadYourFirstDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload your first document to get started'**
  String get uploadYourFirstDocument;

  /// No description provided for @uploadDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload Document'**
  String get uploadDocument;

  /// Number of items in a collection
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String items(int count);

  /// Number of files in a collection
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no files} =1{1 file} other{{count} files}}'**
  String files(int count);

  /// No description provided for @createCollectionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Create collection'**
  String get createCollectionTooltip;

  /// No description provided for @uploadDocumentTooltip.
  ///
  /// In en, this message translates to:
  /// **'Upload document'**
  String get uploadDocumentTooltip;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// Dialog title for restoring a file from trash
  ///
  /// In en, this message translates to:
  /// **'Restore {fileName}'**
  String restoreFile(String fileName);

  /// No description provided for @noCollectionsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No collections available'**
  String get noCollectionsAvailable;

  /// No description provided for @emptyTrash.
  ///
  /// In en, this message translates to:
  /// **'Empty trash'**
  String get emptyTrash;

  /// No description provided for @emptyTrashTooltip.
  ///
  /// In en, this message translates to:
  /// **'Empty trash'**
  String get emptyTrashTooltip;

  /// No description provided for @emptyTrashConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete all items in trash? This action cannot be undone.'**
  String get emptyTrashConfirmation;

  /// No description provided for @fileTitle.
  ///
  /// In en, this message translates to:
  /// **'File title'**
  String get fileTitle;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @optionalNote.
  ///
  /// In en, this message translates to:
  /// **'Optional note'**
  String get optionalNote;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @documentsHint.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documentsHint;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchHint;

  /// Message when no collections match the search query
  ///
  /// In en, this message translates to:
  /// **'No collections found for \"{query}\"'**
  String noCollectionsFoundForQuery(String query);

  /// No description provided for @uncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get uncategorized;

  /// No description provided for @syncingTrash.
  ///
  /// In en, this message translates to:
  /// **'Syncing trash...'**
  String get syncingTrash;

  /// No description provided for @restoring.
  ///
  /// In en, this message translates to:
  /// **'Restoring...'**
  String get restoring;

  /// Success message when file is restored to a collection
  ///
  /// In en, this message translates to:
  /// **'Restored \"{fileName}\" to \"{collectionName}\"'**
  String restoredFileToCollection(String fileName, String collectionName);

  /// No description provided for @clearingTrash.
  ///
  /// In en, this message translates to:
  /// **'Clearing trash...'**
  String get clearingTrash;

  /// No description provided for @trashIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Trash is empty'**
  String get trashIsEmpty;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @shareLink.
  ///
  /// In en, this message translates to:
  /// **'Share link'**
  String get shareLink;

  /// No description provided for @creatingShareLink.
  ///
  /// In en, this message translates to:
  /// **'Creating link...'**
  String get creatingShareLink;

  /// No description provided for @shareThisLink.
  ///
  /// In en, this message translates to:
  /// **'Anyone with this link can access your file.'**
  String get shareThisLink;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @deleteLink.
  ///
  /// In en, this message translates to:
  /// **'Delete link'**
  String get deleteLink;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @linkCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard'**
  String get linkCopiedToClipboard;

  /// No description provided for @deleteShareLink.
  ///
  /// In en, this message translates to:
  /// **'Delete link'**
  String get deleteShareLink;

  /// No description provided for @deleteShareLinkDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete link?'**
  String get deleteShareLinkDialogTitle;

  /// No description provided for @deleteShareLinkConfirmation.
  ///
  /// In en, this message translates to:
  /// **'People with this link will no longer be able to access the file.'**
  String get deleteShareLinkConfirmation;

  /// No description provided for @deletingShareLink.
  ///
  /// In en, this message translates to:
  /// **'Deleting link...'**
  String get deletingShareLink;

  /// No description provided for @shareLinkDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Link deleted successfully'**
  String get shareLinkDeletedSuccessfully;

  /// No description provided for @failedToCreateShareLink.
  ///
  /// In en, this message translates to:
  /// **'Failed to create link'**
  String get failedToCreateShareLink;

  /// No description provided for @failedToDeleteShareLink.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete link'**
  String get failedToDeleteShareLink;

  /// No description provided for @deletingFile.
  ///
  /// In en, this message translates to:
  /// **'Deleting file...'**
  String get deletingFile;

  /// No description provided for @changeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get changeEmail;

  /// No description provided for @authToChangeYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Please authenticate to change your email'**
  String get authToChangeYourEmail;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePasswordTitle;

  /// No description provided for @authToChangeYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Please authenticate to change your password'**
  String get authToChangeYourPassword;

  /// No description provided for @recoveryKey.
  ///
  /// In en, this message translates to:
  /// **'Recovery key'**
  String get recoveryKey;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'Ok'**
  String get ok;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @areYouSureYouWantToLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get areYouSureYouWantToLogout;

  /// No description provided for @yesLogout.
  ///
  /// In en, this message translates to:
  /// **'Yes, logout'**
  String get yesLogout;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @authToViewYourRecoveryKey.
  ///
  /// In en, this message translates to:
  /// **'Please authenticate to view your recovery key'**
  String get authToViewYourRecoveryKey;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @emailVerificationToggle.
  ///
  /// In en, this message translates to:
  /// **'Email verification'**
  String get emailVerificationToggle;

  /// No description provided for @authToChangeEmailVerificationSetting.
  ///
  /// In en, this message translates to:
  /// **'Please authenticate to change email verification'**
  String get authToChangeEmailVerificationSetting;

  /// No description provided for @passkey.
  ///
  /// In en, this message translates to:
  /// **'Passkey'**
  String get passkey;

  /// No description provided for @authenticateGeneric.
  ///
  /// In en, this message translates to:
  /// **'Please authenticate'**
  String get authenticateGeneric;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @appLock.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get appLock;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @appLockOfflineModeWarning.
  ///
  /// In en, this message translates to:
  /// **'You have chosen to proceed without backups. If you forget your applock, you will be locked out from accessing your data.'**
  String get appLockOfflineModeWarning;

  /// No description provided for @authToChangeLockscreenSetting.
  ///
  /// In en, this message translates to:
  /// **'Please authenticate to change lockscreen setting'**
  String get authToChangeLockscreenSetting;

  /// No description provided for @authToViewPasskey.
  ///
  /// In en, this message translates to:
  /// **'Please authenticate to view passkey'**
  String get authToViewPasskey;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @weAreOpenSource.
  ///
  /// In en, this message translates to:
  /// **'We are open source!'**
  String get weAreOpenSource;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get terms;

  /// No description provided for @termsOfServicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get termsOfServicesTitle;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get contactSupport;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @suggestFeatures.
  ///
  /// In en, this message translates to:
  /// **'Suggest features'**
  String get suggestFeatures;

  /// No description provided for @reportABug.
  ///
  /// In en, this message translates to:
  /// **'Report a bug'**
  String get reportABug;

  /// No description provided for @reportBug.
  ///
  /// In en, this message translates to:
  /// **'Report bug'**
  String get reportBug;

  /// No description provided for @social.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get social;

  /// No description provided for @rateUsOnStore.
  ///
  /// In en, this message translates to:
  /// **'Rate us on {storeName}'**
  String rateUsOnStore(Object storeName);

  /// No description provided for @blog.
  ///
  /// In en, this message translates to:
  /// **'Blog'**
  String get blog;

  /// No description provided for @merchandise.
  ///
  /// In en, this message translates to:
  /// **'Merchandise'**
  String get merchandise;

  /// No description provided for @twitter.
  ///
  /// In en, this message translates to:
  /// **'Twitter'**
  String get twitter;

  /// No description provided for @mastodon.
  ///
  /// In en, this message translates to:
  /// **'Mastodon'**
  String get mastodon;

  /// No description provided for @matrix.
  ///
  /// In en, this message translates to:
  /// **'Matrix'**
  String get matrix;

  /// No description provided for @discord.
  ///
  /// In en, this message translates to:
  /// **'Discord'**
  String get discord;

  /// No description provided for @reddit.
  ///
  /// In en, this message translates to:
  /// **'Reddit'**
  String get reddit;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
