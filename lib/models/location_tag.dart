import "package:photos/models/location.dart";

class LocationTag {
  String name;
  int radius;
  Location centerPoint;

  LocationTag({
    required this.name,
    required this.radius,
    required this.centerPoint,
  });
}
