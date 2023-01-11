class InvalidFileError extends ArgumentError {
  InvalidFileError(String message) : super(message);
}

class InvalidFileUploadState extends AssertionError {
  InvalidFileUploadState(String message) : super(message);
}

class SubscriptionAlreadyClaimedError extends Error {}

class WiFiUnavailableError extends Error {}

class SyncStopRequestedError extends Error {}

class NoActiveSubscriptionError extends Error {}

class StorageLimitExceededError extends Error {}

// error when file size + current usage >= storage plan limit + buffer
class FileTooLargeForPlanError extends Error {}

class SilentlyCancelUploadsError extends Error {}

class UserCancelledUploadError extends Error {}

bool isHandledSyncError(Object errObj) {
  if (errObj is UnauthorizedError ||
      errObj is NoActiveSubscriptionError ||
      errObj is WiFiUnavailableError ||
      errObj is StorageLimitExceededError ||
      errObj is SyncStopRequestedError) {
    return true;
  }
  return false;
}

class LockAlreadyAcquiredError extends Error {}

class UnauthorizedError extends Error {}

class RequestCancelledError extends Error {}

class InvalidSyncStatusError extends AssertionError {
  InvalidSyncStatusError(String message) : super(message);
}

class UnauthorizedEditError extends AssertionError {}

class InvalidStateError extends AssertionError {
  InvalidStateError(String message) : super(message);
}

class KeyDerivationError extends Error {}
