import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'allytte_http.dart';
import 'android_color.dart';
import 'app_colors.dart';
import 'connection_notice.dart';
import 'device_prefs.dart';
import 'intro_screen.dart';
import 'legacy_json.dart';
import 'legacy_widgets.dart';
import 'native_bridge.dart';
import 'popup_animation.dart';
import 'qr_scan_screen.dart';
import 'uuid.dart';
import 'web_entry.dart';

const Color _white = Color(0xFFFFFFFF);
const Color _black = Color(0xFF000000);
const Color _transparent = Color(0x00000000);

/// 원본 `MainActivity`. 메서드 이름 옆 주석은 원본(jadx) 이름이다.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.screenInfo});

  /// IntroActivity가 넘긴 기기 등록 응답(`screen_info`).
  final String? screenInfo;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

/// 헤더 메뉴 칸(LinearLayout) 하나.
class _MenuSlot {
  bool visible = true;
  List<_MenuButton> items = <_MenuButton>[];
}

/// `E0()`가 만든 버튼과, 아이콘이 있으면 감싸는 `d1()` 정사각형 칸(px).
class _MenuButton {
  _MenuButton(this.loc);

  final String loc;
  String? text;
  Color textColor = const Color(0xDE000000);
  ButtonBackground background = const DefaultButtonBackground();
  EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10);
  VoidCallback? onTap;

  /// `d1(px, px, button)`로 감쌀 때의 칸 크기(px). null이면 버튼만.
  int? boxPx;
}

/// 원본 Dialog `f7832t`(alert, dialog, nfc 대화상자).
class _AppDialog {
  _AppDialog(this.build);
  final Widget Function() build;
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin
    implements FullscreenHost {
  late DevicePrefs _prefs;
  late DeviceInfo _info;
  String _deviceToken = ''; // f7834v
  bool _ready = false;

  // ---- 화면 크기 ----
  double _dpr = 1;
  int _screenWidthPx = 0; // f7733q0 (Display.getSize)
  int _screenHeightPx = 0; // f7734r0
  int _menuBoxPx = 100; // f7680G
  int _footerBoxPx = 110; // f7682H

  // ---- 웹뷰 ----
  WebEntry? _main; // f7692M
  WebEntry? _popup; // f7714X
  WebEntry? _child; // f7715Y
  WebEntry? _grandchild; // f7716Z
  final List<WebEntry> _frame = <WebEntry>[]; // webview_frame(f7668Y0)의 자식 순서

  // ---- 상태 값 ----
  bool _popupShown = false; // f7670B
  String? _popupAlign; // f7672C
  bool _mainOwner = true; // f7676E
  bool _childOpen = false; // f7717a0
  bool _grandchildOpen = false; // f7718b0
  String? _nfcUrl; // f7722f0
  String? _resultUrl; // f7723g0 (QR·비콘 결과 전송 주소)
  int _backPressedAt = 0; // f7709U0
  JArr? _beaconUuids; // f7711V0
  ui.Image? _sharedBitmap; // f7721e0 (아이콘·헤더 배경이 함께 쓰는 필드)

  // ---- 메인 헤더·본문·푸터 ----
  bool _headerVisible = true;
  final GradientBox _headerBox = GradientBox(color: _white); // f7741y0
  bool _headerHasBitmap = false; // g1()로 배경이 BitmapDrawable로 바뀌었는지
  ui.Image? _headerBitmap;
  final _MenuSlot _left = _MenuSlot();
  final _MenuSlot _center = _MenuSlot();
  final _MenuSlot _right = _MenuSlot();
  bool _footerVisible = true; // main_footer + line_footer
  final GradientBox _footerBox = GradientBox(color: _white); // f7742z0
  List<_MenuButton>? _footerItems; // null이면 레이아웃의 "*" 버튼

  // ---- 팝업 ----
  bool _bgVisible = false; // popup_bg_container
  Alignment _bgGravity = Alignment.topRight; // XML gravity="right"
  int? _popupWidthPx; // null = match_parent
  int? _popupHeightPx; // null = match_parent, -2 = wrap_content
  late final AnimTrack _bgTrack = AnimTrack(_animationListener);
  late final AnimTrack _bodyTrack = AnimTrack(_animationListener);
  late final Ticker _ticker = createTicker(_onTick);
  bool _popupHeaderVisible = false;
  final GradientBox _popupHeaderBox = GradientBox(
    color: _white,
    radius: cornerRadii(tl: 30, tr: 30),
  ); // f7677E0
  bool _subHeadVisible = true;
  bool _subHead2Visible = true;
  bool _subCenterTitleBackground = true;
  final _MenuSlot _popupLeft = _MenuSlot();
  final _MenuSlot _popupCenter = _MenuSlot();
  final _MenuSlot _popupRight = _MenuSlot();
  double _popupBodyPaddingTop = 0;
  bool _popupFooterVisible = false;
  final GradientBox _popupFooterBox = GradientBox(
    color: _white,
    radius: cornerRadii(tl: 30, tr: 30),
  ); // f7681G0
  List<_MenuButton> _popupFooterItems = <_MenuButton>[];

  // ---- 대화상자 ----
  _AppDialog? _dialog; // f7832t

  // ---- 동영상 전체 화면(통합본 6-11) ----
  Widget? _customView;
  VoidCallback? _exitCustomView;

  // ---- 명령 처리 ----
  Future<void> _queue = Future<void>.value();

  @override
  void initState() {
    super.initState();
    NativeBridge.on(
      'jsCommand',
      (MethodCall call) async =>
          _enqueue(call.arguments as String?, fromBridge: true),
    );
    NativeBridge.on('createWindow', (MethodCall call) async {
      final Map<Object?, Object?> args =
          call.arguments as Map<Object?, Object?>;
      await _createWindow(args['parent']! as String, args['token']! as int);
    });
    NativeBridge.on(
      'closeWindow',
      (MethodCall call) async => _closeWindow(call.arguments as String),
    );
    NativeBridge.on(
      'webEvent',
      (MethodCall call) async =>
          WebEntry.handleNativeEvent(call.arguments as Map<Object?, Object?>),
    );
    NativeBridge.on(
      'nfcTag',
      (MethodCall call) async => _onNfcTag(call.arguments as String),
    );
    NativeBridge.on(
      'relaunchIntro',
      (MethodCall call) async => _relaunchIntro(call.arguments as String?),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_screenWidthPx != 0) return;
    final MediaQueryData mq = MediaQuery.of(context);
    _dpr = mq.devicePixelRatio;
    // Display.getSize: 상태 표시줄과 내비게이션 바를 뺀 앱 영역
    _screenWidthPx = (mq.size.width * _dpr).round();
    _screenHeightPx =
        ((mq.size.height - mq.viewPadding.top - mq.viewPadding.bottom) * _dpr)
            .round();
    // V0(): 화면 높이(dp)가 750 이상이면 메뉴 칸을 작게
    if ((_screenHeightPx / _dpr).truncate() >= 750) {
      _menuBoxPx = 80;
      _footerBoxPx = 90;
    }
    _onCreate();
  }

  /// `onCreate()`
  Future<void> _onCreate() async {
    _prefs = await DevicePrefs.instance();
    _info = await NativeBridge.deviceInfo();
    _prefs.webview = 'main';
    _main = await WebEntry.create(
      'main',
      onChanged: _refresh,
      fullscreen: this,
    );
    if (!mounted) return;
    setState(() => _ready = true);
    if (await NativeBridge.nfcState() == 'none') {
      NativeBridge.toast('NFC를 지원하지 않는 단말기입니다.');
    }
    await NativeBridge.setMainActive(true);
    // Y0(screen_info)
    _loadTokens();
    await _enqueue(widget.screenInfo, fromBridge: false);
    await NativeBridge.checkRooting();
  }

  @override
  void dispose() {
    for (final String m in <String>[
      'jsCommand',
      'createWindow',
      'closeWindow',
      'webEvent',
      'nfcTag',
      'relaunchIntro',
    ]) {
      NativeBridge.off(m);
    }
    _ticker.dispose();
    super.dispose();
  }

  /// `P()` + `Y0()`의 토큰 준비.
  void _loadTokens() {
    _deviceToken = _prefs.deviceToken;
    if (_deviceToken.isEmpty) {
      _deviceToken = randomUuid().toUpperCase();
      _prefs.deviceToken = _deviceToken;
    }
  }

  Map<String, String> get _extraHeaders => <String, String>{
    'User-Agent': 'allytte ${_info.versionName}',
    'allytte-device-token': _deviceToken,
    'allytte-device-platform': 'android',
  };

  // ======================================================================
  // 명령 처리기 x0
  // ======================================================================

  /// 밖에서 들어온 명령을 차례대로 처리한다. 원본에서 UI 스레드는 한 번에 하나만 처리하고,
  /// 아이콘을 내려받는 동안에도 멈춰 있으므로 같은 순서를 지키도록 줄을 세운다.
  Future<void> _enqueue(String? json, {required bool fromBridge}) {
    final Future<void> next = _queue.then(
      (_) => _x0(json, fromBridge: fromBridge),
    );
    _queue = next.catchError((Object _) {});
    return _queue;
  }

  /// `x0(json)`. [fromBridge]는 웹 페이지(JavaBridge 스레드)에서 불렸는지.
  ///
  /// 원본에서 `runOnUiThread`로 넘기는 작업(메인·팝업 구성, 팝업 닫기, NFC 확인)은 UI 스레드에서
  /// 불리면 바로 실행되고, JavaBridge 스레드에서 불리면 x0이 끝난 뒤 실행된다.
  Future<void> _x0(String? json, {required bool fromBridge}) async {
    final List<Future<void> Function()> posted = <Future<void> Function()>[];
    Future<void> runOnUi(Future<void> Function() op) async {
      if (fromBridge) {
        posted.add(op);
      } else {
        await op();
      }
    }

    await _dispatch(json, runOnUi, fromBridge: fromBridge);
    for (final Future<void> Function() op in posted) {
      await op();
    }
  }

  Future<void> _dispatch(
    String? json,
    Future<void> Function(Future<void> Function() op) runOnUi, {
    bool fromBridge = false,
  }) async {
    if (json == null || json.isEmpty) return;
    final String source = json
        .replaceAll('https://www.allytte.com', 'https://mobile.ut.ac.kr/')
        .replaceAll('http://allytte.com', 'https://mobile.ut.ac.kr/');
    try {
      final JArr actions = JObj.parse(source).getJSONArray('action');
      for (int i = 0; i < actions.length; i++) {
        final JObj action = actions.getJSONObject(i);
        switch (action.getString('command')) {
          case 'webview':
            switch (action.getJSONObject('config').getString('show')) {
              case 'main':
                await runOnUi(() => _configureMain(action)); // M0
                _prefs.webview = 'main';
              case 'popup':
                await runOnUi(() => _configurePopup(action)); // N0
                _prefs.webview = 'popup';
              case 'change':
                _b0(action.getJSONObject('config').getString('url'));
            }
          case 'alert':
            _c0(action);
          case 'dialog':
            await _g0(action);
          case 'function':
            switch (action.getJSONObject('config').getString('function')) {
              case 'qrcode':
                _f1(action);
              case 'gps':
                await _w0(action);
              case 'nfc':
                await _h1(action, runOnUi);
              case 'beacone':
                _e1(action);
              case 'back':
                // 원본은 JavaBridge 스레드에서 WebView.canGoBack()을 불러 예외가 나므로
                // 웹 페이지가 보낸 back은 아무것도 하지 않고 남은 명령도 버려진다.
                if (fromBridge) {
                  throw StateError('WebView called on JavaBridge thread');
                }
                await _y0();
              case 'close':
                await _a0(runOnUi);
              case 'exit':
                NativeBridge.finishAffinity();
              case 'url':
                _m1(action);
            }
          case 'browser':
            await _d0(action, runOnUi);
          case 'app':
            await _k1(action);
          case 'data':
            _f0(action);
        }
        _refresh();
      }
    } catch (_) {
      // 원본도 예외를 기록만 하고 남은 명령을 버린다.
    }
    _refresh();
  }

  /// UI 스레드에서 x0을 다시 부르는 경우(버튼, POST 응답, `Q0`).
  Future<void> _x0Inline(String json) =>
      _dispatch(json, (Future<void> Function() op) => op());

  void _refresh() {
    if (!mounted) return;
    setState(() {});
    // 숨어 있던 동안 멈춘 애니메이션은 다시 그려질 때 이어서 시간이 흐른다.
    if (_bgDrawn &&
        (_bgTrack.running || _bodyTrack.running) &&
        !_ticker.isActive) {
      _ticker.start();
    }
  }

  /// `Q0(message)`: 알림 명령을 만들어 처리기에 넣는다(따옴표 처리 없이 그대로 끼워 넣음).
  Future<void> _q0(String message) => _x0Inline(
    '{"action":[{"command":"alert","config":{"message":"$message"}}]}',
  );

  /// `O0(url)`: POST 후 응답을 다시 처리기에 넣는다(응답은 UI 스레드에서 처리).
  void _post(String url) {
    allyttePost(url, _info.versionName, _deviceToken).then((String? result) {
      if (mounted) _enqueue(result, fromBridge: false);
    });
  }

  // ======================================================================
  // 메인 화면 구성 (클래스 w)
  // ======================================================================

  Future<void> _configureMain(JObj action) async {
    _mainOwner = true;
    if (_popupShown) await _a0((Future<void> Function() op) => op());
    _bgTrack.clear();
    try {
      final JObj config = action.getJSONObject('config');
      config.getString('show');
      config.getString('align');
      final String url = config.getString('url');
      // 흔들기 설정(config.setting.gesture)은 흔들기를 없애서 읽지 않는다(통합본 6-5~6-7).
      if (config.isNull('header')) {
        _headerVisible = false;
      } else {
        _headerVisible = true;
        final JObj header = config.getJSONObject('header');
        final String bgImage = header.getString('bgImage');
        final String bgColor = header.getString('bgColor');
        final String border = header.getString('border');
        _headerBox.color = _backgroundColor(bgColor);
        if (bgImage != 'null') await _g1(bgImage);
        _applyStroke(_headerBox, border);
        final JObj menu = header.getJSONObject('menu');
        for (final (String side, _MenuSlot slot) in <(String, _MenuSlot)>[
          ('left', _left),
          ('center', _center),
          ('right', _right),
        ]) {
          if (menu.isNull(side)) {
            slot.visible = false;
          } else {
            slot.visible = true;
            slot.items = <_MenuButton>[];
            // 원본은 getJSONObject 뒤에 instanceof를 검사해서 배열이면 여기서 예외로
            // 나머지 구성(푸터, 주소 불러오기)이 모두 중단된다.
            final JObj item = menu.getJSONObject(side);
            slot.items = await _j0(item, 'main_$side');
          }
        }
      }
      if (config.isNull('footer')) {
        _footerVisible = false;
      } else {
        _footerVisible = true;
        await _h0(config.getJSONObject('footer'));
      }
      _b0(url, clearHistory: true);
    } catch (_) {}
    _refresh();
  }

  Color _backgroundColor(String bgColor) {
    if (bgColor == 'null') return _white;
    if (bgColor == 'transparent') return _transparent;
    return parseAndroidColor(bgColor);
  }

  /// `setStroke(N(dp), #000000)` 또는 `setStroke(0, #ffffff)`.
  void _applyStroke(GradientBox box, String border) {
    if (border == 'null') {
      box.setStroke(0, _white);
    } else {
      box.setStroke(_dpToPx(javaParseInt(border)) / _dpr, _black);
    }
  }

  /// `N(context, dp)`: (int) dp 변환.
  int _dpToPx(int dp) => (dp * _dpr).truncate();

  /// `H0(footer)`: 메인 푸터.
  Future<void> _h0(JObj footer) async {
    _mainOwner = false; // 원본 그대로: 푸터를 만들면 뒤로가기 주인이 팝업 쪽으로 바뀐다.
    try {
      _footerItems = <_MenuButton>[];
      final String bgImage = footer.getString('bgImage');
      final String bgColor = footer.getString('bgColor');
      final String border = footer.getString('border');
      final JArr menu = footer.getJSONArray('menu');
      _footerBox.color = _backgroundColor(bgColor);
      if (bgImage != 'null') await _g1(bgImage);
      _applyStroke(_footerBox, border);
      for (int i = 0; i < menu.length; i++) {
        _footerItems!.add(
          await _e0('main', menu.getJSONObject(i))
            ..boxPx = _footerBoxPx,
        );
      }
    } catch (_) {}
  }

  /// `L0(footer)`: 팝업 푸터.
  Future<void> _l0(JObj footer) async {
    try {
      _popupFooterItems = <_MenuButton>[];
      final String bgImage = footer.getString('bgImage');
      final String bgColor = footer.getString('bgColor');
      final String border = footer.getString('border');
      final JArr menu = footer.getJSONArray('menu');
      _popupFooterBox.color = _backgroundColor(bgColor);
      // 원본 그대로: 팝업 푸터 배경 이미지도 메인 헤더 배경으로 간다.
      if (bgImage != 'null') await _g1(bgImage);
      _applyStroke(_popupFooterBox, border);
      for (int i = 0; i < menu.length; i++) {
        _popupFooterItems.add(
          await _e0('popup', menu.getJSONObject(i))
            ..boxPx = _footerBoxPx,
        );
      }
    } catch (_) {}
  }

  /// `I0(layout, array, loc)`
  Future<List<_MenuButton>> _i0(JArr array, String loc) async {
    final List<_MenuButton> items = <_MenuButton>[];
    for (int i = 0; i < array.length; i++) {
      items.addAll(await _j0(array.getJSONObject(i), loc));
    }
    return items;
  }

  /// `J0(layout, object, loc)`: 아이콘이 있으면 `f7680G` px 칸에 넣는다.
  Future<List<_MenuButton>> _j0(JObj json, String loc) async {
    final String icon = !json.isNull('icon') ? json.getString('icon') : 'null';
    final _MenuButton button = await _e0(loc, json);
    if (icon != 'null') button.boxPx = _menuBoxPx;
    return <_MenuButton>[button];
  }

  /// `E0(loc, json)`: 버튼 하나. 중간에 예외가 나면 그때까지 설정한 버튼을 그대로 쓴다.
  Future<_MenuButton> _e0(String loc, JObj json) async {
    final _MenuButton button = _MenuButton(loc);
    try {
      final String icon = !json.isNull('icon')
          ? json.getString('icon')
          : 'null';
      final String name = !json.isNull('name')
          ? json.getString('name')
          : 'null';
      final String align = !json.isNull('align')
          ? json.getString('align')
          : 'null';
      final String color = !json.isNull('color')
          ? json.getString('color')
          : 'null';
      if (icon == 'null') {
        button.background = const TransparentButtonBackground();
      } else {
        switch (align) {
          case 'null':
            button.background = ImageButtonBackground(await _p0(icon));
          // setCompoundDrawables에 크기 없는 그림을 넘겨서 아이콘은 보이지 않고 여백만 생긴다.
          case 'left':
            await _p0(icon);
            button.padding = EdgeInsets.only(left: _dpToPx(30) / _dpr);
          case 'top':
            await _p0(icon);
            button.padding = EdgeInsets.only(top: _dpToPx(30) / _dpr);
          case 'right':
            await _p0(icon);
            button.padding = EdgeInsets.only(right: _dpToPx(30) / _dpr);
          case 'bottom':
            await _p0(icon);
            button.padding = EdgeInsets.only(bottom: _dpToPx(30) / _dpr);
        }
      }
      if (name != 'null') button.text = name;
      if (color != 'null') {
        button.textColor = parseAndroidColor(color);
      } else if (loc == 'popup_full') {
        button.textColor = _white;
      } else {
        button.textColor = _black;
      }
      if (!json.isNull('action')) {
        json.getJSONArray('action').getJSONObject(0);
        final String command = json.toString();
        // 원본은 x0을 끝까지 처리한 뒤 대화상자를 닫는다. 그래서 버튼 명령이 새 대화상자를
        // 띄우면 그 새 대화상자가 닫힌다(그대로 따름).
        button.onTap = () {
          _enqueue(command, fromBridge: false).then((_) {
            if (loc == 'dialog') _cancelDialog();
          });
        };
      }
    } catch (_) {}
    return button;
  }

  /// `P0(url)`: 아이콘을 내려받아 공용 비트맵 필드에 넣고 그 값을 쓴다.
  Future<ui.Image?> _p0(String url) async {
    _storeBitmap(await fetchBitmap(url));
    return _sharedBitmap;
  }

  /// `g1(url)`: 내려받은 그림을 메인 헤더 배경으로(헤더·푸터·팝업 어디서 불러도 메인 헤더).
  Future<void> _g1(String url) async {
    _storeBitmap(await fetchBitmap(url));
    _headerHasBitmap = true;
    _headerBitmap = _sharedBitmap;
  }

  void _storeBitmap(BitmapFetch result) {
    switch (result) {
      case BitmapLoaded(:final ui.Image image):
        _sharedBitmap = image;
      case BitmapUndecodable():
        _sharedBitmap = null;
      case BitmapFailed():
        break; // 실패하면 이전 값 그대로
    }
  }

  /// `B0(url)`: 저장된 `webview`가 `popup`이면 팝업, 아니면 메인 웹뷰에 공통 헤더와 함께 불러온다.
  ///
  /// [clearHistory]면 그 페이지가 끝난 뒤 방문 기록을 지운다(`webview`/`main` 명령). 원본은
  /// 기록을 남겨서, 첫 실행에 권한 안내 페이지를 거쳐 메인으로 간 뒤 뒤로 키를 누르면 이전 서버
  /// 페이지(`page/authority#1`)로 돌아가 앱 헤더 없이 다시 불러왔고, 서버가 HTTP 404를 보였다.
  void _b0(String url, {bool clearHistory = false}) {
    final WebEntry? target = _prefs.webview == 'popup' ? _popup : _main;
    target?.loadUrl(url, _extraHeaders, clearHistoryWhenDone: clearHistory);
  }

  /// `c1(url)`: 팝업에 불러오기. 네트워크가 없으면 불러오지 않는다.
  ///
  /// 원본은 이때 `네트워크가 연결되어 있지 않습니다.` 알림만 띄워 팝업이 빈 채로 남았다.
  /// 개선판은 팝업 안에 연결 안내와 다시 시도 버튼을 보인다(통합본 1-9).
  Future<void> _c1(String url) async {
    if (!await NativeBridge.isNetworkConnected()) {
      _popup?.showOffline(url, _extraHeaders);
      return;
    }
    _popup?.loadUrl(url, _extraHeaders);
  }

  // ======================================================================
  // 팝업 구성 (클래스 RunnableC0257a)
  // ======================================================================

  Future<void> _configurePopup(JObj action) async {
    _mainOwner = false;
    _popupShown = false;
    await _z0();
    try {
      final JObj config = action.getJSONObject('config');
      config.getString('show');
      final String align = config.getString('align');
      final String url = config.getString('url');
      final String header = !config.isNull('header')
          ? config.getString('header')
          : 'null';
      final String footer = !config.isNull('footer')
          ? config.getString('footer')
          : 'null';
      _popupAlign = align;
      final int w80 = (_screenWidthPx * 0.8).truncate();
      final int h80 = (_screenHeightPx * 0.8).truncate();
      switch (align) {
        case 'left':
          _bgGravity = Alignment.topLeft;
          _popupWidthPx = w80;
          _popupHeightPx = null;
          if (!_popupShown) {
            _bgVisible = true;
            _startAnimation(_bgTrack, LegacyAnim.inLeft);
          }
        case 'right':
          _bgGravity = Alignment.topRight;
          _popupWidthPx = w80;
          _popupHeightPx = null;
          if (!_popupShown) {
            _bgVisible = true;
            _startAnimation(_bodyTrack, LegacyAnim.inRight);
          }
        case 'center':
          _bgGravity = Alignment.center;
          _popupWidthPx = w80;
          _popupHeightPx = h80;
          _popupShown = true;
          _bgTrack.clear();
          _bgVisible = true;
        case 'full':
          _bgGravity = Alignment.center;
          _popupWidthPx = null;
          _popupHeightPx = null;
          _popupShown = true;
          _bgTrack.clear();
          _bgVisible = true;
        case 'top':
          _bgGravity = Alignment.topCenter;
          _popupWidthPx = null;
          _popupHeightPx = h80;
          if (!_popupShown) {
            _bgVisible = true;
            _startAnimation(_bodyTrack, LegacyAnim.inTop);
          }
        case 'bottom':
          _bgGravity = Alignment.bottomCenter;
          _popupWidthPx = null;
          _popupHeightPx = h80;
          if (!_popupShown) {
            _bgVisible = true;
            _startAnimation(_bodyTrack, LegacyAnim.inBottom);
          }
      }
      _popupHeaderVisible = false;
      if (config.isNull('header')) {
        _i1(align, header, footer, false);
      } else {
        final JObj h = config.getJSONObject('header');
        final String bgImage = h.getString('bgImage');
        final String bgColor = h.getString('bgColor');
        final String border = h.getString('border');
        _popupHeaderBox.color = _backgroundColor(bgColor);
        _i1(align, header, footer, bgColor == 'transparent');
        // 원본 그대로: 팝업 헤더 배경 이미지가 메인 헤더 배경으로 간다.
        if (bgImage != 'null') await _g1(bgImage);
        _applyStroke(_popupHeaderBox, border);
        if (align == 'full') {
          _subHeadVisible = true;
          _subHead2Visible = false;
          _subCenterTitleBackground = true;
        } else {
          _subHeadVisible = false;
          _subHead2Visible = false;
          _subCenterTitleBackground = false;
        }
        final JObj menu = h.getJSONObject('menu');
        bool any = false;
        for (final (String side, _MenuSlot slot) in <(String, _MenuSlot)>[
          ('left', _popupLeft),
          ('center', _popupCenter),
          ('right', _popupRight),
        ]) {
          if (!menu.isNull(side) && menu.getJSONArray(side).length > 0) {
            slot.visible = true;
            slot.items = <_MenuButton>[];
            final String loc = side == 'center'
                ? (align == 'full' ? 'popup_full' : 'popup_center')
                : 'popup_$side';
            slot.items = await _i0(menu.getJSONArray(side), loc);
            any = true;
          } else {
            slot.visible = false;
          }
        }
        if (any) _popupHeaderVisible = true;
      }
      if (config.isNull('footer')) {
        _popupFooterVisible = false;
      } else {
        _popupFooterVisible = true;
        await _l0(config.getJSONObject('footer'));
      }
      _popup?.loadJavascript(
        'document.clear();document.open();document.close();',
      );
      await _c1(url);
    } catch (_) {}
    _refresh();
  }

  /// `Z0()`: 팝업 웹뷰를 새로 만들어 바꾼다. 같은 틀에 있는 자식·손자 창은 그대로 둔다.
  Future<void> _z0() async {
    final WebEntry? old = _popup;
    if (old != null) _frame.remove(old);
    final WebEntry entry = await WebEntry.create(
      'popup',
      onChanged: _refresh,
      fullscreen: this,
    );
    _popup = entry;
    _frame.add(entry);
  }

  /// `i1(align, header, footer, 헤더투명)`: 팝업 모서리 규칙(HANDOFF 5.7.1).
  void _i1(String align, String header, String footer, bool transparentHeader) {
    final BorderRadius top30 = cornerRadii(tl: 30, tr: 30); // f7669A0
    final BorderRadius bottom30 = cornerRadii(br: 30, bl: 30); // f7671B0
    final BorderRadius none = BorderRadius.zero; // f7675D0
    final WebEntry? web = _popup;
    void corners(bool tl, bool tr, bool br, bool bl) {
      if (web == null) return;
      web
        ..topLeft = tl
        ..topRight = tr
        ..bottomRight = br
        ..bottomLeft = bl;
    }

    final bool hasHeader = header != 'null';
    final bool hasFooter = footer != 'null';
    _popupHeaderBox.radius = top30;
    _popupBodyPaddingTop = 0;
    switch (align) {
      case 'bottom':
        if (!hasHeader && !hasFooter) {
          corners(true, true, false, false);
        } else if (hasHeader && !hasFooter) {
          _popupHeaderBox.radius = top30;
          transparentHeader
              ? corners(true, true, false, false)
              : corners(false, false, false, false);
        } else if (!hasHeader && hasFooter) {
          corners(true, true, false, false);
          _popupFooterBox.radius = none;
        } else {
          _popupHeaderBox.radius = top30;
          _popupFooterBox.radius = none;
          transparentHeader
              ? corners(true, true, false, false)
              : corners(false, false, false, false);
        }
      case 'center':
        if (!hasHeader && !hasFooter) {
          corners(true, true, true, true);
        } else if (hasHeader && !hasFooter) {
          _popupHeaderBox.radius = top30;
          transparentHeader
              ? corners(true, true, true, true)
              : corners(false, false, true, true);
        } else if (!hasHeader && hasFooter) {
          _popupBodyPaddingTop = _dpToPx(30) / _dpr;
          _popupFooterBox.radius = bottom30;
        } else {
          _popupHeaderBox.radius = top30;
          _popupFooterBox.radius = bottom30;
          transparentHeader
              ? corners(true, true, false, false)
              : corners(false, false, false, false);
        }
      case 'top':
        if (!hasHeader && !hasFooter) {
          corners(false, false, true, true);
        } else if (hasHeader) {
          _popupHeaderBox.radius = none;
          corners(false, false, true, true);
        } else {
          _popupFooterBox.radius = bottom30;
        }
      default:
        _popupHeaderBox.radius = none;
        corners(false, false, false, false);
        _popupFooterBox.radius = none;
    }
  }

  // ======================================================================
  // 팝업 닫기 A0와 애니메이션
  // ======================================================================

  /// `A0()`: `webview="main"` 저장 후 닫기(runOnUiThread).
  Future<void> _a0(
    Future<void> Function(Future<void> Function() op) runOnUi,
  ) async {
    _prefs.webview = 'main';
    await runOnUi(() async {
      if (!_popupShown) {
        _bgVisible = false;
      } else {
        switch (_popupAlign) {
          case 'left':
            _startAnimation(_bodyTrack, LegacyAnim.outLeft);
          case 'right':
            _startAnimation(_bodyTrack, LegacyAnim.outRight);
          case 'top':
            _startAnimation(_bodyTrack, LegacyAnim.outTop);
          case 'bottom':
            _startAnimation(_bodyTrack, LegacyAnim.outBottom);
          default:
            _bgVisible = false;
            _popupShown = false;
        }
      }
      _refresh();
    });
  }

  /// 반투명 배경을 누르면 A0.
  void _onBackgroundTap() {
    _queue = _queue
        .then((_) => _a0((Future<void> Function() op) => op()))
        .catchError((Object _) {});
  }

  void _startAnimation(AnimTrack track, LegacyAnim anim) {
    track.start(anim);
    if (!_ticker.isActive) _ticker.start();
  }

  /// 원본 onCreate에서 애니메이션마다 붙인 리스너(y: 왼쪽, z: 오른쪽, A: 위, x: 아래).
  void Function() _animationListener(LegacyAnim anim) {
    switch (anim) {
      case LegacyAnim.inRight:
      case LegacyAnim.outRight:
        return () {
          if (_popupShown) {
            _bgVisible = false;
            _bodyTrack.clear();
            _popupShown = false;
          } else {
            _popupShown = _prefs.webview != 'main';
          }
        };
      case LegacyAnim.inLeft:
      case LegacyAnim.outLeft:
      case LegacyAnim.inTop:
      case LegacyAnim.outTop:
      case LegacyAnim.inBottom:
      case LegacyAnim.outBottom:
        return () {
          if (!_popupShown) {
            _popupShown = true;
            return;
          }
          _bgVisible = false;
          _bodyTrack.clear();
          _popupShown = false;
        };
    }
  }

  /// 배경이 보이거나 애니메이션이 붙어 있으면 그려진다(그려질 때만 애니메이션 시간이 흐름).
  bool get _bgDrawn => _bgVisible || _bgTrack.attached;

  void _onTick(Duration _) {
    if (_bgDrawn) {
      final Duration now =
          SchedulerBinding.instance.currentSystemFrameTimeStamp;
      _bgTrack.tick(now);
      if (_bgDrawn) _bodyTrack.tick(now);
    }
    if (!(_bgDrawn && (_bgTrack.running || _bodyTrack.running))) _ticker.stop();
    _refresh();
  }

  // ======================================================================
  // 대화상자와 로딩
  // ======================================================================

  /// 로딩 표시(원본 `b0()`/`S()`, Dialog `f7833u`): 보이는 웹뷰 가운데 본문을 불러오는 중이고
  /// 아직 새 화면이 그려지지 않은 것이 있으면 켠다. 연결 안내가 떠 있으면 그 안내가 대신한다.
  bool get _loading {
    bool loading(WebEntry? e) => e != null && e.busy && e.problem == null;
    return loading(_main) || (_bgDrawn && _frame.any(loading));
  }

  /// 팝업 연결 안내의 `닫기`: 뒤로 키로 팝업을 닫을 때와 같다.
  void _closePopupFromNotice() {
    _queue = _queue
        .then((_) async {
          await _a0((Future<void> Function() op) => op());
          _mainOwner = true;
        })
        .catchError((Object _) {});
  }

  void _cancelDialog() {
    if (_dialog != null) setState(() => _dialog = null);
  }

  /// `C0(json)`: alert 대화상자.
  void _c0(JObj action) {
    try {
      _cancelDialog();
      final String message = action
          .getJSONObject('config')
          .getString('message');
      _dialog = _AppDialog(
        () => MessagePopup(
          message: message,
          buttonText: '확인',
          buttonColor: schoolColor, // 원본 round_button #1B9CE8(통합본 5-10)
          onPressed: _cancelDialog,
        ),
      );
    } catch (_) {}
  }

  /// `G0(json)`: 버튼 대화상자.
  Future<void> _g0(JObj action) async {
    try {
      _cancelDialog();
      final JObj config = action.getJSONObject('config');
      if (!config.isNull('title')) config.getString('title');
      if (!config.isNull('icon')) config.getString('icon');
      final String message = config.isNull('message')
          ? 'null'
          : config.getString('message');
      final JArr buttons = config.getJSONArray('button');
      final List<_MenuButton> items = <_MenuButton>[];
      for (int i = 0; i < buttons.length; i++) {
        items.add(
          await _e0('dialog', buttons.getJSONObject(i))
            ..boxPx = _footerBoxPx,
        );
      }
      _dialog = _AppDialog(
        () => ButtonsPopup(
          message: message,
          buttons: items.map(_slotButton).toList(),
        ),
      );
    } catch (_) {}
  }

  /// `K0()`: NFC 대기 대화상자.
  void _k0() {
    _cancelDialog();
    _dialog = _AppDialog(
      () => MessagePopup(
        message: '핸드폰을 NFC 태그보드에 가까이 대세요.',
        buttonText: '취소',
        buttonColor: const Color(0xFF7A7B7C),
        onPressed: _cancelDialog,
      ),
    );
  }

  // ======================================================================
  // function 명령
  // ======================================================================

  /// `f1()`: QR 화면. 개선판은 이때 카메라 권한만 요청한다(통합본 1-1).
  void _f1(JObj action) {
    final String url = action.getJSONObject('config').getString('url');
    _resultUrl = url.contains('?') ? '$url&value=' : '$url?value=';
    _openQr();
  }

  Future<void> _openQr() async {
    final bool granted = await NativeBridge.requestFeaturePermission(
      const <String>[NativeBridge.camera],
      deniedMessage: '카메라 권한이 없어 QR 코드를 읽을 수 없습니다.',
      settingsMessage:
          'QR 코드를 읽으려면 카메라 권한이 필요합니다.\n'
          '[설정 열기] → 권한 → 카메라에서 허용해 주세요.',
    );
    if (!granted || !mounted) return;
    final String? result = await _openCovering<String>(const QrScanScreen());
    if (result == null) {
      // 원본은 영어 `Cancelled`였다(통합본 7-1).
      NativeBridge.toast('QR 코드 읽기를 취소했습니다.');
    } else {
      _post('$_resultUrl$result');
    }
  }

  /// `W0()`: 위치 전송. 개선판은 이때 위치 권한만 요청한다(통합본 1-1). 거부하면 원본처럼
  /// 위치를 0으로 보낸다.
  Future<void> _w0(JObj action) async {
    try {
      final String url = action.getJSONObject('config').getString('url');
      await NativeBridge.requestFeaturePermission(
        const <String>[NativeBridge.fineLocation, NativeBridge.coarseLocation],
        deniedMessage: '위치 권한이 없어 현재 위치를 보낼 수 없습니다.',
        settingsMessage:
            '현재 위치를 보내려면 위치 권한이 필요합니다.\n'
            '[설정 열기] → 권한 → 위치에서 허용해 주세요.',
      );
      final String? full = await NativeBridge.gpsUrl(url);
      if (full != null) _post(full);
    } catch (_) {}
  }

  /// `h1()`: NFC 대기. 확인(b1)은 runOnUiThread.
  Future<void> _h1(
    JObj action,
    Future<void> Function(Future<void> Function() op) runOnUi,
  ) async {
    await runOnUi(() async {
      if (await NativeBridge.nfcState() == 'enabled') {
        _k0();
      } else {
        await _q0("설정 화면의 NFC모드를 '기본' 또는 '읽기/쓰기'로 설정하시기 바랍니다.");
      }
      _refresh();
    });
    try {
      final String url = action.getJSONObject('config').getString('url');
      _nfcUrl = url.contains('?') ? '$url&value=' : '$url?value=';
    } catch (_) {}
  }

  /// `onNewIntent`의 NFC 값 → `R0(value)`.
  void _onNfcTag(String value) {
    final String? url = _nfcUrl;
    _post(
      url != null && url.isNotEmpty
          ? '$url$value'
          : 'https://mobile.ut.ac.kr//service/api/device/nfc?value=$value',
    );
  }

  /// `e1()`: 비콘 검색을 시작하고 5초 뒤 `z0()`.
  void _e1(JObj action) {
    try {
      final JObj config = action.getJSONObject('config');
      final String url = config.getString('url');
      _beaconUuids = config.getJSONArray('uuid');
      _resultUrl = url.contains('?') ? '$url&uuid=' : '$url?uuid=';
    } catch (_) {}
    _startBeacon();
  }

  /// 원본은 첫 실행에 받아 둔 대략 위치 권한으로 비콘을 찾았다. 개선판은 시작할 때 권한을 묻지
  /// 않으므로 비콘을 찾을 때 같은 권한을 요청한다. 동작(거부해도 검색 후 전송)은 원본 그대로다.
  Future<void> _startBeacon() async {
    if (!await NativeBridge.checkPermissions(const <String>[
      NativeBridge.coarseLocation,
    ])) {
      await NativeBridge.requestPermissions(const <String>[
        NativeBridge.coarseLocation,
      ]);
    }
    NativeBridge.beaconStart();
    Timer(const Duration(seconds: 5), _z0Beacon);
  }

  /// `z0()`: 찾은 비콘 중 uuid가 맞는 것(뒤에 나온 것이 이김)으로 POST. `major`가 두 번 붙는다.
  Future<void> _z0Beacon() async {
    final List<List<String>> found = await NativeBridge.beaconStop();
    final JArr? uuids = _beaconUuids;
    // 원본은 uuid 목록을 한 번도 받지 못했으면 여기서 예외로 종료된다. 종료는 재현하지 않는다.
    if (uuids == null || !mounted) return;
    String? id1, id2, id3;
    for (int i = 0; i < uuids.length; i++) {
      try {
        final String uuid = uuids.getString(i);
        for (final List<String> beacon in found) {
          if (uuid == beacon[0]) {
            id1 = beacon[0];
            id2 = beacon[1];
            id3 = beacon[2];
          }
        }
      } catch (_) {}
    }
    _post('$_resultUrl$id1&major=$id2&major=$id3');
  }

  /// `m1()`
  void _m1(JObj action) {
    try {
      _post(action.getJSONObject('config').getString('url'));
    } catch (_) {}
  }

  /// `D0()`: 팝업을 닫고 외부 브라우저로.
  Future<void> _d0(
    JObj action,
    Future<void> Function(Future<void> Function() op) runOnUi,
  ) async {
    try {
      await _a0(runOnUi);
      await NativeBridge.startView(
        action.getJSONObject('config').getString('url'),
      );
    } catch (_) {}
  }

  /// `k1()`: 앱 실행, 없으면 스토어 주소.
  Future<void> _k1(JObj action) async {
    try {
      final JObj config = action.getJSONObject('config');
      final String storeUrl = config.getString('storeUrl');
      if (await NativeBridge.launchPackage(config.getString('contentUrl'))) {
        return;
      }
      await NativeBridge.startView(storeUrl);
    } catch (_) {}
  }

  /// `F0()`: 시작 이미지 주소 저장.
  void _f0(JObj action) {
    try {
      final JObj config = action.getJSONObject('config');
      final String type = config.getString('type');
      final JObj json = config.getJSONObject('json');
      if (type == 'global') {
        final String jsonType = json.getString('type');
        final JObj jsonConfig = json.getJSONObject('config');
        if (jsonType == 'splash') {
          final String url = jsonConfig.getString('url');
          _prefs.splashUrl = url;
          downloadSplash(url);
        }
      }
    } catch (_) {}
  }

  // ======================================================================
  // window.open 창
  // ======================================================================

  Future<void> _createWindow(String parent, int token) async {
    final bool isChild = parent == 'popup';
    if (isChild) {
      _childOpen = true;
    } else {
      _grandchildOpen = true;
    }
    final WebEntry entry = await WebEntry.create(
      isChild ? 'child' : 'grandchild',
      onChanged: _refresh,
      fullscreen: this,
      onPageFinished: (String url) {
        // 자식 창에서 통합정보시스템 첫 화면이 끝나면 뒤로가기(원본 그대로).
        if (isChild && url == 'https://tis.ut.ac.kr/main.do') {
          _queue = _queue.then((_) => _y0()).catchError((Object _) {});
        }
      },
    );
    if (isChild) {
      _child = entry;
    } else {
      _grandchild = entry;
    }
    _frame.add(entry);
    _refresh();
    await NativeBridge.attachWindow(token, entry.id);
  }

  /// 자식·손자 창의 `window.close()`(Kotlin `onCloseWindow`).
  ///
  /// 원본은 자식 창이 닫히면 팝업도 닫았다(HANDOFF 5.11). 그래서 ECAMPUS처럼 페이지가 자식 창
  /// (`panopto_login_popup`)을 열었다가 스스로 닫으면 팝업 전체가 열리자마자 닫혔다. 개선판은
  /// 자식 창만 지우고 팝업은 남긴다. 내려받기만 하고 보여 줄 페이지가 없는 자식 창도 Kotlin이
  /// 이 경로로 닫는다(첨부파일).
  Future<void> _closeWindow(String kind) async {
    if (kind == 'child') {
      _childOpen = false;
      final WebEntry? child = _child;
      if (child != null) _frame.remove(child);
      _refresh();
    } else {
      final WebEntry? grandchild = _grandchild;
      if (grandchild != null) {
        _frame.remove(grandchild);
        _refresh();
        NativeBridge.destroyWebView(grandchild.id);
      }
    }
  }

  // ======================================================================
  // 뒤로가기 y0
  // ======================================================================

  Future<void> _y0() async {
    if (_grandchildOpen) {
      final WebEntry? web = _grandchild;
      if (web != null && await web.canGoBack()) {
        await web.goBack();
      } else {
        web?.loadJavascript('window.close();');
        _grandchildOpen = false;
      }
      return;
    }
    if (_childOpen) {
      final WebEntry? web = _child;
      if (web != null && await web.canGoBack()) {
        await web.goBack();
      } else {
        web?.loadJavascript('window.close();');
        _childOpen = false;
      }
      return;
    }
    if (_mainOwner) {
      final WebEntry? web = _main;
      if (web != null && await web.canGoBack()) {
        await web.goBack();
      } else if (DateTime.now().millisecondsSinceEpoch <=
          _backPressedAt + 2000) {
        await NativeBridge.exitProcess();
      } else {
        _backPressedAt = DateTime.now().millisecondsSinceEpoch;
        NativeBridge.toast("'뒤로' 버튼을 한 번 더 누르면 종료됩니다."); // 통합본 7-2
      }
      return;
    }
    final WebEntry? popup = _popup;
    if (popup != null && await popup.canGoBack()) {
      await popup.goBack();
    } else {
      await _a0((Future<void> Function() op) => op());
      _mainOwner = true;
    }
  }

  // ======================================================================
  // 동영상 전체 화면(통합본 6-11)
  // ======================================================================

  /// 원본은 `onShowCustomView`를 처리하지 않고 화면도 세로 고정이라 동영상 전체 화면이 되지
  /// 않았다. 개선판은 웹뷰가 넘긴 전체 화면 뷰를 화면 전체에 띄우고, 그동안만 가로 회전과 시스템
  /// 바 숨기기를 허용한다.
  @override
  void show(Widget view, VoidCallback exit) {
    _customView = view;
    _exitCustomView = exit;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _refresh();
  }

  @override
  void hide() {
    if (_customView == null) return;
    _customView = null;
    _exitCustomView = null;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
      DeviceOrientation.portraitUp,
    ]);
    _refresh();
  }

  void _onBackPressed() {
    // 동영상 전체 화면이면 뒤로 키는 전체 화면만 끝낸다.
    final VoidCallback? exitCustomView = _exitCustomView;
    if (exitCustomView != null) {
      exitCustomView();
      return;
    }
    // 대화상자는 취소할 수 없는 창이라 뒤로 키를 먹는다. 원본은 로딩 표시도 뒤로 키를 먹었지만
    // 개선판의 로딩 표시는 입력을 막지 않는다(통합본 3-31).
    if (_dialog != null) return;
    _queue = _queue.then((_) => _y0()).catchError((Object _) {});
  }

  // ======================================================================
  // 다른 화면(QR, 다시 뜨는 인트로)
  // ======================================================================

  /// 다른 화면이 위에 있는 동안 원본 MainActivity는 onPause 상태(NFC 해제).
  Future<T?> _openCovering<T>(Widget screen) async {
    final NavigatorState navigator = Navigator.of(context);
    await NativeBridge.setMainActive(false);
    final T? result = await navigator.push<T>(
      PageRouteBuilder<T>(
        pageBuilder: (_, _, _) => screen,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
    await NativeBridge.setMainActive(true);
    return result;
  }

  /// 푸시·NFC로 앱이 다시 열린 경우: 원본은 IntroActivity가 새로 떠서 기기 등록을 다시 하고,
  /// 응답을 이미 떠 있는 MainActivity(`onNewIntent`)에 넘긴다.
  Future<void> _relaunchIntro(String? pushUrl) async {
    final String? screenInfo = await _openCovering<String>(
      Builder(
        builder: (BuildContext context) => IntroScreen(
          pushUrl: pushUrl,
          onFinished: (String? info) => Navigator.of(context).pop(info),
        ),
      ),
    );
    if (screenInfo != null && screenInfo.isNotEmpty) {
      _loadTokens();
      await _enqueue(screenInfo, fromBridge: false);
    }
  }

  // ======================================================================
  // 화면
  // ======================================================================

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) _onBackPressed();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
        ),
        child: ColoredBox(
          color: windowBackground,
          child: Stack(
            children: <Widget>[
              SafeArea(
                child: Padding(
                  // CoordinatorLayout layout_margin 1dp
                  padding: const EdgeInsets.all(1),
                  child: LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) =>
                            Stack(
                              children: <Widget>[
                                _content(),
                                // GONE인 동안에도 웹뷰는 붙어 있다(Android 뷰처럼).
                                Positioned.fill(
                                  child: Offstage(
                                    offstage: !_bgDrawn,
                                    child: _popupLayer(constraints.biggest),
                                  ),
                                ),
                              ],
                            ),
                  ),
                ),
              ),
              if (_loading) const Positioned.fill(child: _LoadingLayer()),
              if (_dialog != null)
                Positioned.fill(child: _dialogLayer(_dialog!)),
              if (_customView != null)
                Positioned.fill(
                  child: ColoredBox(color: _black, child: _customView),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// `content_main.xml`
  Widget _content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_headerVisible) _mainHeader(),
        const SizedBox(height: 1), // main_body layout_marginTop
        Expanded(
          child: ColoredBox(
            color: _white,
            child: _ready && _main != null ? _withNotice(_main!) : null,
          ),
        ),
        if (_footerVisible) ...<Widget>[
          const Material(
            color: Color(0xFFDDDDDD),
            elevation: 1,
            child: SizedBox(height: 1),
          ),
          _mainFooter(),
        ],
      ],
    );
  }

  Widget _mainHeader() {
    return Container(
      decoration: _headerHasBitmap ? null : _headerBox.decoration(),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          if (_headerHasBitmap && _headerBitmap != null)
            Positioned.fill(
              child: RawImage(image: _headerBitmap, fit: BoxFit.fill),
            ),
          if (_center.visible)
            SizedBox(
              height: 50,
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _center.items.map(_menuButton).toList(),
              ),
            ),
          if (_left.visible) _sideContainer(_left, Alignment.centerLeft),
          if (_right.visible) _sideContainer(_right, Alignment.centerRight),
        ],
      ),
    );
  }

  /// left/right_container: padding 3dp, 위아래 margin 5dp, marginEnd 5dp.
  Widget _sideContainer(_MenuSlot slot, Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.only(top: 5, bottom: 5, right: 5),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: slot.items.map(_menuButton).toList(),
          ),
        ),
      ),
    );
  }

  /// `main_footer`: 처음에는 레이아웃의 "*" 버튼(AppCompat 기본 버튼).
  Widget _mainFooter() {
    final List<_MenuButton>? items = _footerItems;
    return Container(
      height: 50,
      decoration: _footerBox.decoration(),
      child: Row(
        children: items == null
            ? const <Widget>[LegacyButton(text: '*')]
            : items.map(_slotButton).toList(),
      ),
    );
  }

  /// 버튼 하나(아이콘이 있으면 `d1` 정사각형 칸 안).
  Widget _menuButton(_MenuButton b) {
    final Widget button = LegacyButton(
      text: b.text,
      textColor: b.textColor,
      background: b.background,
      padding: b.padding,
      onTap: b.onTap,
    );
    final int? box = b.boxPx;
    if (box == null) return button;
    return SquareSlot(
      dimension: box / _dpr,
      fitContent: b.text != null && b.background is! ImageButtonBackground,
      child: button,
    );
  }

  /// 푸터·대화상자 버튼 칸: 가로로 똑같이 나눈 칸의 가운데에 정사각형 칸.
  Widget _slotButton(_MenuButton b) =>
      Expanded(child: Center(child: _menuButton(b)));

  /// `popup_bg_container`
  Widget _popupLayer(Size parent) {
    final double width = _popupWidthPx == null
        ? parent.width
        : _popupWidthPx! / _dpr;
    final double height = _popupHeightPx == null
        ? parent.height
        : _popupHeightPx! / _dpr;
    final Size self = Size(width, height);
    return SizedBox.expand(
      child: Transform.translate(
        offset: _bgTrack.offset(parent, parent),
        transformHitTests: false, // 옛 Android 애니메이션은 터치 위치를 옮기지 않는다
        child: GestureDetector(
          onTap: _onBackgroundTap,
          child: ColoredBox(
            color: const Color(0x66000000),
            child: Align(
              alignment: _bgGravity,
              child: Transform.translate(
                offset: _bodyTrack.offset(parent, self),
                transformHitTests: false,
                child: SizedBox(
                  width: width,
                  height: height,
                  child: _popupContainer(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// `popup_container`: 헤더(58dp) / 몸통 / 푸터(50dp)
  Widget _popupContainer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_popupHeaderVisible) _popupHeader(),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0x66000000),
              borderRadius: BorderRadius.circular(30),
            ),
            padding: EdgeInsets.only(top: _popupBodyPaddingTop),
            child: Stack(
              fit: StackFit.expand,
              children: _frame.map(_frameChild).toList(),
            ),
          ),
        ),
        if (_popupFooterVisible)
          Container(
            height: 50,
            decoration: _popupFooterBox.decoration(),
            child: Row(children: _popupFooterItems.map(_slotButton).toList()),
          ),
      ],
    );
  }

  Widget _frameChild(WebEntry entry) {
    if (entry.kind != 'popup') return entry.view;
    return ClipPath(
      clipper: RoundedWebViewClipper(
        topLeft: entry.topLeft,
        topRight: entry.topRight,
        bottomRight: entry.bottomRight,
        bottomLeft: entry.bottomLeft,
        devicePixelRatio: _dpr,
      ),
      child: _withNotice(entry, onClose: _closePopupFromNotice),
    );
  }

  /// 웹뷰 위에 연결 안내(통합본 1-9, 6-10). 웹뷰는 계속 붙여 둔다.
  Widget _withNotice(WebEntry entry, {VoidCallback? onClose}) {
    final ConnectionProblem? problem = entry.problem;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        entry.view,
        if (problem != null)
          ConnectionNotice(
            problem: problem,
            onRetry: entry.retry,
            onClose: onClose,
          ),
      ],
    );
  }

  /// `popup_header`: 터치는 먹기만 한다.
  Widget _popupHeader() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Container(
        height: 58,
        decoration: _popupHeaderBox.decoration(),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            if (_subHeadVisible)
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            if (_subHead2Visible)
              Container(
                width: 250,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF333333),
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            if (_popupCenter.visible)
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: _subCenterTitleBackground
                    ? BoxDecoration(
                        color: const Color(0xFF333333),
                        borderRadius: BorderRadius.circular(30),
                      )
                    : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _popupCenter.items.map(_menuButton).toList(),
                ),
              ),
            if (_popupLeft.visible)
              _sideContainer(_popupLeft, Alignment.centerLeft),
            if (_popupRight.visible)
              _sideContainer(_popupRight, Alignment.centerRight),
          ],
        ),
      ),
    );
  }

  /// 대화상자 창: 화면폭 − 70dp, 뒤를 0.5 어둡게, 바깥 터치 무시. 글자 크기 설정을 키우면
  /// 길어질 수 있어 화면보다 높으면 스크롤한다.
  Widget _dialogLayer(_AppDialog dialog) {
    final double width = ((_screenWidthPx - (_dpr * 70).truncate()) / _dpr)
        .clamp(0, double.infinity);
    return ColoredBox(
      color: const Color(0x80000000),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: SizedBox(width: width, child: dialog.build()),
          ),
        ),
      ),
    );
  }
}

/// 로딩 표시: 가운데에 회전 이미지. 원본은 화면 전체를 덮는 취소 불가 창이라 로딩 중에는
/// 아무것도 누를 수 없었다. 개선판은 터치를 그대로 아래로 넘긴다(통합본 3-31).
class _LoadingLayer extends StatelessWidget {
  const _LoadingLayer();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: SafeArea(child: Center(child: LoadingSpinner())),
    );
  }
}
