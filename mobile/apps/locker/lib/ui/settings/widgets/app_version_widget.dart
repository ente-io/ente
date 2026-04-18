import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/utils/dialog_util.dart";
import "package:flutter/material.dart";
import "package:package_info_plus/package_info_plus.dart";

/// Widget that displays the app version centered at the bottom
/// with an easter egg for tapping multiple times
class AppVersionWidget extends StatefulWidget {
  const AppVersionWidget({super.key});

  @override
  State<AppVersionWidget> createState() => _AppVersionWidgetState();
}

class _AppVersionWidgetState extends State<AppVersionWidget> {
  static const _kTapThresholdForInspector = 5;
  static const _kConsecutiveTapTimeWindowInMilliseconds = 2000;
  static const _kDummyDelayDurationInMilliseconds = 1500;

  int? _lastTap;
  int _consecutiveTaps = 0;

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () async {
        final int now = DateTime.now().millisecondsSinceEpoch;
        if (now - (_lastTap ?? now) <
            _kConsecutiveTapTimeWindowInMilliseconds) {
          _consecutiveTaps++;
          if (_consecutiveTaps == _kTapThresholdForInspector) {
            final dialog = createProgressDialog(
              context,
              "Starting network inspector...",
            );
            await dialog.show();
            await Future.delayed(
              const Duration(milliseconds: _kDummyDelayDurationInMilliseconds),
            );
            await dialog.hide();
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
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  "Version ${snapshot.data!}",
                  style: textTheme.mini.copyWith(
                    color: colorScheme.textMuted,
                  ),
                ),
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
