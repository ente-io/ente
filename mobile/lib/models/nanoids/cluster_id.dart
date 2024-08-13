import "package:flutter/foundation.dart";
import 'package:nanoid/nanoid.dart';

const alphaphet =
    '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
const clusterIDLength = 22;

class ClusterID {
  final String value;

  // Private constructor
  ClusterID._internal(this.value);

  // Factory constructor with validation
  factory ClusterID(String value) {
    if (!_isValidClusterID(value)) {
      throw const FormatException('Invalid NanoID format');
    }
    return ClusterID._internal(value);
  }

  // Static method to generate a new NanoID
  static ClusterID generate() {
    return ClusterID("cluster_${customAlphabet(urlAlphabet, clusterIDLength)}");
  }

  // Validation method
  static bool _isValidClusterID(String value) {
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

  // Override == operator
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClusterID && other.value == value;
  }

  // Override hashCode
  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;

  String toJson() => value;

  static ClusterID fromJson(String value) {
    return ClusterID(value);
  }
}
