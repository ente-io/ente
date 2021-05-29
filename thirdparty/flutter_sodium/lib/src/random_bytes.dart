import 'dart:typed_data';
import 'sodium.dart';

/// Provides a set of functions to generate unpredictable data, suitable for creating secret keys
class RandomBytes {
  /// Generates a random seed for use in bufferDeterministic.
  static Uint8List randomSeed() =>
      Sodium.randombytesBuf(Sodium.randombytesSeedbytes);

  /// Generates an unpredictable value between 0 and 0xffffffff (included).
  static int random() => Sodium.randombytesRandom();

  /// Generates an unpredictable value between 0 and upperBound (excluded).
  static int uniform(int upperBound) => Sodium.randombytesUniform(upperBound);

  /// Generates an unpredictable sequence of bytes of specified size.
  static Uint8List buffer(int size) => Sodium.randombytesBuf(size);

  /// Generates a sequence of bytes of specified size. For a given seed, this function will always output the same sequence.
  static Uint8List bufferDeterministic(int size, Uint8List seed) =>
      Sodium.randombytesBufDeterministic(size, seed);
}
