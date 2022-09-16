class LocationApiResponse {
  final List<LocationDataFromResponse> results;
  LocationApiResponse({
    required this.results,
  });

  LocationApiResponse copyWith({
    required List<LocationDataFromResponse> results,
  }) {
    return LocationApiResponse(
      results: results,
    );
  }

  factory LocationApiResponse.fromMap(Map<String, dynamic> map) {
    return LocationApiResponse(
      results: (map['results']) == null
          ? []
          : List<LocationDataFromResponse>.from(
              (map['results']).map(
                (x) =>
                    LocationDataFromResponse.fromMap(x as Map<String, dynamic>),
              ),
            ),
    );
  }
}

class LocationDataFromResponse {
  final String place;
  final List<double> bbox;
  LocationDataFromResponse({
    required this.place,
    required this.bbox,
  });

  factory LocationDataFromResponse.fromMap(Map<String, dynamic> map) {
    return LocationDataFromResponse(
      place: map['place'] as String,
      bbox: List<double>.from(
        (map['bbox']),
      ),
    );
  }
}
