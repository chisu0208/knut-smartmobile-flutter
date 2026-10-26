import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knut_smartmobile/main.dart';
import 'package:knut_smartmobile/src/legacy_widgets.dart';

/// 메인 화면처럼 위에 `Material`이 없는 화면에 Flutter가 그리는 글자들.
Widget _screen() {
  return ColoredBox(
    color: Colors.white,
    child: SingleChildScrollView(
      child: Column(
        children: <Widget>[
          // full 팝업 헤더 제목(popup_full: 흰 글자)
          const LegacyButton(
            text: '로그인',
            textColor: Colors.white,
            background: TransparentButtonBackground(),
          ),
          // 헤더·푸터 메뉴 버튼
          const LegacyButton(text: '교내전화', textColor: Colors.black),
          // alert 명령 / NFC 대화상자
          MessagePopup(
            message: '알림 내용',
            buttonText: '확인',
            buttonColor: const Color(0xFF1B9CE8),
            onPressed: () {},
          ),
          // dialog 명령
          const ButtonsPopup(message: '대화상자 내용', buttons: <Widget>[]),
        ],
      ),
    ),
  );
}

TextStyle _renderedStyle(WidgetTester tester, String text) {
  final RichText rich = tester.widget<RichText>(
    find.descendant(of: find.text(text), matching: find.byType(RichText)),
  );
  return rich.text.style!;
}

void main() {
  testWidgets('앱은 legacyAppBuilder로 기본 글자 스타일을 깐다', (
    WidgetTester tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext c) {
          context = c;
          return const SizedBox();
        },
      ),
    );
    final MaterialApp app =
        const SmartMobileApp().build(context) as MaterialApp;
    expect(app.builder, legacyAppBuilder);
  });

  testWidgets('Material 없는 화면의 글자도 밑줄·monospace·w900이 없다', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(builder: legacyAppBuilder, home: _screen()),
    );

    for (final String text in <String>['로그인', '교내전화', '알림 내용', '대화상자 내용']) {
      final TextStyle style = _renderedStyle(tester, text);
      expect(
        style.decoration,
        anyOf(isNull, TextDecoration.none),
        reason: text,
      );
      expect(style.fontFamily, isNot('monospace'), reason: text);
      expect(style.fontWeight, isNot(FontWeight.w900), reason: text);
    }

    // 크기·색·굵기는 각 위젯이 정한 값 그대로.
    final TextStyle title = _renderedStyle(tester, '로그인');
    expect(title.fontSize, 14);
    expect(title.color, Colors.white);
    expect(title.fontWeight, FontWeight.w500);
    final TextStyle menu = _renderedStyle(tester, '교내전화');
    expect(menu.fontSize, 14);
    expect(menu.color, Colors.black);
    for (final String text in <String>['알림 내용', '대화상자 내용']) {
      final TextStyle style = _renderedStyle(tester, text);
      expect(style.fontSize, 18, reason: text);
      expect(style.color, Colors.black, reason: text);
      expect(style.fontWeight, FontWeight.w400, reason: text);
    }
  });
}
