import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knut_smartmobile/src/app_data.dart';
import 'package:knut_smartmobile/src/campus_setting.dart';
import 'package:knut_smartmobile/src/transit_tab.dart';

import 'support.dart';

/// 교통 탭 화면(개선판 2차, 목업 `mockups/city.png`·`commute.png`). 데이터는 저장소의
/// `assets/data/transit.json`, 시각은 주입한다.
void main() {
  final AppData data = loadTestData();

  Future<CampusSetting> pumpTransit(
    WidgetTester tester, {
    required DateTime Function() clock,
    CampusSetting? setting,
    OpenedPages? opened,
    double textScale = 1,
    Size size = const Size(412, 915),
  }) async {
    final CampusSetting campus = setting ?? CampusSetting(MemoryStore());
    await pumpScreen(
      tester,
      TransitTab(
        data: data.transit,
        school: data.school,
        setting: campus,
        openPage: (opened ?? OpenedPages()).call,
        clock: clock,
      ),
      textScale: textScale,
      size: size,
    );
    return campus;
  }

  testWidgets('시내버스: 다음 버스 15분, 지난 버스·다음 버스·남은 시간', (
    WidgetTester tester,
  ) async {
    await pumpTransit(tester, clock: mockNow); // 화 14:32
    expect(find.text('교통대 → 터미널'), findsOneWidget);
    expect(find.text('15분'), findsOneWidget);
    expect(find.text('후 출발'), findsOneWidget);
    expect(
      find.textContaining('14:47 교통대 출발 → 15:05 시외터미널 도착'),
      findsOneWidget,
    );
    expect(find.textContaining('그다음 버스 15:10 (38분 후)'), findsOneWidget);
    expect(find.text('15분 후'), findsOneWidget); // 시간표의 다음 버스 배지
    expect(find.text('38분 후'), findsOneWidget);
    expect(find.text('평일만 운행'), findsOneWidget);
    // 지난 버스는 바로 앞 한 대(12:55 700 순환)만 보이고 나머지는 접혀 있다(목업).
    expect(find.text('지남'), findsOneWidget);
    expect(find.text('12:55'), findsOneWidget);
    expect(find.text('08:42'), findsNothing);
    await tester.tap(find.text('지난 버스 11대 보기'));
    await tester.pump();
    expect(find.text('08:42'), findsOneWidget);
    expect(find.text('지남'), findsNWidgets(12));
    expect(find.text('지난 버스 접기'), findsOneWidget);
  });

  testWidgets('남은 시간은 1분마다 갱신된다', (WidgetTester tester) async {
    DateTime now = DateTime(2026, 10, 27, 14, 32, 30);
    await pumpTransit(tester, clock: () => now);
    expect(find.text('15분'), findsOneWidget);
    now = DateTime(2026, 10, 27, 14, 33, 0);
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('14분'), findsOneWidget);
    now = DateTime(2026, 10, 27, 14, 34, 0);
    await tester.pump(const Duration(seconds: 60));
    expect(find.text('13분'), findsOneWidget);
  });

  testWidgets('주말·공휴일·막차 뒤: 운행하지 않는다는 안내와 다음 운행일', (WidgetTester tester) async {
    DateTime now = DateTime(2026, 10, 31, 10, 0); // 토요일
    await pumpTransit(tester, clock: () => now);
    expect(find.text('오늘은 운행하지 않아요 · 주말'), findsOneWidget);
    expect(find.textContaining('다음 운행 11월 2일(월)'), findsOneWidget);
    expect(find.text('11월 2일(월) 시간표'), findsOneWidget);

    now = DateTime(2026, 10, 9, 10, 0); // 한글날(금)
    await tester.pump(const Duration(minutes: 1));
    expect(find.text('오늘은 운행하지 않아요 · 한글날'), findsOneWidget);
    expect(find.textContaining('다음 운행 10월 12일(월)'), findsOneWidget);

    now = DateTime(2026, 12, 25, 10, 0); // 성탄절이지만 학기(12/21까지)가 끝난 뒤
    await tester.pump(const Duration(minutes: 1));
    expect(find.text('오늘은 운행하지 않아요 · 방학·운행 기간 밖'), findsOneWidget);
    expect(find.text('다음 운행일 정보가 없어요'), findsOneWidget);

    now = DateTime(2026, 10, 27, 21, 0); // 막차 뒤
    await tester.pump(const Duration(minutes: 1));
    expect(find.text('오늘 운행이 끝났어요'), findsOneWidget);
    expect(find.text('내일'), findsOneWidget);
    // 막차 뒤에는 다음 운행일 시간표(지난 버스 표시 없음)
    expect(find.text('내일 시간표'), findsOneWidget);
    expect(find.text('지남'), findsNothing);
  });

  testWidgets('통학버스: 시간대에 맞춰 하교가 골라지고 바꿀 수 있다', (WidgetTester tester) async {
    await pumpTransit(tester, clock: mockNow);
    await tester.tap(find.text('통학버스'));
    await tester.pumpAndSettle();
    expect(find.text('청주'), findsOneWidget);
    expect(find.text('청주행 하교 버스'), findsOneWidget);
    expect(find.text('18:10'), findsWidgets);
    expect(
      find.textContaining('3시간 38분 후 · 충주캠퍼스 노천극장 앞에서 타요'),
      findsOneWidget,
    );
    expect(find.text('탑승'), findsOneWidget);
    expect(find.text('편도 3,500원 · PAYCO 모바일 승차권'), findsOneWidget);

    await tester.tap(find.text('등교'));
    await tester.pump();
    expect(find.text('충주캠퍼스행 등교 버스'), findsOneWidget);
    expect(find.text('청주가경터미널'), findsOneWidget);

    await tester.tap(find.text('이천'));
    await tester.pump();
    expect(find.text('이천행 하교 버스'), findsOneWidget); // 노선을 바꾸면 다시 자동
  });

  testWidgets('캠퍼스 순환과 지도 아이콘', (WidgetTester tester) async {
    final OpenedPages opened = OpenedPages();
    await pumpTransit(tester, clock: mockNow, opened: opened);
    await tester.tap(find.text('캠퍼스 순환'));
    await tester.pumpAndSettle();
    expect(find.text('충주 → 증평'), findsOneWidget);
    expect(find.text('오늘 운행이 끝났어요'), findsNothing);
    await tester.tap(find.byTooltip('길찾기'));
    expect(
      opened.pages.single.$2,
      'https://direction.ut.ac.kr/service/mobile/page/index?divisionId=1',
    );
  });

  testWidgets('시간표가 없는 캠퍼스는 안내', (WidgetTester tester) async {
    final CampusSetting setting = await pumpTransit(tester, clock: mockNow);
    setting.campus = 'uiwang';
    await tester.pump();
    expect(find.text('의왕캠퍼스 시내버스 시간표가 없어요'), findsOneWidget);
    expect(find.textContaining('의왕역'), findsOneWidget);
  });

  testWidgets('글자 크기 2배, 좁은 폰(360dp)에서도 깨지지 않는다', (WidgetTester tester) async {
    await pumpTransit(
      tester,
      clock: mockNow,
      textScale: 2,
      size: const Size(360, 780),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('15분'), findsOneWidget);
    for (final String tab in <String>['통학버스', '캠퍼스 순환']) {
      // 큰 글자에서는 위 탭이 옆으로 밀린다.
      await tester.ensureVisible(find.text(tab));
      await tester.pumpAndSettle();
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      expect(
        find.text(tab == '통학버스' ? '청주행 하교 버스' : '충주 → 증평'),
        findsOneWidget,
      );
      await tester.drag(find.byType(ListView).last, const Offset(0, -800));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: tab);
    }
  });
}
