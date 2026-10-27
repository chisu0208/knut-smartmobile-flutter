import 'package:flutter_test/flutter_test.dart';
import 'package:knut_smartmobile/src/meal_data.dart';
import 'package:knut_smartmobile/src/school_calendar.dart';

/// 학식 날짜 줄·쉬는 날·데이터 없는 날(개선판 2차, 통합본 4-5, 4-6).
void main() {
  final SchoolCalendar school = SchoolCalendar(
    holidays: const <String, String>{'2026-10-05': '대체휴일', '2026-10-09': '한글날'},
  );
  final Restaurant student = Restaurant(
    id: 'chungju-student',
    name: '학생식당',
    validFrom: DateTime(2026, 10, 5),
    validTo: DateTime(2026, 10, 9),
    menus: <String, DayMenu>{
      '2026-10-05': DayMenu(date: DateTime(2026, 10, 5), closed: '대체공휴일'),
      '2026-10-06': DayMenu(
        date: DateTime(2026, 10, 6),
        courses: const <MealCourse>[
          MealCourse(
            name: '일품',
            items: <MenuItem>[MenuItem('치즈돈까스', 5000), MenuItem('치킨까스', 4500)],
          ),
        ],
      ),
      '2026-10-08': DayMenu(date: DateTime(2026, 10, 8), closed: '휴무'),
    },
  );

  test('열면 오늘(운영하는 요일)이 골라지고, 주말이면 다음 운영일', () {
    expect(
      initialMealDay(student, DateTime(2026, 10, 6, 14, 32)),
      DateTime(2026, 10, 6),
    );
    expect(
      initialMealDay(student, DateTime(2026, 10, 10, 9)),
      DateTime(2026, 10, 12),
    );
  });

  test('한 주 날짜 줄은 운영하는 요일만, 쉬는 날에는 이름', () {
    final List<MealDay> week = mealWeek(
      student,
      DateTime(2026, 10, 6),
      DateTime(2026, 10, 6, 14, 32),
      school,
    );
    expect(week.map((MealDay d) => d.date.day), <int>[5, 6, 7, 8, 9]);
    expect(week.map((MealDay d) => d.offLabel), <String?>[
      '대체휴일',
      null,
      null,
      '휴무',
      '한글날',
    ]);
    expect(week.map((MealDay d) => d.isToday), <bool>[
      false,
      true,
      false,
      false,
      false,
    ]);
    expect(shortDate(week[1].date), '10/6 화');
  });

  test('날마다 상태: 식단 있음, 쉬는 날, 데이터 없는 날', () {
    final MealDayState served = mealStateOn(
      student,
      DateTime(2026, 10, 6),
      school,
    );
    expect(served, isA<MealServed>());
    expect((served as MealServed).menu.itemCount, 2);

    final MealDayState holiday = mealStateOn(
      student,
      DateTime(2026, 10, 5),
      school,
    );
    expect((holiday as MealClosed).reason, '대체휴일');

    final MealDayState closed = mealStateOn(
      student,
      DateTime(2026, 10, 8),
      school,
    );
    expect((closed as MealClosed).reason, '휴무');

    // 데이터에 없는 평일
    expect(
      mealStateOn(student, DateTime(2026, 10, 7), school),
      isA<MealUnknown>(),
    );
    expect(
      mealStateOn(student, DateTime(2026, 11, 2), school),
      isA<MealUnknown>(),
    );
    // 데이터 밖이어도 학사일정의 쉬는 날은 쉬는 날
    expect(
      mealStateOn(
        student,
        DateTime(2026, 12, 25),
        const SchoolCalendar(holidays: <String, String>{'2026-12-25': '성탄절'}),
      ),
      isA<MealClosed>(),
    );
  });
}
