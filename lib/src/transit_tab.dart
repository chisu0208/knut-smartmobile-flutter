import 'dart:async';

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_data.dart';
import 'campus_setting.dart';
import 'school_calendar.dart';
import 'tab_widgets.dart';
import 'transit_data.dart';

const List<FontFeature> _figures = <FontFeature>[FontFeature.tabularFigures()];

/// 교통 탭(개선판 2차, 통합본 8-1, 8-2, 4-8, 목업 `mockups/city.png`·`commute.png`).
///
/// 위 탭: 시내버스·통학버스·캠퍼스 순환. 캠퍼스는 학식 탭과 같은 설정이다. 다음 버스까지 남은 시간은
/// 1분마다 다시 계산한다. 주말·공휴일·방학이면 "오늘은 운행하지 않아요"와 다음 운행일을 보인다.
/// 지금 시각은 [clock]으로 받는다(테스트).
class TransitTab extends StatefulWidget {
  const TransitTab({
    super.key,
    required this.data,
    required this.school,
    required this.setting,
    required this.openPage,
    this.clock = DateTime.now,
  });

  final TransitData data;
  final SchoolCalendar school;
  final CampusSetting setting;
  final OpenPage openPage;
  final Clock clock;

  @override
  State<TransitTab> createState() => _TransitTabState();
}

class _TransitTabState extends State<TransitTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  Timer? _tick;

  /// 캠퍼스별로 고른 시내버스·순환버스 방향과 통학버스 노선.
  final Map<String, String> _cityDirection = <String, String>{};
  final Map<String, String> _shuttleDirection = <String, String>{};
  final Map<String, String> _commuteRoute = <String, String>{};

  /// 사용자가 바꾼 등교·하교(노선 id별). 없으면 시간대에 맞춰 자동으로 고른다.
  final Map<String, CommuteLeg> _legOverride = <String, CommuteLeg>{};

  @override
  void initState() {
    super.initState();
    widget.setting.addListener(_onSetting);
    _scheduleTick();
  }

  @override
  void dispose() {
    _tick?.cancel();
    widget.setting.removeListener(_onSetting);
    _tabs.dispose();
    super.dispose();
  }

  void _onSetting() => setState(() {});

  /// 다음 분이 바뀔 때 다시 그린다(남은 시간 1분마다 갱신).
  void _scheduleTick() {
    final DateTime now = widget.clock();
    final Duration wait = Duration(
      milliseconds: 60000 - (now.second * 1000 + now.millisecond),
    );
    _tick = Timer(wait, () {
      if (!mounted) return;
      setState(() {});
      _scheduleTick();
    });
  }

  @override
  Widget build(BuildContext context) {
    final String campusId = widget.setting.campus;
    final TransitCampus? campus = widget.data.campus(campusId);
    final DateTime now = widget.clock();
    final bool bigText = MediaQuery.textScalerOf(context).scale(15) > 20;
    return ColoredBox(
      color: AppColors.bg,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TabHeader(
              title: '교통',
              trailing: <Widget>[
                CampusButton(
                  campuses: <CampusOption>[
                    for (final TransitCampus c in widget.data.campuses)
                      CampusOption(id: c.id, name: c.name, short: c.short),
                  ],
                  selected: campusId,
                  onSelected: (String id) => widget.setting.campus = id,
                ),
                if (campus?.mapUrl != null)
                  IconButton(
                    tooltip: campus!.mapTitle ?? '길찾기',
                    onPressed: () => widget.openPage(
                      campus.mapTitle ?? '길찾기',
                      campus.mapUrl!,
                    ),
                    icon: const Icon(Icons.map_outlined),
                  ),
              ],
            ),
            TabBar(
              controller: _tabs,
              isScrollable: bigText,
              tabAlignment: bigText ? TabAlignment.center : null,
              tabs: const <Widget>[
                Tab(text: '시내버스'),
                Tab(text: '통학버스'),
                Tab(text: '캠퍼스 순환'),
              ],
            ),
            Expanded(
              child: campus == null
                  ? const SizedBox.shrink()
                  : TabBarView(
                      controller: _tabs,
                      children: <Widget>[
                        _cityView(campus, now),
                        _commuteView(campus, now),
                        _shuttleView(campus, now),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _basis() {
    final TransitData data = widget.data;
    final String fetched = data.fetchedAt == null
        ? ''
        : '${data.fetchedAt} 학교 홈페이지 기준';
    final String period = data.validFrom == null || data.validTo == null
        ? ''
        : '적용 ${shortDate(data.validFrom!)}~${shortDate(data.validTo!)}';
    return <String>[
      fetched,
      period,
    ].where((String s) => s.isNotEmpty).join(' · ');
  }

  Widget _cityView(TransitCampus campus, DateTime now) {
    final TimetableService? city = widget.data.city(campus.id);
    if (city == null) {
      return ListView(
        key: PageStorageKey<String>('city-${campus.id}'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: <Widget>[
          NoticeCard(
            icon: Icons.directions_bus_outlined,
            title: '${campus.name} 시내버스 시간표가 없어요',
            message: campus.cityGuide.isEmpty
                ? '학교 홈페이지에 시내버스 시간표가 없습니다.'
                : '학교 홈페이지의 찾아오시는 길 안내입니다.',
          ),
          const SizedBox(height: 8),
          for (final String line in campus.cityGuide)
            InfoLine(icon: Icons.directions_bus_outlined, text: line),
          if (campus.cityGuideSource != null)
            DataBasis(
              text: '찾아오시는 길',
              sourceLabel: '학교 안내 보기',
              onOpenSource: () =>
                  widget.openPage('찾아오시는 길', campus.cityGuideSource!),
            ),
        ],
      );
    }
    return _timetableView(
      key: 'city-${campus.id}',
      service: city,
      campus: campus,
      now: now,
      selectedId: _cityDirection[campus.id],
      onSelect: (String id) => setState(() => _cityDirection[campus.id] = id),
      chips: false,
    );
  }

  Widget _shuttleView(TransitCampus campus, DateTime now) {
    final TimetableService? shuttle = widget.data.shuttle(campus.id);
    if (shuttle == null) {
      return ListView(
        key: PageStorageKey<String>('shuttle-${campus.id}'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: <Widget>[
          NoticeCard(
            icon: Icons.airport_shuttle_outlined,
            title: '${campus.name} 캠퍼스 순환버스가 없어요',
          ),
        ],
      );
    }
    return _timetableView(
      key: 'shuttle-${campus.id}',
      service: shuttle,
      campus: campus,
      now: now,
      selectedId: _shuttleDirection[campus.id],
      onSelect: (String id) =>
          setState(() => _shuttleDirection[campus.id] = id),
      chips: true,
    );
  }

  /// 시내버스·캠퍼스 순환버스: 방향 고르기 + 다음 버스 카드 + 오늘 시간표.
  Widget _timetableView({
    required String key,
    required TimetableService service,
    required TransitCampus campus,
    required DateTime now,
    required String? selectedId,
    required ValueChanged<String> onSelect,
    required bool chips,
  }) {
    final List<Direction> directions = service.directionsFor(campus.id);
    final Direction direction = directions.firstWhere(
      (Direction d) => d.id == selectedId,
      orElse: () => directions.first,
    );
    final DirectionBoard board = directionBoard(
      direction,
      service.calendar,
      widget.school,
      now,
    );
    final TextTheme text = Theme.of(context).textTheme;
    return ListView(
      key: PageStorageKey<String>(key),
      padding: const EdgeInsets.only(bottom: 24),
      children: <Widget>[
        if (directions.length > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: chips
                ? Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      for (final Direction d in directions)
                        ChoiceChip(
                          label: Text(d.label),
                          selected: d.id == direction.id,
                          onSelected: (_) => onSelect(d.id),
                        ),
                    ],
                  )
                : SegmentedChoice<String>(
                    options: <(String, String)>[
                      for (final Direction d in directions) (d.id, d.label),
                    ],
                    selected: direction.id,
                    onChanged: onSelect,
                  ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: _NextBusCard(
            board: board,
            direction: direction,
            school: widget.school,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 16, 8),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: <Widget>[
              Text(
                board.runsToday || board.nextService == null
                    ? '오늘 시간표'
                    : '${mediumDate(board.nextService!.day)} 시간표',
                style: text.titleSmall?.copyWith(color: AppColors.sub),
              ),
              if (service.dayLabel != null) _AssistChip(service.dayLabel!),
            ],
          ),
        ),
        if (board.trips.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text('보여 줄 시간표가 없어요', style: text.bodyMedium),
          )
        else
          ColoredBox(
            color: Colors.white,
            child: Column(
              children: <Widget>[
                for (int i = 0; i < board.trips.length; i++) ...<Widget>[
                  if (i > 0) const Divider(),
                  _TripRow(board: board, index: i, direction: direction),
                ],
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            children: <Widget>[
              for (final String note in service.notes)
                InfoLine(icon: Icons.info_outline, text: note),
            ],
          ),
        ),
        DataBasis(
          text: _basis(),
          sourceLabel: '학교 안내 보기',
          onOpenSource: service.source == null
              ? null
              : () => widget.openPage(service.title, service.source!),
        ),
      ],
    );
  }

  Widget _commuteView(TransitCampus campus, DateTime now) {
    final List<CommuteRoute> routes = widget.data.commutesFor(campus.id);
    if (routes.isEmpty) {
      final String? source = widget.data.commutes.isEmpty
          ? null
          : widget.data.commutes.first.source;
      return ListView(
        key: PageStorageKey<String>('commute-${campus.id}'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: <Widget>[
          NoticeCard(
            icon: Icons.directions_bus_outlined,
            title: '${campus.name} 통학버스 노선이 없어요',
            message:
                '학교 홈페이지 통학버스 안내에는 충주캠퍼스 노선만 있습니다. '
                '캠퍼스 사이는 캠퍼스 순환버스를 보세요.',
            actions: <Widget>[
              if (source != null)
                OutlinedButton(
                  onPressed: () => widget.openPage('통학버스', source),
                  child: const Text('학교 안내 보기'),
                ),
            ],
          ),
        ],
      );
    }
    final CommuteRoute route = routes.firstWhere(
      (CommuteRoute r) => r.id == _commuteRoute[campus.id],
      orElse: () => routes.first,
    );
    final CommuteLeg leg =
        _legOverride[route.id] ?? autoCommuteLeg(route, widget.school, now);
    final CommuteDeparture? next = nextCommuteDeparture(
      route,
      leg,
      widget.school,
      now,
    );
    final List<Stop> stops = route.stops(leg);
    return ListView(
      key: PageStorageKey<String>('commute-${campus.id}'),
      padding: const EdgeInsets.only(bottom: 24),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final CommuteRoute r in routes)
                ChoiceChip(
                  label: Text(r.chip),
                  selected: r.id == route.id,
                  onSelected: (_) => setState(() {
                    _commuteRoute[campus.id] = r.id;
                    _legOverride.remove(r.id);
                  }),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SegmentedChoice<CommuteLeg>(
            options: <(CommuteLeg, String)>[
              for (final CommuteLeg l in CommuteLeg.values) (l, l.label),
            ],
            selected: leg,
            onChanged: (CommuteLeg l) =>
                setState(() => _legOverride[route.id] = l),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: _CommuteCard(
            route: route,
            leg: leg,
            campus: campus,
            next: next,
            now: now,
            school: widget.school,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: _StopsCard(stops: stops),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            children: <Widget>[
              if (route.fare != null)
                InfoLine(
                  icon: Icons.payments_outlined,
                  text: <String>[route.fare!, ?route.payment].join(' · '),
                ),
              if (route.periodText != null)
                InfoLine(icon: Icons.event_outlined, text: route.periodText!),
              for (final String note in route.notes)
                InfoLine(icon: Icons.info_outline, text: note),
            ],
          ),
        ),
        DataBasis(
          text: _basis(),
          sourceLabel: '학교 안내 보기',
          onOpenSource: route.source == null
              ? null
              : () => widget.openPage('통학버스', route.source!),
        ),
      ],
    );
  }
}

/// 운행하지 않는 이유(`주말`, `한글날`, `방학`).
String offReasonText(OffReason? reason, DateTime day, SchoolCalendar school) {
  switch (reason) {
    case null:
      return '';
    case OffReason.holiday:
      return school.holidayName(day) ?? '공휴일';
    case OffReason.outOfPeriod:
      return '방학·운행 기간 밖';
    case OffReason.weekend:
      return day.weekday >= DateTime.saturday ? '주말' : '운행하지 않는 요일';
  }
}

/// `내일`, `10월 28일(수)`.
String _dayWord(DateTime day, DateTime now) {
  final DateTime today = dateOnly(now);
  if (day == today) return '오늘';
  if (day == addDays(today, 1)) return '내일';
  return mediumDate(day);
}

/// 다음 버스 카드(목업의 큰 카드).
class _NextBusCard extends StatelessWidget {
  const _NextBusCard({
    required this.board,
    required this.direction,
    required this.school,
  });

  final DirectionBoard board;
  final Direction direction;
  final SchoolCalendar school;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    const Color ink = AppColors.primaryDark;
    final Trip? next = board.next;
    final List<Widget> children = <Widget>[];
    if (next != null) {
      final int minutes = board.minutesUntil(next);
      children.addAll(<Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            LineBadge(next.line, strong: _isMainLine(next.line)),
            Text(
              '다음 버스 · ${direction.from} 출발',
              style: text.titleSmall?.copyWith(color: ink),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _BigLine(
          big: minutes <= 0 ? '곧' : formatDuration(minutes),
          small: '출발',
          prefixSmall: minutes <= 0 ? null : '후',
        ),
        const SizedBox(height: 6),
        Text(
          _tripLine(next, direction),
          style: text.bodyLarge?.copyWith(color: ink, fontFeatures: _figures),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(color: Color(0x266E0E1C)),
        ),
        Row(
          children: <Widget>[
            const Icon(Icons.schedule, size: 18, color: ink),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                board.following == null
                    ? '오늘 마지막 버스예요'
                    : '그다음 버스 ${formatMinutes(board.following!.depart)} '
                          '(${formatDuration(board.minutesUntil(board.following!))} 후)',
                style: text.bodyMedium?.copyWith(
                  color: ink,
                  fontFeatures: _figures,
                ),
              ),
            ),
          ],
        ),
      ]);
    } else {
      final NextService? service = board.nextService;
      final String headline = board.runsToday
          ? '오늘 운행이 끝났어요'
          : '오늘은 운행하지 않아요 · '
                '${offReasonText(board.offReason, board.now, school)}';
      children.addAll(<Widget>[
        Text(headline, style: text.titleSmall?.copyWith(color: ink)),
        const SizedBox(height: 8),
        if (service == null)
          Text('다음 운행일 정보가 없어요', style: text.titleLarge?.copyWith(color: ink))
        else ...<Widget>[
          _BigLine(
            big: formatMinutes(service.trip.depart),
            small: '첫차',
            prefixSmall: _dayWord(service.day, board.now),
            prefixFirst: true,
          ),
          const SizedBox(height: 6),
          Text(
            '다음 운행 ${mediumDate(service.day)} · ${_tripLine(service.trip, direction)}',
            style: text.bodyMedium?.copyWith(
              color: ink,
              fontFeatures: _figures,
            ),
          ),
        ],
      ]);
    }
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

bool _isMainLine(String line) => RegExp(r'^\d+$').hasMatch(line);

/// `14:47 교통대 출발 → 15:05 시외터미널 도착`
String _tripLine(Trip trip, Direction direction) {
  final String arrive = trip.arrive == null
      ? '${direction.to}(도착 시각 안내 없음)'
      : '${formatMinutes(trip.arrive!)} ${direction.to} 도착';
  return '${formatMinutes(trip.depart)} ${direction.from} 출발 → $arrive';
}

/// 큰 글자 줄: `15분 후 출발`, `내일 08:42 첫차`.
class _BigLine extends StatelessWidget {
  const _BigLine({
    required this.big,
    required this.small,
    this.prefixSmall,
    this.prefixFirst = false,
  });

  final String big;
  final String small;
  final String? prefixSmall;

  /// [prefixSmall]을 큰 글자 앞에 둔다.
  final bool prefixFirst;

  @override
  Widget build(BuildContext context) {
    const TextStyle bigStyle = TextStyle(
      fontSize: 44,
      fontWeight: FontWeight.w800,
      height: 1.1,
      letterSpacing: -1,
      color: AppColors.primaryDark,
      fontFeatures: _figures,
    );
    const TextStyle smallStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.primaryDark,
    );
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 6,
      children: <Widget>[
        if (prefixFirst && prefixSmall != null)
          Text(prefixSmall!, style: smallStyle),
        Text(big, style: bigStyle),
        Text(
          !prefixFirst && prefixSmall != null ? '$prefixSmall $small' : small,
          style: smallStyle,
        ),
      ],
    );
  }
}

class _AssistChip extends StatelessWidget {
  const _AssistChip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// 시간표 한 줄: 지난 버스는 흐리게, 다음 버스는 강조, 남은 시간 배지.
class _TripRow extends StatelessWidget {
  const _TripRow({
    required this.board,
    required this.index,
    required this.direction,
  });

  final DirectionBoard board;
  final int index;
  final Direction direction;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Trip trip = board.trips[index];
    final bool past = board.isPast(index);
    final bool next = board.runsToday && index == board.nextIndex;
    final bool following =
        board.runsToday &&
        board.nextIndex != null &&
        index == board.nextIndex! + 1;
    Widget? trailing;
    if (past) {
      trailing = Text('지남', style: text.bodyMedium);
    } else if (next) {
      final int minutes = board.minutesUntil(trip);
      trailing = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: const ShapeDecoration(
          color: AppColors.primary,
          shape: StadiumBorder(),
        ),
        child: Text(
          minutes <= 0 ? '곧 출발' : '${formatDuration(minutes)} 후',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    } else if (following) {
      trailing = Text(
        '${formatDuration(board.minutesUntil(trip))} 후',
        style: text.bodyMedium,
      );
    }
    final String arrive = trip.arrive == null
        ? '${direction.to} 도착 시각 안내 없음'
        : '${direction.to} ${formatMinutes(trip.arrive!)} 도착';
    final Widget time = Text(
      formatMinutes(trip.depart),
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: next ? AppColors.primary : AppColors.ink,
        fontFeatures: _figures,
      ),
    );
    final Widget details = Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        LineBadge(trip.line, strong: _isMainLine(trip.line)),
        Text(arrive, style: text.bodyMedium?.copyWith(fontFeatures: _figures)),
        if (trip.note != null) Text(trip.note!, style: text.bodySmall),
      ],
    );
    // 글자가 크면(1.5배 이상) 시각·남은 시간 줄 아래에 노선·도착을 둔다(한 줄에 다 들어가지 않음).
    final bool stacked = MediaQuery.textScalerOf(context).scale(18) >= 27;
    return Opacity(
      opacity: past ? 0.42 : 1,
      child: Container(
        color: next ? AppColors.primarySoft : null,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(child: time),
                      ?trailing,
                    ],
                  ),
                  const SizedBox(height: 4),
                  details,
                ],
              )
            : Row(
                children: <Widget>[
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 60),
                    child: time,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: details),
                  if (trailing != null) ...<Widget>[
                    const SizedBox(width: 8),
                    trailing,
                  ],
                ],
              ),
      ),
    );
  }
}

/// 통학버스 다음 출발 카드.
class _CommuteCard extends StatelessWidget {
  const _CommuteCard({
    required this.route,
    required this.leg,
    required this.campus,
    required this.next,
    required this.now,
    required this.school,
  });

  final CommuteRoute route;
  final CommuteLeg leg;
  final TransitCampus campus;
  final CommuteDeparture? next;
  final DateTime now;
  final SchoolCalendar school;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    const Color ink = AppColors.primaryDark;
    final String destination = leg == CommuteLeg.fromCampus
        ? route.chip
        : campus.name;
    final String boarding = route.stops(leg).first.name;
    final OffReason? off = route.calendar.offReason(now, school);
    final CommuteDeparture? departure = next;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '$destination행 ${leg.label} 버스',
            style: text.titleSmall?.copyWith(color: ink),
          ),
          if (off != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '오늘은 운행하지 않아요 · ${offReasonText(off, now, school)}',
                style: text.bodyMedium?.copyWith(color: ink),
              ),
            ),
          const SizedBox(height: 8),
          if (departure == null)
            Text('다음 운행일 정보가 없어요', style: text.titleLarge?.copyWith(color: ink))
          else ...<Widget>[
            _BigLine(
              big: formatMinutes(departure.minute),
              small: '출발',
              prefixSmall: departure.day == dateOnly(now)
                  ? null
                  : _dayWord(departure.day, now),
              prefixFirst: true,
            ),
            const SizedBox(height: 6),
            Text(
              departure.day == dateOnly(now)
                  ? '${formatDuration(departure.minutesFrom(now))} 후 · $boarding에서 타요'
                  : '${mediumDate(departure.day)} · $boarding에서 타요',
              style: text.bodyMedium?.copyWith(
                color: ink,
                fontFeatures: _figures,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 정류장 순서와 시각.
class _StopsCard extends StatelessWidget {
  const _StopsCard({required this.stops});

  final List<Stop> stops;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: <Widget>[
            for (int i = 0; i < stops.length; i++)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SizedBox(
                      width: 44,
                      child: Column(
                        children: <Widget>[
                          Expanded(
                            child: i == 0
                                ? const SizedBox.shrink()
                                : const VerticalDivider(
                                    width: 2,
                                    thickness: 2,
                                    color: Color(0x59A3162B),
                                  ),
                          ),
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == 0 ? AppColors.primary : Colors.white,
                              border: Border.all(
                                color: AppColors.primary,
                                width: 3,
                              ),
                            ),
                          ),
                          Expanded(
                            child: i == stops.length - 1
                                ? const SizedBox.shrink()
                                : const VerticalDivider(
                                    width: 2,
                                    thickness: 2,
                                    color: Color(0x59A3162B),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 12, 18, 12),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Wrap(
                                spacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: <Widget>[
                                  Text(stops[i].name, style: text.bodyLarge),
                                  if (i == 0)
                                    Text(
                                      '탑승',
                                      style: text.labelSmall?.copyWith(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              stops[i].time == null
                                  ? '—'
                                  : formatMinutes(stops[i].time!),
                              style: text.titleMedium?.copyWith(
                                fontFeatures: _figures,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
