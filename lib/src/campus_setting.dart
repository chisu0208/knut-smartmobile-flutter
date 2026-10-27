import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 문자열 값 저장소. 앱은 SharedPreferences, 테스트는 [MemoryStore].
abstract interface class KeyValueStore {
  String? getString(String key);
  Future<void> setString(String key, String value);
}

class MemoryStore implements KeyValueStore {
  MemoryStore([Map<String, String>? values])
    : values = values ?? <String, String>{};

  final Map<String, String> values;

  @override
  String? getString(String key) => values[key];

  @override
  Future<void> setString(String key, String value) async => values[key] = value;
}

class _PrefsStore implements KeyValueStore {
  _PrefsStore(this._prefs);
  final SharedPreferencesWithCache _prefs;

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);
}

/// 학식·교통 탭이 함께 쓰는 캠퍼스 설정과, 캠퍼스마다 고른 식당(개선판 2차).
///
/// 원본 저장소(`device.*`, `device_prefs.dart`)와 키가 겹치지 않게 `app.`으로 시작한다.
class CampusSetting extends ChangeNotifier {
  CampusSetting(this._store)
    : _campus = _store.getString(campusKey) ?? defaultCampus;

  static const String defaultCampus = 'chungju';
  static const String campusKey = 'app.campus';
  static const String _restaurantPrefix = 'app.meal_restaurant.';

  static Future<CampusSetting> load() async {
    final SharedPreferencesWithCache prefs =
        await SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(
            allowList: <String>{
              campusKey,
              '${_restaurantPrefix}chungju',
              '${_restaurantPrefix}jeungpyeong',
              '${_restaurantPrefix}uiwang',
            },
          ),
        );
    return CampusSetting(_PrefsStore(prefs));
  }

  final KeyValueStore _store;
  String _campus;

  /// 고른 캠퍼스 id(`chungju`, `jeungpyeong`, `uiwang`).
  String get campus => _campus;

  set campus(String id) {
    if (id == _campus) return;
    _campus = id;
    _store.setString(campusKey, id);
    notifyListeners();
  }

  /// [campus]에서 마지막으로 고른 식당 id.
  String? restaurantFor(String campus) =>
      _store.getString('$_restaurantPrefix$campus');

  void setRestaurant(String campus, String restaurantId) {
    if (restaurantFor(campus) == restaurantId) return;
    _store.setString('$_restaurantPrefix$campus', restaurantId);
    notifyListeners();
  }
}
