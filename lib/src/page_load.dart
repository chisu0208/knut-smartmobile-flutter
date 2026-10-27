import 'dart:async';

import 'package:flutter/foundation.dart';

import 'connection_notice.dart';

/// [PageLoad.retry]가 고른 다시 시도 방법.
sealed class RetryAction {
  const RetryAction();
}

/// 앱이 불러온 주소를 헤더까지 같게 다시 부른다.
class RetryOwnLoad extends RetryAction {
  const RetryOwnLoad(this.url, this.headers);
  final String url;
  final Map<String, String> headers;
}

/// 링크로 가던(또는 실패한) 주소를 다시 부른다.
class RetryUrl extends RetryAction {
  const RetryUrl(this.url);
  final String url;
}

/// 지금 페이지를 새로 고친다.
class RetryReload extends RetryAction {
  const RetryReload();
}

/// 웹뷰 하나의 본문 프레임 불러오기 상태(로딩 표시와 연결 안내).
///
/// - 로딩 표시([busy]): 불러오기를 시작하면 켜고, 새 화면이 처음 그려지면(`visible`) 끈다.
///   원본은 페이지의 모든 파일이 끝날 때까지 화면 전체를 막았다(통합본 3-31).
/// - 연결 안내([problem]): 본문 프레임이 연결 오류로 실패하면 생기고, [slowAfter]가 지나도
///   서버가 답하지 않으면 "늦어지고 있습니다"가 된다(통합본 1-9, 6-10).
///
/// Android WebView의 `onPageStarted`는 서버가 답해서 새 페이지가 시작될 때 온다. 그래서 연결을
/// 기다리는 동안을 알려면 앱이 직접 불러올 때([ownLoad])와 링크로 이동할 때([navigate])부터 잰다.
///
/// 방문 기록 지우기([ownLoad]의 `clearHistory`, [onClearHistory])는 앱이 불러온 그 페이지에만
/// 붙는다.
/// - 그 페이지가 시작될 때(기록에 들어감)와 오류 없이 끝날 때 지운다. 시작될 때 지우므로 다 뜨기
///   전에 링크를 눌러도 이전 기록이 남지 않는다. 서버 리디렉션과 페이지 스크립트가 스스로 넘긴
///   이동은 같은 불러오기로 보고, 넘어간 페이지가 시작·끝날 때도 지운다.
/// - 시작되기 전에(또는 시작된 뒤 끝나기 전에) 사용자가 링크를 누르거나(`byUser`), 뒤로 키로
///   이전 페이지로 가거나([goBack]), 앱이 다른 주소를 불러오면([ownLoad]) 남은 지우기를 버린다.
///   그 뒤 연결 안내의 다시 시도는 앱이 불러온 주소가 아니라 사용자가 간 주소를 다시 부른다.
/// - 연결 오류로 실패하면 남겨 두고, 다시 시도(같은 주소를 같은 헤더로)가 성공하면 지운다.
class PageLoad {
  PageLoad(this._onChanged, {this.onClearHistory});

  /// 이 시간이 지나도 응답이 없으면 늦어지고 있다고 안내한다.
  static const Duration slowAfter = Duration(seconds: 10);

  /// 새 페이지가 시작됐는데 첫 화면 알림이 오지 않을 때 로딩 표시를 걷는 시간.
  static const Duration settleAfterCommit = Duration(seconds: 5);

  final VoidCallback _onChanged;

  /// 방문 기록을 지울 때(`WebView.clearHistory`: 지금 페이지만 남긴다).
  final VoidCallback? onClearHistory;

  bool _busy = false;
  ConnectionProblem? _problem;
  Timer? _slowTimer;
  Timer? _settleTimer;

  /// 앱이 직접 불러온 주소와 헤더.
  String? _ownUrl;
  Map<String, String> _ownHeaders = const <String, String>{};

  /// 직접 불러온 페이지가 아직 끝나지 않았는지(다른 이동으로 바뀌지도 않음), 시작됐는지.
  bool _ownPending = false;
  bool _ownStarted = false;

  /// 직접 불러온 페이지가 끝나면 방문 기록을 지운다.
  bool _clearHistoryPending = false;

  /// 이 웹뷰가 about:blank가 아닌 페이지를 한 번이라도 그렸는지.
  bool _hasPage = false;

  /// 본문 프레임이 실패한 주소(그 오류 페이지의 시작·끝 알림을 가려낸다).
  String? _errorUrl;

  /// 링크로 시작한 본문 이동의 주소.
  String? _navigatingTo;

  /// 본문 프레임을 불러오는 중이고 새 화면이 아직 그려지지 않았다.
  bool get busy => _busy;

  /// 지금 보여 줄 연결 안내. 없으면 null.
  ConnectionProblem? get problem => _problem;

  /// 이 웹뷰가 about:blank가 아닌 페이지를 한 번이라도 그렸는지(시작했는지).
  /// 내려받기 주소만 연 창은 페이지가 시작되지 않으므로 false다.
  bool get hasPage => _hasPage;

  /// 앱이 `loadUrl(url, headers)`로 불러오기 시작했다. [clearHistory]면 이 페이지가 끝난 뒤
  /// 방문 기록을 지운다(클래스 설명).
  void ownLoad(
    String url,
    Map<String, String> headers, {
    bool clearHistory = false,
  }) {
    _ownUrl = url;
    _ownHeaders = headers;
    _ownStarted = false;
    _ownPending = true;
    _clearHistoryPending = clearHistory;
    _errorUrl = null;
    _navigatingTo = null;
    _problem = null;
    _begin();
  }

  /// 네트워크가 없어서 [url]을 불러오지 않았다. 다시 시도하면 그때 불러온다.
  void offline(String url, Map<String, String> headers) {
    _ownUrl = url;
    _ownHeaders = headers;
    _ownStarted = false;
    _ownPending = true;
    _clearHistoryPending = false;
    _problem = ConnectionProblem.offline;
    settle();
  }

  /// 연결 안내의 `다시 시도`: 어떻게 다시 불러올지 고르고 상태를 되돌린다.
  RetryAction retry() {
    final String? own = _ownUrl;
    if (own != null && _ownPending) {
      // 앱이 불러온 페이지가 아직 끝나지 않았다: 헤더까지 같게 다시 부른다.
      final Map<String, String> headers = _ownHeaders;
      ownLoad(own, headers, clearHistory: _clearHistoryPending);
      return RetryOwnLoad(own, headers);
    }
    final String? target = _errorUrl ?? _navigatingTo;
    _problem = null;
    _errorUrl = null;
    _navigatingTo = target;
    _begin();
    return target != null ? RetryUrl(target) : const RetryReload();
  }

  /// 링크로 본문 이동을 시작했다(`shouldOverrideUrlLoading`에서 가로채지 않음).
  /// [byUser]면 사용자가 누른 이동이라 앱이 불러오던 페이지를 대신한다.
  void navigate(String? url, {bool byUser = false}) {
    if (byUser) _dropOwnLoad();
    _navigatingTo = url;
    _errorUrl = null;
    if (_problem != ConnectionProblem.slow) _problem = null;
    _begin();
  }

  /// 앱이 뒤로 키로 이전 페이지로 간다(`goBack`).
  void goBack() => _dropOwnLoad();

  /// 서버가 답해서 새 페이지가 기록에 들어갔다(`doUpdateVisitedHistory`).
  void committed([String? url]) {
    if (!_isBlank(url)) _hasPage = true;
    _connected();
    if (_busy) {
      _settleTimer?.cancel();
      _settleTimer = Timer(settleAfterCommit, settle);
    }
    _onChanged();
  }

  /// `onPageStarted`
  void pageStarted(String url) {
    if (url == _errorUrl) return; // 실패한 주소의 오류 페이지
    if (_ownPending) {
      _ownStarted = true;
      if (_clearHistoryPending) onClearHistory?.call();
    }
    _busy = true;
    committed(url);
  }

  /// `onPageFinished`
  void pageFinished(String url) {
    settle();
    if (url == _errorUrl) return;
    if (_ownPending && _ownStarted) {
      _ownPending = false;
      if (_clearHistoryPending) onClearHistory?.call();
      _clearHistoryPending = false;
    }
    if (_problem != null) {
      _problem = null;
      _onChanged();
    }
  }

  /// 새 화면이 처음 그려졌다(`onPageCommitVisible`): 로딩 표시를 끈다.
  void visible(String? url) {
    if (!_isBlank(url)) _hasPage = true;
    settle();
  }

  /// `onProgressChanged`: 100이면 (멈췄거나 끝났으므로) 로딩 표시를 걷는다.
  void progress(int value) {
    if (value >= 100 && _busy) settle();
  }

  /// 본문 프레임 오류. [connectionError]면 연결 안내를 띄운다.
  void mainFrameError(String? url, {required bool connectionError}) {
    _errorUrl = url;
    if (connectionError) _problem = ConnectionProblem.failed;
    settle();
  }

  /// 연결 실패를 확인해 보니 네트워크 자체가 없었다.
  void markOffline() {
    if (_problem != ConnectionProblem.failed) return;
    _problem = ConnectionProblem.offline;
    _onChanged();
  }

  /// 새 화면이 그려졌거나(`visible`) 불러오기가 끝났다: 로딩 표시를 끈다.
  void settle() {
    _connected();
    _settleTimer?.cancel();
    _settleTimer = null;
    _navigatingTo = null;
    _busy = false;
    _onChanged();
  }

  /// 불러오기 시작: 로딩 표시를 켜고, 늦어지는지 재기 시작한다.
  void _begin() {
    _busy = true;
    _settleTimer?.cancel();
    _settleTimer = null;
    _slowTimer?.cancel();
    _slowTimer = Timer(slowAfter, _onSlow);
    _onChanged();
  }

  void _onSlow() {
    _slowTimer = null;
    if (_busy && _problem == null) {
      _problem = ConnectionProblem.slow;
      _onChanged();
    }
  }

  /// 앱이 불러오던 페이지를 다른 이동이 대신했다: 기록 지우기와 그 주소의 다시 시도를 버린다.
  void _dropOwnLoad() {
    _ownPending = false;
    _clearHistoryPending = false;
  }

  static bool _isBlank(String? url) =>
      url == null || url.isEmpty || url.startsWith('about:blank');

  /// 서버가 답했다: 늦어진다는 안내를 걷는다.
  void _connected() {
    _slowTimer?.cancel();
    _slowTimer = null;
    if (_problem == ConnectionProblem.slow) _problem = null;
  }
}

/// 내려받기가 시작된 [kind] 창을 닫을지.
///
/// 공지 첨부파일은 `window.open`으로 연 자식 창이 내려받기 주소(`FileDown.do`)를 바로 연다.
/// 내려받기는 페이지가 아니라서 그 창에는 그려진 페이지가 없고, 그대로 두면 팝업이 하얗게 남는다
/// (원본도 같았다). 그래서 자식·손자 창이 아직 페이지를 하나도 그리지 않았으면([PageLoad.hasPage])
/// 닫는다. 페이지를 보여 준 뒤 그 안에서 내려받는 창, 팝업·메인 웹뷰는 닫지 않는다.
///
/// 내려받기가 시작될 때 창의 주소(`WebView.getUrl`)는 내려받기 주소라서 주소로는 가릴 수 없다.
bool closeWindowAfterDownload(String kind, PageLoad load) =>
    (kind == 'child' || kind == 'grandchild') && !load.hasPage;
