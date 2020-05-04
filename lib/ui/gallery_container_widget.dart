import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/models/photo.dart';
import 'package:photos/photo_loader.dart';
import 'package:photos/ui/gallery.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/ui/search_page.dart';
import 'package:photos/utils/important_items_filter.dart';
import 'package:provider/provider.dart';

// TODO: Remove redundant layer
class GalleryContainer extends StatefulWidget {
  final Set<Photo> selectedPhotos;
  final Function(Set<Photo>) photoSelectionChangeCallback;

  const GalleryContainer(
    this.selectedPhotos,
    this.photoSelectionChangeCallback, {
    Key key,
  }) : super(key: key);

  @override
  _GalleryContainerState createState() => _GalleryContainerState();
}

class _GalleryContainerState extends State<GalleryContainer> {
  static final importantItemsFilter = ImportantItemsFilter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[_buildHero(context), _buildGallery()],
    );
  }

  FutureBuilder<bool> _buildGallery() {
    return FutureBuilder<bool>(
      future: PhotoLoader.instance.loadPhotos(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Flexible(
            child: Gallery(
              getFilteredPhotos(PhotoLoader.instance.photos),
              widget.selectedPhotos,
              photoSelectionChangeCallback: widget.photoSelectionChangeCallback,
            ),
          );
        } else if (snapshot.hasError) {
          return Text("Error!");
        } else {
          return loadWidget;
        }
      },
    );
  }

  Hero _buildHero(BuildContext context) {
    return Hero(
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
        tag: "search");
  }

  List<Photo> getFilteredPhotos(List<Photo> unfilteredPhotos) {
    final List<Photo> filteredPhotos = List<Photo>();
    for (Photo photo in unfilteredPhotos) {
      if (importantItemsFilter.shouldInclude(photo)) {
        filteredPhotos.add(photo);
      }
    }
    return filteredPhotos;
  }
}
