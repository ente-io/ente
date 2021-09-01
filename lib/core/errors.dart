class InvalidFileError extends ArgumentError {
  InvalidFileError(String message) : super(message);
}

class InvalidFileUploadState extends AssertionError {
  InvalidFileUploadState(String message) : super(message);
}

class WiFiUnavailableError extends Error {}

class SyncStopRequestedError extends Error {}

class NoActiveSubscriptionError extends Error {}

class StorageLimitExceededError extends Error {}

class SilentlyCancelUploadsError extends Error {}

class UserCancelledUploadError extends Error {}

class LockAlreadyAcquiredError extends Error {}

class UnauthorizedError extends Error {}

class RequestCancelledError extends Error {}

class InvalidSyncStatusError extends AssertionError {
  InvalidSyncStatusError(String message) : super(message);
}

class UnauthorizedEditError extends AssertionError {}
