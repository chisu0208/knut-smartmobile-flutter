/// 날짜 계산(개선판 2차, 학식·교통 탭). 날짜는 기기 시간대의 그날 0시 `DateTime`으로 다룬다.
library;

/// 지금 시각을 주는 함수. 테스트에서 시각을 바꿔 넣는다.
typedef Clock = DateTime Function();

/// 시각을 뗀 날짜.
DateTime dateOnly(DateTime time) => DateTime(time.year, time.month, time.day);

/// `2026-10-27` → 날짜.
DateTime parseDate(String text) {
  final List<String> parts = text.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

/// 날짜 → `2026-10-27`.
String isoDate(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

/// 하루를 더한 날짜(서머타임이 있어도 0시를 지킨다).
DateTime addDays(DateTime day, int days) =>
    DateTime(day.year, day.month, day.day + days);

/// `HH:MM` → 0시부터 분.
int parseMinutes(String text) {
  final List<String> parts = text.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

/// 0시부터 분 → `HH:MM`.
String formatMinutes(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
    '${(minutes % 60).toString().padLeft(2, '0')}';

/// 하루 안의 분(초는 버린다).
int minuteOfDay(DateTime time) => time.hour * 60 + time.minute;

const List<String> weekdayNames = <String>['월', '화', '수', '목', '금', '토', '일'];

/// `10/28 수`(통합본 4-6).
String shortDate(DateTime day) =>
    '${day.month}/${day.day} ${weekdayNames[day.weekday - 1]}';

/// `10월 28일 수요일`.
String longDate(DateTime day) =>
    '${day.month}월 ${day.day}일 ${weekdayNames[day.weekday - 1]}요일';

/// `10월 28일(수)`.
String mediumDate(DateTime day) =>
    '${day.month}월 ${day.day}일(${weekdayNames[day.weekday - 1]})';

/// 남은 시간: `15분`, `1시간`, `3시간 38분`.
String formatDuration(int minutes) {
  if (minutes < 60) return '$minutes분';
  final int hours = minutes ~/ 60;
  final int rest = minutes % 60;
  return rest == 0 ? '$hours시간' : '$hours시간 $rest분';
}

/// 시작·끝을 포함하는 날짜 범위.
class DateRange {
  const DateRange(this.start, this.end);

  factory DateRange.fromJson(Map<String, Object?> json) => DateRange(
    parseDate(json['start']! as String),
    parseDate(json['end']! as String),
  );

  final DateTime start;
  final DateTime end;

  bool contains(DateTime day) {
    final DateTime d = dateOnly(day);
    return !d.isBefore(start) && !d.isAfter(end);
  }
}

/// 학교 학사일정의 쉬는 날과 학기(`assets/data/holidays.json`).
class SchoolCalendar {
  const SchoolCalendar({
    this.holidays = const <String, String>{},
    this.terms = const <DateRange>[],
    this.source,
    this.fetchedAt,
  });

  factory SchoolCalendar.fromJson(Map<String, Object?> json) {
    final Map<String, String> holidays = <String, String>{};
    for (final Object? item in json['holidays']! as List<Object?>) {
      final Map<String, Object?> h = item! as Map<String, Object?>;
      holidays[h['date']! as String] = h['name']! as String;
    }
    return SchoolCalendar(
      holidays: holidays,
      terms: <DateRange>[
        for (final Object? t in json['terms']! as List<Object?>)
          DateRange.fromJson(t! as Map<String, Object?>),
      ],
      source: json['source'] as String?,
      fetchedAt: json['fetchedAt'] as String?,
    );
  }

  /// `2026-10-09` → `한글날`.
  final Map<String, String> holidays;

  /// 학기(개강일부터 방학 전날까지). 밖은 방학이다.
  final List<DateRange> terms;
  final String? source;
  final String? fetchedAt;

  /// 쉬는 날 이름. 쉬는 날이 아니면 null.
  String? holidayName(DateTime day) => holidays[isoDate(dateOnly(day))];

  bool isHoliday(DateTime day) => holidayName(day) != null;
}

/// 운행하지 않는 이유.
enum OffReason { weekend, holiday, outOfPeriod }

/// 버스가 다니는 날(요일, 공휴일, 운행 기간).
class ServiceCalendar {
  const ServiceCalendar({
    required this.weekdays,
    this.skipHolidays = true,
    this.periods = const <DateRange>[],
  });

  factory ServiceCalendar.fromJson(Map<String, Object?> json) =>
      ServiceCalendar(
        weekdays: <int>{
          for (final Object? d in json['weekdays']! as List<Object?>) d! as int,
        },
        skipHolidays: json['skipHolidays'] as bool? ?? true,
        periods: <DateRange>[
          for (final Object? p
              in json['periods'] as List<Object?>? ?? const <Object?>[])
            DateRange.fromJson(p! as Map<String, Object?>),
        ],
      );

  /// 다니는 요일(`DateTime.weekday`, 월=1 … 일=7).
  final Set<int> weekdays;

  /// 공휴일에는 다니지 않는다.
  final bool skipHolidays;

  /// 다니는 기간(학기 등). 비어 있으면 기간 제한이 없다.
  final List<DateRange> periods;

  /// [day]에 다니지 않는 이유. 다니면 null. [tripWeekdays]는 그 차만의 요일(월·목·금 등).
  OffReason? offReason(
    DateTime day,
    SchoolCalendar school, {
    Set<int>? tripWeekdays,
  }) {
    if (periods.isNotEmpty && !periods.any((DateRange p) => p.contains(day))) {
      return OffReason.outOfPeriod;
    }
    if (skipHolidays && school.isHoliday(day)) return OffReason.holiday;
    if (!weekdays.contains(day.weekday)) return OffReason.weekend;
    if (tripWeekdays != null && !tripWeekdays.contains(day.weekday)) {
      return OffReason.weekend;
    }
    return null;
  }

  bool runsOn(DateTime day, SchoolCalendar school, {Set<int>? tripWeekdays}) =>
      offReason(day, school, tripWeekdays: tripWeekdays) == null;
}
