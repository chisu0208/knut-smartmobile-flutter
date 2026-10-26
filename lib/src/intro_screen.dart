import 'package:flutter/material.dart';

import 'allytte_http.dart';
import 'device_prefs.dart';
import 'legacy_widgets.dart';
import 'native_bridge.dart';
import 'uuid.dart';

/// 원본 `IntroActivity`(HANDOFF 5.2): 권한 요청 → (저장된 시작 이미지 내려받기) → 기기 등록.
///
/// 기기 등록 응답 문자열(실패면 null)을 [onFinished]로 넘긴다. 원본은 이 값을
/// `screen_info`로 MainActivity에 넘기고 자신은 끝낸다.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key, this.pushUrl, required this.onFinished});

  /// 푸시 알림으로 열린 경우의 `push_url`. 있으면 기기 등록 주소 대신 이 주소로 POST한다.
  final String? pushUrl;
  final void Function(String? screenInfo) onFinished;

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  late final DevicePrefs _prefs;
  late final DeviceInfo _info;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    _prefs = await DevicePrefs.instance();
    _info = await NativeBridge.deviceInfo();
    await _checkPermissions();
  }

  /// `n0()`
  Future<void> _checkPermissions() async {
    final List<String> permissions;
    if (_info.sdkInt >= 33) {
      permissions = const <String>[
        'android.permission.READ_PHONE_NUMBERS',
        'android.permission.CALL_PHONE',
        'android.permission.CAMERA',
        'android.permission.ACCESS_COARSE_LOCATION',
        'android.permission.POST_NOTIFICATIONS',
        'android.permission.NEARBY_WIFI_DEVICES',
      ];
    } else if (_info.sdkInt >= 30) {
      permissions = const <String>[
        'android.permission.READ_PHONE_NUMBERS',
        'android.permission.WRITE_EXTERNAL_STORAGE',
        'android.permission.READ_EXTERNAL_STORAGE',
        'android.permission.CALL_PHONE',
        'android.permission.CAMERA',
        'android.permission.ACCESS_COARSE_LOCATION',
      ];
    } else {
      permissions = const <String>[
        'android.permission.READ_PHONE_STATE',
        'android.permission.WRITE_EXTERNAL_STORAGE',
        'android.permission.READ_EXTERNAL_STORAGE',
        'android.permission.CALL_PHONE',
        'android.permission.CAMERA',
        'android.permission.ACCESS_COARSE_LOCATION',
      ];
    }
    if (!await NativeBridge.checkPermissions(permissions)) {
      _onPermissionResult(await NativeBridge.requestPermissions(permissions));
      return;
    }
    final String splashUrl = _prefs.splashUrl;
    if (splashUrl.isNotEmpty) {
      await downloadSplash(splashUrl);
    }
    await _register();
  }

  /// `onRequestPermissionsResult`
  void _onPermissionResult(List<PermissionResult> results) {
    if (results.isEmpty) return;
    String denied = '';
    for (final PermissionResult r in results) {
      if (r.result == 0) continue;
      final String label = _permissionLabel(r.permission);
      if (!denied.contains(label)) denied = '$denied,$label';
    }
    if (denied.isEmpty) {
      // 이 경로에서는 시작 이미지를 내려받지 않는다(원본 그대로).
      _register();
      return;
    }
    NativeBridge.toast('권한이 거부되었습니다. 해당권한을 허용하셔야 합니다.');
    if (_info.sdkInt >= 29) {
      NativeBridge.showPermissionSettingsDialog(denied.substring(1));
    } else {
      NativeBridge.finishActivity();
    }
  }

  /// 권한 이름에 들어 있는 단어로 고른 안내 이름(원본은 `indexOf(...) > 0`으로 차례대로 검사).
  static String _permissionLabel(String permission) {
    if (permission.indexOf('PHONE') > 0) return '전화';
    if (permission.indexOf('MEDIA') > 0) return '사진및동영상,카메라';
    if (permission.indexOf('CAMERA') > 0) return '카메라';
    if (permission.indexOf('ACCESS') > 0) return '위치';
    if (permission.indexOf('NOTIFICATION') > 0) return '알림';
    if (permission.indexOf('NEARBY') > 0) return '근처기기';
    return permission.indexOf('STORAGE') > 0 ? '파일및미디어' : '기타';
  }

  /// `l0()`: 기기 토큰을 준비하고 기기 등록 주소(또는 push_url)로 POST한다.
  Future<void> _register() async {
    String token = _prefs.deviceToken;
    if (token.isEmpty) {
      token = randomUuid().toUpperCase();
      _prefs.deviceToken = token;
    }
    // 순서·값 그대로: osVersion에 SDK 번호, osName에 버전 문자열, 슬래시 두 개.
    final String query =
        '?devicePlatform=android&modelName=${_info.model}&deviceToken=$token'
        '&osVersion=${_info.sdkInt}&osLang=${_info.language}&osName=${_info.release}'
        '&appVersion=${_info.versionName}&pushToken=${_prefs.pushToken}&siteId=0';
    final String url =
        widget.pushUrl ??
        'https://mobile.ut.ac.kr//service/api/device/save$query';
    final String? response = await allyttePost(url, _info.versionName, token);
    if (_finished || !mounted) return;
    _finished = true;
    widget.onFinished(response);
  }

  @override
  Widget build(BuildContext context) {
    // 원본 배경 그림(drawable 0x7f0700f2)은 해상도별 split APK에만 있어 아직 없다(HANDOFF 5.2).
    // iv_intro 이미지뷰는 gone이라 실제로 보이는 것은 배경뿐이다.
    return const ColoredBox(
      color: windowBackground,
      child: SafeArea(
        child: SizedBox.expand(child: ColoredBox(color: Colors.white)),
      ),
    );
  }
}
