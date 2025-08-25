import "package:photos/generated/l10n.dart";
import "package:photos/models/location/location.dart";
import "package:photos/models/memories/memory.dart";
import "package:photos/models/memories/smart_memory.dart";

class TripMemory extends SmartMemory {
  final Location location;

  // Stuff for the title
  String? locationName;
  int? tripYear;

  TripMemory(
    List<Memory> memories,
    int firstDateToShow,
    int lastDateToShow,
    this.location, {
    this.locationName,
    this.tripYear,
    super.firstCreationTime,
    super.lastCreationTime,
  }) : super(
          memories,
          MemoryType.trips,
          '',
          firstDateToShow,
          lastDateToShow,
        );

  TripMemory copyWith({
    List<Memory>? memories,
    int? firstDateToShow,
    int? lastDateToShow,
    String? locationName,
    int? tripYear,
  }) {
    return TripMemory(
      memories ?? this.memories,
      firstDateToShow ?? this.firstDateToShow,
      lastDateToShow ?? this.lastDateToShow,
      location,
      locationName: locationName ?? this.locationName,
      tripYear: tripYear ?? this.tripYear,
      firstCreationTime: firstCreationTime,
      lastCreationTime: lastCreationTime,
    );
  }

  @override
  String createTitle(AppLocalizations locals, String languageCode) {
    assert(locationName != null || tripYear != null);
    if (locationName != null) {
      if (locationName!.toLowerCase().contains("base")) return locationName!;
      return locals.tripToLocation(location: locationName!);
    }
    if (tripYear != null) {
      if (tripYear == DateTime.now().year - 1) {
        return locals.lastYearsTrip;
      } else {
        return locals.tripInYear(year: tripYear!);
      }
    }
    throw ArgumentError("TripMemory must have a location name or trip year");
  }
}
