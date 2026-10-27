import 'dart:ui';

/// `res/anim/translate_*.xml` 여덟 개(fillAfter).
///
/// 원본은 500ms, accelerate_decelerate(천천히 출발)였다. 개선판은 [AnimTrack.duration]
/// 250ms에 decelerate(빠르게 출발해 감속)로 바꿨다(통합본 6-2). 움직이는 거리와 방향은 원본 그대로다.
enum LegacyAnim {
  inBottom, // fromY 100%p → 0
  inLeft, // fromX -100%p → 0
  inRight, // fromX 100%p → 0
  inTop, // fromY -100%p → 0
  outBottom, // 0 → toY 100%(자기 높이)
  outLeft, // 0 → toX -100%(자기 폭)
  outRight, // 0 → toX 100%
  outTop, // 0 → toY -100%
}

/// Android `View.startAnimation`/`clearAnimation`을 흉내 낸 한 뷰의 애니메이션 상태.
///
/// - 시작 시각은 처음 그려지는 프레임에서 정해진다(START_ON_FIRST_FRAME).
/// - fillAfter라서 끝난 뒤에도 마지막 위치에 머물고, `clear()` 전까지 붙어 있다.
/// - 붙어 있는 동안에는 뷰가 INVISIBLE/GONE이어도 그려지고 터치를 받는다(Android 동작).
/// - 다른 애니메이션으로 바꾸면 이전 것은 끝 알림 없이 사라진다.
/// - `clear()`는 아직 끝나지 않은 애니메이션이면 끝 알림을 보낸다(`Animation.detach()`).
class AnimTrack {
  AnimTrack(this._listenerFor);

  /// 원본 500ms → 개선판 250ms(통합본 6-2).
  static const Duration duration = Duration(milliseconds: 250);

  /// DecelerateInterpolator(factor 1): 빠르게 출발해 감속한다. 원본은 AccelerateDecelerate.
  static double curve(double t) => 1 - (1 - t) * (1 - t);

  final void Function() Function(LegacyAnim anim) _listenerFor;

  LegacyAnim? _anim;
  Duration? _startedAt;
  bool _ended = false;
  double _t = 0;

  /// `getAnimation() != null`
  bool get attached => _anim != null;

  /// 아직 시간이 흘러야 하는지.
  bool get running => _anim != null && !_ended;

  void start(LegacyAnim anim) {
    _anim = anim;
    _startedAt = null;
    _ended = false;
    _t = 0;
  }

  void clear() {
    final LegacyAnim? anim = _anim;
    final bool fire = anim != null && _startedAt != null && !_ended;
    _anim = null;
    _startedAt = null;
    _ended = false;
    _t = 0;
    if (fire) _listenerFor(anim)();
  }

  /// 그려지는 프레임마다 부른다. 끝났으면 끝 알림을 보낸다.
  void tick(Duration now) {
    final LegacyAnim? anim = _anim;
    if (anim == null || _ended) return;
    _startedAt ??= now;
    final double t =
        (now - _startedAt!).inMicroseconds / duration.inMicroseconds;
    if (t >= 1) {
      _t = 1;
      _ended = true;
      _listenerFor(anim)();
    } else {
      _t = t;
    }
  }

  /// 지금 적용할 이동량. [parent]는 부모 크기(%p), [self]는 자기 크기(%).
  Offset offset(Size parent, Size self) {
    final LegacyAnim? anim = _anim;
    if (anim == null) return Offset.zero;
    final double f = curve(_t);
    double lerp(double a, double b) => a + (b - a) * f;
    return switch (anim) {
      LegacyAnim.inBottom => Offset(0, lerp(parent.height, 0)),
      LegacyAnim.inLeft => Offset(lerp(-parent.width, 0), 0),
      LegacyAnim.inRight => Offset(lerp(parent.width, 0), 0),
      LegacyAnim.inTop => Offset(0, lerp(-parent.height, 0)),
      LegacyAnim.outBottom => Offset(0, lerp(0, self.height)),
      LegacyAnim.outLeft => Offset(lerp(0, -self.width), 0),
      LegacyAnim.outRight => Offset(lerp(0, self.width), 0),
      LegacyAnim.outTop => Offset(0, lerp(0, -self.height)),
    };
  }
}

/// 팝업 크기(px). null이면 꽉 채움(match_parent).
typedef PopupSizePx = ({int? width, int? height});

/// 정렬별 팝업 크기(HANDOFF 5.7): `left`·`right`는 화면폭×0.8 × 꽉, `top`·`bottom`은
/// 꽉 × 화면높이×0.8, `center`는 둘 다 0.8, `full`은 꽉. 화면 크기는 `Display.getSize`(px).
/// 그 밖의 정렬이면 null(원본은 크기를 바꾸지 않는다).
///
/// 원본은 팝업을 열 때 한 번 계산했다. 개선판은 그릴 때마다 지금 화면 크기로 계산해서, 분할
/// 화면·창 크기가 바뀌어도 열려 있는 팝업이 창에 맞는다(통합본 6-12).
PopupSizePx? popupSizePx(String align, int screenWidthPx, int screenHeightPx) {
  final int w80 = (screenWidthPx * 0.8).truncate();
  final int h80 = (screenHeightPx * 0.8).truncate();
  return switch (align) {
    'left' || 'right' => (width: w80, height: null),
    'top' || 'bottom' => (width: null, height: h80),
    'center' => (width: w80, height: h80),
    'full' => (width: null, height: null),
    _ => null,
  };
}
