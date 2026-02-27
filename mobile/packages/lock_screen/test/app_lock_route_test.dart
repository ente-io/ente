import 'package:ente_lock_screen/ui/app_lock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildAppLockRoute uses zero transition duration', () {
    final route = buildAppLockRoute(
      const RouteSettings(name: '/lock-screen'),
      const SizedBox.shrink(),
    );

    expect(route.transitionDuration, Duration.zero);
    expect(route.reverseTransitionDuration, Duration.zero);
  });
}
