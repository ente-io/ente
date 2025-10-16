import 'dart:async';
import 'dart:io';

// import "package:dotted_border/dotted_border.dart";
import "package:dotted_border/dotted_border.dart";
import "package:ente_accounts/services/user_service.dart";
import 'package:ente_events/event_bus.dart';
import 'package:ente_ui/components/buttons/gradient_button.dart';
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
import 'package:locker/services/collections/collections_service.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/services/files/sync/models/file.dart';
import "package:locker/ui/collections/collection_flex_grid_view.dart";
import "package:locker/ui/collections/section_title.dart";
import 'package:locker/ui/components/recents_section_widget.dart';
import 'package:locker/ui/components/search_result_view.dart';
import 'package:locker/ui/mixins/search_mixin.dart';
import 'package:locker/ui/pages/all_collections_page.dart';
import 'package:locker/ui/pages/information_page.dart';
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      scaffoldKey.currentState!.openDrawer();
                    },
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedMenu01,
                      color: colorScheme.backdropBase,
                    ),
                  ),
                  GestureDetector(
                    onLongPress: () {
                      sendLogs(
                        context,
                        'vishnu@ente.io',
                        subject: context.l10n.lockerLogs,
                        body: 'Debug logs for Locker app.\n\n',
                      );
                    },
                    child: Text(
                      context.l10n.locker,
                      style: textTheme.h3Bold.copyWith(
                        color: colorScheme.backdropBase,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.backgroundBase,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: TextField(
                  autocorrect: false,
                  enableSuggestions: false,
                  controller: searchController,
                  focusNode: searchFocusNode,
                  onTap: onSearchFocused,
                  onChanged: onSearchChanged,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    hintText: context.l10n.searchHint,
                    hintStyle: TextStyle(
                      color: colorScheme.primary700,
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
                    suffixIcon:
                        (isSearchActive || searchController.text.isNotEmpty)
                            ? GestureDetector(
                                onTap: onClearSearch,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.only(right: 16, left: 8),
                                  child: HugeIcon(
                                    icon: HugeIcons.strokeRoundedCancel01,
                                    color: colorScheme.iconColor,
                                    size: 20,
                                  ),
                                ),
                              )
                            : null,
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 24,
                    ),
                  ),
                  style: TextStyle(
                    color: colorScheme.primary700,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
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
  List<Collection> outgoingCollections = [];
  List<Collection> incomingCollections = [];
  List<Collection> quickLinks = [];
  List<Collection> homeCollections = [];

  String? _error;
  final _logger = Logger('HomePage');
  StreamSubscription? _mediaStreamSubscription;

  @override
  void onFileUploadComplete() {
    // No-op: CollectionService.sync() already fires CollectionsUpdatedEvent
    // which triggers a single refresh. Avoid calling _loadCollections here to
    // prevent duplicate reloads / UI blinking when uploading to multiple
    // collections.
    return;
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
    setState(() {
      _filteredCollections = _filterOutUncategorized(collections);
      _filteredFiles = files;
    });
  }

  @override
  void onSearchStateChanged(bool isActive) {
    if (!isActive) {
      setState(() {
        _filteredCollections = _filterOutUncategorized(_collections);
        _filteredFiles = _recentFiles;
      });
    }
  }

  List<Collection> get _displayedCollections {
    final List<Collection> collections;
    if (isSearchActive) {
      collections = _filteredCollections;
    } else {
      final excludeIds = {
        ...quickLinks.map((c) => c.id),
      };
      collections =
          _collections.where((c) => !excludeIds.contains(c.id)).toList();
    }
    return _filterOutUncategorized(collections);
  }

  List<Collection> _filterOutUncategorized(List<Collection> collections) {
    return CollectionSortUtil.filterAndSortCollections(collections);
  }

  List<Collection> getOnEnteCollections(List<Collection> collections) {
    final excludeIds = {
      ...incomingCollections.map((c) => c.id),
      ...quickLinks.map((c) => c.id),
    };
    collections = collections.where((c) => !excludeIds.contains(c.id)).toList();
    return _filterOutUncategorized(collections);
  }

  final ValueNotifier<bool> _isFabOpen = ValueNotifier<bool>(false);
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _selectedCollections = SelectedCollections();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

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
    _animationController.dispose();
    _isFabOpen.dispose();
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
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final collections = await CollectionService.instance.getCollections();
      await _loadRecentFiles(collections);

      final sortedCollections =
          CollectionSortUtil.getSortedCollections(collections);

      final sharedCollections =
          await CollectionService.instance.getSharedCollections();

      setState(() {
        homeCollections = getOnEnteCollections(sortedCollections);
        _collections = sortedCollections;
        _filteredCollections = _filterOutUncategorized(sortedCollections);
        _filteredFiles = _recentFiles;
        incomingCollections = sharedCollections.incoming;
        outgoingCollections = sharedCollections.outgoing;
        quickLinks = sharedCollections.quickLinks;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = 'Error fetching collections: $error';
        _isLoading = false;
      });
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
      onPopInvokedWithResult: (_, result) async {
        if (_isSettingsOpen) {
          scaffoldKey.currentState!.closeDrawer();
          return;
        } else if (!Platform.isAndroid) {
          Navigator.of(context).pop();
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
          floatingActionButton:
              isSearchActive ? const SizedBox.shrink() : _buildMultiOptionFab(),
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
        child: SearchResultView(
          collections: _filteredCollections,
          files: _filteredFiles,
          searchQuery: searchQuery,
          isHomePage: true,
        ),
      );
    }

    if (_displayedCollections.isEmpty) {
      final colorScheme = getEnteColorScheme(context);
      final textTheme = getEnteTextTheme(context);

      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
              ),
              child: DottedBorder(
                options: RoundedRectDottedBorderOptions(
                  strokeWidth: 2,
                  color: colorScheme.fillMuted,
                  dashPattern: const [6, 6],
                  radius: const Radius.circular(24),
                  padding: const EdgeInsets.all(48),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/empty_state.png',
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Upload a File',
                        style: textTheme.h3Bold,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Click here to upload',
                        style: textTheme.small,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 32, // Account for padding
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._buildCollectionSection(
                  title: context.l10n.collections,
                  collections: homeCollections,
                  viewType: UISectionType.homeCollections,
                ),
                if (outgoingCollections.isNotEmpty)
                  ..._buildCollectionSection(
                    title: context.l10n.sharedByYou,
                    collections: outgoingCollections,
                    viewType: UISectionType.outgoingCollections,
                  ),
                if (incomingCollections.isNotEmpty)
                  ..._buildCollectionSection(
                    title: context.l10n.sharedWithYou,
                    collections: incomingCollections,
                    viewType: UISectionType.incomingCollections,
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
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.description_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.nothingYet,
                style: getEnteTextTheme(context).body.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.uploadYourFirstDocument,
                style: getEnteTextTheme(context).small.copyWith(
                      color: Colors.grey[500],
                    ),
              ),
              const SizedBox(height: 24),
              GradientButton(
                onTap: addFile,
                text: context.l10n.uploadDocument,
                hugeIcon: HugeIcon(
                  icon: HugeIcons.strokeRoundedFile01,
                  color: getEnteColorScheme(context).primary700,
                  size: 20,
                ),
                paddingValue: 8.0,
              ),
            ],
          ),
        ),
      );
    }
    return RecentsSectionWidget(
      collections: _filterOutUncategorized(_collections),
      recentFiles: _recentFiles,
    );
  }

  Widget _buildMultiOptionFab() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isFabOpen,
      builder: (context, isFabOpen, child) {
        final colorScheme = getEnteColorScheme(context);
        final textTheme = getEnteTextTheme(context);

        return Stack(
          children: [
            if (isFabOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _toggleFab,
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
            Positioned(
              right: 64,
              bottom: 64,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isFabOpen)
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 1),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: FadeTransition(
                        opacity: _animation,
                        child: Container(
                          width: 200,
                          decoration: BoxDecoration(
                            color: colorScheme.backgroundElevated,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colorScheme.strokeFaint),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Material(
                                color: Colors.transparent,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(15),
                                  topRight: Radius.circular(15),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    _toggleFab();
                                    _showInformationDialog();
                                  },
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(15),
                                    topRight: Radius.circular(15),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    child: Row(
                                      children: [
                                        HugeIcon(
                                          icon: HugeIcons.strokeRoundedFile01,
                                          color: colorScheme.primary700,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            context.l10n.saveInformation,
                                            style: textTheme.body,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: colorScheme.strokeFaint,
                              ),
                              Material(
                                color: Colors.transparent,
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(15),
                                  bottomRight: Radius.circular(15),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    _toggleFab();
                                    addFile();
                                  },
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(15),
                                    bottomRight: Radius.circular(15),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    child: Row(
                                      children: [
                                        HugeIcon(
                                          icon:
                                              HugeIcons.strokeRoundedFileUpload,
                                          color: colorScheme.primary700,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            context.l10n.saveDocument,
                                            style: textTheme.body,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                onPressed: _toggleFab,
                shape: const CircleBorder(),
                backgroundColor: colorScheme.primary700,
                child: AnimatedRotation(
                  turns: isFabOpen ? 0.125 : 0.0, // 45 degrees when open
                  duration: const Duration(milliseconds: 300),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedPlusSign,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _toggleFab() {
    _isFabOpen.value = !_isFabOpen.value;

    if (_isFabOpen.value) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  List<Widget> _buildCollectionSection({
    required String title,
    required List<Collection> collections,
    required UISectionType viewType,
  }) {
    return [
      SectionOptions(
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
        body: context.l10n.items(collections.length),
        SectionTitle(title: title),
        trailingWidget: IconButtonWidget(
          icon: Icons.chevron_right,
          iconButtonType: IconButtonType.secondary,
          iconColor: getEnteColorScheme(context).textBase,
        ),
      ),
      const SizedBox(height: 24),
      CollectionFlexGridViewWidget(
        collections: collections,
      ),
      const SizedBox(height: 24),
    ];
  }

  void _showInformationDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const InformationPage(),
      ),
    );
  }
}
