import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:knut_smartmobile/src/meal_data.dart';
import 'package:knut_smartmobile/src/school_calendar.dart';
import 'package:knut_smartmobile/src/transit_data.dart';

Map<String, Object?> readJson(String name) =>
    jsonDecode(File('assets/data/$name').readAsStringSync())
        as Map<String, Object?>;

/// 앱 안 고정 데이터(`assets/data/`, `tool/make_data.py`)를 앱 모델로 읽는다(개선판 2차).
void main() {
  test('파일마다 출처·가져온 날짜·적용 기간이 있다', () {
    for (final String name in <String>[
      'meals.json',
      'transit.json',
      'holidays.json',
    ]) {
      final Map<String, Object?> json = readJson(name);
      expect(
        json['fetchedAt'],
        matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')),
        reason: name,
      );
      expect(json['validFrom'], isNotNull, reason: name);
      expect(json['validTo'], isNotNull, reason: name);
    }
    expect(
      readJson('holidays.json')['source'],
      startsWith('https://www.ut.ac.kr/'),
    );
    final Map<String, Object?> meals = readJson('meals.json');
    for (final Object? c in meals['campuses']! as List<Object?>) {
      for (final Object? r
          in (c! as Map<String, Object?>)['restaurants']! as List<Object?>) {
        final Map<String, Object?> restaurant = r! as Map<String, Object?>;
        expect(restaurant['source'], startsWith('https://www.ut.ac.kr/'));
        expect(restaurant['validFrom'], isNotNull);
      }
    }
  });

  test('공휴일·학기(holidays.json)', () {
    final SchoolCalendar school = SchoolCalendar.fromJson(
      readJson('holidays.json'),
    );
    expect(school.holidayName(DateTime(2026, 10, 9)), '한글날');
    expect(school.holidayName(DateTime(2026, 10, 5)), '대체휴일');
    expect(school.isHoliday(DateTime(2026, 10, 27)), isFalse);
    expect(school.terms, hasLength(2));
    expect(school.terms.last.contains(DateTime(2026, 10, 27)), isTrue);
    expect(school.terms.last.contains(DateTime(2026, 12, 22)), isFalse);
  });

  test('식단(meals.json): 세 캠퍼스, 충주 두 식당, 메뉴와 가격', () {
    final MealData meals = MealData.fromJson(readJson('meals.json'));
    expect(meals.campuses.map((MealCampus c) => c.id), <String>[
      'chungju',
      'jeungpyeong',
      'uiwang',
    ]);
    final MealCampus chungju = meals.campus('chungju')!;
    expect(chungju.restaurants.map((Restaurant r) => r.name), <String>[
      '학생식당',
      '교직원식당',
    ]);
    final DayMenu student = chungju.restaurants.first.menuOn(
      DateTime(2026, 10, 27),
    )!;
    expect(student.courses.single.items.first.name, '등심돈까스');
    expect(student.courses.single.items.first.price, 5000);
    final DayMenu staff = chungju.restaurants.last.menuOn(
      DateTime(2026, 10, 27),
    )!;
    expect(staff.courses.single.name, '백반정식');
    expect(staff.courses.single.price, 5500);
    expect(
      staff.courses.single.items.every((MenuItem i) => i.price == null),
      isTrue,
    );
    // 증평은 그림 식단을 옮겨 적은 생활관식당, 의왕은 식당 안내가 없다.
    expect(
      meals
          .campus('jeungpyeong')!
          .restaurants
          .single
          .menuOn(DateTime(2026, 10, 20))!
          .courses
          .length,
      2,
    );
    expect(meals.campus('uiwang')!.restaurants, isEmpty);
    expect(meals.campus('uiwang')!.note, isNotNull);
  });

  test('시간표(transit.json): 시내버스, 통학버스, 캠퍼스 순환', () {
    final TransitData transit = TransitData.fromJson(readJson('transit.json'));
    final TimetableService city = transit.city('chungju')!;
    expect(city.directions.map((Direction d) => d.label), <String>[
      '교통대 → 터미널',
      '터미널 → 교통대',
    ]);
    final Trip first = city.directions.first.trips.first;
    expect(formatMinutes(first.depart), '08:42');
    expect(formatMinutes(first.arrive!), '09:00');
    expect(transit.city('uiwang'), isNull);
    expect(transit.campus('uiwang')!.cityGuide, isNotEmpty);
    expect(
      transit.commutesFor('chungju').map((CommuteRoute r) => r.chip),
      <String>['청주', '이천', '충주 시내'],
    );
    final CommuteRoute cheongju = transit.commutesFor('chungju').first;
    expect(cheongju.fare, '편도 3,500원');
    expect(formatMinutes(cheongju.departure(CommuteLeg.fromCampus)!), '18:10');
    expect(
      transit.shuttle('jeungpyeong')!.directionsFor('jeungpyeong').first.label,
      '증평 → 충주',
    );
    expect(transit.campus('chungju')!.mapUrl, contains('divisionId=1'));
  });
}
