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

class LocalSettings {
  static const kCollectionSortPref = "collection_sort_pref";
  static const kGalleryGroupType = "gallery_group_type";
  static const kPhotoGridSize = "photo_grid_size";
  static const _kisMLLocalIndexingEnabled = "ls.ml_local_indexing";
  static const _kHasSeenMLEnablingBanner = "ls.has_seen_ml_enabling_banner";
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

  final SharedPreferences _prefs;

  LocalSettings(this._prefs);

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

  bool get isMLLocalIndexingEnabled =>
      _prefs.getBool(_kisMLLocalIndexingEnabled) ?? enoughRamForLocalIndexing;

  bool get isSmartMemoriesEnabled =>
      _prefs.getBool(kCuratedMemoriesEnabled) ?? true;

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
    await _prefs.setBool(_kisMLLocalIndexingEnabled, !isMLLocalIndexingEnabled);
    return isMLLocalIndexingEnabled;
  }

  bool get hasSeenMLEnablingBanner =>
      _prefs.getBool(_kHasSeenMLEnablingBanner) ?? false;
  Future<void> setHasSeenMLEnablingBanner() async {
    await _prefs.setBool(_kHasSeenMLEnablingBanner, true);
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
}
