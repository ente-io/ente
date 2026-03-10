import 'dart:async';
import 'dart:io';

import 'package:ente_pure_utils/ente_pure_utils.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

/// Routes pages onto the inner Photos app navigator.
///
/// The Photos app is currently wrapped by an outer `AppLock` `MaterialApp`
/// that owns the lock-screen navigator, while `EnteApp` creates the real app
/// `MaterialApp` inside it. External entry points such as widgets and
/// notifications can arrive while the app is backgrounded and locked. In those
/// cases, a random `BuildContext` may resolve to the outer lock navigator,
/// causing the destination page to be pushed on the wrong stack.
///
/// Use this service for navigation that must land on the actual app stack even
/// when the app is resuming from background, opening from a widget, or handling
/// a notification/deep link without a reliable inner-app `BuildContext`.
///
/// Do not use this service for ordinary in-app navigation where a local page
/// context is already available and intentionally scoped to the current nested
/// navigator tree.
class AppNavigationService {
  AppNavigationService._privateConstructor();

  static final AppNavigationService instance =
      AppNavigationService._privateConstructor();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final Logger _logger = Logger("AppNavigationService");

  NavigatorState? get navigator => navigatorKey.currentState;

  /// Pushes a page onto the inner app navigator.
  ///
  /// This waits briefly for the inner `MaterialApp` to finish rebuilding during
  /// resume/unlock so callers from widget and notification handlers do not have
  /// to coordinate navigator readiness themselves.
  Future<T?> pushPage<T extends Object>(
    Widget page, {
    bool forceCustomPageRoute = false,
  }) async {
    final pageName = page.runtimeType.toString();
    _logger.info(
      "Inner navigator push requested: page=$pageName forceCustomPageRoute=$forceCustomPageRoute",
    );
    final navigator = await _waitForNavigator();
    if (navigator == null) {
      _logger
          .warning("Skipping navigation because app navigator is unavailable");
      return null;
    }

    _logger.info("Inner navigator ready; pushing page=$pageName");
    if (Platform.isAndroid || forceCustomPageRoute) {
      return navigator.push(
        _buildPageRoute(page),
      );
    }

    return navigator.push(
      SwipeableRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return page;
        },
      ),
    );
  }

  /// The inner navigator can be temporarily unavailable while Flutter is
  /// restoring the app tree after resume or unlock. Poll a small number of
  /// frames so external launch handlers can still navigate deterministically.
  Future<NavigatorState?> _waitForNavigator() async {
    for (var attempt = 0; attempt < 60; attempt++) {
      final currentNavigator = navigator;
      if (currentNavigator != null) {
        if (attempt > 0) {
          _logger.info(
            "Inner navigator became available after ${attempt + 1} checks",
          );
        }
        return currentNavigator;
      }
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
    _logger.warning("Inner navigator did not become ready in time");
    return null;
  }
}

PageRouteBuilder<T> _buildPageRoute<T extends Object>(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
    ) {
      return page;
    },
    transitionsBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) {
      return Align(
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 200),
    opaque: false,
  );
}
