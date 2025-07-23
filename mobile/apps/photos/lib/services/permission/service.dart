import "package:photo_manager/photo_manager.dart";
import "package:shared_preferences/shared_preferences.dart";

class PermissionService {
  static const kHasGrantedPermissionsKey = "has_granted_permissions";
  static const kPermissionStateKey = "permission_state";
  final SharedPreferences _prefs;
  PermissionService(this._prefs);
  Future<PermissionState> requestPhotoMangerPermissions() {
    return PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: RequestType.common,
          mediaLocation: true,
        ),
      ),
    );
  }

  bool hasGrantedPermissions() {
    return _prefs.getBool(kHasGrantedPermissionsKey) ?? false;
  }

  bool hasGrantedLimitedPermissions() {
    return _prefs.getString(kPermissionStateKey) ==
        PermissionState.limited.toString();
  }

  bool hasGrantedFullPermission() {
    return (_prefs.getString(kPermissionStateKey) ?? '') ==
        PermissionState.authorized.toString();
  }

  Future<void> onUpdatePermission(PermissionState state) async {
    await _prefs.setBool(kHasGrantedPermissionsKey, true);
    await _prefs.setString(kPermissionStateKey, state.toString());
  }
}
