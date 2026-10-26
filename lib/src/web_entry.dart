import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import 'native_bridge.dart';

/// 원본의 WebView 하나(메인, 팝업, `window.open`으로 열린 자식·손자).
class WebEntry {
  WebEntry._(this.kind, this.controller);

  /// `main`, `popup`, `child`, `grandchild`
  final String kind;
  final WebViewController controller;

  /// RoundedWebView 모서리(팝업만 사용). 새로 만들면 네 모서리 모두 둥글다.
  bool topLeft = true;
  bool topRight = true;
  bool bottomRight = true;
  bool bottomLeft = true;

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
  static Future<WebEntry> create(
    String kind, {
    required void Function(String url) onPageStarted,
    required void Function(String url) onPageFinished,
  }) async {
    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(
          const PlatformWebViewControllerCreationParams(),
        );
    final WebEntry entry = WebEntry._(kind, controller);
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: onPageStarted,
        onPageFinished: onPageFinished,
      ),
    );
    await NativeBridge.installWebView(entry.id, kind);
    return entry;
  }

  /// `loadUrl(url, extraHeaders)`.
  void loadUrl(String url, Map<String, String> headers) {
    NativeBridge.loadUrl(id, url, headers);
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
}
