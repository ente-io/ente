import "dart:convert";
import "dart:io";
import "dart:math";

import "package:computer/computer.dart";
import "package:logging/logging.dart";
import "package:photos/core/constants.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/location_tag_updated_event.dart";
import "package:photos/extensions/stop_watch.dart";
import "package:photos/models/api/entity/type.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/local_entity_data.dart";
import "package:photos/models/location/location.dart";
import 'package:photos/models/location_tag/location_tag.dart';
import "package:photos/services/entity_service.dart";
import "package:photos/services/remote_assets_service.dart";
import "package:shared_preferences/shared_preferences.dart";

class LocationService {
  late SharedPreferences prefs;
  final Logger _logger = Logger((LocationService).toString());
  final Computer _computer = Computer.shared();

  LocationService._privateConstructor();

  static final LocationService instance = LocationService._privateConstructor();

  static const kCitiesRemotePath = "https://static.ente.io/world_cities.json";

  List<City> _cities = [];

  void init(SharedPreferences preferences) {
    prefs = preferences;
    _loadCities();
  }

  Future<Iterable<LocalEntity<LocationTag>>> _getStoredLocationTags() async {
    final data = await EntityService.instance.getEntities(EntityType.location);
    return data.map(
      (e) => LocalEntity(LocationTag.fromJson(json.decode(e.data)), e.id),
    );
  }

  Future<Map<City, List<EnteFile>>> getFilesInCity(
    List<EnteFile> allFiles,
    String query,
  ) async {
    final EnteWatch w = EnteWatch("cities_search")..start();
    w.log('start for files ${allFiles.length} and query $query');
    final result = await _computer.compute(
      getCityResults,
      param: {
        "query": query,
        "cities": _cities,
        "files": allFiles,
      },
    );
    w.log(
      'end for query: $query  on ${allFiles.length} files, found '
      '${result.length} cities',
    );
    return result;
  }

  Future<Iterable<LocalEntity<LocationTag>>> getLocationTags() {
    return _getStoredLocationTags();
  }

  Future<void> addLocation(
    String location,
    Location centerPoint,
    double radius,
  ) async {
    //The area enclosed by the location tag will be a circle on a 3D spherical
    //globe and an ellipse on a 2D Mercator projection (2D map)
    //a & b are the semi-major and semi-minor axes of the ellipse
    //Converting the unit from kilometers to degrees for a and b as that is
    //the unit on the caritesian plane

    try {
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
          .addOrUpdate(EntityType.location, locationTag.toJson());
      Bus.instance.fire(LocationTagUpdatedEvent(LocTagEventType.add));
    } catch (e, s) {
      _logger.severe("Failed to add location tag", e, s);
    }
  }

  Future<List<LocalEntity<LocationTag>>> enclosingLocationTags(
    Location fileCoordinates,
  ) async {
    try {
      final result = List<LocalEntity<LocationTag>>.of([]);
      final locationTagEntities = await getLocationTags();
      for (LocalEntity<LocationTag> locationTagEntity in locationTagEntities) {
        final locationTag = locationTagEntity.item;
        final x = fileCoordinates.latitude! - locationTag.centerPoint.latitude!;
        final y =
            fileCoordinates.longitude! - locationTag.centerPoint.longitude!;
        if ((x * x) / (locationTag.aSquare) + (y * y) / (locationTag.bSquare) <=
            1) {
          result.add(
            locationTagEntity,
          );
        }
      }
      return result;
    } catch (e, s) {
      _logger.severe("Failed to get enclosing location tags", e, s);
      rethrow;
    }
  }

  /// returns [lat, lng]
  List<String>? convertLocationToDMS(Location centerPoint) {
    if (centerPoint.latitude == null || centerPoint.longitude == null) {
      return null;
    }
    final lat = centerPoint.latitude!;
    final long = centerPoint.longitude!;
    final latRef = lat >= 0 ? "N" : "S";
    final longRef = long >= 0 ? "E" : "W";
    final latDMS = _convertCoordinateToDMS(lat.abs());
    final longDMS = _convertCoordinateToDMS(long.abs());

    return [
      "${latDMS[0]}°${latDMS[1]}'${latDMS[2]}\" $latRef",
      "${longDMS[0]}°${longDMS[1]}'${longDMS[2]}\" $longRef",
    ];
  }

  List<int> _convertCoordinateToDMS(double coordinate) {
    final degrees = coordinate.floor();
    final minutes = ((coordinate - degrees) * 60).floor();
    final seconds = ((coordinate - degrees - minutes / 60) * 3600).floor();
    return [degrees, minutes, seconds];
  }

  ///Will only update if there is a change in the locationTag's properties
  Future<void> updateLocationTag({
    required LocalEntity<LocationTag> locationTagEntity,
    double? newRadius,
    Location? newCenterPoint,
    String? newName,
  }) async {
    try {
      final radius = newRadius ?? locationTagEntity.item.radius;
      final centerPoint = newCenterPoint ?? locationTagEntity.item.centerPoint;
      final name = newName ?? locationTagEntity.item.name;

      final locationTag = locationTagEntity.item;
      //Exit if there is no change in locationTag's properties
      if (radius == locationTag.radius &&
          centerPoint == locationTag.centerPoint &&
          name == locationTag.name) {
        return;
      }
      final a =
          (radius * _scaleFactor(centerPoint.latitude!)) / kilometersPerDegree;
      final b = radius / kilometersPerDegree;
      final updatedLoationTag = locationTagEntity.item.copyWith(
        centerPoint: centerPoint,
        aSquare: a * a,
        bSquare: b * b,
        radius: radius,
        name: name,
      );

      await EntityService.instance.addOrUpdate(
        EntityType.location,
        updatedLoationTag.toJson(),
        id: locationTagEntity.id,
      );
      Bus.instance.fire(
        LocationTagUpdatedEvent(
          LocTagEventType.update,
          updatedLocTagEntities: [
            LocalEntity(updatedLoationTag, locationTagEntity.id),
          ],
        ),
      );
    } catch (e, s) {
      _logger.severe("Failed to update location tag", e, s);
      rethrow;
    }
  }

  Future<void> deleteLocationTag(String locTagEntityId) async {
    try {
      await EntityService.instance.deleteEntry(
        locTagEntityId,
      );
      Bus.instance.fire(
        LocationTagUpdatedEvent(
          LocTagEventType.delete,
        ),
      );
    } catch (e, s) {
      _logger.severe("Failed to delete location tag", e, s);
      rethrow;
    }
  }

  Future<void> _loadCities() async {
    try {
      final file =
          await RemoteAssetsService.instance.getAsset(kCitiesRemotePath);
      final startTime = DateTime.now();
      _cities =
          await _computer.compute(parseCities, param: {"filePath": file.path});
      final endTime = DateTime.now();
      _logger.info(
        "Loaded cities in ${(endTime.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch)}ms",
      );
      _logger.info("Loaded cities");
    } catch (e, s) {
      _logger.severe("Failed to load cities", e, s);
    }
  }
}

Future<List<City>> parseCities(Map args) async {
  final file = File(args["filePath"]);
  final citiesJson = json.decode(await file.readAsString());

  final List<dynamic> jsonData = citiesJson['data'];
  final cities =
      jsonData.map<City>((jsonItem) => City.fromMap(jsonItem)).toList();
  return cities;
}

Map<City, List<EnteFile>> getCityResults(Map args) {
  final query = (args["query"] as String).toLowerCase();
  final List<City> cities = args["cities"] as List<City>;
  final List<EnteFile> files = args["files"] as List<EnteFile>;

  final matchingCities = cities
      .where(
        (city) => city.city.toLowerCase().contains(query),
      )
      .toList();

  final Map<City, List<EnteFile>> results = {};
  for (final file in files) {
    if (!file.hasLocation) continue; // Skip files without location
    for (final city in matchingCities) {
      final cityLocation = Location(latitude: city.lat, longitude: city.lng);
      if (isFileInsideLocationTag(
        cityLocation,
        file.location!,
        defaultCityRadius,
      )) {
        results.putIfAbsent(city, () => []).add(file);
        break; // Stop searching once a file is matched with a city
      }
    }
  }
  return results;
}

bool isFileInsideLocationTag(
  Location centerPoint,
  Location fileCoordinates,
  double radius,
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

///The area bounded by the location tag becomes more elliptical with increase
///in the magnitude of the latitude on the caritesian plane. When latitude is
///0 degrees, the ellipse is a circle with a = b = r. When latitude incrases,
///the major axis (a) has to be scaled by the secant of the latitude.
double _scaleFactor(double lat) {
  return 1 / cos(lat * (pi / 180));
}

class City {
  final String city;
  final String country;
  final double lat;
  final double lng;

  City({
    required this.city,
    required this.country,
    required this.lat,
    required this.lng,
  });

  factory City.fromMap(Map<String, dynamic> map) {
    return City(
      city: map['city'] ?? '',
      country: map['country'] ?? '',
      lat: map['lat']?.toDouble() ?? 0.0,
      lng: map['lng']?.toDouble() ?? 0.0,
    );
  }

  factory City.fromJson(String source) => City.fromMap(json.decode(source));

  @override
  String toString() {
    return 'City(city: $city, country: $country, lat: $lat, lng: $lng)';
  }
}

class GPSData {
  final String? latRef;
  final List<double>? lat;
  final String? longRef;
  final List<double>? long;

  GPSData(this.latRef, this.lat, this.longRef, this.long);

  Location? toLocationObj() {
    int? latSign;
    int? longSign;
    if (lat == null || long == null) {
      return null;
    }
    if (lat!.length < 3 || long!.length < 3) {
      return null;
    }
    if (latRef == null && longRef == null) {
      latSign = lat!.any((element) => element < 0) ? -1 : 1;
      longSign = long!.any((element) => element < 0) ? -1 : 1;

      for (var element in lat!) {
        lat![lat!.indexOf(element)] = element.abs();
      }
      for (var element in long!) {
        long![long!.indexOf(element)] = element.abs();
      }
    } else {
      if (latRef!.toLowerCase().startsWith('n')) {
        latSign = 1;
      } else if (latRef!.toLowerCase().startsWith('s')) {
        latSign = -1;
      }
      if (longRef!.toLowerCase().startsWith('e')) {
        longSign = 1;
      } else if (longRef!.toLowerCase().startsWith('w')) {
        longSign = -1;
      }
    }

    //At this point, latSign and longSign will only be null if latRef and longRef
    //is of invalid format.
    if (latSign == null || longSign == null) {
      return null;
    }

    final result = Location(
      latitude: latSign * (lat![0] + lat![1] / 60 + lat![2] / 3600),
      longitude: longSign * (long![0] + long![1] / 60 + long![2] / 3600),
    );
    if (Location.isValidLocation(result)) {
      return result;
    } else {
      return null;
    }
  }
}
