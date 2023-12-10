import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:photos/ui/map/map_button.dart";
import "package:photos/ui/map/tile/layers.dart";

class AddLocationDataWidget extends StatefulWidget {
  const AddLocationDataWidget({super.key});

  @override
  State<AddLocationDataWidget> createState() => _AddLocationDataWidgetState();
}

class _AddLocationDataWidgetState extends State<AddLocationDataWidget> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _mapController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            zoom: 3,
            maxZoom: 18.0,
            minZoom: 2.8,
            onTap: (tapPosition, latlng) {
              print(latlng);
            },
          ),
          children: const [
            OSMFranceTileLayer(),
          ],
        ),
        Positioned(
          // bottom: widget.bottomSheetDraggableAreaHeight + 10,
          bottom: 30,

          right: 10,
          child: Column(
            children: [
              MapButton(
                icon: Icons.add,
                onPressed: () {
                  _mapController.move(
                    _mapController.center,
                    _mapController.zoom + 1,
                  );
                },
                heroTag: 'zoom-in',
              ),
              MapButton(
                icon: Icons.remove,
                onPressed: () {
                  _mapController.move(
                    _mapController.center,
                    _mapController.zoom - 1,
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
