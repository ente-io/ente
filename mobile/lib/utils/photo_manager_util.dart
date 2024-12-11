import "package:photo_manager/photo_manager.dart";

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
