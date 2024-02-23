import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/services/search_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/map/enable_map.dart";
import "package:photos/ui/map/map_screen.dart";

class GoToMapWidget extends StatelessWidget {
  const GoToMapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final textScaleFactor = MediaQuery.textScaleFactorOf(context);
    late final double width;
    if (textScaleFactor <= 1.0) {
      width = 85.0;
    } else {
      width = 85.0 + ((textScaleFactor - 1.0) * 64);
    }

    return GestureDetector(
      onTap: () async {
        final bool result = await requestForMapEnable(context);
        if (result) {
          // ignore: unawaited_futures
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MapScreen(
                filesFutureFn: SearchService.instance.getAllFiles,
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
              S.of(context).yourMap,
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
