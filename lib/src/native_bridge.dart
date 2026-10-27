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

  static const String camera = 'android.permission.CAMERA';
  static const String fineLocation = 'android.permission.ACCESS_FINE_LOCATION';
  static const String coarseLocation =
      'android.permission.ACCESS_COARSE_LOCATION';

  /// 근처 기기 검색(Android 12 이상, 비콘).
  static const String bluetoothScan = 'android.permission.BLUETOOTH_SCAN';

  /// 모두 허용돼 있으면 true.
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

  /// 거부한 뒤에도 시스템이 다시 물어볼 수 있는지(`shouldShowRequestPermissionRationale`).
  static Future<bool> shouldShowRationale(String permission) async =>
      await _call<bool>('shouldShowRationale', permission) ?? false;

  /// 앱 설정 화면으로 갈 수 있는 안내 대화상자(`설정 열기`/`닫기`). 앱은 계속 쓴다.
  static Future<void> showPermissionSettings(String message) =>
      _call<void>('showPermissionSettings', message);

  /// 기능을 쓸 때 그 기능의 권한만 요청한다(통합본 1-1). [permissions] 가운데 하나라도
  /// 허용되면 true. 원본은 첫 실행에 권한 6개를 한꺼번에 묻고, 하나라도 거부하면 앱을 쓸 수
  /// 없게 설정 화면으로 보냈다.
  ///
  /// 거부하면 [deniedMessage]를 토스트로 보이고 false. 다시 물을 수 없는 상태(다시 묻지 않음,
  /// 두 번 거부)면 [settingsMessage]로 설정 화면 안내를 띄운다. 어느 쪽이든 나머지 기능은 그대로다.
  static Future<bool> requestFeaturePermission(
    List<String> permissions, {
    required String deniedMessage,
    required String settingsMessage,
  }) async {
    for (final String permission in permissions) {
      if (await checkPermissions(<String>[permission])) return true;
    }
    final List<PermissionResult> results = await requestPermissions(
      permissions,
    );
    if (results.any((PermissionResult r) => r.result == 0)) return true;
    if (results.isEmpty) return false; // 요청이 중단됨
    if (await shouldShowRationale(permissions.first)) {
      await toast(deniedMessage, long: true);
    } else {
      await showPermissionSettings(settingsMessage);
    }
    return false;
  }

  // ---- 화면/앱 ----

  static Future<void> toast(String text, {bool long = false}) =>
      _call<void>('toast', <String, Object>{'text': text, 'long': long});

  /// `finishAffinity()` (function: exit).
  static Future<void> finishAffinity() => _call<void>('finishAffinity');

  /// `d0()`: finish + System.exit(0) + killProcess.
  static Future<void> exitProcess() => _call<void>('exitProcess');

  /// 외부 앱으로 `ACTION_VIEW`.
  static Future<void> startView(String url) => _call<void>('startView', url);

  /// 패키지 이름으로 앱 실행. 실행했으면 true.
  static Future<bool> launchPackage(String packageName) async =>
      await _call<bool>('launchPackage', packageName) ?? false;

  /// 루팅 확인 후 루팅이면 한 번만 안내한다(통합본 1-2). 원본은 앱을 쓸 수 없게 막았다.
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

  /// `WebView.clearHistory()`: 지금 페이지만 남기고 뒤로·앞으로 기록을 지운다.
  static Future<void> clearHistory(int webViewId) =>
      _call<void>('clearHistory', webViewId);

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
  /// 위치 권한이 없으면 원본처럼 0으로 채운다(권한 요청은 Dart가 먼저 한다).
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
