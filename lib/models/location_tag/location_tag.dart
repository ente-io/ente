import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:photos/models/location/location.dart';

part 'location_tag.freezed.dart';
part 'location_tag.g.dart';

@freezed
class LocationTag with _$LocationTag {
  const factory LocationTag({
    required String name,
    required int radius,
    required Location centerPoint,
  }) = _LocationTag;

  factory LocationTag.fromJson(Map<String, Object?> json) =>
      _$LocationTagFromJson(json);
}
