import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:move_to_background/move_to_background.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/backup_folders_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/events/subscription_purchased_event.dart';
import 'package:photos/events/tab_changed_event.dart';
import 'package:photos/events/trigger_logout_event.dart';
import 'package:photos/events/user_logged_out_event.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/sync_service.dart';
import 'package:photos/ui/backup_folder_selection_page.dart';
import 'package:photos/ui/collections_gallery_widget.dart';
import 'package:photos/ui/extents_page_view.dart';
import 'package:photos/ui/gallery.dart';
import 'package:photos/ui/gallery_app_bar_widget.dart';
import 'package:photos/ui/gallery_footer_widget.dart';
import 'package:photos/ui/grant_permissions_page.dart';
import 'package:photos/ui/loading_photos_page.dart';
import 'package:photos/ui/memories_widget.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/nav_bar.dart';
import 'package:photos/ui/settings_button.dart';
import 'package:photos/ui/shared_collections_gallery.dart';
import 'package:logging/logging.dart';
import 'package:photos/ui/landing_page.dart';
import 'package:photos/ui/sync_indicator.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:uni_links/uni_links.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  static const _deviceFolderGalleryWidget = const CollectionsGalleryWidget();
  static const _sharedCollectionGallery = const SharedCollectionGallery();
  static const _headerWidget = HeaderWidget();

  final _logger = Logger("HomeWidgetState");
  final _selectedFiles = SelectedFiles();
  final _settingsButton = SettingsButton();
  final PageController _pageController = PageController();
  int _selectedTabIndex = 0;
  Widget _headerWidgetWithSettingsButton;

  StreamSubscription<TabChangedEvent> _tabChangedEventSubscription;
  StreamSubscription<SubscriptionPurchasedEvent> _subscriptionPurchaseEvent;
  StreamSubscription<TriggerLogoutEvent> _triggerLogoutEvent;
  StreamSubscription<UserLoggedOutEvent> _loggedOutEvent;

  @override
  void initState() {
    _logger.info("Building initstate");
    _headerWidgetWithSettingsButton = Container(
      margin: const EdgeInsets.only(top: 12),
      child: Stack(
        children: [
          _headerWidget,
          _settingsButton,
        ],
      ),
    );
    _tabChangedEventSubscription =
        Bus.instance.on<TabChangedEvent>().listen((event) {
      if (event.source != TabChangedEventSource.tab_bar) {
        setState(() {
          _selectedTabIndex = event.selectedIndex;
        });
      }
      if (event.source != TabChangedEventSource.page_view) {
        _pageController.animateToPage(
          event.selectedIndex,
          duration: Duration(milliseconds: 150),
          curve: Curves.easeIn,
        );
      }
    });
    _subscriptionPurchaseEvent =
        Bus.instance.on<SubscriptionPurchasedEvent>().listen((event) {
      setState(() {});
    });
    _triggerLogoutEvent =
        Bus.instance.on<TriggerLogoutEvent>().listen((event) async {
      AlertDialog alert = AlertDialog(
        title: Text("session expired"),
        content: Text("please login again"),
        actions: [
          TextButton(
            child: Text(
              "ok",
              style: TextStyle(
                color: Theme.of(context).buttonColor,
              ),
            ),
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop('dialog');
              final dialog = createProgressDialog(context, "logging out...");
              await dialog.show();
              await Configuration.instance.logout();
              await dialog.hide();
            },
          ),
        ],
      );

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return alert;
        },
      );
    });
    _loggedOutEvent = Bus.instance.on<UserLoggedOutEvent>().listen((event) {
      setState(() {});
    });
    _initDeepLinks();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _logger.info("Building home_Widget");

    return WillPopScope(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(0),
          child: Container(),
        ),
        body: _getBody(),
      ),
      onWillPop: () async {
        if (_selectedTabIndex == 0) {
          if (Platform.isAndroid) {
            MoveToBackground.moveTaskToBack();
            return false;
          } else {
            return true;
          }
        } else {
          Bus.instance
              .fire(TabChangedEvent(0, TabChangedEventSource.back_button));
          return false;
        }
      },
    );
  }

  Widget _getBody() {
    if (!Configuration.instance.hasConfiguredAccount()) {
      return LandingPage();
    }
    if (!SyncService.instance.hasGrantedPermissions()) {
      return GrantPermissionsPage();
    }
    if (!SyncService.instance.hasCompletedFirstImport()) {
      return LoadingPhotosPage();
    }
    if (Configuration.instance.getPathsToBackUp().isEmpty) {
      return BackupFolderSelectionPage();
    }

    return Stack(
      children: [
        ExtentsPageView(
          children: [
            _getMainGalleryWidget(),
            _deviceFolderGalleryWidget,
            _sharedCollectionGallery,
          ],
          onPageChanged: (page) {
            Bus.instance.fire(TabChangedEvent(
              page,
              TabChangedEventSource.page_view,
            ));
          },
          physics: NeverScrollableScrollPhysics(),
          controller: _pageController,
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: _buildBottomNavigationBar(),
        ),
      ],
    );
  }

  Future<bool> _initDeepLinks() async {
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      String initialLink = await getInitialLink();
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
    getLinksStream().listen((String link) {
      _logger.info("Link received: " + link);
      _getCredentials(context, link);
    }, onError: (err) {
      _logger.severe(err);
    });
    return false;
  }

  void _getCredentials(BuildContext context, String link) {
    if (Configuration.instance.hasConfiguredAccount()) {
      return;
    }
    final ott = Uri.parse(link).queryParameters["ott"];
    UserService.instance.getCredentials(context, ott);
  }

  Widget _getMainGalleryWidget() {
    var header;
    if (_selectedFiles.files.isEmpty) {
      header = _headerWidgetWithSettingsButton;
    } else {
      header = _headerWidget;
    }
    final gallery = Gallery(
      asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) {
        final importantPaths = Configuration.instance.getPathsToBackUp();
        if (importantPaths.isNotEmpty) {
          return FilesDB.instance.getFilesInPaths(
              creationStartTime, creationEndTime, importantPaths.toList(),
              limit: limit, asc: asc);
        } else {
          return FilesDB.instance.getAllFiles(
              creationStartTime, creationEndTime,
              limit: limit, asc: asc);
        }
      },
      reloadEvent: Bus.instance.on<LocalPhotosUpdatedEvent>(),
      forceReloadEvent: Bus.instance.on<BackupFoldersUpdatedEvent>(),
      tagPrefix: "home_gallery",
      selectedFiles: _selectedFiles,
      header: header,
      footer: GalleryFooterWidget(),
    );
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 50),
          child: gallery,
        ),
        HomePageAppBar(_selectedFiles),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.90),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
          child: GNav(
              rippleColor: Theme.of(context).buttonColor.withOpacity(0.20),
              hoverColor: Theme.of(context).buttonColor.withOpacity(0.20),
              gap: 8,
              activeColor: Theme.of(context).buttonColor.withOpacity(0.75),
              iconSize: 24,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: Duration(milliseconds: 400),
              tabMargin: EdgeInsets.only(left: 8, right: 8),
              tabBackgroundColor:
                  Theme.of(context).appBarTheme.color.withOpacity(0.7),
              haptic: false,
              tabs: [
                GButton(
                  icon: Icons.photo_library_outlined,
                  text: 'photos',
                ),
                GButton(
                  icon: Icons.folder_special_outlined,
                  text: 'albums',
                ),
                GButton(
                  icon: Icons.folder_shared_outlined,
                  text: 'shared',
                ),
              ],
              selectedIndex: _selectedTabIndex,
              onTabChange: (index) {
                setState(() {
                  Bus.instance.fire(TabChangedEvent(
                    index,
                    TabChangedEventSource.tab_bar,
                  ));
                });
              }),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabChangedEventSubscription.cancel();
    _subscriptionPurchaseEvent.cancel();
    _triggerLogoutEvent.cancel();
    _loggedOutEvent.cancel();
    super.dispose();
  }
}

class HomePageAppBar extends StatefulWidget {
  const HomePageAppBar(
    this.selectedFiles, {
    Key key,
  }) : super(key: key);

  final SelectedFiles selectedFiles;

  @override
  _HomePageAppBarState createState() => _HomePageAppBarState();
}

class _HomePageAppBarState extends State<HomePageAppBar> {
  @override
  void initState() {
    super.initState();
    widget.selectedFiles.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final appBar = Container(
      height: 60,
      child: GalleryAppBarWidget(
        GalleryAppBarType.homepage,
        null,
        widget.selectedFiles,
      ),
    );
    if (widget.selectedFiles.files.isEmpty) {
      return IgnorePointer(child: appBar);
    } else {
      return appBar;
    }
  }
}

class HeaderWidget extends StatelessWidget {
  static const _memoriesWidget = const MemoriesWidget();
  static const _syncIndicator = const SyncIndicator();

  const HeaderWidget({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Logger("Header").info("Building header widget");
    const list = [
      _syncIndicator,
      _memoriesWidget,
    ];
    return Column(
      children: list,
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }
}
