class UnsupportError extends Error {
  final String message;

  UnsupportError(this.message);
}

class CompressError extends Error {
  final String message;

  CompressError(this.message);
}
