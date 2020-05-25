import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:like_button/like_button.dart';
import 'package:photos/core/cache/lru_map.dart';
import 'package:photos/favorite_photos_repository.dart';
import 'package:photos/models/photo.dart';
import 'package:photos/ui/extents_page_view.dart';
import 'package:photos/ui/zoomable_image.dart';
import 'package:photos/utils/share_util.dart';
import 'package:logging/logging.dart';

class DetailPage extends StatefulWidget {
  final List<Photo> photos;
  final int selectedIndex;

  DetailPage(this.photos, this.selectedIndex, {key}) : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final _logger = Logger("DetailPageState");
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
    _logger.info("Opening " +
        _photos[_selectedIndex].toString() +
        ". " +
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
        setState(() {
          _selectedIndex = index;
        });
      },
      physics: _shouldDisableScroll
          ? NeverScrollableScrollPhysics()
          : PageScrollPhysics(),
      controller: _pageController,
      itemCount: _photos.length,
    );
  }

  AppBar _buildAppBar() {
    final actions = List<Widget>();
    if (widget.photos[_selectedIndex].localId != null) {
      actions.add(_getFavoriteButton());
    }
    actions.add(IconButton(
      icon: Icon(Icons.share),
      onPressed: () async {
        share(_photos[_selectedIndex]);
      },
    ));
    return AppBar(
      actions: actions,
    );
  }

  Widget _getFavoriteButton() {
    final photo = _photos[_selectedIndex];
    return LikeButton(
      isLiked: FavoritePhotosRepository.instance.isLiked(photo),
      onTap: (oldValue) {
        return FavoritePhotosRepository.instance.setLiked(photo, !oldValue);
      },
    );
  }
}
