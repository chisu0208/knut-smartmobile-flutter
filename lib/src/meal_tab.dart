import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_data.dart';
import 'campus_setting.dart';
import 'meal_data.dart';
import 'school_calendar.dart';
import 'tab_widgets.dart';

/// 학식 탭(개선판 2차, 통합본 4-1~4-6, 8-3, 8-4, 목업 `mockups/meal.png`).
///
/// 위에서 캠퍼스·식당을 고르고, 한 주 날짜 줄에서 날을 고르면 그날 메뉴를 한 줄씩(가격은 오른쪽)
/// 보여 준다. 열면 오늘이 골라져 있다. 데이터는 앱 안 고정 데이터(`assets/data/meals.json`)다.
class MealTab extends StatefulWidget {
  const MealTab({
    super.key,
    required this.data,
    required this.school,
    required this.setting,
    required this.openPage,
    this.clock = DateTime.now,
  });

  final MealData data;
  final SchoolCalendar school;
  final CampusSetting setting;
  final OpenPage openPage;
  final Clock clock;

  @override
  State<MealTab> createState() => _MealTabState();
}

class _MealTabState extends State<MealTab> {
  /// 고른 날과 그 날을 고른 식당. 식당이 바뀌면 다시 고른다.
  DateTime? _day;
  String? _dayFor;

  @override
  void initState() {
    super.initState();
    widget.setting.addListener(_onSetting);
  }

  @override
  void didUpdateWidget(MealTab old) {
    super.didUpdateWidget(old);
    if (old.setting != widget.setting) {
      old.setting.removeListener(_onSetting);
      widget.setting.addListener(_onSetting);
    }
  }

  @override
  void dispose() {
    widget.setting.removeListener(_onSetting);
    super.dispose();
  }

  void _onSetting() => setState(() {});

  MealCampus? get _campus => widget.data.campus(widget.setting.campus);

  Restaurant? _restaurantOf(MealCampus campus) {
    if (campus.restaurants.isEmpty) return null;
    final String? id = widget.setting.restaurantFor(campus.id);
    return campus.restaurants.firstWhere(
      (Restaurant r) => r.id == id,
      orElse: () => campus.restaurants.first,
    );
  }

  DateTime _selectedDay(Restaurant restaurant) {
    if (_dayFor != restaurant.id || _day == null) {
      _dayFor = restaurant.id;
      _day = initialMealDay(restaurant, widget.clock());
    }
    return _day!;
  }

  @override
  Widget build(BuildContext context) {
    final MealCampus? campus = _campus;
    final List<CampusOption> campuses = <CampusOption>[
      for (final MealCampus c in widget.data.campuses)
        CampusOption(id: c.id, name: c.name, short: c.short),
    ];
    return ColoredBox(
      color: AppColors.bg,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TabHeader(
              title: '학식',
              trailing: <Widget>[
                CampusButton(
                  campuses: campuses,
                  selected: widget.setting.campus,
                  onSelected: (String id) => widget.setting.campus = id,
                ),
              ],
            ),
            Expanded(
              child: campus == null
                  ? const SizedBox.shrink()
                  : _body(context, campus),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, MealCampus campus) {
    final Restaurant? restaurant = _restaurantOf(campus);
    if (restaurant == null) {
      return ListView(
        key: const PageStorageKey<String>('meal-list'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: <Widget>[
          NoticeCard(
            icon: Icons.no_meals_outlined,
            title: '${campus.name} 식단 정보가 없어요',
            message: campus.note,
            actions: <Widget>[
              if (campus.source != null)
                OutlinedButton(
                  onPressed: () => widget.openPage('학교 안내', campus.source!),
                  child: const Text('학교 안내 보기'),
                ),
            ],
          ),
        ],
      );
    }
    final DateTime now = widget.clock();
    final DateTime day = _selectedDay(restaurant);
    final List<MealDay> week = mealWeek(restaurant, day, now, widget.school);
    final MealDayState state = mealStateOn(restaurant, day, widget.school);
    final TextTheme text = Theme.of(context).textTheme;
    return ListView(
      key: const PageStorageKey<String>('meal-list'),
      padding: const EdgeInsets.only(bottom: 24),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: campus.restaurants.length > 1
              ? SegmentedChoice<String>(
                  options: <(String, String)>[
                    for (final Restaurant r in campus.restaurants)
                      (r.id, r.name),
                  ],
                  selected: restaurant.id,
                  onChanged: (String id) =>
                      widget.setting.setRestaurant(campus.id, id),
                )
              : Row(
                  children: <Widget>[
                    const Icon(
                      Icons.restaurant,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(restaurant.name, style: text.titleMedium),
                    ),
                  ],
                ),
        ),
        if (restaurant.place != null || restaurant.hours != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              <String>[?restaurant.place, ?restaurant.hours].join(' · '),
              style: text.bodySmall,
            ),
          ),
        _weekNavigator(context, restaurant, day, now),
        _WeekStrip(
          days: week,
          selected: day,
          onSelected: (DateTime d) => setState(() => _day = d),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 12,
            runSpacing: 4,
            children: <Widget>[
              Text(longDate(day), style: text.titleLarge),
              if (state is MealServed)
                Text(
                  '${restaurant.name} · 메뉴 ${state.menu.itemCount}개',
                  style: text.bodyMedium,
                ),
            ],
          ),
        ),
        ..._stateContent(context, restaurant, day, state),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 20, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(Icons.info_outline, size: 16, color: AppColors.sub),
              const SizedBox(width: 6),
              Expanded(
                child: Text('식당 사정에 따라 메뉴가 바뀔 수 있어요', style: text.bodySmall),
              ),
            ],
          ),
        ),
        DataBasis(
          text: _basisText(restaurant),
          sourceLabel: '학교 홈페이지 식단',
          onOpenSource: restaurant.source == null
              ? null
              : () => widget.openPage('식단 안내', restaurant.source!),
        ),
      ],
    );
  }

  /// `식단 기준 10/26 월~10/30 금 · 2026-10-27 학교 홈페이지에서 가져옴`
  String _basisText(Restaurant restaurant) {
    final DateTime? from = restaurant.validFrom;
    final DateTime? to = restaurant.validTo;
    final String range = from == null || to == null
        ? '식단 정보 없음'
        : '식단 기준 ${shortDate(from)}~${shortDate(to)}';
    final String? fetched = restaurant.fetchedAt;
    return fetched == null ? range : '$range · $fetched 학교 홈페이지에서 가져옴';
  }

  /// 주 바꾸기: 지난주·다음 주, 이번 주가 아니면 `이번 주`.
  Widget _weekNavigator(
    BuildContext context,
    Restaurant restaurant,
    DateTime day,
    DateTime now,
  ) {
    final DateTime monday = addDays(day, -(day.weekday - 1));
    final DateTime thisMonday = addDays(dateOnly(now), -(now.weekday - 1));
    void moveWeeks(int weeks) {
      final DateTime target = addDays(monday, weeks * 7);
      setState(() {
        _day = target == thisMonday
            ? initialMealDay(restaurant, now)
            : initialMealDay(restaurant, target);
      });
    }

    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: '지난주',
            onPressed: () => moveWeeks(-1),
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              monday == thisMonday
                  ? '이번 주'
                  : '${monday.month}월 ${monday.day}일 주',
              textAlign: TextAlign.center,
              style: text.titleSmall,
            ),
          ),
          if (monday != thisMonday)
            TextButton(
              onPressed: () =>
                  setState(() => _day = initialMealDay(restaurant, now)),
              child: const Text('이번 주'),
            ),
          IconButton(
            tooltip: '다음 주',
            onPressed: () => moveWeeks(1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  List<Widget> _stateContent(
    BuildContext context,
    Restaurant restaurant,
    DateTime day,
    MealDayState state,
  ) {
    switch (state) {
      case MealServed(:final DayMenu menu):
        return <Widget>[
          for (final String notice in menu.notices) _NoticeBanner(notice),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _MenuCard(menu: menu),
          ),
        ];
      case MealClosed(:final String reason, :final List<String> notices):
        return <Widget>[
          for (final String notice in notices) _NoticeBanner(notice),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: NoticeCard(
              icon: Icons.event_busy_outlined,
              title: '쉬는 날이에요',
              message: reason,
            ),
          ),
        ];
      case MealUnknown():
        return <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: NoticeCard(
              icon: Icons.no_meals_outlined,
              title: '이 날의 식단 정보가 없습니다',
              message: restaurant.validFrom == null
                  ? '학교 홈페이지에서 식단을 확인해 주세요.'
                  : '앱에 있는 식단은 ${shortDate(restaurant.validFrom!)}~'
                        '${shortDate(restaurant.validTo!)}입니다. '
                        '학교 홈페이지에서 새 식단을 확인해 주세요.',
              actions: <Widget>[
                if (restaurant.source != null)
                  FilledButton.icon(
                    onPressed: () =>
                        widget.openPage('식단 안내', restaurant.source!),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('학교 홈페이지 식단 열기'),
                  ),
              ],
            ),
          ),
        ];
    }
  }
}

/// 한 주 날짜 줄. 쉬는 날은 빨간 글씨와 이름(휴일, 한글날 등).
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.days,
    required this.selected,
    required this.onSelected,
  });

  final List<MealDay> days;
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final MealDay day in days)
            Expanded(
              child: _DayCell(
                day: day,
                selected: day.date == dateOnly(selected),
                onTap: () => onSelected(day.date),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final MealDay day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String weekday = weekdayNames[day.date.weekday - 1];
    final String label = day.offLabel ?? (day.isToday ? '오늘' : '');
    final Color weekdayColor = day.isOff
        ? AppColors.primary
        : (selected || day.isToday ? AppColors.primary : AppColors.sub);
    final String semantics = <String>[
      longDate(day.date),
      if (day.isToday) '오늘',
      if (day.offLabel != null) '쉬는 날 ${day.offLabel}',
    ].join(', ');
    return Semantics(
      label: semantics,
      button: true,
      selected: selected,
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey<String>('meal-day-${isoDate(day.date)}'),
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: <Widget>[
              Text(
                weekday,
                style: TextStyle(
                  fontSize: 12,
                  color: weekdayColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: ShapeDecoration(
                  shape: const StadiumBorder(),
                  color: selected
                      ? AppColors.primary
                      : (day.isToday ? AppColors.primarySoft : null),
                ),
                child: Text(
                  '${day.date.day}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                    color: selected
                        ? Colors.white
                        : (day.isOff ? AppColors.sub : AppColors.ink),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label.isEmpty ? ' ' : label,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 식당 안내(행사 등).
class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.campaign_outlined,
            size: 18,
            color: AppColors.primaryDark,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.primaryDark),
            ),
          ),
        ],
      ),
    );
  }
}

/// 메뉴 카드: 메뉴마다 한 줄, 가격은 오른쪽(통합본 4-4). 분류가 둘 이상이거나 정식 가격·이용 시간이
/// 있으면 분류 제목을 보인다.
class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.menu});

  final DayMenu menu;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    const List<FontFeature> figures = <FontFeature>[
      FontFeature.tabularFigures(),
    ];
    final List<Widget> rows = <Widget>[];
    for (final MealCourse course in menu.courses) {
      final bool header =
          menu.courses.length > 1 ||
          course.price != null ||
          course.hours != null;
      if (header) {
        if (rows.isNotEmpty) rows.add(const Divider());
        rows.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: <Widget>[
                      Text(course.name, style: text.titleMedium),
                      if (course.hours != null)
                        Text(course.hours!, style: text.bodySmall),
                    ],
                  ),
                ),
                if (course.price != null)
                  Text(
                    formatWon(course.price!),
                    style: text.titleMedium?.copyWith(fontFeatures: figures),
                  ),
              ],
            ),
          ),
        );
      }
      for (int i = 0; i < course.items.length; i++) {
        final MenuItem item = course.items[i];
        if (i > 0 || (!header && rows.isNotEmpty)) {
          rows.add(const Divider(indent: 18, endIndent: 18));
        }
        rows.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: Text(item.name, style: text.bodyLarge)),
                if (item.price != null) ...<Widget>[
                  const SizedBox(width: 12),
                  Text(
                    formatWon(item.price!),
                    style: text.bodyLarge?.copyWith(
                      color: AppColors.sub,
                      fontFeatures: figures,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        ),
      ),
    );
  }
}
