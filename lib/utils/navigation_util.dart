import 'package:flutter/material.dart';

Future<T> routeToPage<T extends Object>(BuildContext context, Widget page) {
  return Navigator.of(context).push(
    _buildPageRoute(page),
  );
}

void replacePage(BuildContext context, Widget page) {
  Navigator.of(context).pushReplacement(
    _buildPageRoute(page),
  );
}

PageRouteBuilder<T> _buildPageRoute<T extends Object>(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (BuildContext context, Animation<double> animation,
        Animation<double> secondaryAnimation) {
      return page;
    },
    transitionsBuilder: (BuildContext context, Animation<double> animation,
        Animation<double> secondaryAnimation, Widget child) {
      return Align(
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
    transitionDuration: Duration(milliseconds: 200),
    opaque: false,
  );
}
