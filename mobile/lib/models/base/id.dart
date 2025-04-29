import 'package:nanoid/nanoid.dart';

const enteWhiteListedAlphabet =
    '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
const clusterIDLength = 22;

String newClusterID() {
  return "cluster_${customAlphabet(enteWhiteListedAlphabet, clusterIDLength)}";
}

String newID(String prefix) {
  return "${prefix}_${customAlphabet(enteWhiteListedAlphabet, clusterIDLength)}";
}

String newIsolateTaskID(String task) {
  return "${task}_${customAlphabet(enteWhiteListedAlphabet, clusterIDLength)}";
}
