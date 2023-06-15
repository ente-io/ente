import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/map/tile/attribution/map_attribution.dart";
import "package:photos/ui/map/tile/cache.dart";
import "package:url_launcher/url_launcher.dart";
import "package:url_launcher/url_launcher_string.dart";

const String _userAgent = "io.ente.photos";

class OSMTileLayer extends StatelessWidget {
  const OSMTileLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      subdomains: const ['a', 'b', 'c'],
      backgroundColor: Colors.transparent,
      userAgentPackageName: _userAgent,
      tileProvider: CachedNetworkTileProvider(),
    );
  }
}

class OSMFranceTileLayer extends StatelessWidget {
  const OSMFranceTileLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
      fallbackUrl: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      subdomains: const ['a', 'b', 'c'],
      tileProvider: CachedNetworkTileProvider(),
      backgroundColor: Colors.transparent,
      userAgentPackageName: _userAgent,
    );
  }
}

class OSMFranceTileAttributes extends StatelessWidget {
  const OSMFranceTileAttributes({super.key});

  @override
  Widget build(BuildContext context) {
    return MapAttributionWidget(
      alignment: AttributionAlignment.bottomLeft,
      showFlutterMapAttribution: false,
      attributions: [
        TextSourceAttribution(
          S.of(context).openstreetmapContributors,
          textStyle: getEnteTextTheme(context).smallBold,
          onTap: () => launchUrlString('https://openstreetmap.org/copyright'),
        ),
        TextSourceAttribution(
          'HOT Tiles',
          textStyle: getEnteTextTheme(context).smallBold,
          onTap: () => launchUrl(Uri.parse('https://www.hotosm.org/')),
        ),
        TextSourceAttribution(
          S.of(context).hostedAtOsmFrance,
          onTap: () => launchUrl(Uri.parse('https://www.openstreetmap.fr/')),
          textStyle: getEnteTextTheme(context).smallBold,
        ),
      ],
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
      userAgentPackageName: _userAgent,
      tileProvider: CachedNetworkTileProvider(),
      additionalOptions: const {
        "mb_token": String.fromEnvironment("mb_token"),
        "mb_style_id": String.fromEnvironment("mb_style_id"),
        "mb_user": String.fromEnvironment("mb_user"),
      },
    );
  }
}
