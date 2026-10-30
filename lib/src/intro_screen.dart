import 'dart:async';

import 'package:flutter/material.dart';

import 'allytte_http.dart';
import 'connection_notice.dart';
import 'device_prefs.dart';
import 'legacy_json.dart';
import 'legacy_widgets.dart';
import 'native_bridge.dart';
import 'school_url.dart';
import 'uuid.dart';

/// 원본 `IntroActivity`(HANDOFF 5.2): (저장된 시작 이미지 내려받기) → 기기 등록.
///
/// 기기 등록 응답 문자열을 [onFinished]로 넘긴다. 원본은 이 값을 `screen_info`로
/// MainActivity에 넘기고 자신은 끝낸다.
///
/// 원본은 등록에 실패해도(응답이 null) 그대로 메인으로 넘어가 빈 화면과 `*` 버튼만 보였고,
/// 응답을 끝없이 기다렸다. 개선판은 [registerTimeout] 안에 화면 설정을 받지 못하면 여기서
/// 한글 안내와 다시 시도 버튼을 보인다(통합본 1-9, 1-10).
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key, this.pushUrl, required this.onFinished});

  /// 기기 등록 요청 전체(연결부터 응답 끝까지)의 시간 제한.
  static const Duration registerTimeout = Duration(seconds: 10);

  /// 기기 등록 응답이 메인 화면을 구성할 명령 목록(`{"action":[…]}`)인지.
  static bool isScreenInfo(String? response) {
    if (response == null || response.isEmpty) return false;
    try {
      JObj.parse(response).getJSONArray('action');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 기기 등록 주소. [pushUrl]은 Kotlin `pushUrlOf`가 `https://mobile.ut.ac.kr` 주소만 넘기지만,
  /// 거기서는 Android `Uri`로 읽고 연결은 Dart `Uri`로 하므로 같은 파서로 다시 본다. 학교
  /// 주소([isSchoolUrl])가 아니면 기본 등록 주소를 쓴다.
  static String registerUrl(String? pushUrl, String query) =>
      pushUrl != null && isSchoolUrl(pushUrl)
      ? pushUrl
      : 'https://mobile.ut.ac.kr//service/api/device/save$query';

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
  bool _registering = false;
  ConnectionProblem? _problem;

  @override
  void initState() {
    super.initState();
    _start();
  }

  /// 원본은 여기서 권한 6개를 한꺼번에 요청하고, 하나라도 거부하면 설정 화면으로 보내고 끝냈다.
  /// 개선판은 시작할 때 권한을 묻지 않고, 기능을 쓸 때 그 권한만 요청한다(통합본 1-1).
  Future<void> _start() async {
    _prefs = await DevicePrefs.instance();
    _info = await NativeBridge.deviceInfo();
    // 시작 이미지는 화면에 쓰이지 않으므로(HANDOFF 5.2) 기다리지 않고 뒤에서 받는다.
    final String splashUrl = _prefs.splashUrl;
    if (splashUrl.isNotEmpty) unawaited(downloadSplash(splashUrl));
    await _register();
  }

  /// `l0()`: 기기 토큰을 준비하고 기기 등록 주소(또는 push_url)로 POST한다.
  Future<void> _register() async {
    if (_registering || _finished || !mounted) return;
    setState(() {
      _registering = true;
      _problem = null;
    });
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
    final String url = IntroScreen.registerUrl(widget.pushUrl, query);
    final Stopwatch watch = Stopwatch()..start();
    final String? response = await allyttePost(
      url,
      _info.versionName,
      token,
      timeout: IntroScreen.registerTimeout,
    );
    if (_finished || !mounted) return;
    if (!IntroScreen.isScreenInfo(response)) {
      final bool online = await NativeBridge.isNetworkConnected();
      if (!mounted) return;
      setState(() {
        _registering = false;
        _problem = !online
            ? ConnectionProblem.offline
            : watch.elapsed >= IntroScreen.registerTimeout
            ? ConnectionProblem.slow
            : ConnectionProblem.failed;
      });
      return;
    }
    _finished = true;
    widget.onFinished(response);
  }

  @override
  Widget build(BuildContext context) {
    // 원본 배경 그림(drawable 0x7f0700f2)은 해상도별 split APK에만 있어 아직 없다(HANDOFF 5.2).
    // iv_intro 이미지뷰는 gone이라 실제로 보이는 것은 배경뿐이다. 개선판은 등록하는 동안 로딩
    // 표시를, 실패하면 연결 안내를 보인다.
    final ConnectionProblem? problem = _problem;
    return ColoredBox(
      color: windowBackground,
      child: SafeArea(
        child: SizedBox.expand(
          child: ColoredBox(
            color: Colors.white,
            child: problem != null
                ? ConnectionNotice(problem: problem, onRetry: _register)
                : _registering
                ? const Center(child: LoadingSpinner())
                : null,
          ),
        ),
      ),
    );
  }
}
