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
  /// **'No items here'**
  String get noFilesFound;

  /// No description provided for @addFiles.
  ///
  /// In en, this message translates to:
  /// **'Add items'**
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
  /// **'Download failed'**
  String get downloadFailed;

  /// No description provided for @failedToDownloadOrDecrypt.
  ///
  /// In en, this message translates to:
  /// **'Failed to download item'**
  String get failedToDownloadOrDecrypt;

  /// No description provided for @errorOpeningFile.
  ///
  /// In en, this message translates to:
  /// **'Error opening item'**
  String get errorOpeningFile;

  /// Error message when opening an item fails
  ///
  /// In en, this message translates to:
  /// **'Error opening item: {error}'**
  String errorOpeningFileMessage(String error);

  /// Error message when item cannot be opened
  ///
  /// In en, this message translates to:
  /// **'Could not open item: {error}'**
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
  /// **'Item deleted successfully'**
  String get fileDeletedSuccessfully;

  /// Error message when item deletion fails
  ///
  /// In en, this message translates to:
  /// **'Failed to delete item: {error}'**
  String failedToDeleteFile(String error);

  /// No description provided for @fileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Item updated successfully!'**
  String get fileUpdatedSuccessfully;

  /// Error message when item update fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update item: {error}'**
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

  /// Message when item is permanently deleted from trash
  ///
  /// In en, this message translates to:
  /// **'Deleted \"{fileName}\" permanently'**
  String deletedPermanently(String fileName);

  /// Error message when item restoration fails
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
  /// **'Delete item'**
  String get deleteFile;

  /// Confirmation message for item deletion
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
  /// **'Create collection'**
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

  /// No description provided for @collectionEmptyStateTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to see here'**
  String get collectionEmptyStateTitle;

  /// No description provided for @collectionEmptyStateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'There are no items in this collection'**
  String get collectionEmptyStateSubtitle;

  /// No description provided for @yourTrashIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your trash is empty'**
  String get yourTrashIsEmpty;

  /// No description provided for @homeLockerEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Locker is empty'**
  String get homeLockerEmptyTitle;

  /// No description provided for @homeLockerEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Click the + button to get started'**
  String get homeLockerEmptySubtitle;

  /// No description provided for @uploadDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload document'**
  String get uploadDocument;

  /// Number of items in a collection
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String items(int count);

  /// Number of items in a collection
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no items} =1{1 item} other{{count} items}}'**
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

  /// Dialog title for restoring an item from trash
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
  /// **'Item title'**
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

  /// No description provided for @searchEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches found'**
  String get searchEmptyTitle;

  /// No description provided for @searchEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Try searching for something else.'**
  String get searchEmptyDescription;

  /// CTA title prompting the user to search globally
  ///
  /// In en, this message translates to:
  /// **'Search everywhere for \"{query}\"'**
  String searchEverywhereTitle(String query);

  /// No description provided for @searchEverywhereSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search across all collections and files.'**
  String get searchEverywhereSubtitle;

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

  /// Success message when an item is restored to a collection
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
  /// **'This link allows anyone who receives it to access your item. You can remove access at any time by deleting the link.'**
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
  /// **'People with this link will no longer be able to access the item.'**
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
  /// **'Deleting item...'**
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

  /// Dialog body text for sending logs in Locker app (without file name warning)
  ///
  /// In en, this message translates to:
  /// **'This will send logs to help us debug your issue.'**
  String get logsDialogBodyLocker;

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

  /// No description provided for @information.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get information;

  /// No description provided for @saveInformation.
  ///
  /// In en, this message translates to:
  /// **'Save information'**
  String get saveInformation;

  /// No description provided for @saveToLocker.
  ///
  /// In en, this message translates to:
  /// **'Save to Locker'**
  String get saveToLocker;

  /// No description provided for @saveDocumentTitle.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get saveDocumentTitle;

  /// No description provided for @saveDocumentDescription.
  ///
  /// In en, this message translates to:
  /// **'Upload important docs.'**
  String get saveDocumentDescription;

  /// No description provided for @informationDescription.
  ///
  /// In en, this message translates to:
  /// **'Save and share information with loved ones.'**
  String get informationDescription;

  /// No description provided for @personalNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get personalNote;

  /// No description provided for @personalNoteDescription.
  ///
  /// In en, this message translates to:
  /// **'Write down thoughts and instructions.'**
  String get personalNoteDescription;

  /// No description provided for @physicalRecords.
  ///
  /// In en, this message translates to:
  /// **'Thing'**
  String get physicalRecords;

  /// No description provided for @physicalRecordsDescription.
  ///
  /// In en, this message translates to:
  /// **'Save locations of real-world items.'**
  String get physicalRecordsDescription;

  /// No description provided for @accountCredentials.
  ///
  /// In en, this message translates to:
  /// **'Secret'**
  String get accountCredentials;

  /// No description provided for @accountCredentialsDescription.
  ///
  /// In en, this message translates to:
  /// **'Preserve account credentials.'**
  String get accountCredentialsDescription;

  /// Title shown when editing an existing secret
  ///
  /// In en, this message translates to:
  /// **'Edit secret'**
  String get editSecret;

  /// Title shown when editing an existing location record
  ///
  /// In en, this message translates to:
  /// **'Edit location'**
  String get editLocation;

  /// Title shown when editing an existing note
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get editNote;

  /// No description provided for @emergencyContact.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact'**
  String get emergencyContact;

  /// No description provided for @emergencyContactDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep contact info for key people in crises.'**
  String get emergencyContactDescription;

  /// No description provided for @noteName.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get noteName;

  /// No description provided for @noteNameHint.
  ///
  /// In en, this message translates to:
  /// **'Hint text'**
  String get noteNameHint;

  /// No description provided for @noteContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get noteContent;

  /// No description provided for @noteContentHint.
  ///
  /// In en, this message translates to:
  /// **'Write down important thoughts or instructions'**
  String get noteContentHint;

  /// No description provided for @unsavedNoteChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get unsavedNoteChangesTitle;

  /// No description provided for @unsavedNoteChangesDescription.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes in this note. If you go back now, they will be lost.'**
  String get unsavedNoteChangesDescription;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// No description provided for @discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardChanges;

  /// No description provided for @recordName.
  ///
  /// In en, this message translates to:
  /// **'Record name'**
  String get recordName;

  /// No description provided for @recordNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name of the real-world item'**
  String get recordNameHint;

  /// No description provided for @recordLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get recordLocation;

  /// No description provided for @recordLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Where is this item kept?'**
  String get recordLocationHint;

  /// No description provided for @recordNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get recordNotes;

  /// No description provided for @recordNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Additional information about the item'**
  String get recordNotesHint;

  /// No description provided for @credentialName.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get credentialName;

  /// No description provided for @credentialNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name of the service'**
  String get credentialNameHint;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'Login ID or email'**
  String get usernameHint;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordHint;

  /// No description provided for @credentialNotes.
  ///
  /// In en, this message translates to:
  /// **'Additional notes'**
  String get credentialNotes;

  /// No description provided for @credentialNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Recovery methods, security questions, ...'**
  String get credentialNotesHint;

  /// No description provided for @contactName.
  ///
  /// In en, this message translates to:
  /// **'Contact name'**
  String get contactName;

  /// No description provided for @contactNameHint.
  ///
  /// In en, this message translates to:
  /// **'Full name of the emergency contact'**
  String get contactNameHint;

  /// No description provided for @contactDetails.
  ///
  /// In en, this message translates to:
  /// **'Contact details'**
  String get contactDetails;

  /// No description provided for @contactDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Phone number, email, or other contact information'**
  String get contactDetailsHint;

  /// No description provided for @contactNotes.
  ///
  /// In en, this message translates to:
  /// **'Message for contact'**
  String get contactNotes;

  /// No description provided for @contactNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Important information to share with this person when they are contacted'**
  String get contactNotesHint;

  /// No description provided for @saveRecord.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveRecord;

  /// No description provided for @recordSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Record saved successfully'**
  String get recordSavedSuccessfully;

  /// No description provided for @failedToSaveRecord.
  ///
  /// In en, this message translates to:
  /// **'Failed to save record'**
  String get failedToSaveRecord;

  /// No description provided for @pleaseEnterNoteName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get pleaseEnterNoteName;

  /// No description provided for @pleaseEnterNoteContent.
  ///
  /// In en, this message translates to:
  /// **'Please enter content'**
  String get pleaseEnterNoteContent;

  /// No description provided for @pleaseEnterRecordName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a record name'**
  String get pleaseEnterRecordName;

  /// No description provided for @pleaseEnterLocation.
  ///
  /// In en, this message translates to:
  /// **'Please enter a location'**
  String get pleaseEnterLocation;

  /// No description provided for @pleaseEnterAccountName.
  ///
  /// In en, this message translates to:
  /// **'Please enter an account name'**
  String get pleaseEnterAccountName;

  /// No description provided for @pleaseEnterUsername.
  ///
  /// In en, this message translates to:
  /// **'Please enter a username'**
  String get pleaseEnterUsername;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get pleaseEnterPassword;

  /// No description provided for @pleaseEnterContactName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a contact name'**
  String get pleaseEnterContactName;

  /// No description provided for @pleaseEnterContactDetails.
  ///
  /// In en, this message translates to:
  /// **'Please enter contact details'**
  String get pleaseEnterContactDetails;

  /// No description provided for @allowDownloads.
  ///
  /// In en, this message translates to:
  /// **'Allow downloads'**
  String get allowDownloads;

  /// No description provided for @sharedByYou.
  ///
  /// In en, this message translates to:
  /// **'Shared by you'**
  String get sharedByYou;

  /// No description provided for @sharedWithYou.
  ///
  /// In en, this message translates to:
  /// **'Shared with you'**
  String get sharedWithYou;

  /// No description provided for @manageLink.
  ///
  /// In en, this message translates to:
  /// **'Manage link'**
  String get manageLink;

  /// No description provided for @linkExpiry.
  ///
  /// In en, this message translates to:
  /// **'Link expiry'**
  String get linkExpiry;

  /// No description provided for @linkNeverExpires.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get linkNeverExpires;

  /// No description provided for @linkExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get linkExpired;

  /// No description provided for @linkEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get linkEnabled;

  /// No description provided for @setAPassword.
  ///
  /// In en, this message translates to:
  /// **'Set a password'**
  String get setAPassword;

  /// No description provided for @lockButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get lockButtonLabel;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enterPassword;

  /// No description provided for @removeLink.
  ///
  /// In en, this message translates to:
  /// **'Remove link'**
  String get removeLink;

  /// No description provided for @sendLink.
  ///
  /// In en, this message translates to:
  /// **'Send link'**
  String get sendLink;

  /// No description provided for @setPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set password'**
  String get setPasswordTitle;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordTitle;

  /// No description provided for @allowAddingFiles.
  ///
  /// In en, this message translates to:
  /// **'Allow adding items'**
  String get allowAddingFiles;

  /// No description provided for @disableDownloadWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Please note'**
  String get disableDownloadWarningTitle;

  /// No description provided for @disableDownloadWarningBody.
  ///
  /// In en, this message translates to:
  /// **'Viewers can still take screenshots or save a copy of your items using external tools.'**
  String get disableDownloadWarningBody;

  /// No description provided for @allowAddFilesDescription.
  ///
  /// In en, this message translates to:
  /// **'Allow people with the link to also add items to the shared collection.'**
  String get allowAddFilesDescription;

  /// No description provided for @after1Hour.
  ///
  /// In en, this message translates to:
  /// **'After 1 hour'**
  String get after1Hour;

  /// No description provided for @after1Day.
  ///
  /// In en, this message translates to:
  /// **'After 1 day'**
  String get after1Day;

  /// No description provided for @after1Week.
  ///
  /// In en, this message translates to:
  /// **'After 1 week'**
  String get after1Week;

  /// No description provided for @after1Month.
  ///
  /// In en, this message translates to:
  /// **'After 1 month'**
  String get after1Month;

  /// No description provided for @after1Year.
  ///
  /// In en, this message translates to:
  /// **'After 1 year'**
  String get after1Year;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get selectTime;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @noDeviceLimit.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noDeviceLimit;

  /// No description provided for @linkDeviceLimit.
  ///
  /// In en, this message translates to:
  /// **'Device limit'**
  String get linkDeviceLimit;

  /// No description provided for @expiredLinkInfo.
  ///
  /// In en, this message translates to:
  /// **'This link has expired. Please select a new expiry time or disable link expiry.'**
  String get expiredLinkInfo;

  /// No description provided for @linkExpiresOn.
  ///
  /// In en, this message translates to:
  /// **'Link will expire on {expiryTime}'**
  String linkExpiresOn(Object expiryTime);

  /// No description provided for @shareWithPeopleSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'{numberOfPeople, plural, =0 {Share with specific people} =1 {Shared with 1 person} other {Shared with {numberOfPeople} people}}'**
  String shareWithPeopleSectionTitle(int numberOfPeople);

  /// No description provided for @linkHasExpired.
  ///
  /// In en, this message translates to:
  /// **'Link has expired'**
  String get linkHasExpired;

  /// No description provided for @publicLinkEnabled.
  ///
  /// In en, this message translates to:
  /// **'Public link enabled'**
  String get publicLinkEnabled;

  /// No description provided for @shareALink.
  ///
  /// In en, this message translates to:
  /// **'Share a link'**
  String get shareALink;

  /// No description provided for @addViewer.
  ///
  /// In en, this message translates to:
  /// **'Add viewer'**
  String get addViewer;

  /// No description provided for @addCollaborator.
  ///
  /// In en, this message translates to:
  /// **'Add collaborator'**
  String get addCollaborator;

  /// No description provided for @addANewEmail.
  ///
  /// In en, this message translates to:
  /// **'Add a new email'**
  String get addANewEmail;

  /// No description provided for @orPickAnExistingOne.
  ///
  /// In en, this message translates to:
  /// **'Or pick an existing one'**
  String get orPickAnExistingOne;

  /// No description provided for @sharedCollectionSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Create shared and collaborative collections with other Ente users, including users on free plans.'**
  String get sharedCollectionSectionDescription;

  /// No description provided for @createPublicLink.
  ///
  /// In en, this message translates to:
  /// **'Create public link'**
  String get createPublicLink;

  /// No description provided for @addParticipants.
  ///
  /// In en, this message translates to:
  /// **'Add participants'**
  String get addParticipants;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @collaboratorsCanAddFilesToTheSharedCollection.
  ///
  /// In en, this message translates to:
  /// **'Collaborators can add items to the shared collection.'**
  String get collaboratorsCanAddFilesToTheSharedCollection;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter email'**
  String get enterEmail;

  /// Number of viewers that were successfully added to a collection.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0 {Added 0 viewers} =1 {Added 1 viewer} other {Added {count} viewers}}'**
  String viewersSuccessfullyAdded(int count);

  /// Number of collaborators that were successfully added to a collection.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0 {Added 0 collaborator} =1 {Added 1 collaborator} other {Added {count} collaborators}}'**
  String collaboratorsSuccessfullyAdded(int count);

  /// No description provided for @addViewers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0 {Add viewer} =1 {Add viewer} other {Add viewers}}'**
  String addViewers(num count);

  /// No description provided for @addCollaborators.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0 {Add collaborator} =1 {Add collaborator} other {Add collaborators}}'**
  String addCollaborators(num count);

  /// No description provided for @longPressAnEmailToVerifyEndToEndEncryption.
  ///
  /// In en, this message translates to:
  /// **'Long press an email to verify end to end encryption.'**
  String get longPressAnEmailToVerifyEndToEndEncryption;

  /// No description provided for @sharing.
  ///
  /// In en, this message translates to:
  /// **'Sharing...'**
  String get sharing;

  /// No description provided for @invalidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get invalidEmailAddress;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get enterValidEmail;

  /// No description provided for @oops.
  ///
  /// In en, this message translates to:
  /// **'Oops'**
  String get oops;

  /// No description provided for @noItemsMatchSelectedFilters.
  ///
  /// In en, this message translates to:
  /// **'No items match the selected filters'**
  String get noItemsMatchSelectedFilters;

  /// No description provided for @noCollections.
  ///
  /// In en, this message translates to:
  /// **'No collections'**
  String get noCollections;

  /// No description provided for @youCannotShareWithYourself.
  ///
  /// In en, this message translates to:
  /// **'You cannot share with yourself'**
  String get youCannotShareWithYourself;

  /// No description provided for @inviteToEnte.
  ///
  /// In en, this message translates to:
  /// **'Invite to Ente'**
  String get inviteToEnte;

  /// No description provided for @sendInvite.
  ///
  /// In en, this message translates to:
  /// **'Send invite'**
  String get sendInvite;

  /// No description provided for @shareTextRecommendUsingEnte.
  ///
  /// In en, this message translates to:
  /// **'Download Ente\n\nhttps://ente.io'**
  String get shareTextRecommendUsingEnte;

  /// No description provided for @thisIsYourVerificationId.
  ///
  /// In en, this message translates to:
  /// **'This is your Verification ID'**
  String get thisIsYourVerificationId;

  /// No description provided for @someoneSharingAlbumsWithYouShouldSeeTheSameId.
  ///
  /// In en, this message translates to:
  /// **'Someone sharing albums with you should see the same ID on their device.'**
  String get someoneSharingAlbumsWithYouShouldSeeTheSameId;

  /// No description provided for @howToViewShareeVerificationID.
  ///
  /// In en, this message translates to:
  /// **'Please ask them to long-press their email address on the settings screen, and verify that the IDs on both devices match.'**
  String get howToViewShareeVerificationID;

  /// No description provided for @thisIsPersonVerificationId.
  ///
  /// In en, this message translates to:
  /// **'This is {email}\'s Verification ID'**
  String thisIsPersonVerificationId(String email);

  /// No description provided for @verificationId.
  ///
  /// In en, this message translates to:
  /// **'Verification ID'**
  String get verificationId;

  /// No description provided for @verifyEmailID.
  ///
  /// In en, this message translates to:
  /// **'Verify {email}'**
  String verifyEmailID(Object email);

  /// No description provided for @emailNoEnteAccount.
  ///
  /// In en, this message translates to:
  /// **'{email} does not have an Ente account.\n\nSend them an invite to share items.'**
  String emailNoEnteAccount(Object email);

  /// No description provided for @shareMyVerificationID.
  ///
  /// In en, this message translates to:
  /// **'Here\'s my verification ID: {verificationID} for ente.io.'**
  String shareMyVerificationID(Object verificationID);

  /// No description provided for @shareTextConfirmOthersVerificationID.
  ///
  /// In en, this message translates to:
  /// **'Hey, can you confirm that this is your ente.io verification ID: {verificationID}'**
  String shareTextConfirmOthersVerificationID(Object verificationID);

  /// No description provided for @passwordLock.
  ///
  /// In en, this message translates to:
  /// **'Password lock'**
  String get passwordLock;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @addedAs.
  ///
  /// In en, this message translates to:
  /// **'Added as'**
  String get addedAs;

  /// No description provided for @removeParticipant.
  ///
  /// In en, this message translates to:
  /// **'Remove participant'**
  String get removeParticipant;

  /// No description provided for @yesConvertToViewer.
  ///
  /// In en, this message translates to:
  /// **'Yes, convert to viewer'**
  String get yesConvertToViewer;

  /// No description provided for @changePermissions.
  ///
  /// In en, this message translates to:
  /// **'Change permissions'**
  String get changePermissions;

  /// Warning message when changing a collaborator to viewer
  ///
  /// In en, this message translates to:
  /// **'{name} will no longer be able to add items to the collection after becoming a viewer.'**
  String cannotAddMoreFilesAfterBecomingViewer(String name);

  /// No description provided for @removeWithQuestionMark.
  ///
  /// In en, this message translates to:
  /// **'Remove?'**
  String get removeWithQuestionMark;

  /// No description provided for @removeParticipantBody.
  ///
  /// In en, this message translates to:
  /// **'{userEmail} will be removed from this shared collection\n\nAny items added by them will also be removed from the collection'**
  String removeParticipantBody(Object userEmail);

  /// No description provided for @yesRemove.
  ///
  /// In en, this message translates to:
  /// **'Yes, remove'**
  String get yesRemove;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @viewer.
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get viewer;

  /// No description provided for @collaborator.
  ///
  /// In en, this message translates to:
  /// **'Collaborator'**
  String get collaborator;

  /// No description provided for @collaboratorsCanAddFilesToTheSharedAlbum.
  ///
  /// In en, this message translates to:
  /// **'Collaborators can add items to the shared collection.'**
  String get collaboratorsCanAddFilesToTheSharedAlbum;

  /// The count of participants in an album
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0 {No Participants} =1 {1 Participant} other {{count} Participants}}'**
  String albumParticipantsCount(int count);

  /// No description provided for @addMore.
  ///
  /// In en, this message translates to:
  /// **'Add more'**
  String get addMore;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @albumOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get albumOwner;

  /// No description provided for @typeOfCollectionTypeIsNotSupportedForRename.
  ///
  /// In en, this message translates to:
  /// **'Type of collection {collectionType} is not supported for rename'**
  String typeOfCollectionTypeIsNotSupportedForRename(String collectionType);

  /// No description provided for @leaveCollection.
  ///
  /// In en, this message translates to:
  /// **'Leave collection'**
  String get leaveCollection;

  /// No description provided for @filesAddedByYouWillBeRemovedFromTheCollection.
  ///
  /// In en, this message translates to:
  /// **'Items added by you will be removed from the collection'**
  String get filesAddedByYouWillBeRemovedFromTheCollection;

  /// No description provided for @leaveSharedCollection.
  ///
  /// In en, this message translates to:
  /// **'Leave shared collection?'**
  String get leaveSharedCollection;

  /// No description provided for @noSystemLockFound.
  ///
  /// In en, this message translates to:
  /// **'No system lock found'**
  String get noSystemLockFound;

  /// No description provided for @toEnableAppLockPleaseSetupDevicePasscodeOrScreen.
  ///
  /// In en, this message translates to:
  /// **'To enable app lock, please setup device passcode or screen lock in your system settings.'**
  String get toEnableAppLockPleaseSetupDevicePasscodeOrScreen;

  /// No description provided for @legacy.
  ///
  /// In en, this message translates to:
  /// **'Legacy'**
  String get legacy;

  /// No description provided for @authToManageLegacy.
  ///
  /// In en, this message translates to:
  /// **'Please authenticate to manage your trusted contacts'**
  String get authToManageLegacy;

  /// No description provided for @uploadError.
  ///
  /// In en, this message translates to:
  /// **'Upload error'**
  String get uploadError;

  /// Title shown when uploads fail due to running out of storage
  ///
  /// In en, this message translates to:
  /// **'Storage limit reached'**
  String get uploadStorageLimitErrorTitle;

  /// Body shown when uploads fail due to running out of storage
  ///
  /// In en, this message translates to:
  /// **'You\'ve run out of storage space. Free up space to continue uploading.'**
  String get uploadStorageLimitErrorBody;

  /// Title shown when uploads fail because the locker already has the maximum file count
  ///
  /// In en, this message translates to:
  /// **'File limit reached'**
  String get uploadFileCountLimitErrorTitle;

  /// Body shown when uploads fail because the locker already has the maximum file count
  ///
  /// In en, this message translates to:
  /// **'Your individual or family account has hit the 1000-file limit.'**
  String get uploadFileCountLimitErrorBody;

  /// Toast shown when info items fail to save due to hitting the file count limit
  ///
  /// In en, this message translates to:
  /// **'Action failed. Your individual or family account has hit the 1000-file limit.'**
  String get uploadFileCountLimitErrorToast;

  /// Message shown when uploads fail because the user does not have an active subscription
  ///
  /// In en, this message translates to:
  /// **'Subscription required to save info items.'**
  String get uploadSubscriptionRequiredErrorBody;

  /// Title shown when uploads fail because the file exceeds the supported size
  ///
  /// In en, this message translates to:
  /// **'File too large'**
  String get uploadFileTooLargeErrorTitle;

  /// Body shown when uploads fail because the file exceeds the supported size
  ///
  /// In en, this message translates to:
  /// **'This file is larger than the maximum supported upload size of 10GB.'**
  String get uploadFileTooLargeErrorBody;

  /// No description provided for @tryAdjustingYourSearchQuery.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search query'**
  String get tryAdjustingYourSearchQuery;

  /// Message when no items match the search query
  ///
  /// In en, this message translates to:
  /// **'No items found for \"{query}\"'**
  String noFilesFoundForQuery(String query);

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get deselectAll;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @unnamedCollection.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Collection'**
  String get unnamedCollection;

  /// No description provided for @enteLocker.
  ///
  /// In en, this message translates to:
  /// **'ente Locker'**
  String get enteLocker;

  /// Progress message showing uploaded items
  ///
  /// In en, this message translates to:
  /// **'Uploaded {completed}/{total} items...'**
  String uploadedFilesProgress(int completed, int total);

  /// Progress message showing uploaded items with error
  ///
  /// In en, this message translates to:
  /// **'Uploaded {completed}/{total} items... ({error})'**
  String uploadedFilesProgressWithError(int completed, int total, String error);

  /// No description provided for @noCollectionsAvailableForSelection.
  ///
  /// In en, this message translates to:
  /// **'No collections available'**
  String get noCollectionsAvailableForSelection;

  /// No description provided for @createCollectionButton.
  ///
  /// In en, this message translates to:
  /// **'Create collection'**
  String get createCollectionButton;

  /// No description provided for @collectionButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get collectionButtonLabel;

  /// No description provided for @hideWindow.
  ///
  /// In en, this message translates to:
  /// **'Hide window'**
  String get hideWindow;

  /// No description provided for @showWindow.
  ///
  /// In en, this message translates to:
  /// **'Show window'**
  String get showWindow;

  /// No description provided for @exitApp.
  ///
  /// In en, this message translates to:
  /// **'Exit app'**
  String get exitApp;

  /// No description provided for @lockerLogs.
  ///
  /// In en, this message translates to:
  /// **'Locker logs'**
  String get lockerLogs;

  /// No description provided for @recents.
  ///
  /// In en, this message translates to:
  /// **'Recents'**
  String get recents;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @uploadAFile.
  ///
  /// In en, this message translates to:
  /// **'Upload an item'**
  String get uploadAFile;

  /// No description provided for @clickHereToUpload.
  ///
  /// In en, this message translates to:
  /// **'Click here to upload'**
  String get clickHereToUpload;

  /// No description provided for @saveDocument.
  ///
  /// In en, this message translates to:
  /// **'Save document'**
  String get saveDocument;

  /// No description provided for @uploadFiles.
  ///
  /// In en, this message translates to:
  /// **'Upload items'**
  String get uploadFiles;

  /// Number of items selected for upload
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No items selected} =1{1 item selected} other{{count} items selected}}'**
  String filesSelected(int count);

  /// No description provided for @addToCollection.
  ///
  /// In en, this message translates to:
  /// **'Add to collection'**
  String get addToCollection;

  /// No description provided for @newCollection.
  ///
  /// In en, this message translates to:
  /// **'New collection'**
  String get newCollection;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @editItem.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get editItem;

  /// No description provided for @enterNewTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a new title'**
  String get enterNewTitle;

  /// No description provided for @backToView.
  ///
  /// In en, this message translates to:
  /// **'Back to view'**
  String get backToView;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Error message when loading collections fails
  ///
  /// In en, this message translates to:
  /// **'Failed to load collections: {error}'**
  String failedToLoadCollections(String error);

  /// No description provided for @informationCollectionName.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get informationCollectionName;

  /// Success message when record is saved to multiple collections
  ///
  /// In en, this message translates to:
  /// **'Record saved to {count, plural, =1{1 collection} other{{count} collections}} successfully'**
  String recordSavedToMultipleCollections(int count);

  /// Message when a field is copied to clipboard
  ///
  /// In en, this message translates to:
  /// **'{fieldName} copied to clipboard'**
  String copiedToClipboard(String fieldName);

  /// Search results count message
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 result} other{{count} results}} for \"{query}\"'**
  String searchResultsCount(int count, String query);

  /// No description provided for @locker.
  ///
  /// In en, this message translates to:
  /// **'Locker'**
  String get locker;

  /// No description provided for @loginToEnteAccount.
  ///
  /// In en, this message translates to:
  /// **'Log in to your Ente account'**
  String get loginToEnteAccount;

  /// No description provided for @unlockLockerPaidPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock Locker with a paid plan.'**
  String get unlockLockerPaidPlanTitle;

  /// No description provided for @unlockLockerPaidPlanBody.
  ///
  /// In en, this message translates to:
  /// **'Locker is available only to Ente photos paid users. Upgrade to a paid plan from Photos to use Locker'**
  String get unlockLockerPaidPlanBody;

  /// No description provided for @checkoutEntePhotos.
  ///
  /// In en, this message translates to:
  /// **'Checkout Ente Photos'**
  String get checkoutEntePhotos;

  /// No description provided for @okay.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get okay;

  /// No description provided for @noAccountCta.
  ///
  /// In en, this message translates to:
  /// **'I don\'t have an account'**
  String get noAccountCta;

  /// No description provided for @featureSaveImportant.
  ///
  /// In en, this message translates to:
  /// **'Save your important documents and credentials'**
  String get featureSaveImportant;

  /// No description provided for @featurePassAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Pass them on automatically in emergencies'**
  String get featurePassAutomatically;

  /// No description provided for @featureShareAnytime.
  ///
  /// In en, this message translates to:
  /// **'Share them anytime'**
  String get featureShareAnytime;

  /// No description provided for @emailIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailIdLabel;

  /// No description provided for @emailIdHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get emailIdHint;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordLabel;

  /// No description provided for @loginPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get loginPasswordHint;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @logInAction.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logInAction;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @incorrectPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get incorrectPassword;

  /// No description provided for @pleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Please try again'**
  String get pleaseTryAgain;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// No description provided for @checkInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection and try again'**
  String get checkInternetConnection;

  /// No description provided for @verificationFailedTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Verification failed, please try again'**
  String get verificationFailedTryAgain;

  /// No description provided for @recreatePassword.
  ///
  /// In en, this message translates to:
  /// **'Recreate password'**
  String get recreatePassword;

  /// No description provided for @deviceCannotVerifyPassword.
  ///
  /// In en, this message translates to:
  /// **'Your device does not have enough memory to verify your password'**
  String get deviceCannotVerifyPassword;

  /// No description provided for @useRecoveryKey.
  ///
  /// In en, this message translates to:
  /// **'Use recovery key'**
  String get useRecoveryKey;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get invalidEmail;

  /// No description provided for @enterValidEmailFirst.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address first'**
  String get enterValidEmailFirst;

  /// No description provided for @lockerLoginIssueSubject.
  ///
  /// In en, this message translates to:
  /// **'Locker login issue'**
  String get lockerLoginIssueSubject;

  /// No description provided for @unnamed.
  ///
  /// In en, this message translates to:
  /// **'Unnamed'**
  String get unnamed;

  /// No description provided for @collectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get collectionLabel;

  /// No description provided for @areYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// No description provided for @yesDeleteCollection.
  ///
  /// In en, this message translates to:
  /// **'Yes, delete collection'**
  String get yesDeleteCollection;

  /// No description provided for @yesDeleteFile.
  ///
  /// In en, this message translates to:
  /// **'Yes, delete item'**
  String get yesDeleteFile;

  /// Confirmation message body for deleting a single collection
  ///
  /// In en, this message translates to:
  /// **'{collectionName} will be deleted permanently.'**
  String deleteCollectionDialogBody(String collectionName);

  /// Confirmation message body for deleting multiple collections
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 collection} other{{count} collections}} will be deleted permanently.'**
  String deleteMultipleCollectionsDialogBody(int count);

  /// Confirmation message body for deleting multiple items
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}} will be deleted permanently.'**
  String deleteMultipleFilesDialogBody(int count);

  /// Checkbox label asking whether to delete collection items everywhere
  ///
  /// In en, this message translates to:
  /// **'Also delete items from everywhere'**
  String get deleteCollectionFromEverywhere;

  /// Button label for confirming deletion of one or more collections
  ///
  /// In en, this message translates to:
  /// **'Yes, delete {count, plural, =1{collection} other{collections}}'**
  String yesDeleteCollections(int count);

  /// Button label for confirming deletion of one or more items
  ///
  /// In en, this message translates to:
  /// **'Yes, delete {count, plural, =1{item} other{items}}'**
  String yesDeleteFiles(int count);

  /// No description provided for @usage.
  ///
  /// In en, this message translates to:
  /// **'Usage'**
  String get usage;

  /// Display item count usage in the format 'used / max'
  ///
  /// In en, this message translates to:
  /// **'{used} / {max}'**
  String fileCount(String used, String max);
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
