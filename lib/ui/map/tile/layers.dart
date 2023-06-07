import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";

class OSMTileLayer extends StatelessWidget {
  const OSMTileLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      subdomains: const ['a', 'b', 'c'],
      backgroundColor: Colors.transparent,
    );
  }
}

class OSMFranceTileLayer extends StatelessWidget {
  const OSMFranceTileLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
      subdomains: const ['a', 'b', 'c'],
      backgroundColor: Colors.transparent,
    );
  }
}

class MapBoxTilesLayer extends StatelessWidget {
  const MapBoxTilesLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      urlTemplate:
          "https://api.mapbox.com/styles/v1/{mb_user}/{mb_style_id}/tiles/{z}/{x}/{y}?access_token={mb_token}",
      fallbackUrl: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
      subdomains: const ['a', 'b', 'c'],
      backgroundColor: Colors.transparent,
      additionalOptions: const {
        "mb_token": String.fromEnvironment("mb_token"),
        "mb_style_id": String.fromEnvironment("mb_style_id"),
        "mb_user": String.fromEnvironment("mb_user"),
      },
    );
  }
}
