import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:myapp/core/lru_map.dart';
import 'package:myapp/models/photo.dart';
import 'package:myapp/ui/extents_page_view.dart';
import 'package:myapp/ui/zoomable_image.dart';
import 'package:myapp/utils/share_util.dart';

class DetailPage extends StatefulWidget {
  final List<Photo> photos;
  final int selectedIndex;

  DetailPage(this.photos, this.selectedIndex, {key}) : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  bool _shouldDisableScroll = false;
  List<Photo> _photos;
  int _selectedIndex = 0;
  PageController _pageController;
  LRUMap<int, ZoomableImage> _cachedImages;

  @override
  void initState() {
    _photos = widget.photos;
    _selectedIndex = widget.selectedIndex;
    _cachedImages = LRUMap<int, ZoomableImage>(5);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Logger().i("Opening " +
        _photos[_selectedIndex].title +
        ", " +
        _selectedIndex.toString() +
        " / " +
        _photos.length.toString() +
        " photos .");
    return Scaffold(
      appBar: _buildAppBar(),
      body: Center(
        child: Container(
          child: _buildPageView(),
        ),
      ),
    );
  }

  Widget _buildPageView() {
    _pageController = PageController(initialPage: _selectedIndex);
    return ExtentsPageView.extents(
      itemBuilder: (context, index) {
        final photo = _photos[index];
        if (_cachedImages.get(photo.generatedId) != null) {
          return _cachedImages.get(photo.generatedId);
        }
        final image = ZoomableImage(
          photo,
          shouldDisableScroll: (value) {
            setState(() {
              _shouldDisableScroll = value;
            });
          },
        );
        _cachedImages.put(photo.generatedId, image);
        return image;
      },
      extents: 1,
      onPageChanged: (int index) {
        Logger().i("onPageChanged to " + index.toString());
        _selectedIndex = index;
      },
      physics: _shouldDisableScroll
          ? NeverScrollableScrollPhysics()
          : PageScrollPhysics(),
      controller: _pageController,
      itemCount: _photos.length,
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.share),
          onPressed: () async {
            share(_photos[_selectedIndex]);
          },
        )
      ],
    );
  }
}
