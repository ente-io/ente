import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart";
import "package:latlong2/latlong.dart";
import "package:photos/ui/map/image_marker.dart";
import "package:photos/ui/map/map_button.dart";
import 'package:photos/ui/map/map_gallery_tile.dart';
import 'package:photos/ui/map/map_gallery_tile_badge.dart';

import "package:photos/ui/map/map_marker.dart";

class MapView extends StatefulWidget {
  final List<ImageMarker> imageMarkers;
  final Function updateVisibleImages;
  final MapController controller;

  const MapView({
    Key? key,
    required this.updateVisibleImages,
    required this.imageMarkers,
    required this.controller,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  Timer? _debounceTimer;
  LatLng center = LatLng(10.732951, 78.405635);
  bool _isDebouncing = false;

  void _onPositionChanged(position, hasGesture) {
    if (position.bounds != null) {
      if (!_isDebouncing) {
        _isDebouncing = true;
        _debounceTimer?.cancel(); // Cancel previous debounce timer
        _debounceTimer = Timer(const Duration(milliseconds: 200), () {
          widget.updateVisibleImages(position.bounds!);
          _isDebouncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: widget.controller,
          options: MapOptions(
            center: center,
            zoom: 5,
            minZoom: 5,
            maxZoom: 16.5,
            onPositionChanged: _onPositionChanged,
            plugins: [
              MarkerClusterPlugin(),
            ],
          ),
          layers: [
            TileLayerOptions(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: ['a', 'b', 'c'],
            ),
            MarkerClusterLayerOptions(
              maxClusterRadius: 100,
              showPolygon: true,
              size: const Size(75, 75),
              fitBoundsOptions: const FitBoundsOptions(
                padding: EdgeInsets.all(50),
              ),
              markers: widget.imageMarkers.asMap().entries.map((marker) {
                final imageMarker = marker.value;
                return mapMarker(imageMarker, marker.key.toString());
              }).toList(),
              polygonOptions: const PolygonOptions(
                borderColor: Colors.redAccent,
                color: Colors.black12,
                borderStrokeWidth: 3,
              ),
              builder: (context, markers) {
                final index = int.parse(
                  markers.first.key
                      .toString()
                      .replaceAll(RegExp(r'[^0-9]'), ''),
                );
                return Stack(
                  children: [
                    MapGalleryTile(
                      key: Key(markers.first.key.toString()),
                      imageMarker: widget.imageMarkers[index],
                    ),
                    MapGalleryTileBadge(size: markers.length)
                  ],
                );
              },
            ),
          ],
        ),
        Positioned(
          bottom: 10,
          left: 10,
          child: MapButton(
            icon: Icons.my_location,
            onPressed: () {
              widget.controller.move(
                center,
                widget.controller.zoom,
              );
            },
            heroTag: 'location',
          ),
        ),
        Positioned(
          top: 10,
          left: 10,
          child: MapButton(
            icon: Icons.arrow_back,
            onPressed: () {
              Navigator.pop(context);
            },
            heroTag: 'back',
          ),
        ),
        Positioned(
          bottom: 10,
          right: 10,
          child: Column(
            children: [
              MapButton(
                icon: Icons.add,
                onPressed: () {
                  widget.controller.move(
                    widget.controller.center,
                    widget.controller.zoom + 1,
                  );
                },
                heroTag: 'zoom-in',
              ),
              MapButton(
                icon: Icons.remove,
                onPressed: () {
                  widget.controller.move(
                    widget.controller.center,
                    widget.controller.zoom - 1,
                  );
                },
                heroTag: 'zoom-out',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
