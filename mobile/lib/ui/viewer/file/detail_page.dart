import "dart:math";

import 'package:extended_image/extended_image.dart';
import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/errors.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/models/file/file_type.dart";
import "package:photos/ui/common/fast_scroll_physics.dart";
import 'package:photos/ui/tools/editor/image_editor_page.dart';
import "package:photos/ui/tools/editor/video_editor_page.dart";
import "package:photos/ui/viewer/file/file_app_bar.dart";
import "package:photos/ui/viewer/file/file_bottom_bar.dart";
import 'package:photos/ui/viewer/file/file_widget.dart';
import 'package:photos/ui/viewer/gallery/gallery.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/file_util.dart';
import 'package:photos/utils/navigation_util.dart';
import 'package:photos/utils/toast_util.dart';

enum DetailPageMode {
  minimalistic,
  full,
}

class DetailPageConfiguration {
  final List<EnteFile> files;
  final GalleryLoader? asyncLoader;
  final int selectedIndex;
  final String tagPrefix;
  final DetailPageMode mode;
  final bool sortOrderAsc;

  DetailPageConfiguration(
    this.files,
    this.asyncLoader,
    this.selectedIndex,
    this.tagPrefix, {
    this.mode = DetailPageMode.full,
    this.sortOrderAsc = false,
  });

  DetailPageConfiguration copyWith({
    List<EnteFile>? files,
    GalleryLoader? asyncLoader,
    int? selectedIndex,
    String? tagPrefix,
    bool? sortOrderAsc,
  }) {
    return DetailPageConfiguration(
      files ?? this.files,
      asyncLoader ?? this.asyncLoader,
      selectedIndex ?? this.selectedIndex,
      tagPrefix ?? this.tagPrefix,
      sortOrderAsc: sortOrderAsc ?? this.sortOrderAsc,
    );
  }
}

class DetailPage extends StatefulWidget {
  final DetailPageConfiguration config;

  const DetailPage(this.config, {key}) : super(key: key);

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  static const kLoadLimit = 100;
  final _logger = Logger("DetailPageState");
  bool _shouldDisableScroll = false;
  List<EnteFile>? _files;
  late PageController _pageController;
  final _selectedIndexNotifier = ValueNotifier(0);
  bool _hasLoadedTillStart = false;
  bool _hasLoadedTillEnd = false;
  final _enableFullScreenNotifier = ValueNotifier(false);
  bool _isFirstOpened = true;

  @override
  void initState() {
    super.initState();
    _files = [
      ...widget.config.files,
    ]; // Make a copy since we append preceding and succeeding entries to this
    _selectedIndexNotifier.value = widget.config.selectedIndex;
    _preloadEntries();
    _pageController = PageController(initialPage: _selectedIndexNotifier.value);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _enableFullScreenNotifier.dispose();
    _selectedIndexNotifier.dispose();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
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
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: ValueListenableBuilder(
          builder: (BuildContext context, int selectedIndex, _) {
            return FileAppBar(
              _files![selectedIndex],
              _onFileRemoved,
              100,
              widget.config.mode == DetailPageMode.full,
              enableFullScreenNotifier: _enableFullScreenNotifier,
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
            _buildPageView(context),
            ValueListenableBuilder(
              builder: (BuildContext context, int selectedIndex, _) {
                return FileBottomBar(
                  _files![selectedIndex],
                  _onEditFileRequested,
                  widget.config.mode == DetailPageMode.minimalistic,
                  onFileRemoved: _onFileRemoved,
                  userID: Configuration.instance.getUserID(),
                  enableFullScreenNotifier: _enableFullScreenNotifier,
                );
              },
              valueListenable: _selectedIndexNotifier,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageView(BuildContext context) {
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
                _logger.fine('setState $_shouldDisableScroll to $value');
                _shouldDisableScroll = value;
              });
            }
          },
          playbackCallback: (isPlaying) {
            Future.delayed(Duration.zero, () {
              _toggleFullScreen(shouldEnable: isPlaying);
            });
          },
          backgroundDecoration: const BoxDecoration(color: Colors.black),
        );
        return GestureDetector(
          onTap: () {
            file.fileType != FileType.video ? _toggleFullScreen() : null;
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
        _preloadEntries();
      },
      physics: _shouldDisableScroll
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

  void _toggleFullScreen({bool? shouldEnable}) {
    if (shouldEnable != null) {
      if (_enableFullScreenNotifier.value == shouldEnable) return;
    }
    _enableFullScreenNotifier.value = !_enableFullScreenNotifier.value;

    Future.delayed(const Duration(milliseconds: 125), () {
      SystemChrome.setEnabledSystemUIMode(
        //to hide status bar?
        SystemUiMode.manual,
        overlays: _enableFullScreenNotifier.value ? [] : SystemUiOverlay.values,
      );
    });
  }

  Future<void> _preloadEntries() async {
    final isSortOrderAsc = widget.config.sortOrderAsc;

    if (widget.config.asyncLoader == null) return;

    if (_selectedIndexNotifier.value == 0 && !_hasLoadedTillStart) {
      await _loadStartEntries(isSortOrderAsc);
    }

    if (_selectedIndexNotifier.value == _files!.length - 1 &&
        !_hasLoadedTillEnd) {
      await _loadEndEntries(isSortOrderAsc);
    }
  }

  Future<void> _loadStartEntries(bool isSortOrderAsc) async {
    final result = isSortOrderAsc
        ? await widget.config.asyncLoader!(
            galleryLoadStartTime,
            _files![_selectedIndexNotifier.value].creationTime! - 1,
            limit: kLoadLimit,
          )
        : await widget.config.asyncLoader!(
            _files![_selectedIndexNotifier.value].creationTime! + 1,
            DateTime.now().microsecondsSinceEpoch,
            limit: kLoadLimit,
            asc: true,
          );

    setState(() {
      _logger.fine('setState loadStartEntries');
      // Returned result could be a subtype of File
      // ignore: unnecessary_cast
      final files = result.files.reversed.map((e) => e as EnteFile).toList();
      if (!result.hasMore) {
        _hasLoadedTillStart = true;
      }
      final length = files.length;
      files.addAll(_files!);
      _files = files;
      _pageController.jumpToPage(length);
      _selectedIndexNotifier.value = length;
    });
  }

  Future<void> _loadEndEntries(bool isSortOrderAsc) async {
    final result = isSortOrderAsc
        ? await widget.config.asyncLoader!(
            _files![_selectedIndexNotifier.value].creationTime! + 1,
            DateTime.now().microsecondsSinceEpoch,
            limit: kLoadLimit,
            asc: true,
          )
        : await widget.config.asyncLoader!(
            galleryLoadStartTime,
            _files![_selectedIndexNotifier.value].creationTime! - 1,
            limit: kLoadLimit,
          );

    setState(() {
      if (!result.hasMore) {
        _hasLoadedTillEnd = true;
      }
      _logger.fine('setState loadEndEntries hasMore ${result.hasMore}');
      _files!.addAll(result.files);
    });
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
      _files!.remove(file);
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
        S.of(context).sorry,
        S.of(context).weDontSupportEditingPhotosAndAlbumsThatYouDont,
      );
      return;
    }
    final dialog = createProgressDialog(context, S.of(context).pleaseWait);
    await dialog.show();
    try {
      final ioFile = await getFile(file);
      if (ioFile == null) {
        showShortToast(context, S.of(context).failedToFetchOriginalForEdit);
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
          imageProvider,
          file,
          widget.config.copyWith(
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
}
