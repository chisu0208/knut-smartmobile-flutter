import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knut_smartmobile/main.dart' show SmartMobileApp;
import 'package:knut_smartmobile/src/legacy_widgets.dart';

/// 큰 글자 설정(fontScale 2.0)에서 높이가 정해진 헤더·푸터 막대의 버튼 글자가 잘리지 않는지.
/// 막대 모양은 `main_screen.dart`의 `_mainHeader`·`_mainFooter`·`_popupHeader`와 같다.
void main() {
  const TextScaler largest = TextScaler.linear(2);

  Future<void> pumpBar(WidgetTester tester, Widget bar) => tester.pumpWidget(
    MaterialApp(
      theme: SmartMobileApp.theme,
      builder: (BuildContext context, Widget? child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: largest),
        child: SmartMobileApp.wrapScreens(context, child),
      ),
      home: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(width: 412, child: bar),
      ),
    ),
  );

  /// 글자가 다 보이는지: 글자 상자가 글자에 필요한 높이보다 낮지 않다(낮으면 아래가 잘린다).
  bool fullyVisible(WidgetTester tester, String text) {
    final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text(text), matching: find.byType(RichText)),
    );
    final double needed = paragraph.getMinIntrinsicHeight(paragraph.size.width);
    return paragraph.size.height + 0.01 >= needed;
  }

  /// 메인 헤더 가운데 칸(50dp)과 푸터(50dp): 글자 버튼.
  Widget mainBars({required bool capped}) {
    Widget limit(Widget child) => capped
        ? BarTextScale(maxScaleFactor: BarTextScale.bar, child: child)
        : child;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        limit(
          const SizedBox(
            height: 50,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                LegacyButton(
                  text: '스마트모바일',
                  background: TransparentButtonBackground(),
                ),
              ],
            ),
          ),
        ),
        limit(
          const SizedBox(
            height: 50,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Center(child: LegacyButton(text: '*')),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 팝업 헤더(58dp): 가운데 제목 칸 40dp(full 팝업), 오른쪽 글자 버튼.
  Widget popupHeader({required bool capped}) {
    final Widget header = SizedBox(
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            color: const Color(0xFF333333),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                LegacyButton(
                  text: '학교식단',
                  textColor: Colors.white,
                  background: TransparentButtonBackground(),
                ),
              ],
            ),
          ),
          const Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(top: 5, bottom: 5, right: 5),
              child: Padding(
                padding: EdgeInsets.all(3),
                child: LegacyButton(
                  text: '닫기',
                  background: TransparentButtonBackground(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return capped
        ? BarTextScale(maxScaleFactor: BarTextScale.popupHeader, child: header)
        : header;
  }

  testWidgets('상한이 없으면 큰 글자에서 막대 버튼 글자가 잘린다', (WidgetTester tester) async {
    await pumpBar(tester, mainBars(capped: false));
    expect(fullyVisible(tester, '스마트모바일'), isFalse);
    expect(fullyVisible(tester, '*'), isFalse);
    await pumpBar(tester, popupHeader(capped: false));
    expect(fullyVisible(tester, '학교식단'), isFalse);
    expect(fullyVisible(tester, '닫기'), isFalse);
  });

  testWidgets('개선판: 메인 헤더·푸터 글자는 1.8배까지 커지고 잘리지 않는다', (
    WidgetTester tester,
  ) async {
    await pumpBar(tester, mainBars(capped: true));
    for (final String text in <String>['스마트모바일', '*']) {
      expect(fullyVisible(tester, text), isTrue, reason: text);
      final RichText rich = tester.widget<RichText>(
        find.descendant(of: find.text(text), matching: find.byType(RichText)),
      );
      expect(rich.textScaler.scale(14), 14 * BarTextScale.bar, reason: text);
    }
  });

  testWidgets('개선판: 팝업 헤더 글자는 1.2배까지 커지고 잘리지 않는다', (WidgetTester tester) async {
    await pumpBar(tester, popupHeader(capped: true));
    for (final String text in <String>['학교식단', '닫기']) {
      expect(fullyVisible(tester, text), isTrue, reason: text);
    }
  });

  testWidgets('상한보다 작은 글자 크기 설정은 그대로 따른다', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (BuildContext context, Widget? child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.15)),
          child: SmartMobileApp.wrapScreens(context, child),
        ),
        home: const Center(
          child: BarTextScale(
            maxScaleFactor: BarTextScale.popupHeader,
            child: LegacyButton(text: '확인'),
          ),
        ),
      ),
    );
    final RichText rich = tester.widget<RichText>(
      find.descendant(of: find.text('확인'), matching: find.byType(RichText)),
    );
    expect(rich.textScaler, const TextScaler.linear(1.15));
  });
}
