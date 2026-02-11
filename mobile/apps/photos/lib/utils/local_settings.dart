import 'package:flutter/foundation.dart';
import 'package:photos/app_mode.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/ui/viewer/gallery/component/group/type.dart';
import "package:photos/utils/ram_check_util.dart";
import 'package:shared_preferences/shared_preferences.dart';

enum AlbumSortKey {
  albumName,
  newestPhoto,
  lastUpdated,
}

enum AlbumSortDirection {
  ascending,
  descending,
}

enum AlbumViewType {
  grid,
  list,
}

enum PeopleSortKey {
  mostPhotos,
  name,
  lastUpdated,
}

/// Bit positions for offline-related boolean flags stored as a single integer.
/// IMPORTANT: Never reorder or remove values. Only append new values at the end.
enum OfflineFlag {
  mlConsent,
  mapEnabled,
  getStartedBannerDismissed,
  facesBannerDismissed,
  nameFaceBannerDismissed,
  seenMLEnablingBanner,
  mlProgressBannerDismissed,
  offlineSettingsBannerDismissed,
}

class LocalSettings {
  static const kCollectionSortPref = "collection_sort_pref";
  static const kGalleryGroupType = "gallery_group_type";
  static const kPhotoGridSize = "photo_grid_size";
  static const _kisMLLocalIndexingEnabled = "ls.ml_local_indexing";
  static const _kOfflineMLLocalIndexingEnabled = "ls.offline_ml_local_indexing";
  static const kRateUsShownCount = "rate_us_shown_count";
  static const kEnableMultiplePart = "ls.enable_multiple_part";
  static const kCuratedMemoriesEnabled = "ls.curated_memories_enabled";
  static const kOnThisDayNotificationsEnabled =
      "ls.on_this_day_notifications_enabled";
  static const kBirthdayNotificationsEnabled =
      "ls.birthday_notifications_enabled";
  static const kRateUsPromptThreshold = 2;
  static const shouldLoopVideoKey = "video.should_loop";
  static const onGuestViewKey = "on_guest_view";
  static const _hasConfiguredLinksInAppPermissionKey =
      "has_configured_links_in_app_permission";
  static const _hideSharedItemsFromHomeGalleryTag =
      "hide_shared_items_from_home_gallery";
  static const kCollectionViewType = "collection_view_type";
  static const kCollectionSortDirection = "collection_sort_direction";
  static const kPeopleSortKey = "people_sort_key";
  static const kPeopleSortNameAscending = "people_sort_name_ascending";
  static const kPeopleSortUpdatedAscending = "people_sort_updated_ascending";
  static const kPeopleSortPhotosAscending = "people_sort_photos_ascending";
  static const kPeopleSortSimilaritySelected =
      "people_sort_similarity_selected";
  static const kShowLocalIDOverThumbnails = "show_local_id_over_thumbnails";
  static const kEnableDatabaseLogging = "enable_db_logging";
  static const _kInternalUserDisabled = "ls.internal_user_disabled";
  static const _kSharedPhotoFeedCutoffTime = "ls.shared_photo_feed_cutoff_time";
  static const _kWrapped2025ResumeIndex = "ls.wrapped_2025_resume_index";
  static const _kWrapped2025Complete = "ls.wrapped_2025_complete";
  static const _kAppLockEnabled = "ls.app_lock_enabled";
  static const _memoryLaneSeenKey = "faces_timeline_seen_person_ids";
  static const _kChristmasBannerEnabled = "ls.christmas_banner_enabled";
  static const _kAutoMergeThresholdOverride = "ml_debug.auto_merge_threshold";
  static const _kDefaultClusteringDistanceOverride =
      "ml_debug.default_clustering_distance";
  static const _kAppMode = "ls.app_mode";
  static const _kAppModeEnvKey = "app_mode";

  static const _kOfflineFlags = "ls.offline_flags";

  final SharedPreferences _prefs;

  AppMode? _cachedAppMode;

  LocalSettings(this._prefs);

  bool _getFlag(OfflineFlag flag) {
    final bitmap = _prefs.getInt(_kOfflineFlags) ?? 0;
    return (bitmap & (1 << flag.index)) != 0;
  }

  Future<void> _setFlag(OfflineFlag flag, bool value) {
    var bitmap = _prefs.getInt(_kOfflineFlags) ?? 0;
    if (value) {
      bitmap |= (1 << flag.index);
    } else {
      bitmap &= ~(1 << flag.index);
    }
    return _prefs.setInt(_kOfflineFlags, bitmap);
  }

  AlbumSortKey albumSortKey() {
    return AlbumSortKey.values[_prefs.getInt(kCollectionSortPref) ?? 0];
  }

  Future<bool> setAlbumSortKey(AlbumSortKey key) {
    return _prefs.setInt(kCollectionSortPref, key.index);
  }

  Future<void> setAlbumViewType(AlbumViewType viewType) async {
    await _prefs.setInt(kCollectionViewType, viewType.index);
  }

  AlbumViewType albumViewType() {
    final index = _prefs.getInt(kCollectionViewType) ?? 0;
    return AlbumViewType.values[index];
  }

  AlbumSortDirection albumSortDirection() {
    return AlbumSortDirection
        .values[_prefs.getInt(kCollectionSortDirection) ?? 1];
  }

  Future<bool> setAlbumSortDirection(AlbumSortDirection direction) {
    return _prefs.setInt(kCollectionSortDirection, direction.index);
  }

  PeopleSortKey peopleSortKey() {
    final index = _prefs.getInt(kPeopleSortKey);
    if (index == null || index < 0 || index >= PeopleSortKey.values.length) {
      return PeopleSortKey.mostPhotos;
    }
    return PeopleSortKey.values[index];
  }

  Future<bool> setPeopleSortKey(PeopleSortKey key) {
    return _prefs.setInt(kPeopleSortKey, key.index);
  }

  bool get peopleNameSortAscending =>
      _prefs.getBool(kPeopleSortNameAscending) ?? true;

  Future<void> setPeopleNameSortAscending(bool value) async {
    await _prefs.setBool(kPeopleSortNameAscending, value);
  }

  bool get peopleUpdatedSortAscending =>
      _prefs.getBool(kPeopleSortUpdatedAscending) ?? false;

  Future<void> setPeopleUpdatedSortAscending(bool value) async {
    await _prefs.setBool(kPeopleSortUpdatedAscending, value);
  }

  bool get peoplePhotosSortAscending =>
      _prefs.getBool(kPeopleSortPhotosAscending) ?? false;

  Future<void> setPeoplePhotosSortAscending(bool value) async {
    await _prefs.setBool(kPeopleSortPhotosAscending, value);
  }

  bool get peopleSimilaritySortSelected =>
      _prefs.getBool(kPeopleSortSimilaritySelected) ?? true;

  Future<void> setPeopleSimilaritySortSelected(bool value) async {
    await _prefs.setBool(kPeopleSortSimilaritySelected, value);
  }

  bool get appLockEnabledCached => _prefs.getBool(_kAppLockEnabled) ?? false;

  Future<void> setAppLockEnabledCached(bool value) async {
    await _prefs.setBool(_kAppLockEnabled, value);
  }

  GroupType getGalleryGroupType() {
    final groupTypeString = _prefs.getString(kGalleryGroupType);
    if (groupTypeString != null) {
      return GroupType.values.firstWhere(
        (type) => type.toString() == groupTypeString,
        orElse: () => GroupType.values[0],
      );
    }
    return GroupType.values[0];
  }

  Future<void> setGalleryGroupType(GroupType groupType) async {
    await _prefs.setString(kGalleryGroupType, groupType.toString());
  }

  int getPhotoGridSize() {
    if (_prefs.containsKey(kPhotoGridSize)) {
      return _prefs.getInt(kPhotoGridSize)!;
    } else {
      return photoGridSizeDefault;
    }
  }

  Future<void> setPhotoGridSize(int value) async {
    await _prefs.setInt(kPhotoGridSize, value);
  }

  int getRateUsShownCount() {
    if (_prefs.containsKey(kRateUsShownCount)) {
      return _prefs.getInt(kRateUsShownCount)!;
    } else {
      return 0;
    }
  }

  // getEstimatedInstallTimeInMs returns the time when the app was installed
  // The time is stored in shared preferences and will be reset on logout
  DateTime getInstallDateTime() {
    if (_prefs.containsKey('ls.install_time')) {
      return DateTime.fromMillisecondsSinceEpoch(
        _prefs.getInt('ls.install_time')!,
      );
    } else {
      final installTime = DateTime.now();
      _prefs.setInt('ls.install_time', installTime.millisecondsSinceEpoch);
      return installTime;
    }
  }

  Future<void> setRateUsShownCount(int value) async {
    await _prefs.setInt(kRateUsShownCount, value);
  }

  bool shouldPromptToRateUs() {
    return getRateUsShownCount() < kRateUsPromptThreshold;
  }

  bool get offlineMLConsent => _getFlag(OfflineFlag.mlConsent);

  Future<void> setOfflineMLConsent(bool value) =>
      _setFlag(OfflineFlag.mlConsent, value);

  bool get offlineMapEnabled => _getFlag(OfflineFlag.mapEnabled);

  Future<void> setOfflineMapEnabled(bool value) =>
      _setFlag(OfflineFlag.mapEnabled, value);

  bool get isMLLocalIndexingEnabled {
    final key = appMode == AppMode.offline
        ? _kOfflineMLLocalIndexingEnabled
        : _kisMLLocalIndexingEnabled;
    return _prefs.getBool(key) ?? enoughRamForLocalIndexing;
  }

  bool get isSmartMemoriesEnabled =>
      _prefs.getBool(kCuratedMemoriesEnabled) ?? true;

  double? get autoMergeThresholdOverride =>
      _prefs.getDouble(_kAutoMergeThresholdOverride);

  Future<void> setAutoMergeThresholdOverride(double? value) async {
    if (value == null) {
      await _prefs.remove(_kAutoMergeThresholdOverride);
      return;
    }
    await _prefs.setDouble(_kAutoMergeThresholdOverride, value);
  }

  double? get defaultClusteringDistanceOverride =>
      _prefs.getDouble(_kDefaultClusteringDistanceOverride);

  Future<void> setDefaultClusteringDistanceOverride(double? value) async {
    if (value == null) {
      await _prefs.remove(_kDefaultClusteringDistanceOverride);
      return;
    }
    await _prefs.setDouble(_kDefaultClusteringDistanceOverride, value);
  }

  Future<bool> setSmartMemories(bool value) async {
    await _prefs.setBool(kCuratedMemoriesEnabled, value);
    return value;
  }

  bool get isOnThisDayNotificationsEnabled =>
      _prefs.getBool(kOnThisDayNotificationsEnabled) ?? true;

  Future<bool> setOnThisDayNotificationsEnabled(bool value) async {
    await _prefs.setBool(kOnThisDayNotificationsEnabled, value);
    return value;
  }

  bool get birthdayNotificationsEnabled =>
      _prefs.getBool(kBirthdayNotificationsEnabled) ?? true;

  Future<bool> setBirthdayNotificationsEnabled(bool value) async {
    await _prefs.setBool(kBirthdayNotificationsEnabled, value);
    return value;
  }

  bool get userEnabledMultiplePart =>
      _prefs.getBool(kEnableMultiplePart) ?? true;

  Future<bool> setUserEnabledMultiplePart(bool value) async {
    await _prefs.setBool(kEnableMultiplePart, value);
    return value;
  }

  /// toggleFaceIndexing toggles the face indexing setting and returns the new value
  Future<bool> toggleLocalMLIndexing() async {
    final key = appMode == AppMode.offline
        ? _kOfflineMLLocalIndexingEnabled
        : _kisMLLocalIndexingEnabled;
    final nextValue = !(_prefs.getBool(key) ?? enoughRamForLocalIndexing);
    await _prefs.setBool(key, nextValue);
    return nextValue;
  }

  bool get hasSeenMLEnablingBanner =>
      _getFlag(OfflineFlag.seenMLEnablingBanner);
  Future<void> setHasSeenMLEnablingBanner() =>
      _setFlag(OfflineFlag.seenMLEnablingBanner, true);

  bool hasSeenMemoryLane(String personId) {
    final seenIds = _prefs.getStringList(_memoryLaneSeenKey);
    if (seenIds == null || seenIds.isEmpty) {
      return false;
    }
    return seenIds.contains(personId);
  }

  Future<void> markMemoryLaneSeen(String personId) async {
    final List<String> seenIds = List<String>.from(
      _prefs.getStringList(_memoryLaneSeenKey) ?? [],
    );
    if (seenIds.contains(personId)) {
      return;
    }
    seenIds.add(personId);
    await _prefs.setStringList(_memoryLaneSeenKey, seenIds);
  }

  //#region todo:(NG) remove this section, only needed for internal testing to see
  // if the OS stops the app during indexing
  bool get remoteFetchEnabled => _prefs.getBool("remoteFetchEnabled") ?? true;
  Future<void> toggleRemoteFetch() async {
    await _prefs.setBool("remoteFetchEnabled", !remoteFetchEnabled);
  }
  //#endregion

  Future<void> setShouldLoopVideo(bool value) async {
    await _prefs.setBool(shouldLoopVideoKey, value);
  }

  bool shouldLoopVideo() {
    return _prefs.getBool(shouldLoopVideoKey) ?? true;
  }

  Future<void> setOnGuestView(bool value) {
    return _prefs.setBool(onGuestViewKey, value);
  }

  bool isOnGuestView() {
    return _prefs.getBool(onGuestViewKey) ?? false;
  }

  Future<void> setConfiguredLinksInAppPermissions(bool value) async {
    await _prefs.setBool(_hasConfiguredLinksInAppPermissionKey, value);
  }

  /// This is only relevant for fdorid and independent builds since in them,
  /// user has to manually allow the app to open public links in-app
  bool hasConfiguredInAppLinkPermissions() {
    final result = _prefs.getBool(_hasConfiguredLinksInAppPermissionKey);
    return result ?? false;
  }

  Future<void> setHideSharedItemsFromHomeGallery(bool value) async {
    await _prefs.setBool(_hideSharedItemsFromHomeGalleryTag, value);
  }

  bool get hideSharedItemsFromHomeGallery =>
      _prefs.getBool(_hideSharedItemsFromHomeGalleryTag) ?? false;

  bool get showLocalIDOverThumbnails =>
      _prefs.getBool(kShowLocalIDOverThumbnails) ?? false;

  Future<void> setShowLocalIDOverThumbnails(bool value) async {
    await _prefs.setBool(kShowLocalIDOverThumbnails, value);
  }

  bool get enableDatabaseLogging =>
      _prefs.getBool(kEnableDatabaseLogging) ?? kDebugMode;

  Future<void> setEnableDatabaseLogging(bool value) async {
    await _prefs.setBool(kEnableDatabaseLogging, value);
  }

  bool get isInternalUserDisabled =>
      _prefs.getBool(_kInternalUserDisabled) ?? false;

  Future<void> setInternalUserDisabled(bool value) async {
    await _prefs.setBool(_kInternalUserDisabled, value);
  }

  int getOrCreateSharedPhotoFeedCutoffTime() {
    final existingCutoff = _prefs.getInt(_kSharedPhotoFeedCutoffTime);
    if (existingCutoff != null) {
      return existingCutoff;
    }

    // files.added_time is stored in microseconds since epoch.
    final cutoff = DateTime.now().microsecondsSinceEpoch;
    _prefs.setInt(_kSharedPhotoFeedCutoffTime, cutoff).ignore();
    return cutoff;
  }

  int wrapped2025ResumeIndex() {
    return _prefs.getInt(_kWrapped2025ResumeIndex) ?? 0;
  }

  Future<void> setWrapped2025ResumeIndex(int index) async {
    await _prefs.setInt(_kWrapped2025ResumeIndex, index);
  }

  bool wrapped2025Complete() {
    return _prefs.getBool(_kWrapped2025Complete) ?? false;
  }

  Future<void> setWrapped2025Complete() async {
    await _prefs.setBool(_kWrapped2025Complete, true);
  }

  Future<void> resetWrapped2025Complete() async {
    await _prefs.setBool(_kWrapped2025Complete, false);
  }

  bool get isChristmasBannerEnabled =>
      _prefs.getBool(_kChristmasBannerEnabled) ?? true;

  Future<void> setChristmasBannerEnabled(bool value) async {
    await _prefs.setBool(_kChristmasBannerEnabled, value);
  }

  AppMode get appMode {
    if (_cachedAppMode != null) return _cachedAppMode!;

    final savedIndex = _prefs.getInt(_kAppMode);
    if (savedIndex != null &&
        savedIndex >= 0 &&
        savedIndex < AppMode.values.length) {
      _cachedAppMode = AppMode.values[savedIndex];
      return _cachedAppMode!;
    }

    const envValue =
        String.fromEnvironment(_kAppModeEnvKey, defaultValue: "online");
    _cachedAppMode = envValue == "offline" ? AppMode.offline : AppMode.online;
    return _cachedAppMode!;
  }

  Future<void> setAppMode(AppMode mode) async {
    await _prefs.setInt(_kAppMode, mode.index);
    _cachedAppMode = mode;
  }

  bool get isOfflineGetStartedBannerDismissed =>
      _getFlag(OfflineFlag.getStartedBannerDismissed);

  Future<void> setOfflineGetStartedBannerDismissed(bool value) =>
      _setFlag(OfflineFlag.getStartedBannerDismissed, value);

  bool get isMLProgressBannerDismissed =>
      _getFlag(OfflineFlag.mlProgressBannerDismissed);

  Future<void> setMLProgressBannerDismissed(bool value) =>
      _setFlag(OfflineFlag.mlProgressBannerDismissed, value);

  bool get isOfflineFacesBannerDismissed =>
      _getFlag(OfflineFlag.facesBannerDismissed);

  Future<void> setOfflineFacesBannerDismissed(bool value) =>
      _setFlag(OfflineFlag.facesBannerDismissed, value);

  bool get isOfflineNameFaceBannerDismissed =>
      _getFlag(OfflineFlag.nameFaceBannerDismissed);

  Future<void> setOfflineNameFaceBannerDismissed(bool value) =>
      _setFlag(OfflineFlag.nameFaceBannerDismissed, value);

  bool get isOfflineSettingsBannerDismissed =>
      _getFlag(OfflineFlag.offlineSettingsBannerDismissed);

  Future<void> setOfflineSettingsBannerDismissed(bool value) =>
      _setFlag(OfflineFlag.offlineSettingsBannerDismissed, value);
}
