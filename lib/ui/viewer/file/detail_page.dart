import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/errors.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/file.dart';
import 'package:photos/ui/tools/editor/image_editor_page.dart';
import 'package:photos/ui/viewer/file/fading_app_bar.dart';
import 'package:photos/ui/viewer/file/fading_bottom_bar.dart';
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
  final List<File> files;
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
    List<File>? files,
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
  List<File>? _files;
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
            return FadingAppBar(
              _files![selectedIndex],
              _onFileRemoved,
              Configuration.instance.getUserID(),
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
      body: Center(
        child: Stack(
          children: [
            _buildPageView(context),
            ValueListenableBuilder(
              builder: (BuildContext context, int selectedIndex, _) {
                return FadingBottomBar(
                  _files![_selectedIndexNotifier.value],
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    _logger.info("Building with " + _selectedIndexNotifier.value.toString());
    return PageView.builder(
      itemBuilder: (context, index) {
        final file = _files![index];
        _preloadFiles(index);
        return GestureDetector(
          onTap: () {
            _toggleFullScreen();
          },
          child: FileWidget(
            file,
            autoPlay: shouldAutoPlay(),
            tagPrefix: widget.config.tagPrefix,
            shouldDisableScroll: (value) {
              if (_shouldDisableScroll != value) {
                setState(() {
                  _shouldDisableScroll = value;
                });
              }
            },
            //Noticed that when the video is seeked, the video pops and moves the
            //seek bar along with it and it happens when bottomPadding is 0. So we
            //don't toggle full screen for cases where this issue happens.
            playbackCallback: bottomPadding != 0
                ? (isPlaying) {
                    Future.delayed(Duration.zero, () {
                      _toggleFullScreen();
                    });
                  }
                : null,
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
        );
      },
      onPageChanged: (index) {
        _selectedIndexNotifier.value = index;
        _preloadEntries();
      },
      physics: _shouldDisableScroll
          ? const NeverScrollableScrollPhysics()
          : const PageScrollPhysics(),
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

  void _toggleFullScreen() {
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
      // Returned result could be a subtype of File
      // ignore: unnecessary_cast
      final files = result.files.reversed.map((e) => e as File).toList();
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

  Future<void> _onFileRemoved(File file) async {
    final totalFiles = _files!.length;
    if (totalFiles == 1) {
      // Deleted the only file
      Navigator.of(context).pop(); // Close pageview
      return;
    }
    if (_selectedIndexNotifier.value == totalFiles - 1) {
      // Deleted the last file
      await _pageController.previousPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
      setState(() {
        _files!.remove(file);
      });
    } else {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
      setState(() {
        _selectedIndexNotifier.value--;
        _files!.remove(file);
      });
    }
  }

  Future<void> _onEditFileRequested(File file) async {
    if (file.uploadedFileID != null &&
        file.ownerID != Configuration.instance.getUserID()) {
      _logger.severe(
        "Attempt to edit unowned file",
        UnauthorizedEditError(),
        StackTrace.current,
      );
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
