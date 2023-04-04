import "dart:convert";
import "dart:math";

import "package:logging/logging.dart";
import "package:photos/core/constants.dart";
import "package:photos/models/api/entity/type.dart";
import "package:photos/models/local_entity_data.dart";
import "package:photos/models/location/location.dart";
import 'package:photos/models/location_tag/location_tag.dart';
import "package:photos/services/entity_service.dart";
import "package:shared_preferences/shared_preferences.dart";

class LocationService {
  late SharedPreferences prefs;
  final Logger _logger = Logger((LocationService).toString());

  LocationService._privateConstructor();

  static final LocationService instance = LocationService._privateConstructor();

  void init(SharedPreferences preferences) {
    prefs = preferences;
  }

  Future<Iterable<LocalEntity<LocationTag>>> _getStoredLocationTags() async {
    final data = await EntityService.instance.getEntities(EntityType.location);
    return data.map(
        (e) => LocalEntity(LocationTag.fromJson(json.decode(e.data)), e.id));
  }

  Future<Iterable<LocalEntity<LocationTag>>> getLocationTags() {
    return _getStoredLocationTags();
  }

  Future<void> addLocation(
    String location,
    Location centerPoint,
    int radius,
  ) async {
    //The area enclosed by the location tag will be a circle on a 3D spherical
    //globe and an ellipse on a 2D Mercator projection (2D map)
    //a & b are the semi-major and semi-minor axes of the ellipse
    //Converting the unit from kilometers to degrees for a and b as that is
    //the unit on the caritesian plane

    final a =
        (radius * _scaleFactor(centerPoint.latitude!)) / kilometersPerDegree;
    final b = radius / kilometersPerDegree;
    final locationTag = LocationTag(
      name: location,
      radius: radius,
      aSquare: a * a,
      bSquare: b * b,
      centerPoint: centerPoint,
    );
    await EntityService.instance
        .addOrUpdate(EntityType.location, json.encode(locationTag.toJson()));
  }

  ///The area bounded by the location tag becomes more elliptical with increase
  ///in the magnitude of the latitude on the caritesian plane. When latitude is
  ///0 degrees, the ellipse is a circle with a = b = r. When latitude incrases,
  ///the major axis (a) has to be scaled by the secant of the latitude.
  double _scaleFactor(double lat) {
    return 1 / cos(lat * (pi / 180));
  }

  Future<List<LocationTag>> enclosingLocationTags(
      Location fileCoordinates) async {
    try {
      final result = List<LocationTag>.of([]);
      final locationTagsData = (await getLocationTags()).map((e) => e.item);
      for (LocationTag locationTag in locationTagsData) {
        final x = fileCoordinates.latitude! - locationTag.centerPoint.latitude!;
        final y =
            fileCoordinates.longitude! - locationTag.centerPoint.longitude!;
        if ((x * x) / (locationTag.aSquare) + (y * y) / (locationTag.bSquare) <=
            1) {
          result.add(
            locationTag,
          );
        }
      }
      return result;
    } catch (e, s) {
      _logger.severe("Failed to get enclosing location tags", e, s);
      rethrow;
    }
  }

  bool isFileInsideLocationTag(
    Location centerPoint,
    Location fileCoordinates,
    int radius,
  ) {
    final a =
        (radius * _scaleFactor(centerPoint.latitude!)) / kilometersPerDegree;
    final b = radius / kilometersPerDegree;
    final x = centerPoint.latitude! - fileCoordinates.latitude!;
    final y = centerPoint.longitude! - fileCoordinates.longitude!;
    if ((x * x) / (a * a) + (y * y) / (b * b) <= 1) {
      return true;
    }
    return false;
  }
}

class GPSData {
  final String latRef;
  final List<double> lat;
  final String longRef;
  final List<double> long;

  GPSData(this.latRef, this.lat, this.longRef, this.long);

  Location toLocationFormat() {
    final latSign = latRef == "N" ? 1 : -1;
    final longSign = longRef == "E" ? 1 : -1;
    return Location(
      latitude: latSign * lat[0] + lat[1] / 60 + lat[2] / 3600,
      longitude: longSign * long[0] + long[1] / 60 + long[2] / 3600,
    );
  }
}
