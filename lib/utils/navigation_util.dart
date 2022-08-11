import 'dart:io';

import 'package:flutter/material.dart';

Future<T> routeToPage<T extends Object>(
  BuildContext context,
  Widget page, {
  bool forceCustomPageRoute = false,
}) {
  if (Platform.isAndroid || forceCustomPageRoute) {
    return Navigator.of(context).push(
      _buildPageRoute(page),
    );
  } else {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return page;
        },
      ),
    );
  }
}

void replacePage(BuildContext context, Widget page) {
  Navigator.of(context).pushReplacement(
    _buildPageRoute(page),
  );
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

class TransparentRoute extends PageRoute<void> {
  TransparentRoute({
    @required this.builder,
    RouteSettings settings,
  })  : assert(builder != null),
        super(settings: settings, fullscreenDialog: false);

  final WidgetBuilder builder;

  @override
  bool get opaque => false;

  @override
  Color get barrierColor => null;

  @override
  String get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 350);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final result = builder(context);
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(animation),
      child: Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        child: result,
      ),
    );
  }
}
