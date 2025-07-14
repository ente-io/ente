import 'dart:async';

import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/locale.dart';
import 'package:ente_auth/utils/lock_screen_settings.dart';
import 'package:flutter/material.dart';

/// A widget which handles app lifecycle events for showing and hiding a lock screen.
/// This should wrap around a `MyApp` widget (or equivalent).
///
/// [lockScreen] is a [Widget] which should be a screen for handling login logic and
/// calling `AppLock.of(context).didUnlock();` upon a successful login.
///
/// [builder] is a [Function] taking an [Object] as its argument and should return a
/// [Widget]. The [Object] argument is provided by the [lockScreen] calling
/// `AppLock.of(context).didUnlock();` with an argument. [Object] can then be injected
/// in to your `MyApp` widget (or equivalent).
///
/// [enabled] determines wether or not the [lockScreen] should be shown on app launch
/// and subsequent app pauses. This can be changed later on using `AppLock.of(context).enable();`,
/// `AppLock.of(context).disable();` or the convenience method `AppLock.of(context).setEnabled(enabled);`
/// using a bool argument.
///
/// [backgroundLockLatency] determines how much time is allowed to pass when
/// the app is in the background state before the [lockScreen] widget should be
/// shown upon returning. It defaults to instantly.
///

// ignore_for_file: unnecessary_this, library_private_types_in_public_api
class AppLock extends StatefulWidget {
  final Widget Function(Object?) builder;
  final Widget lockScreen;
  final bool enabled;
  final Duration backgroundLockLatency;
  final ThemeData? darkTheme;
  final ThemeData? lightTheme;
  final ThemeMode savedThemeMode;
  final Locale? locale;

  const AppLock({
    super.key,
    required this.builder,
    required this.lockScreen,
    required this.savedThemeMode,
    this.enabled = true,
    this.locale,
    this.backgroundLockLatency = const Duration(seconds: 0),
    this.darkTheme,
    this.lightTheme,
  });

  static _AppLockState? of(BuildContext context) =>
      context.findAncestorStateOfType<_AppLockState>();

  @override
  State<AppLock> createState() => _AppLockState();
}

class _AppLockState extends State<AppLock> with WidgetsBindingObserver {
  static final GlobalKey<NavigatorState> _navigatorKey = GlobalKey();

  late bool _didUnlockForAppLaunch;
  late bool _isLocked;
  late bool _enabled;

  Timer? _backgroundLockLatencyTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    this._didUnlockForAppLaunch = !this.widget.enabled;
    this._isLocked = false;
    this._enabled = this.widget.enabled;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!this._enabled) {
      return;
    }

    if (state == AppLifecycleState.paused &&
        (!this._isLocked && this._didUnlockForAppLaunch)) {
      this._backgroundLockLatencyTimer = Timer(
        Duration(
          milliseconds: LockScreenSettings.instance.getAutoLockTime(),
        ),
        () => this.showLockScreen(),
      );
    }

    if (state == AppLifecycleState.resumed) {
      this._backgroundLockLatencyTimer?.cancel();
    }

    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    this._backgroundLockLatencyTimer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: this.widget.enabled ? this._lockScreen : this.widget.builder(null),
      navigatorKey: _navigatorKey,
      themeMode: widget.savedThemeMode,
      theme: widget.lightTheme,
      darkTheme: widget.darkTheme,
      locale: widget.locale,
      supportedLocales: appSupportedLocales,
      localeListResolutionCallback: localResolutionCallBack,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
      ],
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/lock-screen':
            return PageRouteBuilder(
              pageBuilder: (_, __, ___) => this._lockScreen,
            );
          case '/unlocked':
            return PageRouteBuilder(
              pageBuilder: (_, __, ___) =>
                  this.widget.builder(settings.arguments),
            );
        }
        return PageRouteBuilder(pageBuilder: (_, __, ___) => this._lockScreen);
      },
    );
  }

  Widget get _lockScreen {
    return PopScope(
      child: this.widget.lockScreen,
      canPop: false,
    );
  }

  /// Causes `AppLock` to either pop the [lockScreen] if the app is already running
  /// or instantiates widget returned from the [builder] method if the app is cold
  /// launched.
  ///
  /// [args] is an optional argument which will get passed to the [builder] method
  /// when built. Use this when you want to inject objects created from the
  /// [lockScreen] in to the rest of your app so you can better guarantee that some
  /// objects, services or databases are already instantiated before using them.
  void didUnlock([Object? args]) {
    if (this._didUnlockForAppLaunch) {
      this._didUnlockOnAppPaused();
    } else {
      this._didUnlockOnAppLaunch(args);
    }
  }

  /// Makes sure that [AppLock] shows the [lockScreen] on subsequent app pauses if
  /// [enabled] is true of makes sure it isn't shown on subsequent app pauses if
  /// [enabled] is false.
  ///
  /// This is a convenience method for calling the [enable] or [disable] method based
  /// on [enabled].
  void setEnabled(bool enabled) {
    if (enabled) {
      this.enable();
    } else {
      this.disable();
    }
  }

  /// Makes sure that [AppLock] shows the [lockScreen] on subsequent app pauses.
  void enable() {
    setState(() {
      this._enabled = true;
    });
  }

  /// Makes sure that [AppLock] doesn't show the [lockScreen] on subsequent app pauses.
  void disable() {
    setState(() {
      this._enabled = false;
    });
  }

  /// Manually show the [lockScreen].
  Future<void> showLockScreen() {
    this._isLocked = true;
    return _navigatorKey.currentState!.pushNamed('/lock-screen');
  }

  void _didUnlockOnAppLaunch(Object? args) {
    this._didUnlockForAppLaunch = true;
    _navigatorKey.currentState!
        .pushReplacementNamed('/unlocked', arguments: args);
  }

  void _didUnlockOnAppPaused() {
    this._isLocked = false;
    _navigatorKey.currentState!.pop();
  }
}
