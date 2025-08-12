import "dart:async";
import "dart:io";
import "dart:math";

import 'package:flutter/material.dart';
import "package:flutter/scheduler.dart";
import "package:flutter_animate/flutter_animate.dart";
import 'package:logging/logging.dart';
import "package:photos/core/configuration.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/account/user_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import 'package:photos/ui/tools/app_lock.dart';
import 'package:photos/utils/auth_util.dart';
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/lock_screen_settings.dart";

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final _logger = Logger("LockScreen");
  bool _isShowingLockScreen = false;
  bool _hasPlacedAppInBackground = false;
  bool _hasAuthenticationFailed = false;
  int? lastAuthenticatingTime;
  bool isTimerRunning = false;
  int lockedTimeInSeconds = 0;
  int invalidAttemptCount = 0;
  int remainingTimeInSeconds = 0;
  final _lockscreenSetting = LockScreenSettings.instance;
  late Brightness _platformBrightness;

  @override
  void initState() {
    _logger.info("initiatingState");
    super.initState();
    invalidAttemptCount = _lockscreenSetting.getInvalidAttemptCount();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (isNonMobileIOSDevice()) {
        _logger.info('ignore init for non mobile iOS device');
        return;
      }
      _showLockScreen(source: "postFrameInit");
    });

    _platformBrightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.logout_outlined),
          color: Theme.of(context).iconTheme.color,
          onPressed: () {
            _onLogoutTapped(context);
          },
        ),
      ),
      body: GestureDetector(
        onTap: () {
          isTimerRunning ? null : _showLockScreen(source: "tap");
        },
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              opacity: _platformBrightness == Brightness.light ? 0.08 : 0.12,
              image: const ExactAssetImage(
                'assets/lock_screen_background.png',
              ),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: Column(
              children: [
                const Spacer(),
                SizedBox(
                  height: 120,
                  width: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.grey.shade500.withValues(alpha: 0.2),
                              Colors.grey.shade50.withValues(alpha: 0.1),
                              Colors.grey.shade400.withValues(alpha: 0.2),
                              Colors.grey.shade300.withValues(alpha: 0.4),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colorTheme.backgroundBase,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 75,
                        width: 75,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: isTimerRunning ? 0 : 1,
                            end: isTimerRunning
                                ? _getFractionOfTimeElapsed()
                                : 1,
                          ),
                          duration: const Duration(seconds: 1),
                          builder: (context, value, _) =>
                              CircularProgressIndicator(
                            backgroundColor: colorTheme.fillFaintPressed,
                            value: value,
                            color: colorTheme.primary400,
                            strokeWidth: 1.5,
                          ),
                        ),
                      ),
                      IconButtonWidget(
                        size: 30,
                        icon: Icons.lock,
                        iconButtonType: IconButtonType.primary,
                        iconColor: colorTheme.tabIcon,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                isTimerRunning
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            S.of(context).tooManyIncorrectAttempts,
                            style: textTheme.small,
                          )
                              .animate(
                                delay: const Duration(milliseconds: 2000),
                              )
                              .fadeOut(
                                duration: 400.ms,
                                curve: Curves.easeInOutCirc,
                              ),
                          Text(
                            _formatTime(remainingTimeInSeconds),
                            style: textTheme.small,
                          )
                              .animate(
                                delay: const Duration(milliseconds: 2250),
                              )
                              .fadeIn(
                                duration: 400.ms,
                                curve: Curves.easeInOutCirc,
                              ),
                        ],
                      )
                    : GestureDetector(
                        onTap: () => _showLockScreen(source: "tap"),
                        child: Text(
                          S.of(context).tapToUnlock,
                          style: textTheme.small,
                        ),
                      ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool isNonMobileIOSDevice() {
    if (Platform.isAndroid) {
      return false;
    }
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    return shortestSide > 600 ? true : false;
  }

  void _onLogoutTapped(BuildContext context) {
    showChoiceActionSheet(
      context,
      title: S.of(context).areYouSureYouWantToLogout,
      firstButtonLabel: S.of(context).yesLogout,
      isCritical: true,
      firstButtonOnTap: () async {
        await UserService.instance.logout(context);
        Process.killPid(pid, ProcessSignal.sigkill);
      },
    );
  }

  Future<void> _autoLogoutOnMaxInvalidAttempts() async {
    _logger.info("Auto logout on max invalid attempts");
    Navigator.of(context).popUntil((route) => route.isFirst);
    final dialog = createProgressDialog(context, S.of(context).loggingOut);
    await dialog.show();
    await Configuration.instance.logout();
    await dialog.hide();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    _logger.info(state.toString());
    if (state == AppLifecycleState.resumed && !_isShowingLockScreen) {
      _hasPlacedAppInBackground = false;
      final bool didAuthInLast5Seconds = lastAuthenticatingTime != null &&
          DateTime.now().millisecondsSinceEpoch - lastAuthenticatingTime! <
              5000;

      if (!_hasAuthenticationFailed && !didAuthInLast5Seconds) {
        if (_lockscreenSetting.getlastInvalidAttemptTime() >
                DateTime.now().millisecondsSinceEpoch &&
            !_isShowingLockScreen) {
          final int time = (_lockscreenSetting.getlastInvalidAttemptTime() -
                  DateTime.now().millisecondsSinceEpoch) ~/
              1000;

          Future.delayed(
            Duration.zero,
            () {
              startLockTimer(time);
              _showLockScreen(source: "lifeCycle");
            },
          );
        }
      } else {
        _hasAuthenticationFailed = false;
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (!_isShowingLockScreen) {
        _hasPlacedAppInBackground = true;
        _hasAuthenticationFailed = false;
      }
    }
  }

  @override
  void dispose() {
    _logger.info('disposing');
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> startLockTimer(int timeInSeconds) async {
    if (isTimerRunning) {
      return;
    }

    setState(() {
      isTimerRunning = true;
      remainingTimeInSeconds = timeInSeconds;
    });

    while (remainingTimeInSeconds > 0) {
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        remainingTimeInSeconds--;
      });
    }

    setState(() {
      isTimerRunning = false;
    });
  }

  double _getFractionOfTimeElapsed() {
    final int totalLockedTime =
        lockedTimeInSeconds = pow(2, invalidAttemptCount - 5).toInt() * 30;
    if (remainingTimeInSeconds == 0) return 1;

    return 1 - remainingTimeInSeconds / totalLockedTime;
  }

  String _formatTime(int seconds) {
    final int hours = seconds ~/ 3600;
    final int minutes = (seconds % 3600) ~/ 60;
    final int remainingSeconds = seconds % 60;

    if (hours > 0) {
      return "${hours}h ${minutes}m";
    } else if (minutes > 0) {
      return "${minutes}m ${remainingSeconds}s";
    } else {
      return "${remainingSeconds}s";
    }
  }

  Future<void> _showLockScreen({String source = ''}) async {
    final int currentTimestamp = DateTime.now().millisecondsSinceEpoch;
    _logger.info("Showing lock screen $source $currentTimestamp");
    try {
      if (currentTimestamp < _lockscreenSetting.getlastInvalidAttemptTime() &&
          !_isShowingLockScreen) {
        final int remainingTime =
            (_lockscreenSetting.getlastInvalidAttemptTime() -
                    currentTimestamp) ~/
                1000;

        await startLockTimer(remainingTime);
      }
      _isShowingLockScreen = true;
      final result = isTimerRunning
          ? false
          : await requestAuthentication(
              context,
              context.l10n.authToViewYourMemories,
              isOpeningApp: true,
            );
      _logger.info("LockScreen Result $result");
      _isShowingLockScreen = false;
      if (result) {
        lastAuthenticatingTime = DateTime.now().millisecondsSinceEpoch;
        AppLock.of(context)!.didUnlock();
        await _lockscreenSetting.setInvalidAttemptCount(0);
        setState(() {
          lockedTimeInSeconds = 15;
          isTimerRunning = false;
        });
        await localSettings.setOnGuestView(false);
      } else {
        if (!_hasPlacedAppInBackground) {
          if (_lockscreenSetting.getInvalidAttemptCount() > 4 &&
              invalidAttemptCount !=
                  _lockscreenSetting.getInvalidAttemptCount()) {
            invalidAttemptCount = _lockscreenSetting.getInvalidAttemptCount();

            if (invalidAttemptCount > 9) {
              await _autoLogoutOnMaxInvalidAttempts();
              return;
            }

            lockedTimeInSeconds = pow(2, invalidAttemptCount - 5).toInt() * 30;
            await _lockscreenSetting.setLastInvalidAttemptTime(
              DateTime.now().millisecondsSinceEpoch +
                  lockedTimeInSeconds * 1000,
            );
            await startLockTimer(lockedTimeInSeconds);
          }
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
