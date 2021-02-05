import 'dart:async';

import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/events/tab_changed_event.dart';
import 'package:photos/models/filters/important_items_filter.dart';
import 'package:photos/models/file.dart';
import 'package:photos/repositories/file_repository.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/sync_service.dart';
import 'package:photos/ui/collections_gallery_widget.dart';
import 'package:photos/ui/extents_page_view.dart';
import 'package:photos/ui/gallery.dart';
import 'package:photos/ui/gallery_app_bar_widget.dart';
import 'package:photos/ui/loading_photos_widget.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/ui/memories_widget.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/settings_button.dart';
import 'package:photos/ui/shared_collections_gallery.dart';
import 'package:logging/logging.dart';
import 'package:photos/ui/sign_in_header_widget.dart';
import 'package:photos/ui/sync_indicator.dart';
import 'package:uni_links/uni_links.dart';

class HomeWidget extends StatefulWidget {
  final String title;

  const HomeWidget(this.title, {Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  static final importantItemsFilter = ImportantItemsFilter();
  final _logger = Logger("HomeWidgetState");
  final _deviceFolderGalleryWidget = CollectionsGalleryWidget();
  final _sharedCollectionGallery = SharedCollectionGallery();
  final _selectedFiles = SelectedFiles();
  final _settingsButton = SettingsButton();
  static const _headerWidget = HeaderWidget();
  final PageController _pageController = PageController();
  final _future = FileRepository.instance.loadFiles();

  GlobalKey<ConvexAppBarState> _appBarKey = GlobalKey<ConvexAppBarState>();
  StreamSubscription<LocalPhotosUpdatedEvent> _photosUpdatedEvent;
  StreamSubscription<TabChangedEvent> _tabChangedEventSubscription;

  @override
  void initState() {
    _logger.info("Building initstate");
    _photosUpdatedEvent =
        Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) {
      _logger.info("Building because local photos updated");
      setState(() {});
    });
    _tabChangedEventSubscription =
        Bus.instance.on<TabChangedEvent>().listen((event) {
      if (event.source != TabChangedEventSource.tab_bar) {
        _appBarKey.currentState.animateTo(event.selectedIndex);
      }
      if (event.source != TabChangedEventSource.page_view) {
        _pageController.animateToPage(
          event.selectedIndex,
          duration: Duration(milliseconds: 150),
          curve: Curves.easeIn,
        );
      }
    });
    _initDeepLinks();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _logger.info("Building home_Widget");
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: Container(),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      body: ExtentsPageView(
        children: [
          SyncService.instance.hasScannedDisk()
              ? _getMainGalleryWidget()
              : LoadingPhotosWidget(),
          _deviceFolderGalleryWidget,
          _sharedCollectionGallery,
        ],
        onPageChanged: (page) {
          Bus.instance.fire(TabChangedEvent(
            page,
            TabChangedEventSource.page_view,
          ));
        },
        controller: _pageController,
      ),
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
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var header;
          if (_selectedFiles.files.isEmpty &&
              Configuration.instance.hasConfiguredAccount()) {
            header = Container(
              margin: EdgeInsets.only(top: 12),
              child: Stack(
                children: [_settingsButton, _headerWidget],
              ),
            );
          } else {
            header = _headerWidget;
          }
          return Gallery(
            syncLoader: () {
              return _getFilteredPhotos(FileRepository.instance.files);
            },
            reloadEvent: Bus.instance.on<LocalPhotosUpdatedEvent>(),
            tagPrefix: "home_gallery",
            selectedFiles: _selectedFiles,
            headerWidget: header,
            isHomePageGallery: true,
          );
        } else if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        } else {
          return loadWidget;
        }
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return StyleProvider(
      style: BottomNavBarStyle(),
      child: ConvexAppBar(
        key: _appBarKey,
        items: [
          TabItem(
            icon: Icons.photo_library,
            title: "photos",
          ),
          TabItem(
            icon: Icons.folder_special,
            title: "collections",
          ),
          TabItem(
            icon: Icons.folder_shared,
            title: "shared",
          ),
        ],
        onTap: (index) {
          Bus.instance.fire(TabChangedEvent(
            index,
            TabChangedEventSource.tab_bar,
          ));
        },
        style: TabStyle.reactCircle,
        height: 52,
        backgroundColor: Theme.of(context).appBarTheme.color,
        top: -24,
      ),
    );
  }

  List<File> _getFilteredPhotos(List<File> unfilteredFiles) {
    _logger.info("Filtering " + unfilteredFiles.length.toString());
    final List<File> filteredPhotos = List<File>();
    for (File file in unfilteredFiles) {
      if (importantItemsFilter.shouldInclude(file)) {
        filteredPhotos.add(file);
      }
    }
    _logger.info("Filtered down to " + filteredPhotos.length.toString());
    return filteredPhotos;
  }

  @override
  void dispose() {
    _tabChangedEventSubscription.cancel();
    _photosUpdatedEvent.cancel();
    super.dispose();
  }
}

class HeaderWidget extends StatelessWidget {
  static const _memoriesWidget = const MemoriesWidget();
  static const _signInHeader = const SignInHeader();
  static const _syncIndicator = const SyncIndicator();

  const HeaderWidget({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Logger("Header").info("Building header widget");
    const list = [
      _syncIndicator,
      _signInHeader,
      _memoriesWidget,
    ];
    return Column(children: list);
  }
}

class BottomNavBarStyle extends StyleHook {
  @override
  double get activeIconSize => 32;

  @override
  double get activeIconMargin => 6;

  @override
  double get iconSize => 20;

  @override
  TextStyle textStyle(Color color) {
    return TextStyle(
      color: color,
      fontSize: 12,
    );
  }
}
