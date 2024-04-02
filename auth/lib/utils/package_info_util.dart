import 'package:ente_auth/utils/platform_util.dart';
import 'package:package_info_plus/package_info_plus.dart';

class PackageInfoUtil {
  Future<PackageInfo> getPackageInfo() async {
    return await PackageInfo.fromPlatform();
  }

  String getVersion(PackageInfo info) {
    return info.version;
  }

  String getPackageName(PackageInfo info) {
    if (PlatformUtil.isMobile()) {
      return info.packageName;
    } else {
      return 'io.ente.auth';
    }
  }
}
