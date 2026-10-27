import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knut_smartmobile/main.dart' show SmartMobileApp;
import 'package:knut_smartmobile/src/app_data.dart';
import 'package:knut_smartmobile/src/app_theme.dart';
import 'package:knut_smartmobile/src/meal_data.dart';
import 'package:knut_smartmobile/src/school_calendar.dart';
import 'package:knut_smartmobile/src/transit_data.dart';

/// 새 화면 시험에서 함께 쓰는 것(개선판 2차).

Map<String, Object?> _read(String name) =>
    jsonDecode(File('assets/data/$name').readAsStringSync())
        as Map<String, Object?>;

/// 저장소의 `assets/data/*.json`.
AppData loadTestData() => AppData(
  meals: MealData.fromJson(_read('meals.json')),
  transit: TransitData.fromJson(_read('transit.json')),
  school: SchoolCalendar.fromJson(_read('holidays.json')),
);

/// 목업 기준 시각(2026-10-27 화 14:32). 데이터의 이번 주다.
DateTime mockNow() => DateTime(2026, 10, 27, 14, 32);

/// 폰 크기(기본 412×915 dp)와 글자 배율로 [child]를 띄운다. 앱처럼 앱 테마(M2) 위에 새 화면은
/// M3 테마를 쓴다.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget child, {
  double textScale = 1,
  Size size = const Size(412, 915),
  bool material3 = true,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: SmartMobileApp.theme,
      builder: (BuildContext context, Widget? inner) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: SmartMobileApp.wrapScreens(context, inner),
      ),
      home: material3 ? Theme(data: AppTheme.material3, child: child) : child,
    ),
  );
  await tester.pump();
}

/// 열린 페이지 기록(길찾기·식단 페이지 열기).
class OpenedPages {
  final List<(String, String)> pages = <(String, String)>[];

  void call(String title, String url) => pages.add((title, url));
}
