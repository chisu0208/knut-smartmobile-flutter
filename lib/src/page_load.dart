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
class PageLoad {
  PageLoad(this._onChanged);

  /// 이 시간이 지나도 응답이 없으면 늦어지고 있다고 안내한다.
  static const Duration slowAfter = Duration(seconds: 10);

  /// 새 페이지가 시작됐는데 첫 화면 알림이 오지 않을 때 로딩 표시를 걷는 시간.
  static const Duration settleAfterCommit = Duration(seconds: 5);

  final VoidCallback _onChanged;

  bool _busy = false;
  ConnectionProblem? _problem;
  Timer? _slowTimer;
  Timer? _settleTimer;

  /// 앱이 직접 불러온 주소와 헤더.
  String? _ownUrl;
  Map<String, String> _ownHeaders = const <String, String>{};

  /// 직접 불러온 페이지가 시작됐는지, 오류 없이 끝났는지.
  bool _ownStarted = false;
  bool _ownDone = true;

  /// 본문 프레임이 실패한 주소(그 오류 페이지의 시작·끝 알림을 가려낸다).
  String? _errorUrl;

  /// 링크로 시작한 본문 이동의 주소.
  String? _navigatingTo;

  /// 본문 프레임을 불러오는 중이고 새 화면이 아직 그려지지 않았다.
  bool get busy => _busy;

  /// 지금 보여 줄 연결 안내. 없으면 null.
  ConnectionProblem? get problem => _problem;

  /// 앱이 직접 불러온 페이지가 오류 없이 끝났는지.
  bool get ownLoadDone => _ownDone;

  /// 앱이 `loadUrl(url, headers)`로 불러오기 시작했다.
  void ownLoad(String url, Map<String, String> headers) {
    _ownUrl = url;
    _ownHeaders = headers;
    _ownStarted = false;
    _ownDone = false;
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
    _ownDone = false;
    _problem = ConnectionProblem.offline;
    settle();
  }

  /// 연결 안내의 `다시 시도`: 어떻게 다시 불러올지 고르고 상태를 되돌린다.
  RetryAction retry() {
    final String? own = _ownUrl;
    if (own != null && !_ownDone) {
      // 앱이 불러온 페이지가 아직 끝나지 않았다: 헤더까지 같게 다시 부른다.
      final Map<String, String> headers = _ownHeaders;
      ownLoad(own, headers);
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
  void navigate(String? url) {
    _navigatingTo = url;
    _errorUrl = null;
    if (_problem != ConnectionProblem.slow) _problem = null;
    _begin();
  }

  /// 서버가 답해서 새 페이지가 기록에 들어갔다(`doUpdateVisitedHistory`).
  void committed() {
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
    if (!_ownDone) _ownStarted = true;
    _busy = true;
    committed();
  }

  /// `onPageFinished`
  void pageFinished(String url) {
    settle();
    if (url == _errorUrl) return;
    if (_ownStarted) _ownDone = true;
    if (_problem != null) {
      _problem = null;
      _onChanged();
    }
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

  /// 서버가 답했다: 늦어진다는 안내를 걷는다.
  void _connected() {
    _slowTimer?.cancel();
    _slowTimer = null;
    if (_problem == ConnectionProblem.slow) _problem = null;
  }
}
