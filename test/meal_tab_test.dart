import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knut_smartmobile/src/app_data.dart';
import 'package:knut_smartmobile/src/campus_setting.dart';
import 'package:knut_smartmobile/src/meal_tab.dart';

import 'support.dart';

/// 학식 탭 화면(개선판 2차, 목업 `mockups/meal.png`). 데이터는 저장소의 `assets/data/meals.json`.
void main() {
  final AppData data = loadTestData();

  Future<CampusSetting> pumpMeal(
    WidgetTester tester, {
    DateTime Function()? clock,
    CampusSetting? setting,
    OpenedPages? opened,
    double textScale = 1,
    Size size = const Size(412, 915),
  }) async {
    final CampusSetting campus = setting ?? CampusSetting(MemoryStore());
    await pumpScreen(
      tester,
      MealTab(
        data: data.meals,
        school: data.school,
        setting: campus,
        openPage: (opened ?? OpenedPages()).call,
        clock: clock ?? mockNow,
      ),
      textScale: textScale,
      size: size,
    );
    return campus;
  }

  testWidgets('열면 오늘이 골라지고 메뉴마다 한 줄, 가격은 오른쪽', (WidgetTester tester) async {
    await pumpMeal(tester);
    expect(find.text('학식'), findsOneWidget);
    expect(find.text('10월 27일 화요일'), findsOneWidget);
    expect(find.text('오늘'), findsOneWidget);
    expect(find.text('10/26 월'), findsNothing); // 날짜 줄은 요일과 날짜만
    final Offset name = tester.getTopLeft(find.text('등심돈까스'));
    final Offset price = tester.getTopRight(find.text('5,000원').first);
    expect(price.dx, greaterThan(name.dx + 200)); // 가격은 오른쪽 끝
    expect(find.text('식당 사정에 따라 메뉴가 바뀔 수 있어요'), findsOneWidget);
    expect(find.textContaining('식단 기준 10/26 월~10/30 금'), findsOneWidget);
    // 행사 안내는 메뉴와 따로
    expect(find.textContaining('이천원의 점심밥 이벤트'), findsOneWidget);
  });

  testWidgets('식당을 바꾸면 그 식당 메뉴, 고른 식당은 캠퍼스 설정에 남는다', (
    WidgetTester tester,
  ) async {
    final CampusSetting setting = await pumpMeal(tester);
    await tester.tap(find.text('교직원식당'));
    await tester.pump();
    expect(find.text('백반정식'), findsOneWidget);
    expect(find.text('5,500원'), findsOneWidget);
    expect(find.text('우렁강된장비빔밥'), findsOneWidget);
    expect(setting.restaurantFor('chungju'), 'chungju-staff');
  });

  testWidgets('다른 날을 고르면 그날 메뉴', (WidgetTester tester) async {
    await pumpMeal(tester);
    await tester.tap(find.byKey(const ValueKey<String>('meal-day-2026-10-30')));
    await tester.pump();
    expect(find.text('10월 30일 금요일'), findsOneWidget);
    expect(find.text('치즈돈까스'), findsOneWidget);
  });

  testWidgets('쉬는 날은 빨간 이름, 데이터에 없는 날은 안내와 학교 홈페이지 버튼', (
    WidgetTester tester,
  ) async {
    final OpenedPages opened = OpenedPages();
    // 10/5(대체휴일)~10/9(한글날)이 든 주: 데이터 밖
    await pumpMeal(
      tester,
      clock: () => DateTime(2026, 10, 6, 14, 32),
      opened: opened,
    );
    expect(find.text('대체휴일'), findsOneWidget);
    expect(find.text('한글날'), findsOneWidget);
    final Text holiday = tester.widget<Text>(find.text('한글날'));
    expect(holiday.style?.color, const Color(0xFFA3162B));
    expect(find.text('이 날의 식단 정보가 없습니다'), findsOneWidget);
    await tester.tap(find.text('학교 홈페이지 식단 열기'));
    expect(opened.pages.single.$2, contains('/prog/mealManage/MT01/'));

    await tester.tap(find.byKey(const ValueKey<String>('meal-day-2026-10-09')));
    await tester.pump();
    expect(find.text('쉬는 날이에요'), findsOneWidget);
  });

  testWidgets('주를 넘겨 다음 주로 가고 이번 주로 돌아온다', (WidgetTester tester) async {
    await pumpMeal(tester);
    await tester.tap(find.byTooltip('다음 주'));
    await tester.pump();
    expect(find.text('11월 2일 월요일'), findsOneWidget);
    expect(find.text('이 날의 식단 정보가 없습니다'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '이번 주'));
    await tester.pump();
    expect(find.text('10월 27일 화요일'), findsOneWidget);
  });

  testWidgets('캠퍼스: 증평은 생활관식당(중식·석식), 의왕은 식당 안내 없음', (
    WidgetTester tester,
  ) async {
    final CampusSetting setting = await pumpMeal(
      tester,
      clock: () => DateTime(2026, 10, 20, 12),
    );
    setting.campus = 'jeungpyeong';
    await tester.pump();
    expect(find.text('생활관식당'), findsOneWidget);
    expect(find.text('중식'), findsOneWidget);
    expect(find.text('석식'), findsOneWidget);
    expect(find.text('애호박된장찌개'), findsOneWidget);
    setting.campus = 'uiwang';
    await tester.pump();
    expect(find.text('의왕캠퍼스 식단 정보가 없어요'), findsOneWidget);
  });

  testWidgets('글자 크기 2배, 좁은 폰(360dp)에서도 깨지지 않는다', (WidgetTester tester) async {
    await pumpMeal(tester, textScale: 2, size: const Size(360, 780));
    expect(tester.takeException(), isNull);
    expect(find.text('10월 27일 화요일'), findsOneWidget);
    await tester.tap(find.text('교직원식당'));
    await tester.pump();
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
