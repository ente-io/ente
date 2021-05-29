/// Thrown when a sodium operation fails.
class SodiumException {
  final String message;
  SodiumException(this.message);

  /// Returns a string representation of this object.
  String toString() => message;
}
