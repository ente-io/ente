const String sentryDSN =
    "https://ed4ddd6309b847ba8849935e26e9b648@sentry.ente.io/9";
const String sentryTunnel = "https://sentry-reporter.ente.io";
const String roadmapURL = "https://roadmap.ente.io";
const int microSecondsInDay = 86400000000;
const int android11SDKINT = 30;

// used to identify which ente file are available in app cache
// todo: 6Jun22: delete old media identifier after 3 months
const String oldSharedMediaIdentifier = 'ente-shared://';
const String sharedMediaIdentifier = 'ente-shared-media://';

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
