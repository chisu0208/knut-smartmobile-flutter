import 'package:flutter_test/flutter_test.dart';
import 'package:knut_smartmobile/src/school_calendar.dart';
import 'package:knut_smartmobile/src/transit_data.dart';

/// 다음 버스 계산과 등교·하교 자동 선택(개선판 2차, 교통 탭). 시각을 넣어 계산한다.
void main() {
  final SchoolCalendar school = SchoolCalendar(
    holidays: const <String, String>{'2026-10-09': '한글날'},
    terms: <DateRange>[DateRange(DateTime(2026, 9, 1), DateTime(2026, 12, 21))],
  );
  final ServiceCalendar weekdays = ServiceCalendar(
    weekdays: const <int>{1, 2, 3, 4, 5},
    periods: <DateRange>[
      DateRange(DateTime(2026, 9, 1), DateTime(2026, 12, 21)),
    ],
  );
  final Direction toTerminal = Direction(
    id: 'from-campus',
    label: '교통대 → 터미널',
    from: '교통대',
    to: '시외터미널',
    trips: <Trip>[
      Trip(
        line: '700 순환',
        depart: parseMinutes('12:55'),
        arrive: parseMinutes('13:43'),
      ),
      Trip(
        line: '999',
        depart: parseMinutes('14:47'),
        arrive: parseMinutes('15:05'),
      ),
      Trip(
        line: '999',
        depart: parseMinutes('15:10'),
        arrive: parseMinutes('15:28'),
      ),
      Trip(
        line: '999',
        depart: parseMinutes('20:30'),
        arrive: parseMinutes('20:48'),
      ),
    ],
  );

  group('다음 버스', () {
    test('목업 시각(10/6 화 14:32): 지난 버스, 다음 15분, 그다음 38분', () {
      final DirectionBoard board = directionBoard(
        toTerminal,
        weekdays,
        school,
        DateTime(2026, 10, 6, 14, 32, 40),
      );
      expect(board.runsToday, isTrue);
      expect(board.isPast(0), isTrue); // 12:55
      expect(board.next!.depart, parseMinutes('14:47'));
      expect(board.minutesUntil(board.next!), 15);
      expect(board.following!.depart, parseMinutes('15:10'));
      expect(board.minutesUntil(board.following!), 38);
    });

    test('같은 분에 떠나는 차는 지나지 않은 것으로 본다', () {
      final DirectionBoard board = directionBoard(
        toTerminal,
        weekdays,
        school,
        DateTime(2026, 10, 6, 14, 47, 30),
      );
      expect(board.next!.depart, parseMinutes('14:47'));
      expect(board.minutesUntil(board.next!), 0);
    });

    test('막차 뒤: 오늘 운행이 끝나고 다음 날 첫차', () {
      final DirectionBoard board = directionBoard(
        toTerminal,
        weekdays,
        school,
        DateTime(2026, 10, 6, 21, 0),
      );
      expect(board.runsToday, isTrue);
      expect(board.finishedToday, isTrue);
      expect(board.next, isNull);
      expect(board.isPast(3), isTrue);
      expect(board.nextService!.day, DateTime(2026, 10, 7));
      expect(board.nextService!.trip.depart, parseMinutes('12:55'));
    });

    test('주말: 운행하지 않고 월요일 첫차', () {
      final DirectionBoard board = directionBoard(
        toTerminal,
        weekdays,
        school,
        DateTime(2026, 10, 10, 10, 0), // 토요일
      );
      expect(board.runsToday, isFalse);
      expect(board.offReason, OffReason.weekend);
      expect(board.nextService!.day, DateTime(2026, 10, 12));
      expect(board.trips, hasLength(4)); // 다음 운행일의 시간표
      expect(board.isPast(0), isFalse);
    });

    test('공휴일(한글날 금요일): 운행하지 않고 다음 운행일은 월요일', () {
      final DirectionBoard board = directionBoard(
        toTerminal,
        weekdays,
        school,
        DateTime(2026, 10, 8, 22, 0), // 목요일 막차 뒤
      );
      expect(board.nextService!.day, DateTime(2026, 10, 12));
      final DirectionBoard holiday = directionBoard(
        toTerminal,
        weekdays,
        school,
        DateTime(2026, 10, 9, 9, 0),
      );
      expect(holiday.offReason, OffReason.holiday);
      expect(school.holidayName(DateTime(2026, 10, 9)), '한글날');
    });

    test('방학: 운행 기간 밖이면 다음 학기 첫날, 기간이 끝나면 다음 운행일 없음', () {
      final ServiceCalendar twoTerms = ServiceCalendar(
        weekdays: const <int>{1, 2, 3, 4, 5},
        periods: <DateRange>[
          DateRange(DateTime(2026, 3, 3), DateTime(2026, 6, 22)),
          DateRange(DateTime(2026, 9, 1), DateTime(2026, 12, 21)),
        ],
      );
      final DirectionBoard summer = directionBoard(
        toTerminal,
        twoTerms,
        school,
        DateTime(2026, 7, 15, 9, 0),
      );
      expect(summer.offReason, OffReason.outOfPeriod);
      expect(summer.nextService!.day, DateTime(2026, 9, 1));
      final DirectionBoard winter = directionBoard(
        toTerminal,
        twoTerms,
        school,
        DateTime(2026, 12, 23, 9, 0),
      );
      expect(winter.offReason, OffReason.outOfPeriod);
      expect(winter.nextService, isNull);
    });

    test('월·목·금만 다니는 차는 화요일에 없다', () {
      final Direction uiwang = Direction(
        id: 'chungju-uiwang',
        label: '충주 → 의왕',
        from: '충주(대학원동)',
        to: '의왕(전산관)',
        trips: <Trip>[
          Trip(
            line: '71마6866',
            depart: parseMinutes('13:00'),
            weekdays: const <int>{1, 4, 5},
          ),
        ],
      );
      final DirectionBoard tuesday = directionBoard(
        uiwang,
        weekdays,
        school,
        DateTime(2026, 10, 27, 9, 0),
      );
      expect(tuesday.runsToday, isFalse);
      expect(tuesday.nextService!.day, DateTime(2026, 10, 29)); // 목요일
    });
  });

  group('등교·하교 자동 선택', () {
    final CommuteRoute cheongju = CommuteRoute(
      id: 'commute-cheongju',
      chip: '청주',
      title: '청주가경터미널 ⇄ 신흥고 ⇄ 충주캠퍼스',
      campuses: const <String>['chungju'],
      calendar: weekdays,
      toCampus: <Stop>[
        Stop('청주가경터미널', parseMinutes('07:15')),
        Stop('청주신흥고', parseMinutes('07:45')),
        Stop('중원생활관', parseMinutes('08:53')),
      ],
      fromCampus: <Stop>[
        Stop('충주캠퍼스 노천극장 앞', parseMinutes('18:10')),
        Stop('청주가경터미널', parseMinutes('19:25')),
      ],
    );

    CommuteLeg at(DateTime time) => autoCommuteLeg(cheongju, school, time);

    test('아침에는 등교, 등교 버스가 닿은 뒤부터 하교 버스가 떠날 때까지 하교', () {
      expect(at(DateTime(2026, 10, 6, 6, 50)), CommuteLeg.toCampus);
      expect(at(DateTime(2026, 10, 6, 8, 53)), CommuteLeg.toCampus);
      expect(at(DateTime(2026, 10, 6, 8, 54)), CommuteLeg.fromCampus);
      expect(at(DateTime(2026, 10, 6, 14, 32)), CommuteLeg.fromCampus); // 목업
      expect(at(DateTime(2026, 10, 6, 18, 10)), CommuteLeg.fromCampus);
    });

    test('하교 버스가 떠난 뒤와 다니지 않는 날은 다음 등교', () {
      expect(at(DateTime(2026, 10, 6, 18, 11)), CommuteLeg.toCampus);
      expect(at(DateTime(2026, 10, 10, 14, 0)), CommuteLeg.toCampus); // 토요일
    });

    test('다음 출발: 오늘 아직이면 오늘, 지났으면 다음 운행일', () {
      final CommuteDeparture today = nextCommuteDeparture(
        cheongju,
        CommuteLeg.fromCampus,
        school,
        DateTime(2026, 10, 6, 14, 32),
      )!;
      expect(today.day, DateTime(2026, 10, 6));
      expect(
        today.minutesFrom(DateTime(2026, 10, 6, 14, 32)),
        3 * 60 + 38,
      ); // 목업 "3시간 38분 후"
      final CommuteDeparture tomorrow = nextCommuteDeparture(
        cheongju,
        CommuteLeg.toCampus,
        school,
        DateTime(2026, 10, 8, 19, 0),
      )!;
      expect(tomorrow.day, DateTime(2026, 10, 12)); // 금요일 한글날, 주말 지나 월요일
    });
  });

  test('시각·날짜 표시', () {
    expect(formatDuration(15), '15분');
    expect(formatDuration(60), '1시간');
    expect(formatDuration(218), '3시간 38분');
    expect(shortDate(DateTime(2026, 10, 28)), '10/28 수');
    expect(formatMinutes(parseMinutes('8:42')), '08:42');
  });
}
