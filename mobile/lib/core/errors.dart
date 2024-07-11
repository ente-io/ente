enum InvalidReason {
  assetDeleted,
  assetDeletedEvent,
  sourceFileMissing,
  livePhotoToImageTypeChanged,
  imageToLivePhotoTypeChanged,
  livePhotoVideoMissing,
  thumbnailMissing,
  tooLargeFile,
  unknown,
}

extension InvalidReasonExn on InvalidReason {
  bool get isLivePhotoErr =>
      this == InvalidReason.livePhotoToImageTypeChanged ||
      this == InvalidReason.imageToLivePhotoTypeChanged ||
      this == InvalidReason.livePhotoVideoMissing;
}

class InvalidFileError extends ArgumentError {
  final InvalidReason reason;

  InvalidFileError(String message, this.reason) : super(message);

  @override
  String toString() {
    return 'InvalidFileError: $message (reason: $reason)';
  }
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

class LoginKeyDerivationError extends Error {}

class SrpSetupNotCompleteError extends Error {}

class SharingNotPermittedForFreeAccountsError extends Error {}

class NoMediaLocationAccessError extends Error {}

class PassKeySessionNotVerifiedError extends Error {}

class PassKeySessionExpiredError extends Error {}
