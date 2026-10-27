import 'package:flutter/foundation.dart';

import 'tab_route.dart';

/// 하단 탭(개선판 2차, 통합본 8-5). 순서가 탭 막대 순서다.
enum AppTab { home, attend, library, transit, meal }

/// 탭 막대 쪽([AppShell](app_shell.dart))이 각 탭에 열어 두는 기능.
abstract interface class ShellHost {
  /// 지금 보이는 탭.
  ValueListenable<AppTab> get currentTab;

  /// 홈 탭 쪽 화면(팝업, alert·dialog, 메인 구성 등)을 여는 서버 명령이 왔다. 다른 탭에 있으면
  /// 홈 탭으로 옮긴다.
  void showHome();

  /// 서버 명령의 주소가 출결·도서관 탭 주소다. 그 탭에 불러오고 그 탭으로 옮긴다.
  void openTabRoute(TabRoute route);

  /// 동영상 전체 화면이 시작·끝났다. 전체 화면인 동안 탭 막대를 숨긴다.
  void setFullscreen(AppTab tab, bool fullscreen);
}

/// 탭 하나가 뒤로 키를 받는 곳. 탭이 [onBack]을 넣고, 처리했으면 true를 돌려준다. false면 탭
/// 막대가 홈 탭으로 옮긴다.
class TabBackHandler {
  Future<bool> Function()? onBack;
}

/// 홈의 타일·메뉴가 보낸 출결·도서관 주소를 그 탭에 넘기는 곳. 탭이 아직 만들어지지 않았으면
/// 만들어질 때 가져간다.
class WebTabLink extends ChangeNotifier {
  String? _pendingUrl;

  void open(String url) {
    _pendingUrl = url;
    notifyListeners();
  }

  /// 기다리는 주소를 가져가고 비운다.
  String? takeUrl() {
    final String? url = _pendingUrl;
    _pendingUrl = null;
    return url;
  }
}

/// 탭 막대가 탭 하나에 주는 것.
class TabContext {
  const TabContext({
    required this.tab,
    required this.host,
    required this.home,
    required this.back,
    this.link,
  });

  final AppTab tab;
  final ShellHost host;
  final HomeController home;
  final TabBackHandler back;

  /// 출결·도서관 탭만.
  final WebTabLink? link;
}

/// 홈 탭(`MainScreen`)이 다른 탭에 열어 두는 기능. 홈 탭이 만들어지면 채운다.
class HomeController {
  Future<ServiceResult> Function(String serviceId)? _requestService;
  bool Function()? _hasLogin;
  VoidCallback? _login;
  int _generation = 0;

  /// `MainScreen`이 부른다.
  void attach({
    required Future<ServiceResult> Function(String serviceId) requestService,
    required bool Function() hasLogin,
    required VoidCallback login,
  }) {
    _requestService = requestService;
    _hasLogin = hasLogin;
    _login = login;
  }

  void detach() {
    _requestService = null;
    _hasLogin = null;
    _login = null;
  }

  /// 홈 웹뷰에서 `AllytteCommand.callService("SERVICE", serviceId)`를 실행하고 결과를 기다린다.
  Future<ServiceResult> requestService(String serviceId) async {
    final Future<ServiceResult> Function(String)? request = _requestService;
    if (request == null) return const ServiceNoResponse(called: false);
    return request(serviceId);
  }

  /// 홈 위쪽 막대에 로그인 버튼이 있는지([isLoginButton]).
  bool get hasLogin => _hasLogin?.call() ?? false;

  /// 홈 위쪽 막대의 로그인 버튼과 같은 동작(그 버튼의 명령을 실행한다).
  void login() => _login?.call();

  /// 메인 화면이 서버 설정으로 다시 구성된 횟수(로그인·로그아웃 뒤 등). 출결·도서관 탭은 실패한
  /// 뒤 이 값이 바뀌었으면 다시 열 때 주소를 다시 받아 온다.
  int get generation => _generation;

  void mainConfigured() => _generation++;
}
