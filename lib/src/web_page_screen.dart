import 'package:flutter/material.dart';

import 'native_bridge.dart';
import 'web_entry.dart';
import 'web_tab.dart';

/// 앱 안 웹 페이지 화면(개선판 2차): 교통 탭의 길찾기·캠퍼스 지도, 학식 탭의 학교 홈페이지 식단.
///
/// 출결·도서관 탭처럼 웹뷰 kind `tab`(외부 사이트용, `allytteAndroid` 통로 없음)을 쓴다. 화면
/// 전체를 덮고, 뒤로 키는 웹 페이지가 뒤로 갈 수 있으면 뒤로, 아니면 닫는다.
class WebPageScreen extends StatefulWidget {
  const WebPageScreen({super.key, required this.title, required this.url});

  final String title;
  final String url;

  @override
  State<WebPageScreen> createState() => _WebPageScreenState();
}

class _WebPageScreenState extends State<WebPageScreen>
    implements FullscreenHost {
  WebEntry? _web;
  Widget? _customView;
  VoidCallback? _exitCustomView;

  @override
  void initState() {
    super.initState();
    WebEntry.create('tab', onChanged: _refresh, fullscreen: this).then((
      WebEntry web,
    ) {
      if (!mounted) {
        NativeBridge.destroyWebView(web.id);
        return;
      }
      setState(() => _web = web);
      web.loadUrl(widget.url, const <String, String>{});
    });
  }

  @override
  void dispose() {
    final WebEntry? web = _web;
    if (web != null) {
      if (_customView != null) exitVideoFullscreen();
      WidgetsBinding.instance.endOfFrame.then(
        (_) => NativeBridge.destroyWebView(web.id),
      );
    }
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void show(Widget view, VoidCallback exit) {
    _customView = view;
    _exitCustomView = exit;
    enterVideoFullscreen();
    _refresh();
  }

  @override
  void hide() {
    if (_customView == null) return;
    _customView = null;
    _exitCustomView = null;
    exitVideoFullscreen();
    _refresh();
  }

  Future<void> _onBack() async {
    final VoidCallback? exit = _exitCustomView;
    if (exit != null) {
      exit();
      return;
    }
    final WebEntry? web = _web;
    if (web != null && await web.canGoBack()) {
      await web.goBack();
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final WebEntry? web = _web;
    final Widget? custom = _customView;
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) _onBack();
      },
      // 동영상 전체 화면은 위에 덮는다(웹뷰는 그대로 붙여 둔다).
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
              leading: IconButton(
                tooltip: '닫기',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: web == null
                ? const Center(child: CircularProgressIndicator())
                : WebSurface(entry: web),
          ),
          if (custom != null) ColoredBox(color: Colors.black, child: custom),
        ],
      ),
    );
  }
}
