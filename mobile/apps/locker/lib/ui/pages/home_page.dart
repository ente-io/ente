import 'dart:async';
import 'dart:io';

import "package:ente_accounts/services/user_service.dart";
import 'package:ente_events/event_bus.dart';
import "package:ente_ui/components/buttons/icon_button_widget.dart";
import 'package:ente_ui/theme/ente_theme.dart';
import 'package:ente_ui/utils/dialog_util.dart';
import 'package:ente_utils/email_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "package:hugeicons/hugeicons.dart";
import 'package:listen_sharing_intent/listen_sharing_intent.dart';
import 'package:locker/events/collections_updated_event.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/models/selected_collections.dart';
import 'package:locker/models/ui_section_type.dart';
import 'package:locker/services/collections/collections_service.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/services/files/sync/models/file.dart';
import "package:locker/ui/collections/collection_flex_grid_view.dart";
import "package:locker/ui/collections/section_title.dart";
import "package:locker/ui/components/home_empty_state_widget.dart";
import 'package:locker/ui/components/recents_section_widget.dart';
import 'package:locker/ui/components/search_result_view.dart';
import 'package:locker/ui/mixins/search_mixin.dart';
import 'package:locker/ui/pages/all_collections_page.dart';
import 'package:locker/ui/pages/save_page.dart';
import "package:locker/ui/pages/settings_page.dart";
import 'package:locker/ui/pages/uploader_page.dart';
import 'package:locker/utils/collection_sort_util.dart';
import 'package:logging/logging.dart';

class CustomLockerAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final bool isSearchActive;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final VoidCallback onSearchFocused;
  final VoidCallback onClearSearch;
  final ValueChanged<String>? onSearchChanged;

  const CustomLockerAppBar({
    super.key,
    required this.scaffoldKey,
    required this.isSearchActive,
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
    final textTheme = getEnteTextTheme(context);
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
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onLongPress: () {
                      sendLogs(
                        context,
                        'support@ente.io',
                        subject: context.l10n.lockerLogs,
                        body: 'Debug logs for Locker app.\n\n',
                      );
                    },
                    child: Text(
                      context.l10n.locker,
                      style: textTheme.h3Bold.copyWith(
                        color: Colors.white,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
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
                      color: colorScheme.textMuted,
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
  late final _settingsPage = SettingsPage(
    emailNotifier: UserService.instance.emailValueNotifier,
    scaffoldKey: scaffoldKey,
  );
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchFocusNode = FocusNode();
  bool _isLoading = true;
  bool _isSettingsOpen = false;

  List<Collection> _collections = [];
  late final SelectedCollections _selectedCollections;
  List<Collection> _filteredCollections = [];
  List<EnteFile> _recentFiles = [];
  List<EnteFile> _filteredFiles = [];
  List<Collection> homeCollections = [];

  String? _error;
  final _logger = Logger('HomePage');
  StreamSubscription? _mediaStreamSubscription;

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

  List<Collection> getOnEnteCollections(List<Collection> collections) {
    return _filterOutUncategorized(collections);
  }

  @override
  void initState() {
    super.initState();
    _selectedCollections = SelectedCollections();

    _loadCollections();

    if (CollectionService.instance.hasCompletedFirstSync()) {
      _loadCollections();
    }

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
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    disposeSharing();
    super.dispose();
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
            _logger.info('Shared file: ${file.path}, type: ${file.type}');
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
          _logger.info('Initial shared file: ${file.path}, type: ${file.type}');
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
        _logger.info('Processing shared file: ${sharedFile.path}');
        if (sharedFile.path.isNotEmpty) {
          final file = File(sharedFile.path);
          if (await file.exists()) {
            _logger.info('File exists, uploading: ${sharedFile.path}');
            await uploadFiles([file]);
          } else {
            _logger.warning('Shared file does not exist: ${sharedFile.path}');
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

      if (mounted) {
        setState(() {
          homeCollections = getOnEnteCollections(sortedCollections);
          _collections = sortedCollections;
          _filteredCollections = _filterOutUncategorized(sortedCollections);
          _filteredFiles = _recentFiles;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = 'Error fetching collections: $error';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadRecentFiles(List<Collection> collections) async {
    final allFiles = <EnteFile>[];

    allFiles.addAll(await CollectionService.instance.getAllFiles());

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
    // Clear text and unfocus to properly dismiss search
    searchController.clear();
    _searchFocusNode.unfocus();
    // Simulate ESC key to deactivate search state
    // ignore: prefer_const_constructors
    final escapeEvent = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.escape,
      logicalKey: LogicalKeyboardKey.escape,
      timeStamp: const Duration(seconds: 0),
    );
    handleKeyEvent(escapeEvent);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return PopScope(
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
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedPlusSign,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

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
        final scrollBottomPadding =
            MediaQuery.of(context).padding.bottom + 120.0;

        return SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 16.0,
            bottom: scrollBottomPadding,
          ),
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._buildCollectionSection(
                  title: context.l10n.collections,
                  collections: homeCollections,
                  viewType: UISectionType.homeCollections,
                ),
                _buildRecentsSection(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentsSection() {
    if (_recentFiles.isEmpty) {
      return const HomeEmptyStateWidget();
    }
    return RecentsSectionWidget(
      collections: _filterOutUncategorized(_collections),
      recentFiles: _recentFiles,
    );
  }

  List<Widget> _buildCollectionSection({
    required String title,
    required List<Collection> collections,
    required UISectionType viewType,
  }) {
    final colorScheme = getEnteColorScheme(context);
    return [
      SectionOptions(
        SectionTitle(title: title),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AllCollectionsPage(
                viewType: viewType,
                selectedCollections: _selectedCollections,
              ),
            ),
          );
        },
        trailingWidget: IconButtonWidget(
          icon: Icons.chevron_right,
          iconButtonType: IconButtonType.secondary,
          iconColor: colorScheme.textBase,
        ),
      ),
      const SizedBox(height: 12),
      CollectionFlexGridViewWidget(
        collections: collections,
      ),
      const SizedBox(height: 24),
    ];
  }

  void _openSavePage() {
    showSaveBottomSheet(
      context,
      onUploadDocument: addFile,
    );
  }
}
