import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import 'connection_notice.dart';
import 'native_bridge.dart';
import 'page_load.dart';

/// 원본의 WebView 하나(메인, 팝업, `window.open`으로 열린 자식·손자).
///
/// 개선판에서는 본문 프레임 불러오기 상태([PageLoad])를 웹뷰마다 기억해서 로딩 표시와 연결
/// 안내를 정한다(통합본 3-31, 1-9, 6-10).
class WebEntry {
  WebEntry._(this.kind, this.controller, VoidCallback onChanged)
    : _load = PageLoad(onChanged);

  /// 연결 안내를 띄울 본문 프레임 오류(연결 자체가 안 된 경우).
  static const Set<WebResourceErrorType> connectionErrors =
      <WebResourceErrorType>{
        WebResourceErrorType.hostLookup,
        WebResourceErrorType.connect,
        WebResourceErrorType.timeout,
        WebResourceErrorType.io,
        WebResourceErrorType.failedSslHandshake,
        WebResourceErrorType.proxyAuthentication,
        WebResourceErrorType.redirectLoop,
        WebResourceErrorType.tooManyRequests,
      };

  /// Kotlin이 보내는 웹뷰 이벤트를 받을 항목들. 웹뷰가 해제되면 같이 사라지도록 약하게 잡는다.
  static final Map<int, WeakReference<WebEntry>> _byId =
      <int, WeakReference<WebEntry>>{};

  /// `main`, `popup`, `child`, `grandchild`
  final String kind;
  final WebViewController controller;
  final PageLoad _load;

  /// RoundedWebView 모서리(팝업만 사용). 새로 만들면 네 모서리 모두 둥글다.
  bool topLeft = true;
  bool topRight = true;
  bool bottomRight = true;
  bool bottomLeft = true;

  /// 본문 프레임을 불러오는 중이고 새 화면이 아직 그려지지 않았다(로딩 표시).
  bool get busy => _load.busy;

  /// 지금 보여 줄 연결 안내. 없으면 null.
  ConnectionProblem? get problem => _load.problem;

  int get id =>
      (controller.platform as AndroidWebViewController).webViewIdentifier;

  late final Widget view = WebViewWidget.fromPlatformCreationParams(
    key: ObjectKey(this),
    params: AndroidWebViewWidgetCreationParams(
      controller: controller.platform,
      // 웹뷰 위에서 시작한 터치는 모두 웹뷰가 받는다(Android 뷰와 같음).
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
        Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
      },
    ),
  );

  /// webview_flutter로 WebView를 만들고, 네이티브 쪽에서 원본 설정을 입힌다.
  ///
  /// [onChanged]는 로딩 표시나 연결 안내가 바뀔 때, [onPageFinished]는 원본처럼 페이지가 끝날 때
  /// 불린다.
  static Future<WebEntry> create(
    String kind, {
    required VoidCallback onChanged,
    void Function(String url)? onPageFinished,
  }) async {
    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(
          const PlatformWebViewControllerCreationParams(),
        );
    final WebEntry entry = WebEntry._(kind, controller, onChanged);
    final PageLoad load = entry._load;
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: load.pageStarted,
        onPageFinished: (String url) {
          load.pageFinished(url);
          onPageFinished?.call(url);
        },
        onProgress: load.progress,
        onWebResourceError: entry._resourceError,
      ),
    );
    await NativeBridge.installWebView(entry.id, kind);
    _byId.removeWhere((_, WeakReference<WebEntry> ref) => ref.target == null);
    _byId[entry.id] = WeakReference<WebEntry>(entry);
    return entry;
  }

  /// Kotlin(`WebViewBridge`)이 보낸 이벤트: `navigate`(링크로 본문 이동 시작), `committed`
  /// (방문 기록 갱신), `visible`(새 화면이 처음 그려짐), `download`(이동이 내려받기로 끝남).
  static void handleNativeEvent(Map<Object?, Object?> event) {
    final WebEntry? entry = _byId[event['id']]?.target;
    if (entry == null) return;
    switch (event['type']) {
      case 'navigate':
        entry._load.navigate(event['url'] as String?);
      case 'committed':
        entry._load.committed();
      case 'visible':
      case 'download':
        entry._load.settle();
    }
  }

  /// `loadUrl(url, extraHeaders)`.
  void loadUrl(String url, Map<String, String> headers) {
    _load.ownLoad(url, headers);
    NativeBridge.loadUrl(id, url, headers);
  }

  /// 네트워크가 없어서 [url]을 불러오지 않았다. 다시 시도하면 그때 불러온다.
  void showOffline(String url, Map<String, String> headers) =>
      _load.offline(url, headers);

  /// 연결 안내의 `다시 시도`.
  void retry() {
    switch (_load.retry()) {
      case RetryOwnLoad(:final String url, :final Map<String, String> headers):
        NativeBridge.loadUrl(id, url, headers);
      case RetryUrl(:final String url):
        NativeBridge.loadUrl(id, url, const <String, String>{});
      case RetryReload():
        controller.reload();
    }
  }

  /// `loadUrl("javascript:...")`.
  void loadJavascript(String script) {
    NativeBridge.loadJavascriptUrl(id, script);
  }

  Future<bool> canGoBack() async {
    try {
      return await controller.canGoBack();
    } catch (_) {
      return false;
    }
  }

  Future<void> goBack() async {
    try {
      await controller.goBack();
    } catch (_) {}
  }

  void _resourceError(WebResourceError error) {
    if (error.isForMainFrame == false) return;
    final bool connection = connectionErrors.contains(error.errorType);
    _load.mainFrameError(error.url, connectionError: connection);
    if (connection) {
      NativeBridge.isNetworkConnected().then((bool connected) {
        if (!connected) _load.markOffline();
      });
    }
  }
}
