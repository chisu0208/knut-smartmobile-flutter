import 'package:flutter/services.dart';

/// Kotlin(`MainActivity.kt`)과 주고받는 채널.
///
/// 원본에서 시스템 기본 대화상자, 토스트, 인텐트, 권한, NFC, 비콘처럼 Android가 직접
/// 그리거나 처리하던 부분은 Kotlin에서 원본 코드와 같은 API로 처리한다.
class NativeBridge {
  NativeBridge._();

  static const MethodChannel _channel = MethodChannel(
    'kr.ac.ut.mobile.flutter/native',
  );

  static final Map<String, Future<dynamic> Function(MethodCall call)>
  _handlers = <String, Future<dynamic> Function(MethodCall call)>{};

  static bool _installed = false;

  /// Kotlin에서 오는 호출을 받을 처리기를 등록한다.
  static void on(
    String method,
    Future<dynamic> Function(MethodCall call) handler,
  ) {
    _handlers[method] = handler;
    if (!_installed) {
      _installed = true;
      _channel.setMethodCallHandler((MethodCall call) async {
        final Future<dynamic> Function(MethodCall call)? h =
            _handlers[call.method];
        if (h == null) return null;
        return h(call);
      });
    }
  }

  static void off(String method) => _handlers.remove(method);

  static Future<T?> _call<T>(String method, [Object? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  // ---- 기기 정보 ----

  static Future<DeviceInfo> deviceInfo() async {
    final Map<Object?, Object?> m =
        await _call<Map<Object?, Object?>>('deviceInfo') ??
        <Object?, Object?>{};
    return DeviceInfo(
      sdkInt: (m['sdkInt'] as int?) ?? 0,
      model: (m['model'] as String?) ?? '',
      release: (m['release'] as String?) ?? '',
      language: (m['language'] as String?) ?? '',
      versionName: (m['versionName'] as String?) ?? '',
    );
  }

  /// 시작 인텐트에 실려 온 `push_url`(푸시 알림으로 열린 경우).
  static Future<String?> takeLaunchPushUrl() =>
      _call<String>('takeLaunchPushUrl');

  /// `U()`: 와이파이 또는 모바일 데이터로 연결되어 있는지.
  static Future<bool> isNetworkConnected() async =>
      await _call<bool>('isNetworkConnected') ?? false;

  // ---- 권한 ----

  static Future<bool> checkPermissions(List<String> permissions) async =>
      await _call<bool>('checkPermissions', permissions) ?? false;

  /// 결과는 [권한, 결과코드(0=허용)] 쌍의 목록. 요청이 중단되면 빈 목록.
  static Future<List<PermissionResult>> requestPermissions(
    List<String> permissions,
  ) async {
    final List<Object?> raw =
        await _call<List<Object?>>('requestPermissions', permissions) ??
        <Object?>[];
    return raw.map((Object? e) {
      final Map<Object?, Object?> m = e! as Map<Object?, Object?>;
      return PermissionResult(m['permission']! as String, m['result']! as int);
    }).toList();
  }

  /// IntroActivity `o0()`의 권한 안내 대화상자(시스템 AlertDialog).
  static Future<void> showPermissionSettingsDialog(String labels) =>
      _call<void>('showPermissionSettingsDialog', labels);

  // ---- 화면/앱 ----

  static Future<void> toast(String text, {bool long = false}) =>
      _call<void>('toast', <String, Object>{'text': text, 'long': long});

  /// `finish()`.
  static Future<void> finishActivity() => _call<void>('finishActivity');

  /// `finishAffinity()` (function: exit).
  static Future<void> finishAffinity() => _call<void>('finishAffinity');

  /// `d0()`: finish + System.exit(0) + killProcess.
  static Future<void> exitProcess() => _call<void>('exitProcess');

  /// 외부 앱으로 `ACTION_VIEW`.
  static Future<void> startView(String url) => _call<void>('startView', url);

  /// 패키지 이름으로 앱 실행. 실행했으면 true.
  static Future<bool> launchPackage(String packageName) async =>
      await _call<bool>('launchPackage', packageName) ?? false;

  /// 루팅 확인 후 루팅이면 원본과 같은 시스템 대화상자를 띄운다.
  static Future<void> checkRooting() => _call<void>('checkRooting');

  // ---- 웹뷰 ----

  /// webview_flutter가 만든 네이티브 WebView에 원본과 같은 설정, `allytteAndroid` 객체,
  /// 링크 처리, 다운로드, `window.open` 처리를 붙인다.
  static Future<void> installWebView(int webViewId, String kind) => _call<void>(
    'installWebView',
    <String, Object>{'id': webViewId, 'kind': kind},
  );

  /// `window.open`으로 요청된 창(token)에 새 WebView를 연결한다.
  static Future<void> attachWindow(int token, int webViewId) => _call<void>(
    'attachWindow',
    <String, Object>{'token': token, 'id': webViewId},
  );

  static Future<void> destroyWebView(int webViewId) =>
      _call<void>('destroyWebView', webViewId);

  /// 네이티브 WebView에 `loadUrl(url, extraHeaders)`. 주소 문자열을 그대로 넘긴다.
  static Future<void> loadUrl(
    int webViewId,
    String url,
    Map<String, String> headers,
  ) => _call<void>('loadUrl', <String, Object>{
    'id': webViewId,
    'url': url,
    'headers': headers,
  });

  /// 네이티브 WebView에 `loadUrl("javascript:...")`.
  static Future<void> loadJavascriptUrl(int webViewId, String script) =>
      _call<void>('loadJavascriptUrl', <String, Object>{
        'id': webViewId,
        'script': script,
      });

  // ---- 기기 기능 ----

  /// 'none'(NFC 없음), 'disabled', 'enabled'
  static Future<String> nfcState() async =>
      await _call<String>('nfcState') ?? 'none';

  /// 메인 화면이 앞에 있는 동안만 NFC foreground dispatch를 켠다.
  static Future<void> setMainActive(bool active) =>
      _call<void>('setMainActive', active);

  /// `W0()`: 위치를 읽어 원본과 같은 형식으로 붙인 주소. 형식 오류 등으로 실패하면 null.
  static Future<String?> gpsUrl(String url) => _call<String>('gpsUrl', url);

  static Future<void> beaconStart() => _call<void>('beaconStart');

  /// 지금까지 찾은 비콘(id1, id2, id3 문자열)을 돌려주고 검색을 멈춘다.
  static Future<List<List<String>>> beaconStop() async {
    final List<Object?> raw =
        await _call<List<Object?>>('beaconStop') ?? <Object?>[];
    return raw
        .map(
          (Object? e) =>
              (e! as List<Object?>).map((Object? s) => s! as String).toList(),
        )
        .toList();
  }
}

class DeviceInfo {
  const DeviceInfo({
    required this.sdkInt,
    required this.model,
    required this.release,
    required this.language,
    required this.versionName,
  });

  final int sdkInt;
  final String model;
  final String release;
  final String language;
  final String versionName;
}

class PermissionResult {
  const PermissionResult(this.permission, this.result);
  final String permission;
  final int result;
}
