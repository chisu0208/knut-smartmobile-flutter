import 'dart:async';

import 'package:flutter/material.dart';

/// 앱을 쓰는 동안 인터넷이 끊겼을 때 홈 맨 위에 보이는 안내 띠(개선판).
///
/// 홈 타일은 페이지가 서버로 직접 요청을 보내서, 연결이 끊기면 눌러도 아무 반응이 없었고 앱은 그
/// 실패를 알 수 없었다. 앱이 연결 상태(Kotlin `networkChanged`)를 따로 지켜보다가 이 띠로 알린다.
/// 앱 하단 바 버튼과 팝업은 이미 열 때 연결을 확인해 연결 안내([ConnectionNotice])를 보인다.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  static const String message = '인터넷에 연결되어 있지 않습니다';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      child: const ColoredBox(
        color: Color(0xFF3A3F4B),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.wifi_off, size: 18, color: Colors.white),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 연결이 끊겼다는 알림을 바로 띠로 바꾸지 않고 [delay] 동안 지켜본다.
///
/// 와이파이에서 모바일 데이터로 넘어갈 때처럼 잠깐 끊겼다 돌아오는 경우에 띠가 깜빡이지 않게 한다.
/// 끊긴 채로 [delay]가 지나야 [onChanged]가 `true`(끊김)로 불리고, 돌아오면 바로 `false`로 불린다.
class OfflineTracker {
  OfflineTracker({
    required this.onChanged,
    this.delay = const Duration(milliseconds: 1500),
  });

  final void Function(bool offline) onChanged;
  final Duration delay;

  bool _offline = false;
  Timer? _timer;

  /// 지금 띠를 보여야 하는지.
  bool get offline => _offline;

  /// Kotlin이 알려 준 연결 상태. 끊긴 상태가 이어지는 동안 거듭 불려도 기다리는 시간은 다시 재지 않는다.
  void update({required bool online}) {
    if (online) {
      _timer?.cancel();
      _timer = null;
      if (_offline) {
        _offline = false;
        onChanged(false);
      }
      return;
    }
    if (_offline || _timer != null) return;
    _timer = Timer(delay, () {
      _timer = null;
      _offline = true;
      onChanged(true);
    });
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
