// @dart=2.9

class LocationApiResponse {
  final List<LocationDataFromResponse> results;
  LocationApiResponse({
    this.results,
  });

  LocationApiResponse copyWith({
    List<LocationDataFromResponse> results,
  }) {
    return LocationApiResponse(
      results: results ?? this.results,
    );
  }

  factory LocationApiResponse.fromMap(Map<String, dynamic> map) {
    return LocationApiResponse(
      results: List<LocationDataFromResponse>.from(
        (map['results']).map(
          (x) => LocationDataFromResponse.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }
}

class LocationDataFromResponse {
  final String place;
  final List<double> bbox;
  LocationDataFromResponse({
    this.place,
    this.bbox,
  });

  LocationDataFromResponse copyWith({
    String place,
    List<double> bbox,
  }) {
    return LocationDataFromResponse(
      place: place ?? this.place,
      bbox: bbox ?? this.bbox,
    );
  }

  factory LocationDataFromResponse.fromMap(Map<String, dynamic> map) {
    return LocationDataFromResponse(
      place: map['place'] as String,
      bbox: List<double>.from(
        (map['bbox']),
      ),
    );
  }
}
