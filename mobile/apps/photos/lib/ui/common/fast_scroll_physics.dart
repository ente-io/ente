import 'package:flutter/material.dart';

class FastScrollPhysics extends PageScrollPhysics {
  final double speedFactor;

  const FastScrollPhysics({this.speedFactor = 2.0, super.parent});

  @override
  FastScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return FastScrollPhysics(
      speedFactor: speedFactor,
      parent: buildParent(ancestor),
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    return super.createBallisticSimulation(position, velocity * speedFactor);
  }
}
