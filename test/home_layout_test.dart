import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knut_smartmobile/src/home_layout.dart';
import 'package:knut_smartmobile/src/legacy_widgets.dart';

import 'support.dart';

/// 홈 탭 위쪽 막대(개선판 2차): 서버 `footer`(≡ ☆ 집 로그인)를 홈 탭 맨 위에 그린다.
/// 모양은 `main_screen.dart`의 `_topBar`와 같다(원본 아이콘 칸 `d1`, 90px 정사각형).
void main() {
  final List<String> taps = <String>[];

  Widget iconButton(String name) => SquareSlot(
    dimension: 90 / 3, // 90px, devicePixelRatio 3
    fitContent: false,
    child: LegacyButton(
      key: ValueKey<String>(name),
      background: const ImageButtonBackground(null),
      onTap: () => taps.add(name),
    ),
  );

  Widget layout({required bool withFooter}) => HomeLayout(
    topBar: withFooter
        ? HomeTopBar(
            box: GradientBox(color: Colors.white),
            buttons: <HomeTopBarButton>[
              for (final String name in <String>[
                'menu',
                'favorite',
                'home',
                'login',
              ])
                HomeTopBarButton(
                  onTap: () => taps.add(name),
                  child: iconButton(name),
                ),
            ],
          )
        : null,
    header: const SizedBox(key: ValueKey<String>('header'), height: 75),
    body: const ColoredBox(key: ValueKey<String>('body'), color: Colors.white),
  );

  setUp(taps.clear);

  testWidgets('서버 footer는 홈 탭 맨 위 막대: 헤더·본문보다 위', (WidgetTester tester) async {
    await pumpScreen(tester, layout(withFooter: true), material3: false);
    final double bar = tester.getTopLeft(find.byType(HomeTopBar)).dy;
    final double header = tester
        .getTopLeft(find.byKey(const ValueKey<String>('header')))
        .dy;
    final double body = tester
        .getTopLeft(find.byKey(const ValueKey<String>('body')))
        .dy;
    expect(bar, 0);
    expect(header, HomeTopBar.height);
    expect(body, greaterThan(header));
    expect(tester.getSize(find.byType(HomeTopBar)).height, HomeTopBar.height);
    // 하단 바용 회색 구분선(#DDDDDD)이 없다
    expect(
      find.byWidgetPredicate(
        (Widget w) => w is Material && w.color == const Color(0xFFDDDDDD),
      ),
      findsNothing,
    );
  });

  testWidgets('버튼 모양은 그대로, 누르는 곳은 칸 전체(48dp 이상)', (WidgetTester tester) async {
    await pumpScreen(tester, layout(withFooter: true), material3: false);
    // 아이콘 칸은 원본처럼 30dp
    expect(tester.getSize(find.byType(SquareSlot).first), const Size(30, 30));
    // 칸 하나: 412/4 × 50dp
    final Rect cell = tester.getRect(
      find
          .ancestor(
            of: find.byKey(const ValueKey<String>('login')),
            matching: find.byType(GestureDetector),
          )
          .last,
    );
    expect(cell.width, greaterThanOrEqualTo(48));
    expect(cell.height, greaterThanOrEqualTo(48));
    // 아이콘 밖(칸 가장자리)을 눌러도 그 버튼
    await tester.tapAt(cell.topLeft + const Offset(4, 4));
    await tester.tapAt(cell.bottomRight - const Offset(4, 4));
    expect(taps, <String>['login', 'login']);
    // 아이콘을 누르면 한 번만
    await tester.tap(find.byKey(const ValueKey<String>('menu')));
    expect(taps, <String>['login', 'login', 'menu']);
  });

  testWidgets('footer가 없으면 막대를 숨긴다', (WidgetTester tester) async {
    await pumpScreen(tester, layout(withFooter: false), material3: false);
    expect(find.byType(HomeTopBar), findsNothing);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey<String>('header'))).dy,
      0,
    );
  });
}
