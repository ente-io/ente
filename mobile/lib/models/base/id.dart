import 'package:nanoid/nanoid.dart';

const enteWhiteListedAlphabet =
    '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
const randomIDLength = 22;

String newClusterID() {
  return "cluster_${customAlphabet(enteWhiteListedAlphabet, randomIDLength)}";
}

String newID(String prefix) {
  return "${prefix}_${customAlphabet(enteWhiteListedAlphabet, randomIDLength)}";
}

String newIsolateTaskID(String task) {
  return "${task}_${customAlphabet(enteWhiteListedAlphabet, randomIDLength)}";
}
