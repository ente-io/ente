import "package:locker/models/item_view_type.dart";
import "package:shared_preferences/shared_preferences.dart";

class LocalSettings {
  static const kItemViewType = "item_view_type";

  final SharedPreferences _prefs;

  LocalSettings(this._prefs);

  Future<void> setItemViewType(ItemViewType viewType) async {
    await _prefs.setInt(kItemViewType, viewType.index);
  }

  ItemViewType itemViewType() {
    final index = _prefs.getInt(kItemViewType) ?? 0;
    return ItemViewType.values[index];
  }
}
