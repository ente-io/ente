import 'package:freezed_annotation/freezed_annotation.dart';

part 'location.freezed.dart';
part 'location.g.dart';

@freezed
class Location with _$Location {
  const factory Location({
    required double? latitude,
    required double? longitude,
  }) = _Location;

  factory Location.fromJson(Map<String, Object?> json) =>
      _$LocationFromJson(json);

  static isValidLocation(Location? location) {
    if (location == null) return false;
    if (location.latitude == null || location.longitude == null) return false;
    final latValue = location.latitude!;
    final longValue = location.longitude!;
    if (latValue.isNaN || latValue.isInfinite) {
      return false;
    }
    if (longValue.isNaN || longValue.isInfinite) {
      return false;
    }
    if (latValue == 0.0 && longValue == 0.0) return false;
    return true;
  }
}
