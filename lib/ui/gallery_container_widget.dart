import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:myapp/models/photo.dart';
import 'package:myapp/ui/change_notifier_builder.dart';
import 'package:myapp/ui/search_page.dart';
import 'package:myapp/utils/camera_items_filter.dart';
import 'package:myapp/utils/gallery_items_filter.dart';
import 'package:provider/provider.dart';

import '../photo_loader.dart';
import 'gallery.dart';
import 'loading_widget.dart';

class GalleryContainer extends StatelessWidget {
  final GalleryType type;

  static final importantItemsFilter = CameraItemsFilter();
  static final galleryItemsFilter = GalleryItemsFilter();

  const GalleryContainer(
    this.type, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final photoLoader = PhotoLoader.instance;
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
              return ChangeNotifierProvider<PhotoLoader>.value(
                value: photoLoader,
                child: ChangeNotifierBuilder(
                    value: photoLoader,
                    builder: (_, __) {
                      var collatedPhotos = photoLoader.collatedPhotos;
                      return Flexible(child: _getGallery(collatedPhotos));
                    }),
              );
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

  Gallery _getGallery(List<List<Photo>> collatedPhotos) {
    return type == GalleryType.important_photos
        ? Gallery(getCollatedPhotos(collatedPhotos, importantItemsFilter))
        : Gallery(getCollatedPhotos(collatedPhotos, galleryItemsFilter));
  }

  List<List<Photo>> getCollatedPhotos(
      List<List<Photo>> source, GalleryItemsFilter filter) {
    final List<List<Photo>> collatedList = List<List<Photo>>();
    for (List<Photo> unfilteredPhotos in source) {
      final List<Photo> filteredPhotos = List<Photo>();
      for (Photo photo in unfilteredPhotos) {
        if (filter.shouldInclude(photo)) {
          filteredPhotos.add(photo);
        }
      }
      if (filteredPhotos.isNotEmpty) {
        collatedList.add(filteredPhotos);
      }
    }
    return collatedList;
  }
}

enum GalleryType {
  important_photos,
  all_photos,
}
