import 'dart:io';

import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/ui/common/gradient_button.dart';
import 'package:ente_auth/ui/tools/app_lock.dart';
import 'package:ente_auth/utils/auth_util.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with WidgetsBindingObserver {
  final _logger = Logger("LockScreen");
  bool _isShowingLockScreen = false;
  bool _hasPlacedAppInBackground = false;
  bool _hasAuthenticationFailed = false;
  int? lastAuthenticatingTime;

  @override
  void initState() {
    _logger.info("initiatingState");
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (isNonMobileIOSDevice()) {
        _logger.info('ignore init for non mobile iOS device');
        return;
      }
      _showLockScreen(source: "postFrameInit");
    });
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
                Opacity(
                  opacity: 0.2,
                  child: Image.asset('assets/loading_photos_background.png'),
                ),
                SizedBox(
                  width: 180,
                  child: GradientButton(
                    text: context.l10n.unlock,
                    iconData: Icons.lock_open_outlined,
                    onTap: () async {
                      // ignore: unawaited_futures
                      _showLockScreen(source: "tapUnlock");
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool isNonMobileIOSDevice() {
    if (Platform.isAndroid) {
      return false;
    }
    var shortestSide = MediaQuery.of(context).size.shortestSide;
    return shortestSide > 600 ? true : false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _logger.info(state.toString());
    if (state == AppLifecycleState.resumed && !_isShowingLockScreen) {
      // This is triggered either when the lock screen is dismissed or when
      // the app is brought to foreground
      _hasPlacedAppInBackground = false;
      final bool didAuthInLast5Seconds = lastAuthenticatingTime != null &&
          DateTime.now().millisecondsSinceEpoch - lastAuthenticatingTime! <
              5000;
      if (!_hasAuthenticationFailed && !didAuthInLast5Seconds) {
        // Show the lock screen again only if the app is resuming from the
        // background, and not when the lock screen was explicitly dismissed
        Future.delayed(
          Duration.zero,
          () => _showLockScreen(source: "lifeCycle"),
        );
      } else {
        _hasAuthenticationFailed = false; // Reset failure state
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // This is triggered either when the lock screen pops up or when
      // the app is pushed to background
      if (!_isShowingLockScreen) {
        _hasPlacedAppInBackground = true;
        _hasAuthenticationFailed = false; // reset failure state
      }
    }
  }

  @override
  void dispose() {
    _logger.info('disposing');
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _showLockScreen({String source = ''}) async {
    final int id = DateTime.now().millisecondsSinceEpoch;
    _logger.info("Showing lock screen $source $id");
    try {
      _isShowingLockScreen = true;
      final result = await requestAuthentication(
        context,
        context.l10n.authToViewSecrets,
      );
      _logger.finest("LockScreen Result $result $id");
      _isShowingLockScreen = false;
      if (result) {
        lastAuthenticatingTime = DateTime.now().millisecondsSinceEpoch;
        AppLock.of(context)!.didUnlock();
      } else {
        if (!_hasPlacedAppInBackground) {
          // Treat this as a failure only if user did not explicitly
          // put the app in background
          _hasAuthenticationFailed = true;
          _logger.info("Authentication failed");
        }
      }
    } catch (e, s) {
      _isShowingLockScreen = false;
      _logger.severe(e, s);
    }
  }
}
