import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/ui/common/gradient_button.dart';
import 'package:photos/ui/tools/app_lock.dart';
import 'package:photos/utils/auth_util.dart';

class LockScreen extends StatefulWidget {
  LockScreen({Key key}) : super(key: key);

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _logger = Logger("LockScreen");

  @override
  void initState() {
    _showLockScreen();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  MediaQuery.of(context).platformBrightness == Brightness.light
                      ? 'assets/loading_photos_background.png'
                      : 'assets/loading_photos_background_dark.png',
                ),
                SizedBox(
                  width: 172,
                  child: GradientButton(
                    linearGradientColors: const [
                      Color(0xFF2CD267),
                      Color(0xFF1DB954),
                    ],
                    onTap: () async {
                      _showLockScreen();
                    },
                    child: Text(
                      'Unlock',
                      style: gradientButtonTextTheme(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLockScreen() async {
    _logger.info("Showing lockscreen");
    try {
      final result = await requestAuthentication(
        "Please authenticate to view your memories",
      );
      if (result) {
        AppLock.of(context).didUnlock();
      }
    } catch (e, s) {
      _logger.severe(e, s);
    }
  }
}
