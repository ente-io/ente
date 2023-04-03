import "dart:collection";
import "dart:convert";
import "dart:math";

import "package:photos/core/constants.dart";
import "package:photos/models/location/location.dart";
import 'package:photos/models/location_tag/location_tag.dart';
import "package:shared_preferences/shared_preferences.dart";

class LocationService {
  SharedPreferences? prefs;
  LocationService._privateConstructor();

  static final LocationService instance = LocationService._privateConstructor();

  Future<void> init() async {
    prefs ??= await SharedPreferences.getInstance();
  }

  List<String> getAllLocationTags() {
    var list = prefs!.getStringList('locations');
    list ??= [];
    return list;
  }

  Future<void> addLocation(
    String location,
    Location centerPoint,
    int radius,
  ) async {
    final list = getAllLocationTags();
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
    list.add(json.encode(locationTag.toJson()));
    await prefs!.setStringList('locations', list);
  }

  ///The area bounded by the location tag becomes more elliptical with increase
  ///in the magnitude of the latitude on the caritesian plane. When latitude is
  ///0 degrees, the ellipse is a circle with a = b = r. When latitude incrases,
  ///the major axis (a) has to be scaled by the secant of the latitude.
  double _scaleFactor(double lat) {
    return 1 / cos(lat * (pi / 180));
  }

  List<LocationTag> enclosingLocationTags(Location fileCoordinates) {
    final result = List<LocationTag>.of([]);
    final locationTagsData = getAllLocationTags();
    for (String locationTagData in locationTagsData) {
      final locationTag = LocationTag.fromJson(json.decode(locationTagData));
      // final locationJson = json.decode(locationTag);
      // final center = locationJson["center"];
      final x = fileCoordinates.latitude! - locationTag.centerPoint.latitude!;
      final y = fileCoordinates.longitude! - locationTag.centerPoint.longitude!;
      if ((x * x) / (locationTag.aSquare) + (y * y) / (locationTag.bSquare) <=
          1) {
        result.add(
          locationTag,
        );
      }
    }
    return result;
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

  Future<void> addFileToLocation(int locationId, int fileId) async {
    final list = getFilesByLocation(locationId.toString());
    list.add(fileId.toString());
    await prefs!.setStringList("location_$locationId", list);
  }

  List<String> getFilesByLocation(String locationId) {
    var fileList = prefs!.getStringList("location_$locationId");
    fileList ??= [];
    return fileList;
  }

  List<String> getLocationsByFileID(int fileId) {
    final locationList = getAllLocationTags();
    final locations = List<dynamic>.of([]);
    for (String locationString in locationList) {
      final locationJson = json.decode(locationString);
      locations.add(locationJson);
    }
    final res = List<String>.of([]);
    for (dynamic location in locations) {
      final list = getFilesByLocation(location["id"].toString());
      if (list.contains(fileId.toString())) {
        res.add(location["name"]);
      }
    }
    return res;
  }

  Map<String, List<String>> clusterFilesByLocation() {
    final map = HashMap<String, List<String>>();
    var locations = prefs!.getStringList('locations');
    locations ??= [];
    for (String locationData in locations) {
      final locationJson = json.decode(locationData);
      map.putIfAbsent(
        locationData,
        () => getFilesByLocation(locationJson['id'].toString()),
      );
    }
    return map;
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
