import 'package:photos/models/search/location_misc./place_and_bbox.dart';

class ResultsToListOfPlaceAndBbox {
  List<PlaceAndBbox> results;
  ResultsToListOfPlaceAndBbox({
    this.results,
  });

  ResultsToListOfPlaceAndBbox copyWith({
    List<PlaceAndBbox> results,
  }) {
    return ResultsToListOfPlaceAndBbox(
      results: results ?? this.results,
    );
  }

  factory ResultsToListOfPlaceAndBbox.fromMap(Map<String, dynamic> map) {
    return ResultsToListOfPlaceAndBbox(
      results: List<PlaceAndBbox>.from(
        (map['results']).map(
          (x) => PlaceAndBbox.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }
}
