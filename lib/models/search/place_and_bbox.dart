// ignore_for_file: public_member_api_docs, sort_constructors_first

class PlaceAndBbox {
  final String place;
  final List<double> bbox;
  PlaceAndBbox({
    this.place,
    this.bbox,
  });

  PlaceAndBbox copyWith({
    String place,
    List<double> bbox,
  }) {
    return PlaceAndBbox(
      place: place ?? this.place,
      bbox: bbox ?? this.bbox,
    );
  }

  factory PlaceAndBbox.fromMap(Map<String, dynamic> map) {
    return PlaceAndBbox(
      place: map['place'] as String,
      bbox: List<double>.from(
        (map['bbox']),
      ),
    );
  }
}
