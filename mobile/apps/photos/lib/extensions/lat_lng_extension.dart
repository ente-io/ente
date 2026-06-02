import "package:photo_manager/photo_manager.dart";
import "package:photos/models/location/location.dart";

extension LatLngExtension on LatLng? {
  Location? toEnteLocation() {
    final latLng = this;
    if (latLng == null) {
      return null;
    }
    if (latLng.latitude == 0.0 ||
        latLng.latitude.isNaN ||
        latLng.latitude.isInfinite ||
        latLng.longitude == 0.0 ||
        latLng.longitude.isNaN ||
        latLng.longitude.isInfinite) {
      return null;
    }
    return Location(latitude: latLng.latitude, longitude: latLng.longitude);
  }
}
