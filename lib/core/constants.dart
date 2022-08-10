const int kThumbnailSmallSize = 256;
const int kThumbnailQuality = 50;
const int kThumbnailLargeSize = 512;
const int kCompressedThumbnailResolution = 1080;
const int kThumbnailDataLimit = 100 * 1024;
const String kSentryDSN =
    "https://2235e5c99219488ea93da34b9ac1cb68@sentry.ente.io/4";
const String kSentryDebugDSN =
    "https://ca5e686dd7f149d9bf94e620564cceba@sentry.ente.io/3";
const String kSentryTunnel = "https://sentry-reporter.ente.io";
const String kRoadmapURL = "https://roadmap.ente.io";
const int kMicroSecondsInDay = 86400000000;
const int kAndroid11SDKINT = 30;
const int kGalleryLoadStartTime = -8000000000000000; // Wednesday, March 6, 1748
const int kGalleryLoadEndTime = 9223372036854775807; // 2^63 -1

// used to identify which ente file are available in app cache
// todo: 6Jun22: delete old media identifier after 3 months
const String kOldSharedMediaIdentifier = 'ente-shared://';
const String kSharedMediaIdentifier = 'ente-shared-media://';

const int kMaxLivePhotoToastCount = 2;
const String kLivePhotoToastCounterKey = "show_live_photo_toast";

const kThumbnailDiskLoadDeferDuration = Duration(milliseconds: 40);
const kThumbnailServerLoadDeferDuration = Duration(milliseconds: 80);

// 256 bit key maps to 24 words
// https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki#Generating_the_mnemonic
const kMnemonicKeyWordCount = 24;

// https://stackoverflow.com/a/61162219
const kDragSensitivity = 8;

const kSupportEmail = 'support@ente.io';

// Default values for various feature flags
class FFDefault {
  static const bool enableStripe = true;
  static const bool disableUrlSharing = false;
  static const bool disableCFWorker = false;
  static const bool enableMissingLocationMigration = false;
}

const kDefaultProductionEndpoint = 'https://api.ente.io';
