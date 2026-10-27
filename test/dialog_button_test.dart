import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knut_smartmobile/main.dart' show SmartMobileApp;
import 'package:knut_smartmobile/src/legacy_widgets.dart';

/// `dialog` 명령의 버튼 칸(에뮬레이터 확인에서 `예`가 `여`로 잘려 보인 것).
void main() {
  // Pixel 7(밀도 2.625, 화면 높이 750dp 이상)의 대화상자 버튼 칸 90px
  const double slot = 90 / 2.625;

  Future<void> pumpDialog(WidgetTester tester, {required bool fitContent}) =>
      tester.pumpWidget(
        MaterialApp(
          theme: SmartMobileApp.theme,
          builder: SmartMobileApp.wrapScreens,
          home: Center(
            child: SizedBox(
              width: 342, // 화면폭(412dp) − 70dp
              child: ButtonsPopup(
                message: '로그아웃 하시겠습니까?',
                buttons: <Widget>[
                  for (final String name in <String>['예', '아니오'])
                    Expanded(
                      child: Center(
                        child: SquareSlot(
                          dimension: slot,
                          fitContent: fitContent,
                          child: LegacyButton(
                            text: name,
                            background: const TransparentButtonBackground(),
                            onTap: () {},
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );

  /// 글자가 다 보이는지: 글자 상자가 칸 안에 있고, 글자 상자가 글자 전체 폭보다 좁지 않다
  /// (좁으면 TextOverflow.clip으로 글자 오른쪽이 잘린다. `예`의 오른쪽 획이 잘려 `여`로 보임).
  bool fullyVisible(WidgetTester tester, String text) {
    final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text(text), matching: find.byType(RichText)),
    );
    final double fullWidth = paragraph.getMaxIntrinsicWidth(double.infinity);
    final Rect label = tester.getRect(find.text(text));
    final Rect box = tester.getRect(
      find.ancestor(of: find.text(text), matching: find.byType(SquareSlot)),
    );
    return paragraph.size.width + 0.01 >= fullWidth &&
        box.contains(label.topLeft) &&
        box.contains(label.bottomRight - const Offset(0.01, 0.01));
  }

  testWidgets('원본처럼 정사각형 칸에 넣으면 글자가 잘린다', (WidgetTester tester) async {
    await pumpDialog(tester, fitContent: false);
    expect(fullyVisible(tester, '예'), isFalse);
    expect(fullyVisible(tester, '아니오'), isFalse);
  });

  testWidgets('개선판: 글자 버튼은 글자가 다 보인다', (WidgetTester tester) async {
    await pumpDialog(tester, fitContent: true);
    expect(fullyVisible(tester, '예'), isTrue);
    expect(fullyVisible(tester, '아니오'), isTrue);
    // 누르기 쉬운 크기(AppCompat 버튼 최소 88×48dp)
    final Size size = tester.getSize(find.byType(LegacyButton).first);
    expect(size.width, greaterThanOrEqualTo(88));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('아이콘 칸은 원본처럼 정사각형 그대로', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(
        child: SquareSlot(
          dimension: slot,
          fitContent: false,
          child: SizedBox(width: 88, height: 48),
        ),
      ),
    );
    expect(tester.getSize(find.byType(SquareSlot)), const Size(slot, slot));
  });
}
