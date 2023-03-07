import "dart:collection";
import "dart:convert";

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
    double lon,
    int radius,
  ) async {
    final list = getLocations();
    final data = {
      "id": list.length,
      "name": location,
      "lat": lat,
      "lon": lon,
      "radius": radius,
    };
    final encodedMap = json.encode(data);
    list.add(encodedMap);
    await prefs!.setStringList('locations', list);
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
