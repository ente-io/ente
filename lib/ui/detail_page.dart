import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/ui/fading_app_bar.dart';
import 'package:photos/ui/fading_bottom_bar.dart';
import 'package:photos/ui/gallery.dart';
import 'package:photos/ui/image_editor_page.dart';
import 'package:photos/ui/video_widget.dart';
import 'package:photos/ui/zoomable_image.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/file_util.dart';
import 'package:photos/utils/navigation_util.dart';

class DetailPageConfiguration {
  final List<File> files;
  final GalleryLoader asyncLoader;
  final int selectedIndex;
  final String tagPrefix;

  DetailPageConfiguration(
    this.files,
    this.asyncLoader,
    this.selectedIndex,
    this.tagPrefix,
  );

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

  DetailPage(this.config, {key}) : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
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
    _files = widget.config.files;
    _selectedIndex = widget.config.selectedIndex;
    _preloadEntries();
    super.initState();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.info("Opening " +
        _files[_selectedIndex].toString() +
        ". " +
        (_selectedIndex + 1).toString() +
        " / " +
        _files.length.toString() +
        " files .");
    _appBarKey = GlobalKey<FadingAppBarState>();
    _bottomBarKey = GlobalKey<FadingBottomBarState>();
    return Scaffold(
      appBar: FadingAppBar(
        _files[_selectedIndex],
        _onFileDeleted,
        100,
        key: _appBarKey,
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: Container(
          child: Stack(
            children: [
              _buildPageView(),
              FadingBottomBar(
                _files[_selectedIndex],
                _onEditFileRequested,
                key: _bottomBarKey,
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.black,
    );
  }

  Widget _buildPageView() {
    _logger.info("Building with " + _selectedIndex.toString());
    _pageController = PageController(initialPage: _selectedIndex);
    return PageView.builder(
      itemBuilder: (context, index) {
        final file = _files[index];
        Widget content;
        if (file.fileType == FileType.image) {
          content = ZoomableImage(
            file,
            shouldDisableScroll: (value) {
              setState(() {
                _shouldDisableScroll = value;
              });
            },
            tagPrefix: widget.config.tagPrefix,
          );
        } else if (file.fileType == FileType.video) {
          content = VideoWidget(
            file,
            autoPlay: !_hasPageChanged, // Autoplay if it was opened directly
            tagPrefix: widget.config.tagPrefix,
            playbackCallback: (isPlaying) {
              _shouldHideAppBar = isPlaying;
              _toggleFullScreen();
            },
          );
        } else {
          content = Icon(Icons.error);
        }
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
          ? NeverScrollableScrollPhysics()
          : PageScrollPhysics(),
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
      SystemChrome.setEnabledSystemUIOverlays(
        _shouldHideAppBar ? [] : SystemUiOverlay.values,
      );
    });
  }

  void _preloadEntries() async {
    if (_selectedIndex == 0 && !_hasLoadedTillStart) {
      final result = await widget.config.asyncLoader(
          _files[_selectedIndex].creationTime + 1,
          DateTime.now().microsecondsSinceEpoch,
          limit: kLoadLimit,
          asc: true);
      setState(() {
        final files = result.files.reversed.toList();
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
          kGalleryLoadStartTime, _files[_selectedIndex].creationTime - 1,
          limit: kLoadLimit);
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

  Future<void> _onFileDeleted(File file) async {
    final totalFiles = _files.length;
    if (totalFiles == 1) {
      // Deleted the only file
      Navigator.of(context, rootNavigator: true).pop(); // Close pageview
      Navigator.of(context, rootNavigator: true).pop(); // Close gallery
      return;
    }
    if (_selectedIndex == totalFiles - 1) {
      // Deleted the last file
      await _pageController.previousPage(
          duration: Duration(milliseconds: 200), curve: Curves.easeInOut);
      setState(() {
        _files.remove(file);
      });
    } else {
      await _pageController.nextPage(
          duration: Duration(milliseconds: 200), curve: Curves.easeInOut);
      setState(() {
        _selectedIndex--;
        _files.remove(file);
      });
    }
    Navigator.of(context, rootNavigator: true).pop(); // Close dialog
  }

  Future<void> _onEditFileRequested(File file) async {
    final dialog = createProgressDialog(context, "please wait...");
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
