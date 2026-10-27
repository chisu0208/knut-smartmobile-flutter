import 'package:flutter_test/flutter_test.dart';
import 'package:knut_smartmobile/src/popup_animation.dart';

/// 팝업 크기(HANDOFF 5.7, 통합본 6-12): 정렬별 80% 규칙을 지금 화면 크기로 계산한다.
void main() {
  test('정렬별 크기는 원본 규칙 그대로(화면의 80%, 소수점 버림)', () {
    expect(popupSizePx('left', 1080, 2274), (width: 864, height: null));
    expect(popupSizePx('right', 1080, 2274), (width: 864, height: null));
    expect(popupSizePx('top', 1080, 2274), (width: null, height: 1819));
    expect(popupSizePx('bottom', 1080, 2274), (width: null, height: 1819));
    expect(popupSizePx('center', 1080, 2274), (width: 864, height: 1819));
    expect(popupSizePx('full', 1080, 2274), (width: null, height: null));
  });

  test('알 수 없는 정렬이면 null(이전 크기를 그대로 씀)', () {
    expect(popupSizePx('middle', 1080, 2274), isNull);
  });

  test('분할 화면으로 창이 줄면 같은 정렬도 새 창의 80%', () {
    // Pixel 7 세로 전체(1080×2274px) → 위아래 분할 화면의 위쪽 창(1080×1100px 정도)
    expect(popupSizePx('center', 1080, 1100), (width: 864, height: 880));
    expect(popupSizePx('bottom', 1080, 1100), (width: null, height: 880));
    // 가로로 돌리면 폭과 높이가 바뀐다
    expect(popupSizePx('right', 2400, 1000), (width: 1920, height: null));
  });
}
