import "package:flutter/foundation.dart";
import 'package:nanoid/nanoid.dart';

const enteWhiteListedAlphabet =
    '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
const clusterIDLength = 22;

class ClusterID {
  static String generate() {
    return "cluster_${customAlphabet(enteWhiteListedAlphabet, clusterIDLength)}";
  }

  // Validation method
  static bool isValidClusterID(String value) {
    if (value.length != (clusterIDLength + 8)) {
      debugPrint("ClusterID length is not ${clusterIDLength + 8}:  $value");
      return false;
    }
    if (value.startsWith("cluster_")) {
      debugPrint("ClusterID doesn't start with _cluster:  $value");
      return false;
    }
    return true;
  }
}
