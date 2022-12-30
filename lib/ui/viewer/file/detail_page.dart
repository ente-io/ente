// @dart=2.9

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/errors.dart';
import 'package:photos/models/file.dart';
import 'package:photos/ui/tools/editor/image_editor_page.dart';
import 'package:photos/ui/viewer/file/fading_app_bar.dart';
import 'package:photos/ui/viewer/file/fading_bottom_bar.dart';
import 'package:photos/ui/viewer/file/file_widget.dart';
import 'package:photos/ui/viewer/gallery/gallery.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/file_util.dart';
import 'package:photos/utils/navigation_util.dart';

enum DetailPageMode {
  minimalistic,
  full,
}

class DetailPageConfiguration {
  final List<File> files;
  final GalleryLoader asyncLoader;
  final int selectedIndex;
  final String tagPrefix;
  final DetailPageMode mode;

  DetailPageConfiguration(
    this.files,
    this.asyncLoader,
    this.selectedIndex,
    this.tagPrefix, {
    this.mode = DetailPageMode.full,
  });

  DetailPageConfiguration copyWith({
    List<File> files,
    GalleryLoader asyncLoader,
    int selectedIndex,
    String tagPrefix,
  }) {
    return DetailPageConfiguration(
      files ?? this.files,
      asyncLoader ?? this.asyncLoader,
      selectedIndex ?? this.selectedIndex,
      tagPrefix ?? this.tagPrefix,
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
  List<File> _files;
  PageController _pageController;
  int _selectedIndex = 0;
  bool _hasPageChanged = false;
  bool _hasLoadedTillStart = false;
  bool _hasLoadedTillEnd = false;
  bool _shouldHideAppBar = false;
  GlobalKey<FadingAppBarState> _appBarKey;
  GlobalKey<FadingBottomBarState> _bottomBarKey;

  @override
  void initState() {
    _files = [
      ...widget.config.files
    ]; // Make a copy since we append preceding and succeeding entries to this
    _selectedIndex = widget.config.selectedIndex;
    _preloadEntries();
    super.initState();
  }

  @override
  void dispose() {
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
          _files[_selectedIndex].toString() +
          ". " +
          (_selectedIndex + 1).toString() +
          " / " +
          _files.length.toString() +
          " files .",
    );
    _appBarKey = GlobalKey<FadingAppBarState>();
    _bottomBarKey = GlobalKey<FadingBottomBarState>();
    return Scaffold(
      appBar: FadingAppBar(
        _files[_selectedIndex],
        _onFileRemoved,
        Configuration.instance.getUserID(),
        100,
        widget.config.mode == DetailPageMode.full,
        key: _appBarKey,
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: Stack(
          children: [
            _buildPageView(),
            FadingBottomBar(
              _files[_selectedIndex],
              _onEditFileRequested,
              widget.config.mode == DetailPageMode.minimalistic,
              key: _bottomBarKey,
            ),
          ],
        ),
      ),

      // backgroundColor: Theme.of(context).colorScheme.onPrimary,
    );
  }

  Widget _buildPageView() {
    _logger.info("Building with " + _selectedIndex.toString());
    _pageController = PageController(initialPage: _selectedIndex);
    return PageView.builder(
      itemBuilder: (context, index) {
        final file = _files[index];
        final Widget content = FileWidget(
          file,
          autoPlay: !_hasPageChanged,
          tagPrefix: widget.config.tagPrefix,
          shouldDisableScroll: (value) {
            if (_shouldDisableScroll != value) {
              setState(() {
                _shouldDisableScroll = value;
              });
            }
          },
          playbackCallback: (isPlaying) {
            _shouldHideAppBar = isPlaying;
            Future.delayed(Duration.zero, () {
              _toggleFullScreen();
            });
          },
          backgroundDecoration: const BoxDecoration(color: Colors.black),
        );
        _preloadFiles(index);
        return GestureDetector(
          onTap: () {
            _shouldHideAppBar = !_shouldHideAppBar;
            _toggleFullScreen();
          },
          child: content,
        );
      },
      onPageChanged: (index) {
        setState(() {
          _selectedIndex = index;
          _hasPageChanged = true;
        });
        _preloadEntries();
        _preloadFiles(index);
      },
      physics: _shouldDisableScroll
          ? const NeverScrollableScrollPhysics()
          : const PageScrollPhysics(),
      controller: _pageController,
      itemCount: _files.length,
    );
  }

  void _toggleFullScreen() {
    if (_shouldHideAppBar) {
      _appBarKey.currentState.hide();
      _bottomBarKey.currentState.hide();
    } else {
      _appBarKey.currentState.show();
      _bottomBarKey.currentState.show();
    }
    Future.delayed(Duration.zero, () {
      SystemChrome.setEnabledSystemUIMode(
        //to hide status bar?
        SystemUiMode.manual,
        overlays: _shouldHideAppBar ? [] : SystemUiOverlay.values,
      );
    });
  }

  void _preloadEntries() async {
    if (widget.config.asyncLoader == null) {
      return;
    }
    if (_selectedIndex == 0 && !_hasLoadedTillStart) {
      final result = await widget.config.asyncLoader(
        _files[_selectedIndex].creationTime + 1,
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
        files.addAll(_files);
        _files = files;
        _pageController.jumpToPage(length);
        _selectedIndex = length;
      });
    }
    if (_selectedIndex == _files.length - 1 && !_hasLoadedTillEnd) {
      final result = await widget.config.asyncLoader(
        galleryLoadStartTime,
        _files[_selectedIndex].creationTime - 1,
        limit: kLoadLimit,
      );
      setState(() {
        if (!result.hasMore) {
          _hasLoadedTillEnd = true;
        }
        _files.addAll(result.files);
      });
    }
  }

  void _preloadFiles(int index) {
    if (index > 0) {
      preloadFile(_files[index - 1]);
    }
    if (index < _files.length - 1) {
      preloadFile(_files[index + 1]);
    }
  }

  Future<void> _onFileRemoved(File file) async {
    final totalFiles = _files.length;
    if (totalFiles == 1) {
      // Deleted the only file
      Navigator.of(context).pop(); // Close pageview
      return;
    }
    if (_selectedIndex == totalFiles - 1) {
      // Deleted the last file
      await _pageController.previousPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
      setState(() {
        _files.remove(file);
      });
    } else {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
      setState(() {
        _selectedIndex--;
        _files.remove(file);
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
        "Sorry",
        "We don't support editing photos and albums that you don't own yet",
      );
      return;
    }
    final dialog = createProgressDialog(context, "Please wait...");
    await dialog.show();
    final imageProvider =
        ExtendedFileImageProvider(await getFile(file), cacheRawData: true);
    await precacheImage(imageProvider, context);
    await dialog.hide();
    replacePage(
      context,
      ImageEditorPage(
        imageProvider,
        file,
        widget.config.copyWith(
          files: _files,
          selectedIndex: _selectedIndex,
        ),
      ),
    );
  }
}
