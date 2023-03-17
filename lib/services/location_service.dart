import "dart:collection";
import "dart:convert";
import "dart:math";

import "package:photos/core/constants.dart";
import "package:shared_preferences/shared_preferences.dart";

class LocationService {
  SharedPreferences? prefs;
  LocationService._privateConstructor();

  static final LocationService instance = LocationService._privateConstructor();

  Future<void> init() async {
    prefs ??= await SharedPreferences.getInstance();
  }

  List<String> getLocations() {
    var list = prefs!.getStringList('locations');
    list ??= [];
    return list;
  }

  Future<void> addLocation(
    String location,
    double lat,
    double long,
    int radius,
  ) async {
    final list = getLocations();
    //The area enclosed by the location tag will be a circle on a 3D spherical
    //globe and an ellipse on a 2D Mercator projection (2D map)
    //a & b are the semi-major and semi-minor axes of the ellipse
    //Converting the unit from kilometers to degrees for a and b as that is
    //the unit on the caritesian plane
    final a = (radius * _scaleFactor(lat)) / kilometersPerDegree;
    final b = radius / kilometersPerDegree;
    final center = [lat, long];
    final data = {
      "name": location,
      "radius": radius,
      "a": a,
      "b": b,
      "center": center,
    };
    final encodedMap = json.encode(data);
    list.add(encodedMap);
    await prefs!.setStringList('locations', list);
  }

  ///The area bounded by the location tag becomes more elliptical with increase
  ///in the magnitude of the latitude on the caritesian plane. When latitude is
  ///0 degrees, the ellipse is a circle with a = b = r. When latitude incrases,
  ///the major axis (a) has to be scaled by the secant of the latitude.
  double _scaleFactor(double lat) {
    return 1 / cos(lat * (pi / 180));
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
    final locationList = getLocations();
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
  String latRef;
  List<double> lat;
  String longRef;
  List<double> long;

  GPSData(this.latRef, this.lat, this.longRef, this.long);
}
