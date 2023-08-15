import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import 'package:logging/logging.dart';
import 'package:media_extension/media_extension_action_types.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:move_to_background/move_to_background.dart';
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
import "package:photos/models/collection_items.dart";
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/app_lifecycle_service.dart';
import 'package:photos/services/collections_service.dart';
import "package:photos/services/entity_service.dart";
import 'package:photos/services/local_sync_service.dart';
import "package:photos/services/notification_service.dart";
import 'package:photos/services/update_service.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/states/user_details_state.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/collections/collection_action_sheet.dart';
import 'package:photos/ui/extents_page_view.dart';
import 'package:photos/ui/home/grant_permissions_widget.dart';
import 'package:photos/ui/home/header_widget.dart';
import 'package:photos/ui/home/home_bottom_nav_bar.dart';
import 'package:photos/ui/home/home_gallery_widget.dart';
import 'package:photos/ui/home/landing_page_widget.dart';
import "package:photos/ui/home/loading_photos_widget.dart";
import 'package:photos/ui/home/preserve_footer_widget.dart';
import 'package:photos/ui/home/start_backup_hook_widget.dart';
import 'package:photos/ui/notification/update/change_log_page.dart';
import 'package:photos/ui/settings/app_update_dialog.dart';
import 'package:photos/ui/settings_page.dart';
import "package:photos/ui/tabs/shared_collections_tab.dart";
import "package:photos/ui/tabs/user_collections_tab.dart";
import "package:photos/ui/viewer/gallery/collection_page.dart";
import 'package:photos/utils/dialog_util.dart';
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
  static final _settingsPage = SettingsPage(
    emailNotifier: UserService.instance.emailValueNotifier,
  );
  static const _headerWidget = HeaderWidget();

  final _logger = Logger("HomeWidgetState");
  final _selectedFiles = SelectedFiles();
  final GlobalKey shareButtonKey = GlobalKey();

  final PageController _pageController = PageController();
  int _selectedTabIndex = 0;

  // for receiving media files
  // ignore: unused_field
  StreamSubscription? _intentDataStreamSubscription;
  List<SharedMediaFile>? _sharedFiles;
  bool _shouldRenderCreateCollectionSheet = false;
  bool _showShowBackupHook = false;

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

  @override
  void initState() {
    _logger.info("Building initstate");
    _tabChangedEventSubscription =
        Bus.instance.on<TabChangedEvent>().listen((event) {
      if (event.source != TabChangedEventSource.pageView) {
        debugPrint(
          "TabChange going from $_selectedTabIndex to ${event.selectedIndex} souce: ${event.source}",
        );
        _selectedTabIndex = event.selectedIndex;
        // _pageController.jumpToPage(_selectedTabIndex);
        _pageController.animateToPage(
          event.selectedIndex,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeIn,
        );
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
                )
              }
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
    UpdateService.instance.shouldUpdate().then((shouldUpdate) {
      if (shouldUpdate) {
        Future.delayed(Duration.zero, () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AppUpdateDialog(
                UpdateService.instance.getLatestVersionInfo(),
              );
            },
            barrierColor: Colors.black.withOpacity(0.85),
          );
        });
      }
    });
    // For sharing images coming from outside the app
    _initMediaShareSubscription();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Future.delayed(
        const Duration(seconds: 1),
        () => {
          if (mounted) {showChangeLog(context)}
        },
      ),
    );

    NotificationService.instance.init(_onDidReceiveNotificationResponse);

    super.initState();
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
            Navigator.of(context, rootNavigator: true).pop('dialog');
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
    super.dispose();
  }

  void _initMediaShareSubscription() {
    // For sharing images coming from outside the app while the app is in the memory
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getMediaStream().listen(
      (List<SharedMediaFile> value) {
        setState(() {
          _shouldRenderCreateCollectionSheet = true;
          _sharedFiles = value;
        });
      },
      onError: (err) {
        _logger.severe("getIntentDataStream error: $err");
      },
    );
    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> value) {
      setState(() {
        _sharedFiles = value;
        _shouldRenderCreateCollectionSheet = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    _logger.info("Building home_Widget with tab $_selectedTabIndex");
    bool isSettingsOpen = false;
    final enableDrawer = LocalSyncService.instance.hasCompletedFirstImport();
    final action = AppLifecycleService.instance.mediaExtensionAction.action;
    return UserDetailsStateWidget(
      child: WillPopScope(
        child: Scaffold(
          drawerScrimColor: getEnteColorScheme(context).strokeFainter,
          drawerEnableOpenDragGesture: false,
          //using a hack instead of enabling this as enabling this will create other problems
          drawer: enableDrawer
              ? ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Drawer(
                    width: double.infinity,
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
          resizeToAvoidBottomInset: false,
        ),
        onWillPop: () async {
          if (_selectedTabIndex == 0) {
            if (isSettingsOpen) {
              Navigator.pop(context);
              return false;
            }
            if (Platform.isAndroid && action == IntentAction.main) {
              MoveToBackground.moveTaskToBack();
              return false;
            } else {
              return true;
            }
          } else {
            Bus.instance
                .fire(TabChangedEvent(0, TabChangedEventSource.backButton));
            return false;
          }
        },
      ),
    );
  }

  Widget _getBody(BuildContext context) {
    if (!Configuration.instance.hasConfiguredAccount()) {
      _closeDrawerIfOpen(context);
      return const LandingPageWidget();
    }
    if (!LocalSyncService.instance.hasGrantedPermissions()) {
      EntityService.instance.syncEntities();
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
      ReceiveSharingIntent.reset();
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
                    ? const StartBackupHookWidget(headerWidget: _headerWidget)
                    : HomeGalleryWidget(
                        header: _headerWidget,
                        footer: const PreserveFooterWidget(),
                        selectedFiles: _selectedFiles,
                      ),
                _userCollectionsTab,
                _sharedCollectionTab,
              ],
            );
          },
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: HomeBottomNavigationBar(
            _selectedFiles,
            selectedTabIndex: _selectedTabIndex,
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
    final bool show = await UpdateService.instance.showChangeLog();
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
    UpdateService.instance.hideChangeLog().ignore();
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
