import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import "package:photos/generated/l10n.dart";

class AppVersionWidget extends StatefulWidget {
  const AppVersionWidget({
    super.key,
  });

  @override
  State<AppVersionWidget> createState() => _AppVersionWidgetState();
}

class _AppVersionWidgetState extends State<AppVersionWidget> {
  static const kTapThresholdForInspector = 5;
  static const kConsecutiveTapTimeWindowInMilliseconds = 2000;

  int? _lastTap;
  int _consecutiveTaps = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () async {
        final int now = DateTime.now().millisecondsSinceEpoch;
        if (now - (_lastTap ?? now) < kConsecutiveTapTimeWindowInMilliseconds) {
          _consecutiveTaps++;
          if (_consecutiveTaps == kTapThresholdForInspector) {
            // Do nothing
          }
        } else {
          _consecutiveTaps = 1;
        }
        _lastTap = now;
      },
      child: FutureBuilder<String>(
        future: _getAppVersion(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                AppLocalizations.of(context)
                    .appVersion(versionValue: snapshot.data!),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Future<String> _getAppVersion() async {
    final pkgInfo = await PackageInfo.fromPlatform();
    return pkgInfo.version;
  }
}
