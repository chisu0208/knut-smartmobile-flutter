import 'school_calendar.dart';

/// 메뉴 한 줄(통합본 4-4: 메뉴마다 한 줄, 가격은 오른쪽).
class MenuItem {
  const MenuItem(this.name, [this.price]);

  factory MenuItem.fromJson(Map<String, Object?> json) =>
      MenuItem(json['name']! as String, json['price'] as int?);

  final String name;

  /// 원. 없으면 null(정식은 분류에 가격이 있다).
  final int? price;
}

/// 분류 하나(일품, 백반정식, 중식 등).
class MealCourse {
  const MealCourse({
    required this.name,
    this.price,
    this.hours,
    this.items = const <MenuItem>[],
  });

  factory MealCourse.fromJson(Map<String, Object?> json) => MealCourse(
    name: json['name']! as String,
    price: json['price'] as int?,
    hours: json['hours'] as String?,
    items: <MenuItem>[
      for (final Object? item
          in json['items'] as List<Object?>? ?? const <Object?>[])
        MenuItem.fromJson(item! as Map<String, Object?>),
    ],
  );

  final String name;

  /// 정식 가격(교직원식당 백반정식 5,500원 등).
  final int? price;

  /// 이 분류의 이용 시간.
  final String? hours;
  final List<MenuItem> items;
}

/// 하루 식단.
class DayMenu {
  const DayMenu({
    required this.date,
    this.notices = const <String>[],
    this.courses = const <MealCourse>[],
    this.closed,
    this.hours,
  });

  factory DayMenu.fromJson(Map<String, Object?> json) => DayMenu(
    date: parseDate(json['date']! as String),
    notices: <String>[
      for (final Object? n
          in json['notices'] as List<Object?>? ?? const <Object?>[])
        n! as String,
    ],
    courses: <MealCourse>[
      for (final Object? c
          in json['courses'] as List<Object?>? ?? const <Object?>[])
        MealCourse.fromJson(c! as Map<String, Object?>),
    ],
    closed: json['closed'] as String?,
    hours: json['hours'] as String?,
  );

  final DateTime date;

  /// 식당 안내(행사 등).
  final List<String> notices;

  /// 내용이 있는 분류만(통합본 4-5: 내용 없는 분류는 숨김).
  final List<MealCourse> courses;

  /// 쉬는 날이면 그 이유(`한글날`, `대체공휴일` 등).
  final String? closed;

  /// 이 날 이용 시간.
  final String? hours;

  int get itemCount =>
      courses.fold<int>(0, (int sum, MealCourse c) => sum + c.items.length);
}

/// 식당 하나.
class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    this.place,
    this.hours,
    this.days = const <int>{1, 2, 3, 4, 5},
    this.note,
    this.source,
    this.fetchedAt,
    this.validFrom,
    this.validTo,
    this.menus = const <String, DayMenu>{},
  });

  factory Restaurant.fromJson(Map<String, Object?> json) {
    final Map<String, DayMenu> menus = <String, DayMenu>{};
    for (final Object? m
        in json['menus'] as List<Object?>? ?? const <Object?>[]) {
      final DayMenu menu = DayMenu.fromJson(m! as Map<String, Object?>);
      menus[isoDate(menu.date)] = menu;
    }
    final String? from = json['validFrom'] as String?;
    final String? to = json['validTo'] as String?;
    return Restaurant(
      id: json['id']! as String,
      name: json['name']! as String,
      place: json['place'] as String?,
      hours: json['hours'] as String?,
      days: <int>{
        for (final Object? d
            in json['days'] as List<Object?>? ?? const <Object?>[1, 2, 3, 4, 5])
          d! as int,
      },
      note: json['note'] as String?,
      source: json['source'] as String?,
      fetchedAt: json['fetchedAt'] as String?,
      validFrom: from == null ? null : parseDate(from),
      validTo: to == null ? null : parseDate(to),
      menus: menus,
    );
  }

  final String id;
  final String name;
  final String? place;
  final String? hours;

  /// 운영하는 요일(월=1 … 일=7).
  final Set<int> days;
  final String? note;

  /// 학교 홈페이지 식단 페이지.
  final String? source;

  /// 데이터를 가져온 날(`2026-10-27`).
  final String? fetchedAt;

  /// 데이터가 다루는 기간.
  final DateTime? validFrom;
  final DateTime? validTo;
  final Map<String, DayMenu> menus;

  DayMenu? menuOn(DateTime day) => menus[isoDate(dateOnly(day))];
}

/// 캠퍼스 하나의 식당들.
class MealCampus {
  const MealCampus({
    required this.id,
    required this.name,
    required this.short,
    this.note,
    this.source,
    this.restaurants = const <Restaurant>[],
  });

  factory MealCampus.fromJson(Map<String, Object?> json) => MealCampus(
    id: json['id']! as String,
    name: json['name']! as String,
    short: json['short']! as String,
    note: json['note'] as String?,
    source: json['source'] as String?,
    restaurants: <Restaurant>[
      for (final Object? r in json['restaurants']! as List<Object?>)
        Restaurant.fromJson(r! as Map<String, Object?>),
    ],
  );

  final String id;
  final String name;
  final String short;

  /// 식당 안내가 없는 캠퍼스의 설명.
  final String? note;
  final String? source;
  final List<Restaurant> restaurants;
}

/// `assets/data/meals.json`.
class MealData {
  const MealData({required this.campuses, this.fetchedAt});

  factory MealData.fromJson(Map<String, Object?> json) => MealData(
    fetchedAt: json['fetchedAt'] as String?,
    campuses: <MealCampus>[
      for (final Object? c in json['campuses']! as List<Object?>)
        MealCampus.fromJson(c! as Map<String, Object?>),
    ],
  );

  final String? fetchedAt;
  final List<MealCampus> campuses;

  MealCampus? campus(String id) {
    for (final MealCampus c in campuses) {
      if (c.id == id) return c;
    }
    return null;
  }
}

/// 날짜 줄의 하루.
class MealDay {
  const MealDay({required this.date, required this.isToday, this.offLabel});

  final DateTime date;
  final bool isToday;

  /// 쉬는 날이면 빨간 글씨로 보일 이름(`한글날`, `휴무`). 아니면 null.
  final String? offLabel;

  bool get isOff => offLabel != null;
}

/// 식당 [restaurant]의 [day]가 든 주(월~일) 가운데 운영하는 요일(통합본 4-6).
List<MealDay> mealWeek(
  Restaurant restaurant,
  DateTime day,
  DateTime today,
  SchoolCalendar school,
) {
  final DateTime monday = addDays(dateOnly(day), -(day.weekday - 1));
  final DateTime todayDate = dateOnly(today);
  return <MealDay>[
    for (int i = 0; i < 7; i++)
      if (restaurant.days.contains(i + 1))
        MealDay(
          date: addDays(monday, i),
          isToday: addDays(monday, i) == todayDate,
          offLabel: offLabelOf(restaurant, addDays(monday, i), school),
        ),
  ];
}

/// 쉬는 날 이름: 학사일정의 쉬는 날이면 그 이름, 식단에 쉬는 날로 적혀 있으면 `휴무`.
String? offLabelOf(Restaurant restaurant, DateTime day, SchoolCalendar school) {
  final String? holiday = school.holidayName(day);
  if (holiday != null) return holiday;
  final DayMenu? menu = restaurant.menuOn(day);
  if (menu != null && menu.courses.isEmpty && menu.closed != null) return '휴무';
  return null;
}

/// 학식 탭을 열 때 고를 날: 오늘이 운영하는 요일이면 오늘, 아니면(주말 등) 다음 운영일.
DateTime initialMealDay(Restaurant restaurant, DateTime today) {
  DateTime day = dateOnly(today);
  for (int i = 0; i < 7; i++) {
    if (restaurant.days.contains(day.weekday)) return day;
    day = addDays(day, 1);
  }
  return dateOnly(today);
}

/// 고른 날의 식단 상태.
sealed class MealDayState {
  const MealDayState();
}

/// 식단이 있다.
class MealServed extends MealDayState {
  const MealServed(this.menu);
  final DayMenu menu;
}

/// 쉬는 날(학사일정의 쉬는 날이거나 식단에 쉬는 날로 적힘).
class MealClosed extends MealDayState {
  const MealClosed(this.reason, [this.notices = const <String>[]]);
  final String reason;
  final List<String> notices;
}

/// 데이터에 없는 날.
class MealUnknown extends MealDayState {
  const MealUnknown();
}

MealDayState mealStateOn(
  Restaurant restaurant,
  DateTime day,
  SchoolCalendar school,
) {
  final DayMenu? menu = restaurant.menuOn(day);
  if (menu != null && menu.courses.isNotEmpty) return MealServed(menu);
  final String? holiday = school.holidayName(day);
  if (menu != null && menu.closed != null) {
    return MealClosed(holiday ?? menu.closed!, menu.notices);
  }
  if (holiday != null) return MealClosed(holiday);
  return const MealUnknown();
}
