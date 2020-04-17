import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logger/logger.dart';
import 'package:myapp/models/photo.dart';
import 'package:myapp/ui/change_notifier_builder.dart';
import 'package:myapp/ui/search_page.dart';
import 'package:myapp/utils/important_items_filter.dart';
import 'package:myapp/utils/gallery_items_filter.dart';
import 'package:provider/provider.dart';

import '../photo_loader.dart';
import 'gallery.dart';
import 'loading_widget.dart';

// TODO: Remove redundant layer
class GalleryContainer extends StatefulWidget {
  final GalleryType type;
  final Function(Set<Photo>) photoSelectionChangeCallback;

  static final importantItemsFilter = ImportantItemsFilter();
  static final galleryItemsFilter = GalleryItemsFilter();

  const GalleryContainer(
    this.type, {
    Key key,
    this.photoSelectionChangeCallback,
  }) : super(key: key);

  @override
  _GalleryContainerState createState() => _GalleryContainerState();
}

class _GalleryContainerState extends State<GalleryContainer> {
  PhotoLoader get photoLoader => Provider.of<PhotoLoader>(context);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Hero(
            child: TextField(
              readOnly: true,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (BuildContext context) {
                      return SearchPage();
                    },
                  ),
                );
              },
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Search "Paris"',
                contentPadding: const EdgeInsets.all(12.0),
              ),
            ),
            tag: "search"),
        FutureBuilder<bool>(
          future: photoLoader.loadPhotos(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ChangeNotifierBuilder(
                  value: photoLoader,
                  builder: (_, __) {
                    return Flexible(child: _getGallery(photoLoader.photos));
                  });
            } else if (snapshot.hasError) {
              return Text("Error!");
            } else {
              return loadWidget;
            }
          },
        )
      ],
    );
  }

  Gallery _getGallery(List<Photo> photos) {
    return widget.type == GalleryType.important_photos
        ? Gallery(
            getFilteredPhotos(photos, GalleryContainer.importantItemsFilter),
            photoSelectionChangeCallback: widget.photoSelectionChangeCallback,
          )
        : Gallery(
            getFilteredPhotos(photos, GalleryContainer.galleryItemsFilter),
            photoSelectionChangeCallback: widget.photoSelectionChangeCallback,
          );
  }

  List<Photo> getFilteredPhotos(
      List<Photo> unfilteredPhotos, GalleryItemsFilter filter) {
    final List<Photo> filteredPhotos = List<Photo>();
    for (Photo photo in unfilteredPhotos) {
      if (filter.shouldInclude(photo)) {
        filteredPhotos.add(photo);
      }
    }
    return filteredPhotos;
  }
}

enum GalleryType {
  important_photos,
  all_photos,
}
