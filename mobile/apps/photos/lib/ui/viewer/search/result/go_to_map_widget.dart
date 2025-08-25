import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/services/search_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/map/enable_map.dart";
import "package:photos/ui/map/map_screen.dart";

//Used for empty state of location section
class GoToMap extends StatelessWidget {
  const GoToMap({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final bool result = await requestForMapEnable(context);
        if (result) {
          // ignore: unawaited_futures
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MapScreen(
                filesFutureFn: SearchService.instance.getAllFilesForSearch,
              ),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 14, 8, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Transform.scale(
              scale: 1.2,
              child: Image.asset(
                "assets/map_world.png",
                width: 64,
                height: 64,
              ),
            ),
            const SizedBox(
              height: 11.5,
            ),
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
