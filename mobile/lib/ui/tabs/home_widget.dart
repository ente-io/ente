import 'dart:async';
import "dart:convert";
import "dart:io";

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import 'package:logging/logging.dart';
import "package:media_extension/media_extension_action_types.dart";
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import "package:move_to_background/move_to_background.dart";
import "package:package_info_plus/package_info_plus.dart";
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/events/account_configured_event.dart';
import 'package:photos/events/backup_folders_updated_event.dart';
import "package:photos/events/collection_updated_event.dart";
import "package:photos/events/files_updated_event.dart";
import 'package:photos/events/permission_granted_event.dart';
import 'package:photos/events/subscription_purchased_event.dart';
import 'package:photos/events/sync_status_update_event.dart';
import 'package:photos/events/tab_changed_event.dart';
import 'package:photos/events/trigger_logout_event.dart';
import 'package:photos/events/user_logged_out_event.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/collection/collection.dart";
import 'package:photos/models/collection/collection_items.dart';
import "package:photos/models/file/file.dart";
import 'package:photos/models/selected_files.dart';
import "package:photos/service_locator.dart";
import 'package:photos/services/app_lifecycle_service.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/local_sync_service.dart';
import "package:photos/services/notification_service.dart";
import "package:photos/services/remote_sync_service.dart";
import 'package:photos/services/user_service.dart';
import 'package:photos/states/user_details_state.dart';
import 'package:photos/theme/colors.dart';
import "package:photos/theme/effects.dart";
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/collections/collection_action_sheet.dart';
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import 'package:photos/ui/extents_page_view.dart';
import 'package:photos/ui/home/grant_permissions_widget.dart';
import 'package:photos/ui/home/header_widget.dart';
import 'package:photos/ui/home/home_bottom_nav_bar.dart';
import 'package:photos/ui/home/home_gallery_widget.dart';
import 'package:photos/ui/home/landing_page_widget.dart';
import "package:photos/ui/home/loading_photos_widget.dart";
import 'package:photos/ui/home/start_backup_hook_widget.dart';
import 'package:photos/ui/notification/update/change_log_page.dart';
import "package:photos/ui/settings/app_update_dialog.dart";
import "package:photos/ui/settings_page.dart";
import "package:photos/ui/tabs/shared_collections_tab.dart";
import "package:photos/ui/tabs/user_collections_tab.dart";
import "package:photos/ui/viewer/actions/file_viewer.dart";
import "package:photos/ui/viewer/gallery/collection_page.dart";
import "package:photos/ui/viewer/gallery/shared_public_collection_page.dart";
import "package:photos/ui/viewer/search/search_widget.dart";
import 'package:photos/ui/viewer/search_tab/search_tab.dart';
import "package:photos/utils/collection_util.dart";
import "package:photos/utils/crypto_util.dart";
import 'package:photos/utils/dialog_util.dart';
import "package:photos/utils/diff_fetcher.dart";
import "package:photos/utils/navigation_util.dart";
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:uni_links/uni_links.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  static const _userCollectionsTab = UserCollectionsTab();
  static const _sharedCollectionTab = SharedCollectionsTab();
  static const _searchTab = SearchTab();
  static final _settingsPage = SettingsPage(
    emailNotifier: UserService.instance.emailValueNotifier,
  );

  final _logger = Logger("HomeWidgetState");
  final _selectedFiles = SelectedFiles();

  final PageController _pageController = PageController();
  int _selectedTabIndex = 0;

  // for receiving media files
  // ignore: unused_field
  StreamSubscription? _intentDataStreamSubscription;
  List<SharedMediaFile>? _sharedFiles;
  bool _shouldRenderCreateCollectionSheet = false;
  bool _showShowBackupHook = false;
  final isOnSearchTabNotifier = ValueNotifier<bool>(false);

  late StreamSubscription<TabChangedEvent> _tabChangedEventSubscription;
  late StreamSubscription<SubscriptionPurchasedEvent>
      _subscriptionPurchaseEvent;
  late StreamSubscription<TriggerLogoutEvent> _triggerLogoutEvent;
  late StreamSubscription<UserLoggedOutEvent> _loggedOutEvent;
  late StreamSubscription<PermissionGrantedEvent> _permissionGrantedEvent;
  late StreamSubscription<SyncStatusUpdate> _firstImportEvent;
  late StreamSubscription<BackupFoldersUpdatedEvent> _backupFoldersUpdatedEvent;
  late StreamSubscription<AccountConfiguredEvent> _accountConfiguredEvent;
  late StreamSubscription<CollectionUpdatedEvent> _collectionUpdatedEvent;
  late StreamSubscription _publicAlbumLinkSubscription;

  final DiffFetcher _diffFetcher = DiffFetcher();

  @override
  void initState() {
    _logger.info("Building initstate");
    super.initState();
    _tabChangedEventSubscription =
        Bus.instance.on<TabChangedEvent>().listen((event) {
      _selectedTabIndex = event.selectedIndex;

      if (event.selectedIndex == 3) {
        isOnSearchTabNotifier.value = true;
      } else {
        isOnSearchTabNotifier.value = false;
      }
      if (event.source != TabChangedEventSource.pageView) {
        debugPrint(
          "TabChange going from $_selectedTabIndex to ${event.selectedIndex} souce: ${event.source}",
        );
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            event.selectedIndex,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeIn,
          );
        }
      }
    });
    _subscriptionPurchaseEvent =
        Bus.instance.on<SubscriptionPurchasedEvent>().listen((event) {
      setState(() {});
    });
    _accountConfiguredEvent =
        Bus.instance.on<AccountConfiguredEvent>().listen((event) {
      setState(() {});
    });
    _triggerLogoutEvent =
        Bus.instance.on<TriggerLogoutEvent>().listen((event) async {
      await _autoLogoutAlert();
    });
    _loggedOutEvent = Bus.instance.on<UserLoggedOutEvent>().listen((event) {
      _logger.info('logged out, selectTab index to 0');
      _selectedTabIndex = 0;
      if (mounted) {
        setState(() {});
      }
    });
    _permissionGrantedEvent =
        Bus.instance.on<PermissionGrantedEvent>().listen((event) async {
      if (mounted) {
        setState(() {});
      }
    });
    _firstImportEvent =
        Bus.instance.on<SyncStatusUpdate>().listen((event) async {
      if (mounted && event.status == SyncStatus.completedFirstGalleryImport) {
        Duration delayInRefresh = const Duration(milliseconds: 0);
        // Loading page will redirect to BackupFolderSelectionPage.
        // To avoid showing folder hook in middle during routing,
        // delay state refresh for home page
        if (!LocalSyncService.instance.hasGrantedLimitedPermissions()) {
          delayInRefresh = const Duration(milliseconds: 250);
        }
        Future.delayed(
          delayInRefresh,
          () => {
            if (mounted)
              {
                setState(
                  () {},
                ),
              },
          },
        );
      }
    });
    _backupFoldersUpdatedEvent =
        Bus.instance.on<BackupFoldersUpdatedEvent>().listen((event) async {
      if (mounted) {
        setState(() {});
      }
    });
    _collectionUpdatedEvent = Bus.instance.on<CollectionUpdatedEvent>().listen(
      (event) async {
        // only reset state if backup hook is shown. This is to ensure that
        // during first sync, we don't keep showing backup hook if user has
        // files
        if (mounted &&
            _showShowBackupHook &&
            event.type == EventType.addedOrUpdated) {
          setState(() {});
        }
      },
    );
    _initDeepLinks();
    updateService.shouldShowUpdateNotification().then((value) {
      Future.delayed(Duration.zero, () {
        if (value) {
          showDialog(
            useRootNavigator: false,
            context: context,
            builder: (BuildContext context) {
              return AppUpdateDialog(
                updateService.getLatestVersionInfo(),
              );
            },
            barrierColor: Colors.black.withOpacity(0.85),
          );
          updateService.resetUpdateAvailableShownTime();
        }
      });
    });

    Platform.isIOS ? _initDeepLinkSubscriptionForPublicAlbums() : null;

    // For sharing images coming from outside the app
    _initMediaShareSubscription();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Future.delayed(
        const Duration(seconds: 1),
        () => {
          if (mounted) {showChangeLog(context)},
        },
      ),
    );

    NotificationService.instance
        .initialize(_onDidReceiveNotificationResponse)
        .ignore();

    if (Platform.isAndroid &&
        !localSettings.hasConfiguredInAppLinkPermissions() &&
        RemoteSyncService.instance.isFirstRemoteSyncDone()) {
      PackageInfo.fromPlatform().then((packageInfo) {
        final packageName = packageInfo.packageName;
        if (packageName == 'io.ente.photos.independent' ||
            packageName == 'io.ente.photos.fdroid') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              requestPermissionToOpenLinksInApp(context, packageName);
            }
          });
        }
      });
    }
  }

  Future<void> _handlePublicAlbumLink(Uri uri) async {
    try {
      final Collection collection = await CollectionsService.instance
          .getCollectionFromPublicLink(context, uri);
      final existingCollection =
          CollectionsService.instance.getCollectionByID(collection.id);

      if (collection.owner!.id! == Configuration.instance.getUserID() ||
          (existingCollection != null && !existingCollection.isDeleted)) {
        await routeToPage(
          context,
          CollectionPage(
            CollectionWithThumbnail(collection, null),
          ),
        );
        return;
      }
      final dialog = createProgressDialog(context, "Loading...");
      final publicUrl = collection.publicURLs![0];
      if (!publicUrl!.enableDownload) {
        await showErrorDialog(
          context,
          context.l10n.canNotOpenTitle,
          context.l10n.canNotOpenBody,
        );
        return;
      }
      if (publicUrl.passwordEnabled) {
        await showTextInputDialog(
          context,
          title: S.of(context).enterPassword,
          submitButtonLabel: S.of(context).ok,
          alwaysShowSuccessState: false,
          popnavAfterSubmission: false,
          onSubmit: (String text) async {
            if (text.trim() == "") {
              return;
            }
            try {
              final hashedPassword = await CryptoUtil.deriveKey(
                utf8.encode(text),
                CryptoUtil.base642bin(publicUrl.nonce!),
                publicUrl.memLimit!,
                publicUrl.opsLimit!,
              );

              unawaited(
                CollectionsService.instance
                    .verifyPublicCollectionPassword(
                  context,
                  CryptoUtil.bin2base64(hashedPassword),
                  collection.id,
                )
                    .then((result) async {
                  if (result) {
                    await dialog.show();

                    final List<EnteFile> sharedFiles =
                        await _diffFetcher.getPublicFiles(
                      context,
                      collection.id,
                      collection.pubMagicMetadata.asc ?? false,
                    );
                    await dialog.hide();
                    Navigator.of(context).pop();

                    await routeToPage(
                      context,
                      SharedPublicCollectionPage(
                        files: sharedFiles,
                        CollectionWithThumbnail(
                          collection,
                          null,
                        ),
                      ),
                    );
                  }
                }),
              );
            } catch (e, s) {
              _logger.severe("Failed to decrypt password for album", e, s);
              await showGenericErrorDialog(context: context, error: e);
              return;
            }
          },
        );
      } else {
        await dialog.show();

        final List<EnteFile> sharedFiles = await _diffFetcher.getPublicFiles(
          context,
          collection.id,
          collection.pubMagicMetadata.asc ?? false,
        );
        await dialog.hide();

        await routeToPage(
          context,
          SharedPublicCollectionPage(
            files: sharedFiles,
            CollectionWithThumbnail(
              collection,
              null,
            ),
          ),
        );
      }
    } catch (e, s) {
      _logger.severe("Failed to handle public album link", e, s);
      return;
    }
  }

  Future<void> _autoLogoutAlert() async {
    final AlertDialog alert = AlertDialog(
      title: Text(S.of(context).sessionExpired),
      content: Text(S.of(context).pleaseLoginAgain),
      actions: [
        TextButton(
          child: Text(
            S.of(context).ok,
            style: TextStyle(
              color: Theme.of(context).colorScheme.greenAlternative,
            ),
          ),
          onPressed: () async {
            Navigator.of(context).pop('dialog');
            Navigator.of(context).popUntil((route) => route.isFirst);
            final dialog =
                createProgressDialog(context, S.of(context).loggingOut);
            await dialog.show();
            await Configuration.instance.logout();
            await dialog.hide();
          },
        ),
      ],
    );

    await showDialog(
      useRootNavigator: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  @override
  void dispose() {
    _tabChangedEventSubscription.cancel();
    _subscriptionPurchaseEvent.cancel();
    _triggerLogoutEvent.cancel();
    _loggedOutEvent.cancel();
    _permissionGrantedEvent.cancel();
    _firstImportEvent.cancel();
    _backupFoldersUpdatedEvent.cancel();
    _accountConfiguredEvent.cancel();
    _intentDataStreamSubscription?.cancel();
    _collectionUpdatedEvent.cancel();
    isOnSearchTabNotifier.dispose();
    _pageController.dispose();
    _publicAlbumLinkSubscription.cancel();
    super.dispose();
  }

  void _initMediaShareSubscription() {
    // For sharing images/public links coming from outside the app while the app is in the memory
    _intentDataStreamSubscription =
        ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> value) {
        if (value[0].path.contains("albums.ente.io")) {
          final uri = Uri.parse(value[0].path);
          _handlePublicAlbumLink(uri);
          return;
        }

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              actions: [
                const SizedBox(height: 24),
                ButtonWidget(
                  labelText: S.of(context).openFile,
                  buttonType: ButtonType.primary,
                  onTap: () async {
                    Navigator.of(context).pop(true);
                  },
                ),
                const SizedBox(
                  height: 12,
                ),
                ButtonWidget(
                  buttonType: ButtonType.secondary,
                  labelText: S.of(context).backupFile,
                  onTap: () async {
                    Navigator.of(context).pop(false);
                  },
                ),
              ],
            );
          },
        ).then((shouldOpenFile) {
          if (shouldOpenFile) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) {
                  return FileViewer(
                    sharedMediaFile: value[0],
                  );
                },
              ),
            );
          } else {
            if (mounted) {
              setState(() {
                _shouldRenderCreateCollectionSheet = true;
                _sharedFiles = value;
              });
            }
          }
        });
      },
      onError: (err) {
        _logger.severe("getIntentDataStream error: $err");
      },
    );
    // For sharing images/public links coming from outside the app while the app is closed
    ReceiveSharingIntent.instance
        .getInitialMedia()
        .then((List<SharedMediaFile> value) {
      if (mounted) {
        if (value[0].path.contains("albums.ente.io")) {
          final uri = Uri.parse(value[0].path);
          _handlePublicAlbumLink(uri);
          return;
        }

        if (AppLifecycleService.instance.mediaExtensionAction.type ==
                MediaType.image ||
            AppLifecycleService.instance.mediaExtensionAction.type ==
                MediaType.video) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) {
                return const FileViewer();
              },
            ),
          );
          return;
        }

        setState(() {
          _sharedFiles = value;
          _shouldRenderCreateCollectionSheet = true;
        });
      }
    });
  }

  Future<void> _initDeepLinkSubscriptionForPublicAlbums() async {
    try {
      final initialUri = await getInitialUri();
      if (initialUri != null) {
        if (initialUri.toString().contains("albums.ente.io")) {
          await _handlePublicAlbumLink(initialUri);
        } else {
          _logger.info(
            "uri doesn't contain 'albums.ente.io' in initial public album deep link",
          );
        }
      } else {
        _logger.info(
          "No initial link received in public album link subscription.",
        );
      }
    } catch (e) {
      _logger.severe("Error while getting initial public album deep link: $e");
    }

    _publicAlbumLinkSubscription = uriLinkStream.listen(
      (Uri? uri) {
        if (uri != null) {
          if (uri.toString().contains("albums.ente.io")) {
            _handlePublicAlbumLink(uri);
          } else {
            _logger.info(
              "uri doesn't contain 'albums.ente.io' in public album link subscription",
            );
          }
        } else {
          _logger.info("No link received in public album link subscription.");
        }
      },
      onError: (err) {
        _logger.severe("Error while getting public album deep link: $err");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _logger.info("Building home_Widget with tab $_selectedTabIndex");
    bool isSettingsOpen = false;
    final enableDrawer = LocalSyncService.instance.hasCompletedFirstImport();
    final action = AppLifecycleService.instance.mediaExtensionAction.action;
    return UserDetailsStateWidget(
      child: PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (didPop) return;
          if (_selectedTabIndex == 0) {
            if (_selectedFiles.files.isNotEmpty) {
              _selectedFiles.clearAll();
              return;
            }
            if (isSettingsOpen) {
              Navigator.pop(context);
            } else if (Platform.isAndroid && action == IntentAction.main) {
              unawaited(MoveToBackground.moveTaskToBack());
            } else {
              Navigator.pop(context);
            }
          } else {
            Bus.instance
                .fire(TabChangedEvent(0, TabChangedEventSource.backButton));
          }
        },
        child: Scaffold(
          drawerScrimColor: getEnteColorScheme(context).strokeFainter,
          drawerEnableOpenDragGesture: false,
          //using a hack instead of enabling this as enabling this will create other problems
          drawer: enableDrawer
              ? ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Drawer(
                    width: double.infinity,
                    shape: const RoundedRectangleBorder(),
                    child: _settingsPage,
                  ),
                )
              : null,
          onDrawerChanged: (isOpened) => isSettingsOpen = isOpened,
          body: SafeArea(
            bottom: false,
            child: Builder(
              builder: (context) {
                return _getBody(context);
              },
            ),
          ),

          ///To fix the status bar not adapting it's color when switching
          ///screens the have different appbar colours.
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(0),
            child: AppBar(
              backgroundColor: getEnteColorScheme(context).backgroundBase,
            ),
          ),
          resizeToAvoidBottomInset: false,
        ),
      ),
    );
  }

  Widget _getBody(BuildContext context) {
    if (!Configuration.instance.hasConfiguredAccount()) {
      _closeDrawerIfOpen(context);
      return const LandingPageWidget();
    }
    if (!LocalSyncService.instance.hasGrantedPermissions()) {
      entityService.syncEntities();
      return const GrantPermissionsWidget();
    }
    if (!LocalSyncService.instance.hasCompletedFirstImport()) {
      return const LoadingPhotosWidget();
    }
    if (_sharedFiles != null &&
        _sharedFiles!.isNotEmpty &&
        _shouldRenderCreateCollectionSheet) {
      //The gallery is getting rebuilt for some reason when the keyboard is up.
      //So to stop showing multiple CreateCollectionSheets, this flag
      //needs to be set to false the first time it is rendered.
      _shouldRenderCreateCollectionSheet = false;
      ReceiveSharingIntent.instance.reset();
      Future.delayed(const Duration(milliseconds: 10), () {
        showCollectionActionSheet(
          context,
          sharedFiles: _sharedFiles,
          actionType: CollectionActionType.addFiles,
        );
      });
    }

    _showShowBackupHook =
        !Configuration.instance.hasSelectedAnyBackupFolder() &&
            !LocalSyncService.instance.hasGrantedLimitedPermissions() &&
            CollectionsService.instance.getActiveCollections().isEmpty;

    return Stack(
      children: [
        Builder(
          builder: (context) {
            return ExtentsPageView(
              onPageChanged: (page) {
                Bus.instance.fire(
                  TabChangedEvent(
                    page,
                    TabChangedEventSource.pageView,
                  ),
                );
              },
              controller: _pageController,
              openDrawer: Scaffold.of(context).openDrawer,
              physics: const BouncingScrollPhysics(),
              children: [
                _showShowBackupHook
                    ? const StartBackupHookWidget(headerWidget: HeaderWidget())
                    : HomeGalleryWidget(
                        header: const HeaderWidget(),
                        footer: const SizedBox(
                          height: 160,
                        ),
                        selectedFiles: _selectedFiles,
                      ),
                _userCollectionsTab,
                _sharedCollectionTab,
                _searchTab,
              ],
            );
          },
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: ValueListenableBuilder(
            valueListenable: isOnSearchTabNotifier,
            builder: (context, value, child) {
              return Container(
                decoration: value
                    ? BoxDecoration(
                        color: getEnteColorScheme(context).backgroundElevated,
                        boxShadow: shadowFloatFaintLight,
                      )
                    : null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    value
                        ? const SearchWidget()
                            .animate()
                            .fadeIn(
                              duration: const Duration(milliseconds: 225),
                              curve: Curves.easeInOutSine,
                            )
                            .scale(
                              begin: const Offset(0.8, 0.8),
                              end: const Offset(1, 1),
                              duration: const Duration(
                                milliseconds: 225,
                              ),
                              curve: Curves.easeInOutSine,
                            )
                            .slide(
                              begin: const Offset(0, 0.4),
                              curve: Curves.easeInOutSine,
                              duration: const Duration(
                                milliseconds: 225,
                              ),
                            )
                        : const SizedBox.shrink(),
                    HomeBottomNavigationBar(
                      _selectedFiles,
                      selectedTabIndex: _selectedTabIndex,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _closeDrawerIfOpen(BuildContext context) {
    Scaffold.of(context).isDrawerOpen
        ? SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
            Scaffold.of(context).closeDrawer();
          })
        : null;
  }

  Future<bool> _initDeepLinks() async {
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      final String? initialLink = await getInitialLink();
      // Parse the link and warn the user, if it is not correct,
      // but keep in mind it could be `null`.
      if (initialLink != null) {
        _logger.info("Initial link received: " + initialLink);
        _getCredentials(context, initialLink);
        return true;
      } else {
        _logger.info("No initial link received.");
      }
    } on PlatformException {
      // Handle exception by warning the user their action did not succeed
      // return?
      _logger.severe("PlatformException thrown while getting initial link");
    }

    // Attach a listener to the stream
    linkStream.listen(
      (String? link) {
        _logger.info("Link received: " + link!);
        _getCredentials(context, link);
      },
      onError: (err) {
        _logger.severe(err);
      },
    );
    return false;
  }

  void _getCredentials(BuildContext context, String? link) {
    if (Configuration.instance.hasConfiguredAccount()) {
      return;
    }
    final ott = Uri.parse(link!).queryParameters["ott"]!;
    UserService.instance.verifyEmail(context, ott);
  }

  showChangeLog(BuildContext context) async {
    final bool show = await updateService.showChangeLog();
    if (!show || !Configuration.instance.isLoggedIn()) {
      return;
    }
    final colorScheme = getEnteColorScheme(context);
    await showBarModalBottomSheet(
      topControl: const SizedBox.shrink(),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(5),
          topRight: Radius.circular(5),
        ),
      ),
      backgroundColor: colorScheme.backgroundElevated,
      enableDrag: false,
      barrierColor: backdropFaintDark,
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: const ChangeLogPage(),
        );
      },
    );
    // Do not show change dialog again
    updateService.hideChangeLog().ignore();
  }

  void _onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse,
  ) async {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      debugPrint('notification payload: $payload');
      final collectionID = Uri.parse(payload).queryParameters["collectionID"];
      if (collectionID != null) {
        final collection = CollectionsService.instance
            .getCollectionByID(int.parse(collectionID))!;
        final thumbnail =
            await CollectionsService.instance.getCover(collection);
        // ignore: unawaited_futures
        routeToPage(
          context,
          CollectionPage(
            CollectionWithThumbnail(
              collection,
              thumbnail,
            ),
          ),
        );
      }
    }
  }
}
