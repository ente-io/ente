import 'package:freezed_annotation/freezed_annotation.dart';
import "package:photos/core/constants.dart";
import 'package:photos/models/location/location.dart';

part 'location_tag.freezed.dart';
part 'location_tag.g.dart';

@freezed
class LocationTag with _$LocationTag {
  const LocationTag._();
  const factory LocationTag({
    required String name,
    required int radius,
    required double aSquare,
    required double bSquare,
    required Location centerPoint,
  }) = _LocationTag;

  factory LocationTag.fromJson(Map<String, Object?> json) =>
      _$LocationTagFromJson(json);

  int get radiusIndex {
    return radiusValues.indexOf(radius);
  }
}
