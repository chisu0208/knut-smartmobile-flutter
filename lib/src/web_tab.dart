import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'connection_notice.dart';
import 'native_bridge.dart';
import 'shell_link.dart';
import 'tab_route.dart';
import 'tab_widgets.dart';
import 'web_entry.dart';

/// 웹뷰 하나와 그 위의 연결 안내·로딩 막대(출결·도서관 탭, 앱 안 웹 페이지).
class WebSurface extends StatelessWidget {
  const WebSurface({super.key, required this.entry});

  final WebEntry entry;

  @override
  Widget build(BuildContext context) {
    final ConnectionProblem? problem = entry.problem;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        entry.view,
        if (problem != null)
          ConnectionNotice(problem: problem, onRetry: entry.retry),
        if (entry.busy && problem == null)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 3),
          ),
      ],
    );
  }
}

enum _WebTabStatus { requesting, web, loginNeeded, unavailable }

/// 출결·도서관 탭(개선판 2차, 통합본 4-9, 8-5): 학교 사이트를 탭 안 웹 화면으로 띄운다.
///
/// 처음 열 때(와 다시 시도할 때) 홈 웹뷰에서 `AllytteCommand.callService("SERVICE", id)`를
/// 실행하고, 서버가 답한 주소 명령을 가로채 이 탭 웹뷰에 불러온다(`tab_route.dart`). 서버가 준 주소를
/// 그대로 쓰므로 로그인한 상태로 열린다. 답이 주소 명령이 아니면(로그인 필요 알림 등) 그 명령은
/// 홈에서 원래대로 처리되고, 이 탭은 "로그인이 필요합니다"와 로그인 버튼을 보인다.
///
/// 외부 사이트이므로 웹뷰에 `allytteAndroid` 통로를 붙이지 않는다(통합본 9-7, Kotlin kind `tab`).
class WebTab extends StatefulWidget {
  const WebTab({super.key, required this.kind, required this.tab});

  final WebTabKind kind;
  final TabContext tab;

  @override
  State<WebTab> createState() => _WebTabState();
}

class _WebTabState extends State<WebTab> implements FullscreenHost {
  WebEntry? _web;
  _WebTabStatus _status = _WebTabStatus.requesting;
  bool _requesting = false;

  /// 주소를 받아 오지 못한 때의 홈 구성 횟수. 그 뒤 홈이 다시 구성됐으면(로그인 등) 탭을 다시 열 때
  /// 주소를 다시 받아 온다.
  int _failedGeneration = -1;

  /// 홈 웹뷰가 주소를 부르지 못했다(홈 화면이 학교 메인 페이지가 아님).
  bool _notCalled = false;

  Widget? _customView;
  VoidCallback? _exitCustomView;

  TabContext get _tab => widget.tab;

  @override
  void initState() {
    super.initState();
    _tab.back.onBack = _onBack;
    _tab.link?.addListener(_onLink);
    _tab.host.currentTab.addListener(_onCurrentTab);
    _start();
  }

  @override
  void dispose() {
    _tab.back.onBack = null;
    _tab.link?.removeListener(_onLink);
    _tab.host.currentTab.removeListener(_onCurrentTab);
    final WebEntry? web = _web;
    if (web != null) {
      WidgetsBinding.instance.endOfFrame.then(
        (_) => NativeBridge.destroyWebView(web.id),
      );
    }
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _start() async {
    final WebEntry web = await WebEntry.create(
      'tab',
      onChanged: _refresh,
      fullscreen: this,
    );
    if (!mounted) {
      NativeBridge.destroyWebView(web.id);
      return;
    }
    _web = web;
    final String? url = _tab.link?.takeUrl();
    if (url != null) {
      _load(url);
    } else {
      await _request();
    }
  }

  /// 홈의 타일이 이 탭 주소를 보냈다.
  void _onLink() {
    if (_web == null) return; // 만들어지면 _start가 가져간다
    final String? url = _tab.link?.takeUrl();
    if (url != null) _load(url);
  }

  void _onCurrentTab() {
    if (_tab.host.currentTab.value != _tab.tab) return;
    final bool failed =
        _status == _WebTabStatus.loginNeeded ||
        _status == _WebTabStatus.unavailable;
    if (failed && _tab.home.generation != _failedGeneration) _request();
  }

  Future<void> _request() async {
    if (_requesting || _web == null) return;
    _requesting = true;
    setState(() => _status = _WebTabStatus.requesting);
    final ServiceResult result = await _tab.home.requestService(
      widget.kind.serviceId,
    );
    _requesting = false;
    if (!mounted) return;
    switch (result) {
      case ServiceRouted(:final TabRoute route):
        if (route.tab == widget.kind) {
          _load(route.url);
        } else {
          _fail(_WebTabStatus.unavailable, notCalled: false);
          _tab.host.openTabRoute(route);
        }
      case ServiceNotRouted():
        _fail(_WebTabStatus.loginNeeded, notCalled: false);
      case ServiceNoResponse(:final bool called):
        _fail(_WebTabStatus.unavailable, notCalled: !called);
    }
  }

  void _fail(_WebTabStatus status, {required bool notCalled}) {
    _failedGeneration = _tab.home.generation;
    setState(() {
      _status = status;
      _notCalled = notCalled;
    });
  }

  /// 서버가 준 주소를 탭의 첫 페이지로 연다. 그 페이지가 뜨면 방문 기록을 지워서, 뒤로 키가 전에
  /// 받은 주소의 페이지로 돌아가지 않고 홈 탭으로 간다.
  void _load(String url) {
    setState(() => _status = _WebTabStatus.web);
    // 외부 사이트라 원본 헤더(기기 토큰 등)는 보내지 않는다(통합본 9-3).
    _web!.loadUrl(url, const <String, String>{}, clearHistoryWhenDone: true);
  }

  Future<bool> _onBack() async {
    final VoidCallback? exit = _exitCustomView;
    if (exit != null) {
      exit();
      return true;
    }
    final WebEntry? web = _web;
    if (_status == _WebTabStatus.web && web != null && await web.canGoBack()) {
      await web.goBack();
      return true;
    }
    return false;
  }

  @override
  void show(Widget view, VoidCallback exit) {
    _customView = view;
    _exitCustomView = exit;
    enterVideoFullscreen();
    _tab.host.setFullscreen(_tab.tab, true);
    _refresh();
  }

  @override
  void hide() {
    if (_customView == null) return;
    _customView = null;
    _exitCustomView = null;
    exitVideoFullscreen();
    _tab.host.setFullscreen(_tab.tab, false);
    _refresh();
  }

  void _login() {
    _tab.home.login();
    _tab.host.showHome();
  }

  @override
  Widget build(BuildContext context) {
    final Widget? custom = _customView;
    // 동영상 전체 화면은 위에 덮는다(웹뷰는 그대로 붙여 둔다).
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        _content(context),
        if (custom != null) ColoredBox(color: Colors.black, child: custom),
      ],
    );
  }

  Widget _content(BuildContext context) {
    final WebEntry? web = _web;
    final TextTheme text = Theme.of(context).textTheme;
    return ColoredBox(
      color: AppColors.bg,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(left: 20, right: 4),
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        widget.kind.serviceName,
                        style: text.titleMedium,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '처음 화면으로',
                    onPressed: _requesting ? null : _request,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  if (web != null)
                    Offstage(
                      offstage: _status != _WebTabStatus.web,
                      child: WebSurface(entry: web),
                    ),
                  if (_status != _WebTabStatus.web) _notice(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notice(BuildContext context) {
    final String name = widget.kind.serviceName;
    final Widget card = switch (_status) {
      _WebTabStatus.requesting => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            '$name 화면을 여는 중이에요',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
      _WebTabStatus.loginNeeded => NoticeCard(
        icon: Icons.lock_outline,
        title: '로그인이 필요합니다',
        message: _tab.home.hasLogin
            ? '$name은 스마트모바일에 로그인해야 열 수 있어요.'
            : '$name은 스마트모바일에 로그인해야 열 수 있어요. '
                  '홈 위쪽 막대의 로그인 버튼으로 로그인해 주세요.',
        actions: <Widget>[
          if (_tab.home.hasLogin)
            FilledButton(onPressed: _login, child: const Text('로그인'))
          else
            FilledButton(
              onPressed: _tab.host.showHome,
              child: const Text('홈으로'),
            ),
          OutlinedButton(onPressed: _request, child: const Text('다시 시도')),
        ],
      ),
      _WebTabStatus.unavailable => NoticeCard(
        icon: Icons.cloud_off_outlined,
        title: '$name 화면을 열지 못했어요',
        message: _notCalled
            ? '홈 화면이 학교 메인 페이지일 때 열 수 있어요. 홈에서 처음 화면으로 돌아간 뒤 다시 시도해 주세요.'
            : '학교 서버가 답하지 않았어요. 잠시 뒤 다시 시도해 주세요.',
        actions: <Widget>[
          FilledButton(onPressed: _request, child: const Text('다시 시도')),
          OutlinedButton(
            onPressed: _tab.host.showHome,
            child: const Text('홈으로'),
          ),
        ],
      ),
      _WebTabStatus.web => const SizedBox.shrink(),
    };
    return ColoredBox(
      color: AppColors.bg,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: card,
        ),
      ),
    );
  }
}
