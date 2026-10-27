import 'dart:async';
import 'dart:convert';

/// 학교 웹 사이트를 탭 안에 띄우는 탭(개선판 2차).
///
/// 메인 페이지의 타일은 `AllytteCommand.callService("SERVICE", id)`로 서버 서비스를 부르고, 서버가
/// 앱 명령으로 답한다(`https://mobile.ut.ac.kr/js/allytte-command.js`). 로그인한 메인에서 확인한
/// 서비스 id와 응답(로컬 세션, 2026-10-27):
/// - 전자출결 `9`: `browser` 명령, Chrome에서 로그인된 채 `attend.ut.ac.kr`이 열림
/// - 도서관 `e`: full 팝업(`webview`/`popup`)으로 `https://mchains.ut.ac.kr/index.ax`
enum WebTabKind {
  attend(
    title: '출결',
    serviceName: '전자출결',
    serviceId: '9',
    host: 'attend.ut.ac.kr',
  ),
  library(
    title: '도서관',
    serviceName: '도서관',
    serviceId: 'e',
    host: 'mchains.ut.ac.kr',
  );

  const WebTabKind({
    required this.title,
    required this.serviceName,
    required this.serviceId,
    required this.host,
  });

  /// 탭 이름.
  final String title;

  /// 학교 서비스 이름(안내 문구).
  final String serviceName;

  /// `AllytteCommand.callService("SERVICE", id)`의 id.
  final String serviceId;

  /// 이 탭으로 보내는 주소의 호스트.
  final String host;
}

/// 출결·도서관 탭에 불러올 주소.
class TabRoute {
  const TabRoute(this.tab, this.url);

  final WebTabKind tab;
  final String url;

  @override
  bool operator ==(Object other) =>
      other is TabRoute && other.tab == tab && other.url == url;

  @override
  int get hashCode => Object.hash(tab, url);

  @override
  String toString() => 'TabRoute(${tab.name}, $url)';
}

/// [url]의 호스트가 출결·도서관 탭 주소이면 그 탭.
WebTabKind? tabForUrl(String url) {
  final Uri? uri = Uri.tryParse(url.trim());
  if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
    return null;
  }
  final String host = uri.host.toLowerCase();
  for (final WebTabKind kind in WebTabKind.values) {
    if (host == kind.host) return kind;
  }
  return null;
}

/// 서버 명령 JSON(`{"action":[…]}`)이 출결·도서관 탭 주소를 여는 명령이면 그 탭과 주소.
///
/// 주소를 꺼내는 규칙은 여기 한 곳이다. 서버 응답의 정확한 모양은 클라우드에서 확인하지 못해서,
/// 아래에 맞지 않으면 null을 돌려주고 명령은 홈에서 원래대로 처리된다(전자출결은 외부 브라우저,
/// 도서관은 full 팝업).
/// - 주소 명령(`browser`, 또는 `webview`의 `show`가 `popup`)이 정확히 하나
/// - 그 주소(`config.url`)의 호스트가 `attend.ut.ac.kr` 또는 `mchains.ut.ac.kr`
/// - 나머지 명령은 팝업 닫기(`function`/`close`)뿐
TabRoute? tabRouteOf(String? json) {
  if (json == null || json.isEmpty) return null;
  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException {
    return null;
  }
  if (decoded is! Map<String, Object?>) return null;
  final Object? actions = decoded['action'];
  if (actions is! List<Object?> || actions.isEmpty) return null;
  TabRoute? route;
  for (final Object? action in actions) {
    if (action is! Map<String, Object?>) return null;
    final Object? command = action['command'];
    final Object? config = action['config'];
    if (config is! Map<String, Object?>) return null;
    if (command == 'function' && config['function'] == 'close') continue;
    final Object? url = config['url'];
    final bool address =
        command == 'browser' ||
        (command == 'webview' && config['show'] == 'popup');
    if (!address || url is! String || route != null) return null;
    final WebTabKind? tab = tabForUrl(url);
    if (tab == null) return null;
    route = TabRoute(tab, url);
  }
  return route;
}

/// 서버 하단 바(개선판 2차부터 홈 위쪽 막대) 버튼의 JSON이 로그인 버튼인지.
///
/// 원본 하단 바의 마지막 버튼(사람+자물쇠)은 로그인하기 전에는 로그인 full 팝업을 열고, 로그인한
/// 뒤에는 같은 자리에서 로그아웃을 한다(통합본 3-3, 3-4). 탭의 "로그인" 버튼이 로그아웃을 하면 안
/// 되므로 로그아웃 표시가 있는 버튼은 고르지 않는다.
bool isLoginButton(String buttonJson) {
  final String lower = buttonJson.toLowerCase();
  const List<String> logout = <String>[
    'logout',
    'log_out',
    'log-out',
    'signout',
  ];
  if (logout.any(lower.contains) || buttonJson.contains('로그아웃')) {
    return false;
  }
  const List<String> login = <String>['login', 'log_in', 'log-in', 'signin'];
  return login.any(lower.contains) || buttonJson.contains('로그인');
}

/// 탭이 홈 웹뷰에 서비스 주소를 요청한 결과.
sealed class ServiceResult {
  const ServiceResult();
}

/// 서버가 탭 주소 명령으로 답했다.
class ServiceRouted extends ServiceResult {
  const ServiceRouted(this.route);
  final TabRoute route;
}

/// 서버가 답했지만 주소 명령이 아니었다(로그인이 필요하다는 알림 등). 그 명령은 홈에서 처리했다.
class ServiceNotRouted extends ServiceResult {
  const ServiceNotRouted();
}

/// 답이 없었다. [called]가 false면 홈 화면이 학교 메인 페이지가 아니라서 부르지 못했다.
class ServiceNoResponse extends ServiceResult {
  const ServiceNoResponse({required this.called});
  final bool called;
}

/// 탭의 서비스 주소 요청을 홈 웹뷰에서 오는 명령과 맞춘다.
///
/// 홈 웹뷰에서 [script]를 실행하면 웹 페이지가 앱에 `시작 표시 → 서버 응답 → 끝 표시`를 차례로
/// 보낸다(`allytteAndroid.allytteCommandHandler`). `callService`는 동기 요청(`async: false`)이라
/// 응답은 두 표시 사이에 온다. 그 사이에 온 탭 주소 명령은 여기서 가로채고, 다른 명령은 홈에서
/// 원래대로 처리하게 둔다(가로채지 않음).
class ServiceRequests {
  ServiceRequests({this.timeout = const Duration(seconds: 15)});

  /// 끝 표시가 이 시간 안에 오지 않으면 답이 없는 것으로 본다.
  final Duration timeout;

  static const String _markerKey = 'knutTabRequest';

  final Map<int, _PendingService> _pending = <int, _PendingService>{};
  int _nextId = 1;
  int? _active;

  /// 새 요청. [script]에 같은 id를 넣어 홈 웹뷰에서 실행한다.
  ({int id, Future<ServiceResult> result}) start() {
    final int id = _nextId++;
    final _PendingService pending = _PendingService();
    pending.timer = Timer(timeout, () => _finish(id, called: false));
    _pending[id] = pending;
    return (id: id, result: pending.completer.future);
  }

  /// 스크립트를 실행하지 못했을 때.
  void cancel(int id) => _finish(id, called: false);

  /// 홈 웹뷰에서 실행할 스크립트.
  static String script(int id, String serviceId) {
    final String sid = jsonEncode(serviceId);
    return '''
(function () {
  var bridge = window.allytteAndroid;
  if (!bridge) return;
  bridge.allytteCommandHandler('{"$_markerKey":"begin","id":$id}');
  var called = false;
  try {
    if (typeof AllytteCommand !== 'undefined' && AllytteCommand.callService) {
      called = true;
      AllytteCommand.callService("SERVICE", $sid);
    }
  } catch (e) {}
  bridge.allytteCommandHandler('{"$_markerKey":"end","id":$id,"called":' + called + '}');
})();''';
  }

  /// 홈 웹뷰가 보낸 명령. true면 여기서 처리했으니(표시, 가로챈 주소) 명령 처리기에 넣지 않는다.
  bool handle(String? json) {
    final ({String type, int id, bool called})? marker = _markerOf(json);
    if (marker != null) {
      if (marker.type == 'begin') {
        _active = _pending.containsKey(marker.id) ? marker.id : null;
      } else {
        if (_active == marker.id) _active = null;
        _finish(marker.id, called: marker.called);
      }
      return true;
    }
    final _PendingService? pending = _active == null ? null : _pending[_active];
    if (pending == null) return false;
    final TabRoute? route = tabRouteOf(json);
    if (route != null && pending.route == null) {
      pending.route = route;
      return true;
    }
    pending.gotOther = true;
    return false;
  }

  void _finish(int id, {required bool called}) {
    final _PendingService? pending = _pending.remove(id);
    if (pending == null) return;
    pending.timer?.cancel();
    final TabRoute? route = pending.route;
    pending.completer.complete(
      route != null
          ? ServiceRouted(route)
          : pending.gotOther
          ? const ServiceNotRouted()
          : ServiceNoResponse(called: called),
    );
  }

  static ({String type, int id, bool called})? _markerOf(String? json) {
    if (json == null || !json.contains(_markerKey)) return null;
    try {
      final Object? decoded = jsonDecode(json);
      if (decoded is! Map<String, Object?>) return null;
      final Object? type = decoded[_markerKey];
      final Object? id = decoded['id'];
      if ((type != 'begin' && type != 'end') || id is! int) return null;
      return (type: type as String, id: id, called: decoded['called'] == true);
    } on FormatException {
      return null;
    }
  }
}

class _PendingService {
  final Completer<ServiceResult> completer = Completer<ServiceResult>();
  Timer? timer;
  TabRoute? route;
  bool gotOther = false;
}
