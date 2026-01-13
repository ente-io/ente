import "dart:async";
import "dart:math";

import 'package:extended_image/extended_image.dart';
import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/errors.dart';
import "package:photos/core/event_bus.dart";
import "package:photos/events/guest_view_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/extensions/file_props.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/models/file/file_type.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/local_authentication_service.dart";
import "package:photos/states/detail_page_state.dart";
import "package:photos/ui/common/fast_scroll_physics.dart";
import 'package:photos/ui/notification/toast.dart';
import "package:photos/ui/tools/editor/image_editor/image_editor_page.dart";
import "package:photos/ui/tools/editor/video_editor_page.dart";
import "package:photos/ui/viewer/file/file_app_bar.dart";
import "package:photos/ui/viewer/file/file_bottom_bar.dart";
import 'package:photos/ui/viewer/file/file_widget.dart';
import "package:photos/ui/viewer/file/panorama_viewer_screen.dart";
import "package:photos/ui/viewer/file/text_detection_overlay_button.dart";
import 'package:photos/ui/viewer/gallery/gallery.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/file_util.dart';
import 'package:photos/utils/navigation_util.dart';
import "package:photos/utils/thumbnail_util.dart";

enum DetailPageMode {
  minimalistic,
  full,
}

class DetailPageConfiguration {
  final List<EnteFile> files;
  final int selectedIndex;
  final String tagPrefix;
  final DetailPageMode mode;
  final bool isLocalOnlyContext;

  /// Callback invoked with the page context after the page is ready.
  /// Useful for showing bottom sheets or dialogs after navigation completes.
  final void Function(BuildContext context)? onPageReady;

  DetailPageConfiguration(
    this.files,
    this.selectedIndex,
    this.tagPrefix, {
    this.mode = DetailPageMode.full,
    this.isLocalOnlyContext = false,
    this.onPageReady,
  });

  DetailPageConfiguration copyWith({
    List<EnteFile>? files,
    GalleryLoader? asyncLoader,
    int? selectedIndex,
    String? tagPrefix,
    bool? isLocalOnlyContext,
  }) {
    return DetailPageConfiguration(
      files ?? this.files,
      selectedIndex ?? this.selectedIndex,
      tagPrefix ?? this.tagPrefix,
      isLocalOnlyContext: isLocalOnlyContext ?? this.isLocalOnlyContext,
    );
  }
}

class DetailPage extends StatefulWidget {
  final DetailPageConfiguration config;

  const DetailPage(this.config, {super.key});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final _enableFullScreenNotifier = ValueNotifier(false);
  final _isInSharedCollectionNotifier = ValueNotifier(false);
  final _showingThumbnailFallbackNotifier = ValueNotifier<int?>(null);

  @override
  void dispose() {
    _enableFullScreenNotifier.dispose();
    _isInSharedCollectionNotifier.dispose();
    _showingThumbnailFallbackNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Separating body to a different widget to avoid
    // unnecessary reinitialization of the InheritedDetailPageState
    // when the body is rebuilt, which can reset state stored in it.
    return InheritedDetailPageState(
      enableFullScreenNotifier: _enableFullScreenNotifier,
      isInSharedCollectionNotifier: _isInSharedCollectionNotifier,
      showingThumbnailFallbackNotifier: _showingThumbnailFallbackNotifier,
      child: _Body(widget.config),
    );
  }
}

class _Body extends StatefulWidget {
  final DetailPageConfiguration config;

  const _Body(this.config);

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _logger = Logger("DetailPageState");
  bool _shouldDisableScroll = false;
  List<EnteFile>? _files;
  late PageController _pageController;
  final _selectedIndexNotifier = ValueNotifier(0);
  bool _isFirstOpened = true;
  bool isGuestView = false;
  bool swipeLocked = false;
  late final StreamSubscription<GuestViewEvent> _guestViewEventSubscription;

  @override
  void initState() {
    super.initState();
    _files = widget.config.files;

    _selectedIndexNotifier.value = widget.config.selectedIndex;
    _pageController = PageController(initialPage: _selectedIndexNotifier.value);
    _guestViewEventSubscription =
        Bus.instance.on<GuestViewEvent>().listen((event) {
      setState(() {
        isGuestView = event.isGuestView;
        swipeLocked = event.swipeLocked;
      });
    });

    // Update shared collection state after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updateSharedCollectionState(_files![_selectedIndexNotifier.value]);
      widget.config.onPageReady?.call(context);
    });
  }

  @override
  void dispose() {
    _guestViewEventSubscription.cancel();
    _pageController.dispose();
    _selectedIndexNotifier.dispose();
    super.dispose();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Color(0x00010000),
      ),
    );

    unawaited(
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      _files![_selectedIndexNotifier.value];
    } catch (e) {
      _logger.severe(e);
      Navigator.pop(context);
    }
    _logger.info(
      "Opening " +
          _files![_selectedIndexNotifier.value].toString() +
          ". " +
          (_selectedIndexNotifier.value + 1).toString() +
          " / " +
          _files!.length.toString() +
          " files .",
    );
    return PopScope(
      canPop: !isGuestView,
      onPopInvokedWithResult: (didPop, _) async {
        if (isGuestView) {
          final authenticated = await _requestAuthentication();
          if (authenticated) {
            Bus.instance.fire(GuestViewEvent(false, false));
            await localSettings.setOnGuestView(false);
          }
        }
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: ValueListenableBuilder(
            builder: (BuildContext context, int selectedIndex, _) {
              return FileAppBar(
                _files![selectedIndex],
                _onFileRemoved,
                _onEditFileRequested,
                enableFullScreenNotifier: InheritedDetailPageState.of(context)
                    .enableFullScreenNotifier,
                mode: widget.config.mode,
              );
            },
            valueListenable: _selectedIndexNotifier,
          ),
        ),
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.black,
        body: Center(
          child: Stack(
            children: [
              _buildPageView(),
              ValueListenableBuilder(
                builder: (BuildContext context, int selectedIndex, _) {
                  return widget.config.mode == DetailPageMode.minimalistic
                      ? const SizedBox()
                      : FileBottomBar(
                          _files![selectedIndex],
                          onFileRemoved: _onFileRemoved,
                          userID: Configuration.instance.getUserID(),
                          enableFullScreenNotifier:
                              InheritedDetailPageState.of(context)
                                  .enableFullScreenNotifier,
                          isLocalOnlyContext: widget.config.isLocalOnlyContext,
                        );
                },
                valueListenable: _selectedIndexNotifier,
              ),
              ValueListenableBuilder(
                valueListenable: _selectedIndexNotifier,
                builder: (BuildContext context, int selectedIndex, _) {
                  return widget.config.mode == DetailPageMode.minimalistic
                      ? const SizedBox.shrink()
                      : TextDetectionOverlayButton(
                          file: _files![selectedIndex],
                          enableFullScreenNotifier:
                              InheritedDetailPageState.of(context)
                                  .enableFullScreenNotifier,
                          isGuestView: isGuestView,
                        );
                },
              ),
              ValueListenableBuilder(
                valueListenable: _selectedIndexNotifier,
                builder: (BuildContext context, int selectedIndex, _) {
                  if (_files![selectedIndex].isPanorama() == true) {
                    return ValueListenableBuilder(
                      valueListenable: InheritedDetailPageState.of(context)
                          .enableFullScreenNotifier,
                      builder: (context, value, child) {
                        return IgnorePointer(
                          ignoring: value,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: !value ? 1.0 : 0.0,
                            child: Align(
                              alignment: Alignment.center,
                              child: Tooltip(
                                message: AppLocalizations.of(context).panorama,
                                child: IconButton(
                                  style: IconButton.styleFrom(
                                    backgroundColor: const Color(0xAA252525),
                                    fixedSize: const Size(44, 44),
                                  ),
                                  icon: const Icon(
                                    Icons.threesixty,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                  onPressed: () async {
                                    await openPanoramaViewerPage(
                                      _files![selectedIndex],
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }
                  return const SizedBox();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> openPanoramaViewerPage(EnteFile file) async {
    final fetchedFile = await getFile(file);
    if (fetchedFile == null) {
      return;
    }
    final fetchedThumbnail = await getThumbnail(file);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) {
          return PanoramaViewerScreen(
            file: fetchedFile,
            thumbnail: fetchedThumbnail,
          );
        },
      ),
    ).ignore();
  }

  Widget _buildPageView() {
    return PageView.builder(
      clipBehavior: Clip.none,
      itemBuilder: (context, index) {
        final file = _files![index];
        _preloadFiles(index);
        final Widget fileContent = FileWidget(
          file,
          autoPlay: shouldAutoPlay(),
          tagPrefix: widget.config.tagPrefix,
          shouldDisableScroll: (value) {
            if (_shouldDisableScroll != value) {
              setState(() {
                _logger.info('setState $_shouldDisableScroll to $value');
                _shouldDisableScroll = value;
              });
            }
          },
          playbackCallback: (shouldEnable, reason) {
            Future.delayed(Duration.zero, () {
              InheritedDetailPageState.of(context).requestFullScreen(
                shouldEnable: shouldEnable,
                reason: reason,
              );
            });
          },
          backgroundDecoration: const BoxDecoration(color: Colors.black),
        );
        return GestureDetector(
          onTap: () {
            file.fileType != FileType.video
                ? InheritedDetailPageState.of(context).toggleFullScreenByUser()
                : null;
          },
          child: fileContent,
        );
      },
      onPageChanged: (index) {
        if (_selectedIndexNotifier.value == index) {
          if (kDebugMode) {
            debugPrint("onPageChanged called with same index $index");
          }
          // always notify listeners when the index is the same because
          // the total number of files might have changed
          // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
          _selectedIndexNotifier.notifyListeners();
        } else {
          _selectedIndexNotifier.value = index;
        }
        Bus.instance.fire(GuestViewEvent(isGuestView, swipeLocked));
        _updateSharedCollectionState(_files![index]);
      },
      physics: _shouldDisableScroll || swipeLocked
          ? const NeverScrollableScrollPhysics()
          : const FastScrollPhysics(speedFactor: 4.0),
      controller: _pageController,
      itemCount: _files!.length,
    );
  }

  bool shouldAutoPlay() {
    if (_isFirstOpened) {
      _isFirstOpened = false;
      return true;
    }
    return false;
  }

  void _preloadFiles(int index) {
    if (index > 0) {
      preloadFile(_files![index - 1]);
    }
    if (index < _files!.length - 1) {
      preloadFile(_files![index + 1]);
    }
  }

  Future<void> _onFileRemoved(EnteFile file) async {
    final totalFiles = _files!.length;
    if (totalFiles == 1) {
      // Deleted the only file
      Navigator.of(context).pop(); // Close pageview
      return;
    }
    setState(() {
      _files!.removeAt(_selectedIndexNotifier.value);
      _selectedIndexNotifier.value = min(
        _selectedIndexNotifier.value,
        totalFiles - 2,
      );
    });
    final currentPageIndex = _pageController.page!.round();
    final int targetPageIndex = _files!.length > currentPageIndex
        ? currentPageIndex
        : currentPageIndex - 1;
    if (_files!.isNotEmpty) {
      await _pageController.animateToPage(
        targetPageIndex,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _onEditFileRequested(EnteFile file) async {
    if (file.uploadedFileID != null &&
        file.ownerID != Configuration.instance.getUserID()) {
      _logger.severe(
        "Attempt to edit unowned file",
        UnauthorizedEditError(),
        StackTrace.current,
      );
      // ignore: unawaited_futures
      showErrorDialog(
        context,
        AppLocalizations.of(context).sorry,
        AppLocalizations.of(context)
            .weDontSupportEditingPhotosAndAlbumsThatYouDont,
      );
      return;
    }
    final dialog =
        createProgressDialog(context, AppLocalizations.of(context).pleaseWait);
    await dialog.show();

    try {
      final ioFile = await getFile(file);
      if (ioFile == null) {
        showShortToast(
          context,
          AppLocalizations.of(context).failedToFetchOriginalForEdit,
        );
        await dialog.hide();
        return;
      }
      if (file.fileType == FileType.video) {
        await dialog.hide();
        replacePage(
          context,
          VideoEditorPage(
            file: file,
            ioFile: ioFile,
            detailPageConfig: widget.config.copyWith(
              files: _files,
              selectedIndex: _selectedIndexNotifier.value,
            ),
          ),
        );
        return;
      }
      final imageProvider =
          ExtendedFileImageProvider(ioFile, cacheRawData: true);
      await precacheImage(imageProvider, context);
      await dialog.hide();
      replacePage(
        context,
        ImageEditorPage(
          originalFile: file,
          file: ioFile,
          detailPageConfig: widget.config.copyWith(
            files: _files,
            selectedIndex: _selectedIndexNotifier.value,
          ),
        ),
      );
    } catch (e) {
      await dialog.hide();
      _logger.warning("Failed to initiate edit", e);
    }
  }

  Future<bool> _requestAuthentication() async {
    return await LocalAuthenticationService.instance.requestLocalAuthentication(
      context,
      "Please authenticate to view more photos and videos.",
    );
  }

  Future<void> _updateSharedCollectionState(EnteFile file) async {
    final fileID = file.uploadedFileID;
    final notifier =
        InheritedDetailPageState.maybeOf(context)?.isInSharedCollectionNotifier;

    if (notifier == null) return;

    if (fileID == null) {
      notifier.value = false;
      return;
    }

    final isShared =
        await CollectionsService.instance.isFileInSharedCollection(fileID);

    // Guard: Only update if still showing the same file
    // (user may have swiped to a different file while awaiting)
    if (_files![_selectedIndexNotifier.value].uploadedFileID == fileID) {
      notifier.value = isShared;
    }
  }
}
