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
  final LatLng center;
  final double minZoom;
  final double maxZoom;
  final double initialZoom;
  final int debounceDuration;

  const MapView({
    Key? key,
    required this.updateVisibleImages,
    required this.imageMarkers,
    required this.controller,
    required this.center,
    required this.minZoom,
    required this.maxZoom,
    required this.initialZoom,
    required this.debounceDuration,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  Timer? _debounceTimer;
  bool _isDebouncing = false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: widget.controller,
          options: MapOptions(
            minZoom: widget.minZoom,
            maxZoom: widget.maxZoom,
            onPositionChanged: (position, hasGesture) {
              if (position.bounds != null) {
                if (!_isDebouncing) {
                  _isDebouncing = true;
                  _debounceTimer?.cancel();
                  _debounceTimer = Timer(
                      Duration(milliseconds: widget.debounceDuration), () {
                    widget.updateVisibleImages(position.bounds!);
                    _isDebouncing = false;
                  });
                }
              }
            },
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
                padding: EdgeInsets.all(1),
              ),
              markers: widget.imageMarkers.asMap().entries.map((marker) {
                final imageMarker = marker.value;
                return mapMarker(imageMarker, marker.key.toString());
              }).toList(),
              polygonOptions: const PolygonOptions(
                borderColor: Colors.green,
                color: Colors.transparent,
                borderStrokeWidth: 1,
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
