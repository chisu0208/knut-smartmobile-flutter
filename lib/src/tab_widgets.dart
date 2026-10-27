import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 새 화면(학식, 교통, 출결·도서관 탭 안내)이 함께 쓰는 부품(개선판 2차).
///
/// 모두 휴대폰 글자 크기 설정을 따르고, 글자가 커지면 칸이 늘어나거나 줄이 바뀐다(높이를 정해 두지
/// 않는다). 누르는 곳은 48dp 이상이다(통합본 5-4).

/// 화면 제목 줄: 제목(24), 오른쪽에 캠퍼스 단추·아이콘.
class TabHeader extends StatelessWidget {
  const TabHeader({
    super.key,
    required this.title,
    this.trailing = const <Widget>[],
  });

  final String title;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          ...trailing,
        ],
      ),
    );
  }
}

/// 캠퍼스 하나.
class CampusOption {
  const CampusOption({
    required this.id,
    required this.name,
    required this.short,
  });

  final String id;

  /// `충주캠퍼스`
  final String name;

  /// `충주`
  final String short;
}

/// 캠퍼스 고르기 단추. 학식·교통 탭이 같은 설정을 쓴다(`campus_setting.dart`).
class CampusButton extends StatelessWidget {
  const CampusButton({
    super.key,
    required this.campuses,
    required this.selected,
    required this.onSelected,
  });

  final List<CampusOption> campuses;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final CampusOption current = campuses.firstWhere(
      (CampusOption c) => c.id == selected,
      orElse: () => campuses.first,
    );
    return Semantics(
      label: '캠퍼스 ${current.name}',
      button: true,
      excludeSemantics: true,
      child: PopupMenuButton<String>(
        tooltip: '캠퍼스 고르기',
        initialValue: current.id,
        onSelected: onSelected,
        position: PopupMenuPosition.under,
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          for (final CampusOption c in campuses)
            CheckedPopupMenuItem<String>(
              value: c.id,
              checked: c.id == current.id,
              child: Text(c.name),
            ),
        ],
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.only(left: 12, right: 6),
          decoration: const ShapeDecoration(
            color: Colors.white,
            shape: StadiumBorder(side: BorderSide(color: AppColors.line)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.place_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                current.short,
                key: const ValueKey<String>('campus-button-label'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Icon(Icons.arrow_drop_down, color: AppColors.sub),
            ],
          ),
        ),
      ),
    );
  }
}

/// 둘·셋 가운데 하나를 고르는 칸(목업의 식당·방향 선택). 글자가 커지면 칸 안에서 줄이 바뀐다.
class SegmentedChoice<T> extends StatelessWidget {
  const SegmentedChoice({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.titleSmall;
    final List<Widget> children = <Widget>[];
    for (int i = 0; i < options.length; i++) {
      final (T value, String label) = options[i];
      final bool on = value == selected;
      if (i > 0) {
        children.add(
          const VerticalDivider(width: 1, thickness: 1, color: AppColors.mute),
        );
      }
      children.add(
        Expanded(
          child: Semantics(
            button: true,
            selected: on,
            inMutuallyExclusiveGroup: true,
            child: Material(
              color: on ? AppColors.primarySoft : Colors.white,
              child: InkWell(
                onTap: () => onChanged(value),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        if (on) ...<Widget>[
                          const Icon(
                            Icons.check,
                            size: 18,
                            color: AppColors.primaryDark,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: style?.copyWith(
                              color: on ? AppColors.primaryDark : AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.mute),
        borderRadius: BorderRadius.circular(24),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

/// 노선 배지(`999`, `700 순환`). [strong]이면 대표색 바탕.
class LineBadge extends StatelessWidget {
  const LineBadge(this.text, {super.key, this.strong = true});

  final String text;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: strong ? AppColors.primary : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.4,
          color: strong ? Colors.white : AppColors.primaryDark,
        ),
      ),
    );
  }
}

/// 아이콘 + 안내 한 줄(요금, 운행 기간, 안내 문구).
class InfoLine extends StatelessWidget {
  const InfoLine({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// 내용이 없거나 열 수 없을 때의 안내(통합본 8-9).
class NoticeCard extends StatelessWidget {
  const NoticeCard({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actions = const <Widget>[],
  });

  final IconData icon;
  final String title;
  final String? message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          children: <Widget>[
            Icon(icon, size: 40, color: AppColors.mute),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: text.titleMedium),
            if (message != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: text.bodyMedium,
              ),
            ],
            if (actions.isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 데이터 기준일과 출처 열기(학교 홈페이지).
class DataBasis extends StatelessWidget {
  const DataBasis({
    super.key,
    required this.text,
    this.sourceLabel,
    this.onOpenSource,
  });

  final String text;
  final String? sourceLabel;
  final VoidCallback? onOpenSource;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: <Widget>[
          Text(text, style: Theme.of(context).textTheme.bodySmall),
          if (onOpenSource != null)
            TextButton.icon(
              onPressed: onOpenSource,
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(sourceLabel ?? '학교 홈페이지'),
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            ),
        ],
      ),
    );
  }
}

/// `5,000원`
String formatWon(int won) {
  final String digits = won.toString();
  final StringBuffer out = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return '$out원';
}
