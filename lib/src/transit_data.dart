import 'school_calendar.dart';

/// 차 한 대의 출발·도착.
class Trip {
  const Trip({
    required this.line,
    required this.depart,
    this.arrive,
    this.note,
    this.weekdays,
  });

  factory Trip.fromJson(Map<String, Object?> json) => Trip(
    line: json['line']! as String,
    depart: parseMinutes(json['depart']! as String),
    arrive: json['arrive'] == null
        ? null
        : parseMinutes(json['arrive']! as String),
    note: json['note'] as String?,
    weekdays: json['weekdays'] == null
        ? null
        : <int>{
            for (final Object? d in json['weekdays']! as List<Object?>)
              d! as int,
          },
  );

  /// 노선(`999`, `700 순환`, 차량 번호).
  final String line;

  /// 출발 시각(0시부터 분).
  final int depart;

  /// 도착 시각. 학교 안내에 없으면 null.
  final int? arrive;
  final String? note;

  /// 이 차만 다니는 요일(월·목·금 등). null이면 노선 달력대로.
  final Set<int>? weekdays;
}

/// 한 방향(교통대 → 터미널 등)의 시간표.
class Direction {
  const Direction({
    required this.id,
    required this.label,
    required this.from,
    required this.to,
    this.fromCampus,
    this.toCampus,
    this.trips = const <Trip>[],
  });

  factory Direction.fromJson(Map<String, Object?> json) => Direction(
    id: json['id']! as String,
    label: json['label']! as String,
    from: json['from']! as String,
    to: json['to']! as String,
    fromCampus: json['fromCampus'] as String?,
    toCampus: json['toCampus'] as String?,
    trips: <Trip>[
      for (final Object? t in json['trips']! as List<Object?>)
        Trip.fromJson(t! as Map<String, Object?>),
    ],
  );

  final String id;
  final String label;
  final String from;
  final String to;
  final String? fromCampus;
  final String? toCampus;
  final List<Trip> trips;
}

/// 시간표가 있는 노선(시내버스, 캠퍼스 순환버스).
class TimetableService {
  const TimetableService({
    required this.id,
    required this.kind,
    required this.campuses,
    required this.title,
    required this.calendar,
    this.source,
    this.dayLabel,
    this.notes = const <String>[],
    this.directions = const <Direction>[],
  });

  factory TimetableService.fromJson(Map<String, Object?> json) =>
      TimetableService(
        id: json['id']! as String,
        kind: json['kind']! as String,
        campuses: <String>[
          for (final Object? c in json['campuses']! as List<Object?>)
            c! as String,
        ],
        title: json['title']! as String,
        source: json['source'] as String?,
        calendar: ServiceCalendar.fromJson(
          json['calendar']! as Map<String, Object?>,
        ),
        dayLabel: json['dayLabel'] as String?,
        notes: <String>[
          for (final Object? n
              in json['notes'] as List<Object?>? ?? const <Object?>[])
            n! as String,
        ],
        directions: <Direction>[
          for (final Object? d in json['directions']! as List<Object?>)
            Direction.fromJson(d! as Map<String, Object?>),
        ],
      );

  final String id;

  /// `city` 또는 `shuttle`.
  final String kind;
  final List<String> campuses;
  final String title;
  final String? source;
  final ServiceCalendar calendar;

  /// 운행 요일 표시(`평일만 운행`).
  final String? dayLabel;
  final List<String> notes;
  final List<Direction> directions;

  /// [campus]에서 볼 방향: 그 캠퍼스에서 출발하는 방향, 도착하는 방향, 관내 순서. 캠퍼스가 정해지지
  /// 않은 방향(시내버스)은 모두.
  List<Direction> directionsFor(String campus) {
    final List<Direction> out = <Direction>[];
    out.addAll(
      directions.where(
        (Direction d) =>
            d.fromCampus == null ||
            (d.fromCampus == campus && d.toCampus != campus),
      ),
    );
    out.addAll(
      directions.where(
        (Direction d) =>
            d.fromCampus != null &&
            d.fromCampus != campus &&
            d.toCampus == campus,
      ),
    );
    out.addAll(
      directions.where(
        (Direction d) => d.fromCampus == campus && d.toCampus == campus,
      ),
    );
    return out;
  }
}

/// 통학버스 정류장.
class Stop {
  const Stop(this.name, this.time);

  factory Stop.fromJson(Map<String, Object?> json) => Stop(
    json['name']! as String,
    json['time'] == null ? null : parseMinutes(json['time']! as String),
  );

  final String name;

  /// 시각(0시부터 분). 학교 안내가 순서에 맞지 않아 비운 곳은 null.
  final int? time;
}

/// 등교·하교.
enum CommuteLeg {
  toCampus('등교'),
  fromCampus('하교');

  const CommuteLeg(this.label);
  final String label;
}

/// 통학버스 노선(청주, 이천, 충주 시내).
class CommuteRoute {
  const CommuteRoute({
    required this.id,
    required this.chip,
    required this.title,
    required this.campuses,
    required this.calendar,
    required this.toCampus,
    required this.fromCampus,
    this.source,
    this.periodText,
    this.fare,
    this.payment,
    this.notes = const <String>[],
  });

  factory CommuteRoute.fromJson(Map<String, Object?> json) {
    List<Stop> stops(String key) => <Stop>[
      for (final Object? s in json[key]! as List<Object?>)
        Stop.fromJson(s! as Map<String, Object?>),
    ];
    return CommuteRoute(
      id: json['id']! as String,
      chip: json['chip']! as String,
      title: json['title']! as String,
      campuses: <String>[
        for (final Object? c in json['campuses']! as List<Object?>)
          c! as String,
      ],
      source: json['source'] as String?,
      calendar: ServiceCalendar.fromJson(
        json['calendar']! as Map<String, Object?>,
      ),
      periodText: json['periodText'] as String?,
      fare: json['fare'] as String?,
      payment: json['payment'] as String?,
      notes: <String>[
        for (final Object? n
            in json['notes'] as List<Object?>? ?? const <Object?>[])
          n! as String,
      ],
      toCampus: stops('toCampus'),
      fromCampus: stops('fromCampus'),
    );
  }

  final String id;

  /// 노선 칩 이름.
  final String chip;
  final String title;
  final List<String> campuses;
  final String? source;
  final ServiceCalendar calendar;
  final String? periodText;
  final String? fare;
  final String? payment;
  final List<String> notes;
  final List<Stop> toCampus;
  final List<Stop> fromCampus;

  List<Stop> stops(CommuteLeg leg) =>
      leg == CommuteLeg.toCampus ? toCampus : fromCampus;

  /// 그 방향 버스가 첫 정류장을 떠나는 시각.
  int? departure(CommuteLeg leg) {
    for (final Stop stop in stops(leg)) {
      if (stop.time != null) return stop.time;
    }
    return null;
  }

  /// 그 방향 버스가 마지막 정류장에 닿는 시각.
  int? arrival(CommuteLeg leg) {
    for (final Stop stop in stops(leg).reversed) {
      if (stop.time != null) return stop.time;
    }
    return null;
  }
}

/// 캠퍼스별 교통 안내(지도, 시간표가 없는 캠퍼스의 시내버스 안내).
class TransitCampus {
  const TransitCampus({
    required this.id,
    required this.name,
    required this.short,
    this.mapTitle,
    this.mapUrl,
    this.cityGuide = const <String>[],
    this.cityGuideSource,
  });

  factory TransitCampus.fromJson(Map<String, Object?> json) {
    final Map<String, Object?>? map = json['map'] as Map<String, Object?>?;
    return TransitCampus(
      id: json['id']! as String,
      name: json['name']! as String,
      short: json['short']! as String,
      mapTitle: map?['title'] as String?,
      mapUrl: map?['url'] as String?,
      cityGuide: <String>[
        for (final Object? g
            in json['cityGuide'] as List<Object?>? ?? const <Object?>[])
          g! as String,
      ],
      cityGuideSource: json['cityGuideSource'] as String?,
    );
  }

  final String id;
  final String name;
  final String short;
  final String? mapTitle;
  final String? mapUrl;
  final List<String> cityGuide;
  final String? cityGuideSource;
}

/// `assets/data/transit.json`.
class TransitData {
  const TransitData({
    required this.campuses,
    required this.timetables,
    required this.commutes,
    this.fetchedAt,
    this.validFrom,
    this.validTo,
  });

  factory TransitData.fromJson(Map<String, Object?> json) {
    final List<TimetableService> timetables = <TimetableService>[];
    final List<CommuteRoute> commutes = <CommuteRoute>[];
    for (final Object? s in json['services']! as List<Object?>) {
      final Map<String, Object?> service = s! as Map<String, Object?>;
      if (service['kind'] == 'commute') {
        commutes.add(CommuteRoute.fromJson(service));
      } else {
        timetables.add(TimetableService.fromJson(service));
      }
    }
    final String? from = json['validFrom'] as String?;
    final String? to = json['validTo'] as String?;
    return TransitData(
      fetchedAt: json['fetchedAt'] as String?,
      validFrom: from == null ? null : parseDate(from),
      validTo: to == null ? null : parseDate(to),
      campuses: <TransitCampus>[
        for (final Object? c in json['campuses']! as List<Object?>)
          TransitCampus.fromJson(c! as Map<String, Object?>),
      ],
      timetables: timetables,
      commutes: commutes,
    );
  }

  final String? fetchedAt;
  final DateTime? validFrom;
  final DateTime? validTo;
  final List<TransitCampus> campuses;
  final List<TimetableService> timetables;
  final List<CommuteRoute> commutes;

  TransitCampus? campus(String id) {
    for (final TransitCampus c in campuses) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// [campus]의 시내버스. 없으면 null.
  TimetableService? city(String campus) => _timetable('city', campus);

  /// [campus]에서 볼 캠퍼스 순환버스. 없으면 null.
  TimetableService? shuttle(String campus) => _timetable('shuttle', campus);

  List<CommuteRoute> commutesFor(String campus) => <CommuteRoute>[
    for (final CommuteRoute r in commutes)
      if (r.campuses.contains(campus)) r,
  ];

  TimetableService? _timetable(String kind, String campus) {
    for (final TimetableService s in timetables) {
      if (s.kind == kind &&
          s.campuses.contains(campus) &&
          s.directionsFor(campus).isNotEmpty) {
        return s;
      }
    }
    return null;
  }
}

/// 다음 운행일의 첫 차.
class NextService {
  const NextService(this.day, this.trip);
  final DateTime day;
  final Trip trip;
}

/// 한 방향의 지금 상태(통합본 8-2: 다음 버스까지 남은 시간).
class DirectionBoard {
  const DirectionBoard({
    required this.now,
    required this.offReason,
    required this.trips,
    required this.nextIndex,
    required this.nextService,
    this.nextServiceTrips = const <Trip>[],
  });

  final DateTime now;

  /// 오늘 다니지 않는 이유. 다니면 null.
  final OffReason? offReason;

  /// 보여 줄 시간표: 오늘 다니면 오늘 차들, 아니면 다음 운행일의 차들.
  final List<Trip> trips;

  /// 오늘 다음 차의 [trips] 위치. 오늘 다니지 않거나 막차가 지났으면 null.
  final int? nextIndex;

  /// 오늘 다닐 차가 없을 때(다니지 않는 날, 막차 뒤) 다음 운행일의 첫 차. 기간 안에 없으면 null.
  final NextService? nextService;

  /// [nextService] 날의 시간표.
  final List<Trip> nextServiceTrips;

  bool get runsToday => offReason == null;

  /// 오늘 다니는데 막차가 지났다.
  bool get finishedToday => runsToday && nextIndex == null;

  Trip? get next => nextIndex == null ? null : trips[nextIndex!];

  /// 다음 차의 다음 차(오늘).
  Trip? get following => nextIndex == null || nextIndex! + 1 >= trips.length
      ? null
      : trips[nextIndex! + 1];

  /// 오늘 [trip]까지 남은 분. 지난 차는 음수.
  int minutesUntil(Trip trip) => trip.depart - minuteOfDay(now);

  /// 오늘 시간표에서 이미 떠난 차.
  bool isPast(int index) =>
      runsToday && (nextIndex == null || index < nextIndex!);
}

/// 다음 운행일을 찾는 가장 먼 날수.
const int _searchDays = 400;

/// [now]에 [direction]의 상태를 계산한다. 주말·공휴일·운행 기간 밖이면 다니지 않는 날로 보고
/// 다음 운행일의 첫 차를 찾는다. 같은 분에 떠나는 차는 아직 지나지 않은 것으로 본다.
DirectionBoard directionBoard(
  Direction direction,
  ServiceCalendar calendar,
  SchoolCalendar school,
  DateTime now,
) {
  final DateTime today = dateOnly(now);
  List<Trip> tripsOn(DateTime day) => <Trip>[
    for (final Trip t in direction.trips)
      if (calendar.runsOn(day, school, tripWeekdays: t.weekdays)) t,
  ]..sort((Trip a, Trip b) => a.depart.compareTo(b.depart));

  NextService? nextFrom(DateTime start) {
    for (int i = 0; i < _searchDays; i++) {
      final DateTime day = addDays(start, i);
      final List<Trip> trips = tripsOn(day);
      if (trips.isNotEmpty) return NextService(day, trips.first);
    }
    return null;
  }

  final List<Trip> todays = tripsOn(today);
  if (todays.isEmpty) {
    final NextService? next = nextFrom(addDays(today, 1));
    final List<Trip> nextTrips = next == null
        ? const <Trip>[]
        : tripsOn(next.day);
    return DirectionBoard(
      now: now,
      offReason:
          calendar.offReason(today, school) ?? OffReason.weekend, // 그 요일 차가 없음
      trips: nextTrips,
      nextIndex: null,
      nextService: next,
      nextServiceTrips: nextTrips,
    );
  }
  final int minute = minuteOfDay(now);
  final int index = todays.indexWhere((Trip t) => t.depart >= minute);
  final NextService? next = index < 0 ? nextFrom(addDays(today, 1)) : null;
  return DirectionBoard(
    now: now,
    offReason: null,
    trips: todays,
    nextIndex: index < 0 ? null : index,
    nextService: next,
    nextServiceTrips: next == null ? const <Trip>[] : tripsOn(next.day),
  );
}

/// 통학버스 노선을 고를 때 자동으로 고를 등교·하교.
///
/// - 오늘 다니고 등교 버스가 캠퍼스에 닿기 전이면 등교
/// - 오늘 다니고 하교 버스가 캠퍼스를 떠나기 전이면 하교
/// - 그 밖(하교 버스가 떠난 뒤, 다니지 않는 날)은 다음 운행일의 등교
CommuteLeg autoCommuteLeg(
  CommuteRoute route,
  SchoolCalendar school,
  DateTime now,
) {
  if (!route.calendar.runsOn(now, school)) return CommuteLeg.toCampus;
  final int minute = minuteOfDay(now);
  final int? toEnd = route.arrival(CommuteLeg.toCampus);
  if (toEnd != null && minute <= toEnd) return CommuteLeg.toCampus;
  final int? fromStart = route.departure(CommuteLeg.fromCampus);
  if (fromStart != null && minute <= fromStart) return CommuteLeg.fromCampus;
  return CommuteLeg.toCampus;
}

/// 통학버스 한 방향의 다음 출발.
class CommuteDeparture {
  const CommuteDeparture(this.day, this.minute);

  final DateTime day;

  /// 첫 정류장 출발 시각(0시부터 분).
  final int minute;

  DateTime get time =>
      DateTime(day.year, day.month, day.day, minute ~/ 60, minute % 60);

  /// [now]부터 남은 분.
  int minutesFrom(DateTime now) => time
      .difference(DateTime(now.year, now.month, now.day, now.hour, now.minute))
      .inMinutes;
}

/// 통학버스 [leg] 방향의 다음 출발(오늘 아직 떠나지 않았으면 오늘, 아니면 다음 운행일).
CommuteDeparture? nextCommuteDeparture(
  CommuteRoute route,
  CommuteLeg leg,
  SchoolCalendar school,
  DateTime now,
) {
  final int? depart = route.departure(leg);
  if (depart == null) return null;
  final DateTime today = dateOnly(now);
  for (int i = 0; i < _searchDays; i++) {
    final DateTime day = addDays(today, i);
    if (!route.calendar.runsOn(day, school)) continue;
    if (i == 0 && depart < minuteOfDay(now)) continue;
    return CommuteDeparture(day, depart);
  }
  return null;
}
