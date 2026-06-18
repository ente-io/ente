import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/search_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/map/map_screen.dart";
import 'package:photos/ui/notification/toast.dart';

//Used for empty state of location section
class GoToMap extends StatelessWidget {
  const GoToMap({super.key});

  @override
  Widget build(BuildContext context) {
    final mapTileAsset = EnteTheme.isDark(context)
        ? "assets/search_map_tile_dark.png"
        : "assets/search_map_tile_light.png";
    return GestureDetector(
      onTap: () async {
        if (!mapEnabled) {
          try {
            await setMapEnabled(true);
            if (!context.mounted) {
              return;
            }
          } catch (e) {
            if (!context.mounted) {
              return;
            }
            showShortToast(
              context,
              AppLocalizations.of(context).somethingWentWrong,
            );
            return;
          }
        }
        // ignore: unawaited_futures
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MapScreen(
              filesFutureFn: SearchService.instance.getAllFilesForSearch,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 14, 8, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ClipOval(
              child: Image.asset(
                mapTileAsset,
                width: 66.5,
                height: 66.5,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              AppLocalizations.of(context).yourMap,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: getEnteTextTheme(context).mini,
            ),
          ],
        ),
      ),
    );
  }
}
