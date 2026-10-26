import 'dart:math' as math;
import 'dart:ui';

/// `res/anim/translate_*.xml` 여덟 개(500ms, accelerate_decelerate, fillAfter).
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

  static const Duration duration = Duration(milliseconds: 500);

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
    // AccelerateDecelerateInterpolator
    final double f = math.cos((_t + 1) * math.pi) / 2 + 0.5;
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
