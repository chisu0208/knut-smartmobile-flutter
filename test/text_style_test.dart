import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knut_smartmobile/main.dart' show SmartMobileApp;
import 'package:knut_smartmobile/src/legacy_widgets.dart';

/// 실제 앱과 같은 `MaterialApp` 설정(테마, builder) 아래에서, 메인 화면처럼
/// `pushReplacement` + `PageRouteBuilder`로 [screen]을 띄운다. 이 경로에는 `Material`이
/// 끼어들지 않는다.
Future<void> pumpLikeMainScreen(WidgetTester tester, Widget screen) async {
  final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      theme: SmartMobileApp.theme,
      builder: SmartMobileApp.wrapScreens,
      home: const SizedBox.shrink(),
    ),
  );
  navigator.currentState!.pushReplacement(
    PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => screen,
      transitionDuration: Duration.zero,
    ),
  );
  await tester.pumpAndSettle();
}

/// [text]가 실제로 그려지는 스타일(물려받은 기본 스타일까지 합친 것).
TextStyle renderedStyle(WidgetTester tester, String text) {
  final RichText rich = tester.widget<RichText>(
    find.descendant(of: find.text(text), matching: find.byType(RichText)),
  );
  return rich.text.style!;
}

/// 원본 TextView 기본값: 밑줄 없음, 시스템 글꼴.
void expectTextViewDefaults(TextStyle style) {
  expect(style.decoration, anyOf(isNull, TextDecoration.none));
  expect(style.fontFamily, isNot('monospace'));
  expect(style.fontWeight, isNot(FontWeight.w900));
}

void main() {
  group('Flutter가 그리는 글자', () {
    testWidgets('헤더·푸터 버튼, alert·dialog 메시지에 오류 표시용 스타일이 없다', (
      WidgetTester tester,
    ) async {
      await pumpLikeMainScreen(
        tester,
        Column(
          children: <Widget>[
            // full 팝업 헤더 제목(popup_full 칸, 흰 글자)
            const LegacyButton(
              text: '로그인',
              textColor: Colors.white,
              background: TransparentButtonBackground(),
            ),
            // 처음 푸터의 "*" 버튼(AppCompat 기본 버튼)
            const LegacyButton(text: '*'),
            MessagePopup(
              message: 'alert 메시지',
              buttonText: '확인',
              buttonColor: const Color(0xFF1B9CE8),
              onPressed: () {},
            ),
            const ButtonsPopup(
              message: 'dialog 메시지',
              buttons: <Widget>[
                Expanded(
                  child: Center(child: LegacyButton(text: '예')),
                ),
              ],
            ),
          ],
        ),
      );

      final Iterable<RichText> texts = tester.widgetList<RichText>(
        find.byType(RichText),
      );
      expect(texts, hasLength(6));
      for (final RichText rich in texts) {
        expectTextViewDefaults(rich.text.style!);
      }

      // 크기·색·굵기는 위젯이 정한 그대로다.
      final TextStyle title = renderedStyle(tester, '로그인');
      expect(title.fontSize, 14);
      expect(title.fontWeight, FontWeight.w500);
      expect(title.color, Colors.white);

      final TextStyle star = renderedStyle(tester, '*');
      expect(star.color, const Color(0xDE000000));

      for (final String message in <String>['alert 메시지', 'dialog 메시지']) {
        final TextStyle style = renderedStyle(tester, message);
        expect(style.fontSize, 18);
        expect(style.fontWeight, anyOf(isNull, FontWeight.normal));
        expect(style.color, Colors.black);
      }

      final TextStyle ok = renderedStyle(tester, '확인');
      expect(ok.fontSize, 18);
      expect(ok.fontWeight, FontWeight.w500);
      expect(ok.color, Colors.white);
    });
  });
}
