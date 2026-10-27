import 'dart:convert';

import 'package:flutter/services.dart';

import 'meal_data.dart';
import 'school_calendar.dart';
import 'transit_data.dart';

/// 학식·교통 탭의 앱 안 고정 데이터(`assets/data/`, `tool/make_data.py`로 만듦).
class AppData {
  const AppData({
    required this.meals,
    required this.transit,
    required this.school,
  });

  final MealData meals;
  final TransitData transit;
  final SchoolCalendar school;

  static Future<AppData> load([AssetBundle? bundle]) async {
    final AssetBundle assets = bundle ?? rootBundle;
    Future<Map<String, Object?>> read(String name) async =>
        jsonDecode(await assets.loadString('assets/data/$name'))
            as Map<String, Object?>;
    return AppData(
      meals: MealData.fromJson(await read('meals.json')),
      transit: TransitData.fromJson(await read('transit.json')),
      school: SchoolCalendar.fromJson(await read('holidays.json')),
    );
  }
}

/// 학교 홈페이지 같은 웹 페이지를 앱 안에서 연다(길찾기, 식단 페이지). 탭 막대가 넣어 준다.
typedef OpenPage = void Function(String title, String url);
