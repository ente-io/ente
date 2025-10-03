import 'dart:async';
import 'dart:io';

import "package:ente_accounts/services/user_service.dart";
import 'package:ente_events/event_bus.dart';
import 'package:ente_ui/components/buttons/gradient_button.dart';
import "package:ente_ui/components/buttons/icon_button_widget.dart";
import 'package:ente_ui/theme/ente_theme.dart';
import 'package:ente_ui/utils/dialog_util.dart';
import 'package:ente_utils/email_util.dart';
import 'package:flutter/material.dart';
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
import 'package:locker/ui/pages/collection_page.dart';
import 'package:locker/ui/pages/information_page.dart';
import "package:locker/ui/pages/settings_page.dart";
import 'package:locker/ui/pages/uploader_page.dart';
import 'package:locker/utils/collection_actions.dart';
import 'package:locker/utils/collection_sort_util.dart';
import 'package:logging/logging.dart';

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

  void _navigateToCollection(Collection collection) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CollectionPage(collection: collection),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          drawer: Drawer(
            width: 428,
            child: _settingsPage,
          ),
          drawerEnableOpenDragGesture: !Platform.isAndroid,
          onDrawerChanged: (isOpened) => _isSettingsOpen = isOpened,
          appBar: AppBar(
            leading: buildSearchLeading(),
            title: GestureDetector(
              onLongPress: () {
                sendLogs(
                  context,
                  'vishnu@ente.io',
                  subject: 'Locker logs',
                  body: 'Debug logs for Locker app.\n\n',
                );
              },
              child: const Text(
                'Locker',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
            actions: [
              buildSearchAction(),
              ...buildSearchActions(),
            ],
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
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.folder_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.noCollectionsFound,
                  style: getEnteTextTheme(context).large.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.createYourFirstCollection,
                  style: getEnteTextTheme(context).body.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: GradientButton(
                    onTap: _createCollection,
                    text: context.l10n.createCollection,
                    iconData: Icons.add,
                    paddingValue: 8.0,
                  ),
                ),
              ],
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
                iconData: Icons.file_upload,
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

  Future<void> _createCollection() async {
    final createdCollection = await CollectionActions.createCollection(context);

    if (createdCollection != null) {
      await _loadCollections();
      _navigateToCollection(createdCollection);
    }
  }

  Widget _buildMultiOptionFab() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isFabOpen,
      builder: (context, isFabOpen, child) {
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
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isFabOpen) ...[
                    ScaleTransition(
                      scale: _animation,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                _toggleFab();
                                _showInformationDialog();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: getEnteColorScheme(context).fillBase,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  context.l10n.saveInformation,
                                  style:
                                      getEnteTextTheme(context).small.copyWith(
                                            color: getEnteColorScheme(context)
                                                .backgroundBase,
                                          ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FloatingActionButton(
                              heroTag: "information",
                              mini: true,
                              onPressed: () {
                                _toggleFab();
                                _showInformationDialog();
                              },
                              backgroundColor:
                                  getEnteColorScheme(context).fillBase,
                              child: const Icon(Icons.edit_document),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_collections.isNotEmpty)
                      ScaleTransition(
                        scale: _animation,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  _toggleFab();
                                  addFile();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: getEnteColorScheme(context).fillBase,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    context.l10n.uploadDocumentTooltip,
                                    style: getEnteTextTheme(context)
                                        .small
                                        .copyWith(
                                          color: getEnteColorScheme(context)
                                              .backgroundBase,
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              FloatingActionButton(
                                heroTag: "addFile",
                                mini: true,
                                onPressed: () {
                                  _toggleFab();
                                  addFile();
                                },
                                backgroundColor:
                                    getEnteColorScheme(context).fillBase,
                                child: const Icon(Icons.file_upload),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                  FloatingActionButton(
                    onPressed: _toggleFab,
                    child: AnimatedRotation(
                      turns: isFabOpen ? 0.125 : 0.0, // 45 degrees when open
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(Icons.add),
                    ),
                  ),
                ],
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
        SectionTitle(title: title),
        trailingWidget: IconButtonWidget(
          icon: Icons.chevron_right,
          iconButtonType: IconButtonType.secondary,
          iconColor: getEnteColorScheme(context).blurStrokePressed,
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
