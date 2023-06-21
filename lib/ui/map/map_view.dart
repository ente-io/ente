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
import "package:photos/ui/map/tile/layers.dart";

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
  late List<Marker> _markers;

  @override
  void initState() {
    super.initState();
    _markers = _buildMakers();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    super.dispose();
  }

  void onChange(LatLngBounds bounds) {
    if (!_isDebouncing) {
      _isDebouncing = true;
      _debounceTimer?.cancel();
      _debounceTimer = Timer(
        Duration(milliseconds: widget.debounceDuration),
        () {
          widget.updateVisibleImages(bounds);
          _isDebouncing = false;
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: widget.controller,
          options: MapOptions(
            center: widget.center,
            minZoom: widget.minZoom,
            maxZoom: widget.maxZoom,
            enableMultiFingerGestureRace: true,
            zoom: widget.initialZoom,
            maxBounds: LatLngBounds(
              LatLng(-90, -180),
              LatLng(90, 180),
            ),
            onPositionChanged: (position, hasGesture) {
              if (position.bounds != null) {
                onChange(position.bounds!);
              }
            },
          ),
          nonRotatedChildren: const [
            Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: OSMFranceTileAttributes(),
            )
          ],
          children: [
            const OSMFranceTileLayer(),
            MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                anchor: AnchorPos.align(AnchorAlign.top),
                maxClusterRadius: 100,
                showPolygon: false,
                size: const Size(75, 75),
                fitBoundsOptions: const FitBoundsOptions(
                  padding: EdgeInsets.all(1),
                ),
                markers: _markers,
                onClusterTap: (_) {
                  if (!_isDebouncing) {
                    onChange(widget.controller.bounds!);
                  }
                },
                builder: (context, List<Marker> markers) {
                  final index = int.parse(
                    markers.first.key
                        .toString()
                        .replaceAll(RegExp(r'[^0-9]'), ''),
                  );
                  final String clusterKey =
                      'map-badge-$index-len-${markers.length}';

                  return Stack(
                    key: ValueKey(clusterKey),
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
            )
          ],
        ),
        Positioned(
          top: 4,
          left: 10,
          child: SafeArea(
            child: MapButton(
              icon: Icons.arrow_back,
              onPressed: () {
                Navigator.pop(context);
              },
              heroTag: 'back',
            ),
          ),
        ),
        Positioned(
          bottom: 30,
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

  List<Marker> _buildMakers() {
    return List<Marker>.generate(widget.imageMarkers.length, (index) {
      final imageMarker = widget.imageMarkers[index];
      return mapMarker(imageMarker, index.toString());
    });
  }
}
