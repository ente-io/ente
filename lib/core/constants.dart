const int thumbnailSmallSize = 256;
const int thumbnailQuality = 50;
const int thumbnailLargeSize = 512;
const int compressedThumbnailResolution = 1080;
const int thumbnailDataLimit = 100 * 1024;
const String sentryDSN =
    "https://2235e5c99219488ea93da34b9ac1cb68@sentry.ente.io/4";
const String sentryDebugDSN =
    "https://ca5e686dd7f149d9bf94e620564cceba@sentry.ente.io/3";
const String sentryTunnel = "https://sentry-reporter.ente.io";
const String roadmapURL = "https://roadmap.ente.io";
const int microSecondsInDay = 86400000000;
const int android11SDKINT = 30;
const int jan011981Time = 347155200000000;
const int galleryLoadStartTime = -8000000000000000; // Wednesday, March 6, 1748
const int galleryLoadEndTime = 9223372036854775807; // 2^63 -1
const int batchSize = 1000;
const photoGridSizeDefault = 4;
const photoGridSizeMin = 2;
const photoGridSizeMax = 6;
const subGalleryMultiplier = 10;

// used to identify which ente file are available in app cache
// todo: 6Jun22: delete old media identifier after 3 months
const String oldSharedMediaIdentifier = 'ente-shared://';
const String sharedMediaIdentifier = 'ente-shared-media://';

const int maxLivePhotoToastCount = 2;
const String livePhotoToastCounterKey = "show_live_photo_toast";
const String fileCaptionDefaultHint = "Add a description...";

const thumbnailDiskLoadDeferDuration = Duration(milliseconds: 40);
const thumbnailServerLoadDeferDuration = Duration(milliseconds: 80);

// 256 bit key maps to 24 words
// https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki#Generating_the_mnemonic
const mnemonicKeyWordCount = 24;

// https://stackoverflow.com/a/61162219
const dragSensitivity = 8;

const supportEmail = 'support@ente.io';

// Default values for various feature flags
class FFDefault {
  static const bool enableStripe = true;
  static const bool disableCFWorker = false;
}

const kDefaultProductionEndpoint = 'https://api.ente.io';

const int intMaxValue = 9223372036854775807;

//Screen width of iPhone 14 pro max in points is taken as maximum
const double restrictedMaxWidth = 430;

const double mobileSmallThreshold = 336;
