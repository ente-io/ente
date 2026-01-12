import 'dart:async';
import 'dart:io';

import "package:app_links/app_links.dart";
import "package:ente_accounts/services/user_service.dart";
import 'package:ente_events/event_bus.dart';
import "package:ente_ui/components/alert_bottom_sheet.dart";
import 'package:ente_ui/theme/ente_theme.dart';
import 'package:ente_ui/utils/dialog_util.dart';
import 'package:flutter/material.dart';
import "package:hugeicons/hugeicons.dart";
import 'package:listen_sharing_intent/listen_sharing_intent.dart';
import 'package:locker/events/collections_updated_event.dart';
import 'package:locker/events/trigger_logout_event.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/services/collections/collections_service.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/services/configuration.dart';
import 'package:locker/services/files/sync/models/file.dart';
import "package:locker/states/user_details_state.dart";
import "package:locker/ui/components/gradient_button.dart";
import "package:locker/ui/components/home_empty_state_widget.dart";
import 'package:locker/ui/components/recents_section_widget.dart';
import 'package:locker/ui/components/search_result_view.dart';
import "package:locker/ui/drawer/drawer_page.dart";
import 'package:locker/ui/mixins/search_mixin.dart';
import 'package:locker/ui/pages/save_page.dart';
import 'package:locker/ui/pages/uploader_page.dart';
import 'package:locker/utils/collection_sort_util.dart';
import 'package:logging/logging.dart';

class CustomLockerAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final bool isSearchActive;
  final bool isSyncing;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final VoidCallback onSearchFocused;
  final VoidCallback onClearSearch;
  final ValueChanged<String>? onSearchChanged;

  const CustomLockerAppBar({
    super.key,
    required this.scaffoldKey,
    required this.isSearchActive,
    this.isSyncing = false,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchFocused,
    required this.onClearSearch,
    this.onSearchChanged,
  });

  @override
  Size get preferredSize => const Size.fromHeight(156);

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final hasQuery = searchController.text.isNotEmpty;
    final showClearIcon = isSearchActive || hasQuery;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primary700,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () {
                        scaffoldKey.currentState!.openDrawer();
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedMenu01,
                          color: Colors.white,
                          strokeWidth: 2.25,
                        ),
                      ),
                    ),
                  ),
                  isSyncing
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Syncing...",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      : Image.asset(
                          'assets/locker-logo.png',
                          height: 28,
                        ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: TextField(
                  autocorrect: false,
                  enableSuggestions: false,
                  controller: searchController,
                  focusNode: searchFocusNode,
                  onTap: onSearchFocused,
                  cursorColor: colorScheme.primary700,
                  onChanged: onSearchChanged,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    hintText: context.l10n.searchHint,
                    hintStyle: TextStyle(
                      color: colorScheme.iconColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 8),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedSearch01,
                        color: colorScheme.primary700,
                        size: 20,
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 24,
                    ),
                    suffixIcon: showClearIcon
                        ? IconButton(
                            onPressed: onClearSearch,
                            splashRadius: 20,
                            padding: const EdgeInsets.only(right: 16, left: 8),
                            icon: HugeIcon(
                              icon: HugeIcons.strokeRoundedCancel01,
                              color: colorScheme.iconColor,
                              size: 20,
                            ),
                          )
                        : null,
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                  ),
                  style: TextStyle(
                    color: colorScheme.iconColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends UploaderPage {
  final String? initialSearchQuery;

  const HomePage({super.key, this.initialSearchQuery});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends UploaderPageState<HomePage>
    with TickerProviderStateMixin, SearchMixin {
  late final _settingsPage = DrawerPage(
    emailNotifier: UserService.instance.emailValueNotifier,
    scaffoldKey: scaffoldKey,
  );
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchFocusNode = FocusNode();
  bool _isLoading = true;
  bool _hasCompletedInitialLoad = false;
  bool _isSettingsOpen = false;

  List<Collection> _collections = [];
  List<Collection> _filteredCollections = [];
  List<EnteFile> _recentFiles = [];
  List<EnteFile> _filteredFiles = [];

  String? _error;
  final _logger = Logger('HomePage');
  StreamSubscription? _mediaStreamSubscription;
  StreamSubscription<Uri>? _deepLinkSubscription;
  StreamSubscription<TriggerLogoutEvent>? _triggerLogoutSubscription;

  @override
  void onFileUploadComplete() {
    _loadCollections();
  }

  @override
  List<Collection> get allCollections => _collections;

  @override
  List<EnteFile> get allFiles => _recentFiles;

  @override
  void onSearchResultsChanged(
    List<Collection> collections,
    List<EnteFile> files,
  ) {
    if (mounted) {
      setState(() {
        _filteredCollections = _filterOutUncategorized(collections);
        _filteredFiles = files;
      });
    }
  }

  @override
  void onSearchStateChanged(bool isActive) {
    if (!isActive && mounted) {
      setState(() {
        _filteredCollections = _filterOutUncategorized(_collections);
        _filteredFiles = _recentFiles;
      });
    }
  }

  List<Collection> get _displayedCollections {
    final collections = isSearchActive ? _filteredCollections : _collections;
    return _filterOutUncategorized(collections);
  }

  List<Collection> _filterOutUncategorized(List<Collection> collections) {
    return CollectionSortUtil.filterAndSortCollections(collections);
  }

  @override
  void initState() {
    super.initState();

    _loadCollections();

    // Initialize sharing functionality to handle shared files
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Add a small delay to ensure the app is fully loaded
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            initializeSharing();
          }
        });
      }
    });

    _initDeepLinks();

    // Activate search if initial query is provided (after collections are loaded)
    if (widget.initialSearchQuery != null &&
        widget.initialSearchQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Wait a bit more to ensure collections are loaded
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            activateSearchWithQuery(widget.initialSearchQuery!);
          }
        });
      });
    }

    Bus.instance.on<CollectionsUpdatedEvent>().listen((event) async {
      await _loadCollections();
    });

    _triggerLogoutSubscription =
        Bus.instance.on<TriggerLogoutEvent>().listen((event) async {
      await _autoLogoutAlert();
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _deepLinkSubscription?.cancel();
    _triggerLogoutSubscription?.cancel();
    disposeSharing();
    super.dispose();
  }

  Future<void> _autoLogoutAlert() async {
    if (!mounted) return;

    final navigator = Navigator.of(context);
    final l10n = context.l10n;

    await showAlertBottomSheet(
      context,
      title: l10n.sessionExpired,
      message: l10n.pleaseLoginAgain,
      assetPath: "assets/warning-grey.png",
      isDismissible: false,
      showCloseButton: false,
      buttons: [
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            text: context.l10n.ok,
            onTap: () async {
              navigator.pop();
              final dialog = createProgressDialog(
                context,
                l10n.pleaseWait,
              );
              await dialog.show();
              await Configuration.instance.logout();
              await dialog.hide();
              navigator.popUntil((route) => route.isFirst);
            },
          ),
        ),
      ],
    );
  }

  void initializeSharing() {
    _logger.info('Initializing sharing functionality...');

    try {
      _mediaStreamSubscription =
          ReceiveSharingIntent.instance.getMediaStream().listen(
        (List<SharedMediaFile> value) {
          _logger
              .info('Received shared media files via stream: ${value.length}');
          for (var file in value) {
            _logger.info('Shared file received, type: ${file.type}');
          }
          if (value.isNotEmpty) {
            _handleSharedFiles(value);
          }
        },
        onError: (err) {
          _logger.severe('Error receiving shared media: $err');
        },
      );

      _logger.info('Media stream subscription created successfully');
    } catch (e) {
      _logger.severe('Error setting up media stream: $e');
    }

    _checkInitialSharedContent();
  }

  Future<void> _checkInitialSharedContent() async {
    try {
      _logger.info('Checking for initial shared content...');

      final initialMedia =
          await ReceiveSharingIntent.instance.getInitialMedia();
      _logger.info('Initial media check result: ${initialMedia.length} files');

      if (initialMedia.isNotEmpty) {
        _logger
            .info('Found initial shared media files: ${initialMedia.length}');
        for (var file in initialMedia) {
          _logger.info('Initial shared file, type: ${file.type}');
        }
        await _handleSharedFiles(initialMedia);
      } else {
        _logger.info('No initial shared media files found');
      }
    } catch (e) {
      _logger.severe('Error checking initial shared content: $e');
    }
  }

  Future<void> _handleSharedFiles(List<SharedMediaFile> sharedFiles) async {
    _logger.info('_handleSharedFiles called with ${sharedFiles.length} files');

    if (!mounted) {
      _logger.warning('Context not mounted, cannot handle shared files');
      return;
    }

    try {
      for (final sharedFile in sharedFiles) {
        _logger.info('Processing shared file');
        if (sharedFile.path.isNotEmpty) {
          final file = File(sharedFile.path);
          if (await file.exists()) {
            _logger.info('File exists, uploading');
            await uploadFiles([file]);
          } else {
            _logger.warning('Shared file does not exist');
          }
        } else {
          _logger.warning('Shared file has empty path');
        }
      }

      await ReceiveSharingIntent.instance.reset();
      _logger.info('Reset sharing intent after handling files');
    } catch (e) {
      _logger.severe('Error handling shared files: $e');
      if (mounted) {
        await showErrorDialog(
          context,
          context.l10n.uploadError,
          'Failed to process shared files: $e',
        );
      }
    }
  }

  void disposeSharing() {
    _mediaStreamSubscription?.cancel();
    ReceiveSharingIntent.instance.reset();
    _logger.info('Sharing functionality disposed');
  }

  Future<void> _initDeepLinks() async {
    final appLinks = AppLinks();

    try {
      final initialLink = await appLinks.getInitialLink();
      if (initialLink != null) {
        _logger.info('Initial deep link received');
      }
    } catch (e) {
      _logger.severe('Error getting initial deep link: $e');
    }

    _deepLinkSubscription = appLinks.uriLinkStream.listen(
      (Uri uri) {
        _logger.info('Deep link received via stream');
      },
      onError: (err) {
        _logger.severe('Error receiving deep link: $err');
      },
    );
  }

  Future<void> _loadCollections() async {
    final shouldShowLoading =
        _collections.isEmpty && _recentFiles.isEmpty && !_isLoading;

    try {
      if (mounted && (shouldShowLoading || _error != null)) {
        setState(() {
          if (shouldShowLoading) {
            _isLoading = true;
          }
          _error = null;
        });
      }

      final collections = await CollectionService.instance.getCollections();
      await _loadRecentFiles(collections);

      final sortedCollections =
          CollectionSortUtil.getSortedCollections(collections);

      // Only mark initial load complete when first sync has finished
      // This prevents empty state while sync is in progress
      final hasCompletedFirstSync =
          CollectionService.instance.hasCompletedFirstSync();

      if (mounted) {
        setState(() {
          _collections = sortedCollections;
          _filteredCollections = _filterOutUncategorized(sortedCollections);
          _filteredFiles = _recentFiles;
          _isLoading = false;
          _hasCompletedInitialLoad = hasCompletedFirstSync;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = 'Error fetching collections: $error';
          _isLoading = false;
          _hasCompletedInitialLoad =
              CollectionService.instance.hasCompletedFirstSync();
        });
      }
    }
  }

  Future<void> _loadRecentFiles(List<Collection> collections) async {
    final allFiles = <EnteFile>[];

    for (final collection in collections) {
      allFiles.addAll(
        await CollectionService.instance.getFilesInCollection(collection),
      );
    }

    final uniqueFiles = <EnteFile>[];
    final seenHashes = <String>{};
    final seenIds = <int>{};

    for (final file in allFiles) {
      bool isDuplicate = false;

      if (file.hash != null && seenHashes.contains(file.hash)) {
        isDuplicate = true;
      } else if (file.uploadedFileID != null &&
          seenIds.contains(file.uploadedFileID)) {
        isDuplicate = true;
      }

      if (!isDuplicate) {
        uniqueFiles.add(file);
        if (file.hash != null) seenHashes.add(file.hash!);
        if (file.uploadedFileID != null) seenIds.add(file.uploadedFileID!);
      }
    }

    uniqueFiles.sort((a, b) {
      final timeA = a.updationTime ?? a.modificationTime ?? 0;
      final timeB = b.updationTime ?? b.modificationTime ?? 0;
      return timeB.compareTo(timeA);
    });

    _recentFiles = uniqueFiles;
  }

  void _handleSearchChange(String query) {
    // Trigger search by activating search with the current query
    activateSearchWithQuery(query);
  }

  void _handleSearchFocused() {
    // Activate search when TextField is tapped/focused
    if (!isSearchActive) {
      activateSearchWithQuery('');
    }
  }

  void _handleClearSearch() {
    // Clear text and unfocus before dismissing search
    searchController.clear();
    _searchFocusNode.unfocus();

    dismissSearch();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return UserDetailsStateWidget(
      child: PopScope(
        canPop: !isSearchActive && !_isSettingsOpen,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) {
            return;
          }

          if (isSearchActive) {
            _handleClearSearch();
            return;
          }

          if (_isSettingsOpen) {
            scaffoldKey.currentState!.closeDrawer();
            return;
          }
        },
        child: KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: handleKeyEvent,
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: colorScheme.backgroundBase,
            drawer: Drawer(
              width: 428,
              backgroundColor: colorScheme.backgroundBase,
              child: _settingsPage,
            ),
            drawerEnableOpenDragGesture: !Platform.isAndroid,
            onDrawerChanged: (isOpened) => _isSettingsOpen = isOpened,
            appBar: CustomLockerAppBar(
              scaffoldKey: scaffoldKey,
              isSearchActive: isSearchActive,
              isSyncing: !_hasCompletedInitialLoad || _isLoading,
              searchController: searchController,
              searchFocusNode: _searchFocusNode,
              onSearchFocused: _handleSearchFocused,
              onClearSearch: _handleClearSearch,
              onSearchChanged: _handleSearchChange,
            ),
            body: _buildBody(),
            floatingActionButton: isSearchActive
                ? null
                : FloatingActionButton(
                    onPressed: _openSavePage,
                    shape: const CircleBorder(),
                    backgroundColor: colorScheme.primary700,
                    elevation: 0,
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedPlusSign,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _loadCollections(),
                  child: Text(context.l10n.retry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (isSearchActive) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: SearchResultView(
          collections: _filteredCollections,
          files: _filteredFiles,
          searchQuery: searchQuery,
          isHomePage: true,
        ),
      );
    }
    if (_displayedCollections.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: HomeEmptyStateWidget(),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final scrollBottomPadding = MediaQuery.of(context).padding.bottom + 120;

        return _recentFiles.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: HomeEmptyStateWidget(),
                ),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 32.0,
                  bottom: scrollBottomPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RecentsSectionWidget(
                      collections: _filterOutUncategorized(_collections),
                      recentFiles: _recentFiles,
                    ),
                  ],
                ),
              );
      },
    );
  }

  void _openSavePage() {
    showSaveBottomSheet(
      context,
      onUploadDocument: addFile,
    );
  }
}
