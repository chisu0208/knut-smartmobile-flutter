import 'popup_animation.dart';

/// 팝업이 보이는지와 뒤로 키를 누가 받는지(원본 MainActivity 필드, HANDOFF 5.7·5.12·5.13).
///
/// - [shown] `f7670B`: 팝업이 다 나와 있다(등장 애니메이션이 끝남).
/// - [bgVisible]: 반투명 배경(`popup_bg_container`)이 보인다.
/// - [mainOwner] `f7676E`: 뒤로 키를 메인 웹뷰가 받는다. false면 팝업 쪽(5.13 4번).
/// - [align] `f7672C`: 지금 팝업의 정렬.
/// - [bg]·[body]: 반투명 배경 전체와 팝업 본체의 애니메이션. `left`만 등장을 [bg]에 건다.
///
/// 화면(배치·크기)은 메인 화면이 그리고, 여기에는 상태가 바뀌는 규칙만 둔다.
class PopupState {
  PopupState({required this.onAnimationStart, required this.webviewIsMain});

  /// 애니메이션을 시작했다. 메인 화면이 프레임을 돌려 [tick]을 부른다.
  final void Function() onAnimationStart;

  /// 저장된 `webview` 값이 `main`인지(오른쪽 애니메이션의 끝 처리가 본다).
  final bool Function() webviewIsMain;

  bool shown = false;
  bool bgVisible = false;
  bool mainOwner = true;
  String? align;

  late final AnimTrack bg = AnimTrack(_listenerFor);
  late final AnimTrack body = AnimTrack(_listenerFor);

  /// 배경이 보이거나 애니메이션이 붙어 있으면 그려진다(그려질 때만 시간이 흐름).
  bool get drawn => bgVisible || bg.attached;

  /// 아직 시간이 흘러야 하는 애니메이션이 있다.
  bool get animating => drawn && (bg.running || body.running);

  /// 팝업 구성(`RunnableC0257a`)의 시작: `f7676E = false`, `f7670B = false`.
  void beginOpen() {
    mainOwner = false;
    shown = false;
  }

  /// 정렬별 등장(5.7 3번). `center`·`full`은 애니메이션 없이 바로 다 나온다.
  void enter(String align) {
    this.align = align;
    switch (align) {
      case 'left':
        if (!shown) {
          bgVisible = true;
          _start(bg, LegacyAnim.inLeft);
        }
      case 'right':
        if (!shown) {
          bgVisible = true;
          _start(body, LegacyAnim.inRight);
        }
      case 'center':
      case 'full':
        shown = true;
        bg.clear();
        bgVisible = true;
      case 'top':
        if (!shown) {
          bgVisible = true;
          _start(body, LegacyAnim.inTop);
        }
      case 'bottom':
        if (!shown) {
          bgVisible = true;
          _start(body, LegacyAnim.inBottom);
        }
    }
  }

  /// `A0()`의 닫기(runOnUiThread 안). 다 나와 있으면 정렬별 퇴장, 아니면 바로 숨긴다.
  ///
  /// 개선판:
  /// - 닫는 모든 경로(✕·배경 탭·`browser` 명령·뒤로 키·연결 안내 `닫기`)에서 뒤로 키를 메인으로
  ///   되돌린다. 원본은 메인 구성과 뒤로 키로 닫을 때만 되돌려서(5.12), ✕나 배경 탭으로 닫은 뒤
  ///   첫 뒤로 키가 숨은 팝업으로 가 아무 반응이 없었다.
  /// - 나오는 중(다 나오기 전)에 닫으면 배경·본체 애니메이션을 모두 뗀다. 원본은 `left` 팝업의
  ///   배경이 남았고(fillAfter), 다른 정렬은 나중에 끝 알림이 "다 나옴"으로 바꿀 수 있었다.
  void close() {
    if (!shown) {
      bgVisible = false;
      // 나오는 중이었으면 끝 알림이 shown을 true로 바꾸므로 뗀 뒤 되돌린다.
      bg.clear();
      body.clear();
      shown = false;
    } else {
      switch (align) {
        case 'left':
          _start(body, LegacyAnim.outLeft);
        case 'right':
          _start(body, LegacyAnim.outRight);
        case 'top':
          _start(body, LegacyAnim.outTop);
        case 'bottom':
          _start(body, LegacyAnim.outBottom);
        default:
          bgVisible = false;
          shown = false;
      }
    }
    mainOwner = true;
  }

  /// 메인 구성(`webview`/`main`)의 "팝업 애니메이션 취소".
  void cancelAnimation() => bg.clear();

  /// 그려지는 프레임마다 부른다.
  void tick(Duration now) {
    if (!drawn) return;
    bg.tick(now);
    if (drawn) body.tick(now);
  }

  void _start(AnimTrack track, LegacyAnim anim) {
    track.start(anim);
    onAnimationStart();
  }

  /// 원본 onCreate에서 애니메이션마다 붙인 리스너(y: 왼쪽, z: 오른쪽, A: 위, x: 아래).
  void Function() _listenerFor(LegacyAnim anim) {
    switch (anim) {
      case LegacyAnim.inRight:
      case LegacyAnim.outRight:
        return () {
          if (shown) {
            bgVisible = false;
            body.clear();
            bg.clear(); // 개선판: 앞선 left 팝업의 배경 애니메이션도 뗀다(close 참고)
            shown = false;
          } else {
            shown = !webviewIsMain();
          }
        };
      case LegacyAnim.inLeft:
      case LegacyAnim.outLeft:
      case LegacyAnim.inTop:
      case LegacyAnim.outTop:
      case LegacyAnim.inBottom:
      case LegacyAnim.outBottom:
        return () {
          if (!shown) {
            shown = true;
            return;
          }
          bgVisible = false;
          body.clear();
          // 개선판: left 팝업이 배경에 건 등장 애니메이션도 떼어, 닫은 뒤 배경이 남지 않게 한다
          // (HANDOFF 5.12). 이미 끝난 애니메이션이라 끝 알림은 다시 오지 않는다.
          bg.clear();
          shown = false;
        };
    }
  }
}
