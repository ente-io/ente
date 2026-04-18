import 'package:ente_pure_utils/ente_pure_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';

class PackageInfoUtil {
  Future<PackageInfo> getPackageInfo() async {
    return await PackageInfo.fromPlatform();
  }

  String getVersion(PackageInfo info) {
    return info.version;
  }

  String getPackageName(PackageInfo info) {
    if (PlatformDetector.isMobile()) {
      return info.packageName;
    } else {
      return 'io.ente.auth';
    }
  }
}
