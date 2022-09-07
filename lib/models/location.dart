// @dart=2.9

class Location {
  final double latitude;
  final double longitude;

  Location(this.latitude, this.longitude);

  @override
  String toString() => 'Location(latitude: $latitude, longitude: $longitude)';
}
