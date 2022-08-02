import 'package:flutter/widgets.dart';

class LocationResultsWidget extends StatelessWidget {
  final dynamic locationAndFiles;
  const LocationResultsWidget(this.locationAndFiles, {Key key})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Location',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    locationAndFiles['place'],
                    style: const TextStyle(fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text('1 memory')
                ],
              ),
            ),
            SizedBox(
              height: 50,
              width: 50,
              // child: ThumbnailWidget(),
              child: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
      onTap: () {
        // _routeToDetailPage(locationAndFiles, context);
      },
    );
  }
}
