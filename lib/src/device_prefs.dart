import 'package:shared_preferences/shared_preferences.dart';

/// 원본 SharedPreferences `"device"` 저장소(BaseActivity `R()`/`Z()`).
///
/// 키: `device_token`, `push_token`, `splash_url`, `webview`(`"main"`/`"popup"`).
class DevicePrefs {
  DevicePrefs._(this._prefs);

  static DevicePrefs? _instance;

  static Future<DevicePrefs> instance() async {
    return _instance ??= DevicePrefs._(
      await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(
          allowList: <String>{
            _kDeviceToken,
            _kPushToken,
            _kSplashUrl,
            _kWebview,
          },
        ),
      ),
    );
  }

  static const String _prefix = 'device.';
  static const String _kDeviceToken = '${_prefix}device_token';
  static const String _kPushToken = '${_prefix}push_token';
  static const String _kSplashUrl = '${_prefix}splash_url';
  static const String _kWebview = '${_prefix}webview';

  final SharedPreferencesWithCache _prefs;

  /// 값이 없으면 빈 문자열(원본 `getString(key, "")`).
  String _read(String key) => _prefs.getString(key) ?? '';

  void _write(String key, String value) {
    _prefs.setString(key, value);
  }

  String get deviceToken => _read(_kDeviceToken);
  set deviceToken(String value) => _write(_kDeviceToken, value);

  String get pushToken => _read(_kPushToken);

  String get splashUrl => _read(_kSplashUrl);
  set splashUrl(String value) => _write(_kSplashUrl, value);

  String get webview => _read(_kWebview);
  set webview(String value) => _write(_kWebview, value);
}
