import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_data.dart';
import 'app_theme.dart';
import 'campus_setting.dart';
import 'meal_tab.dart';
import 'school_calendar.dart';
import 'shell_link.dart';
import 'tab_route.dart';
import 'transit_tab.dart';
import 'web_page_screen.dart';

/// 학식·교통 탭이 쓰는 데이터와 캠퍼스 설정.
class ShellData {
  const ShellData(this.data, this.setting);

  final AppData data;
  final CampusSetting setting;

  static Future<ShellData> load() async =>
      ShellData(await AppData.load(), await CampusSetting.load());
}

/// 하단 탭 5개(홈·출결·도서관·교통·학식) 화면(개선판 2차, 통합본 3-1, 8-5).
///
/// - 탭 막대는 Material 3 `NavigationBar`이고 탭 이름을 보인다.
/// - 탭을 바꿔도 각 탭 상태(스크롤, 열린 팝업, 웹 페이지)가 남는다(`IndexedStack`). 출결·도서관 탭은
///   처음 열 때 만든다.
/// - 뒤로 키: 홈이 아닌 탭은 그 탭이 처리하지 않으면(웹 페이지가 뒤로 갈 수 없으면) 홈 탭으로 간다.
///   홈 탭은 원래 규칙(`MainScreen`의 `y0`, 종료 안내 포함) 그대로다.
/// - 홈 탭 쪽 화면을 여는 서버 명령이 오면 홈 탭으로 옮긴다([ShellHost.showHome]).
/// - 동영상 전체 화면인 동안 탭 막대를 숨겨 영상이 화면 전체를 덮는다.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.home,
    required this.webTab,
    this.load = ShellData.load,
    this.openPage,
    this.clock = DateTime.now,
  });

  /// 홈 탭(앱에서는 `MainScreen`).
  final Widget Function(BuildContext context, TabContext tab) home;

  /// 출결·도서관 탭(앱에서는 `WebTab`).
  final Widget Function(BuildContext context, WebTabKind kind, TabContext tab)
  webTab;

  /// 학식·교통 탭 데이터와 캠퍼스 설정.
  final Future<ShellData> Function() load;

  /// 길찾기·식단 페이지 열기. 없으면 앱 안 웹 페이지 화면([WebPageScreen])을 띄운다.
  final OpenPage? openPage;
  final Clock clock;

  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell> implements ShellHost {
  final ValueNotifier<AppTab> _current = ValueNotifier<AppTab>(AppTab.home);
  final Set<AppTab> _visited = <AppTab>{AppTab.home};
  final Map<AppTab, TabBackHandler> _back = <AppTab, TabBackHandler>{
    for (final AppTab tab in AppTab.values) tab: TabBackHandler(),
  };
  final HomeController _home = HomeController();
  final Map<WebTabKind, WebTabLink> _links = <WebTabKind, WebTabLink>{
    for (final WebTabKind kind in WebTabKind.values) kind: WebTabLink(),
  };
  final Set<AppTab> _fullscreen = <AppTab>{};
  ShellData? _data;
  Object? _loadError;

  @override
  ValueListenable<AppTab> get currentTab => _current;

  /// 홈 탭 기능(테스트).
  HomeController get home => _home;

  @override
  void initState() {
    super.initState();
    widget.load().then(
      (ShellData data) {
        if (mounted) setState(() => _data = data);
      },
      onError: (Object error) {
        if (mounted) setState(() => _loadError = error);
      },
    );
  }

  @override
  void dispose() {
    _current.dispose();
    for (final WebTabLink link in _links.values) {
      link.dispose();
    }
    super.dispose();
  }

  static AppTab tabOf(WebTabKind kind) => switch (kind) {
    WebTabKind.attend => AppTab.attend,
    WebTabKind.library => AppTab.library,
  };

  void select(AppTab tab) {
    if (_current.value == tab && _visited.contains(tab)) return;
    setState(() => _visited.add(tab));
    _current.value = tab;
  }

  @override
  void showHome() => select(AppTab.home);

  @override
  void openTabRoute(TabRoute route) {
    _links[route.tab]!.open(route.url);
    select(tabOf(route.tab));
  }

  @override
  void setFullscreen(AppTab tab, bool fullscreen) {
    setState(() {
      if (fullscreen) {
        _fullscreen.add(tab);
      } else {
        _fullscreen.remove(tab);
      }
    });
  }

  /// 뒤로 키: 지금 탭이 처리하지 않으면 홈 탭으로.
  Future<void> handleBack() async {
    final AppTab tab = _current.value;
    final Future<bool> Function()? onBack = _back[tab]!.onBack;
    final bool handled = onBack != null && await onBack();
    if (!handled && tab != AppTab.home && _current.value == tab) {
      select(AppTab.home);
    }
  }

  void _openPage(String title, String url) {
    final OpenPage? open = widget.openPage;
    if (open != null) {
      open(title, url);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => Theme(
          data: AppTheme.material3,
          child: WebPageScreen(title: title, url: url),
        ),
      ),
    );
  }

  TabContext _context(AppTab tab, [WebTabKind? kind]) => TabContext(
    tab: tab,
    host: this,
    home: _home,
    back: _back[tab]!,
    link: kind == null ? null : _links[kind],
  );

  Widget _tabChild(BuildContext context, AppTab tab, ThemeData legacy) {
    if (!_visited.contains(tab)) return const SizedBox.shrink();
    switch (tab) {
      case AppTab.home:
        // 홈 탭은 1차의 원본 모양 위젯이라 앱 테마(Material 2)를 쓴다. 화면 크기는 홈 탭 영역으로
        // 알려 준다: MainScreen은 이 크기(`Display.getSize`)로 팝업 크기(80% 규칙)와 대화상자 폭을
        // 정하는데, 탭 막대가 생겨 창 전체보다 작아졌다.
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) =>
              MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(size: constraints.biggest),
                child: Theme(
                  data: legacy,
                  child: widget.home(context, _context(tab)),
                ),
              ),
        );
      case AppTab.attend:
        return widget.webTab(
          context,
          WebTabKind.attend,
          _context(tab, WebTabKind.attend),
        );
      case AppTab.library:
        return widget.webTab(
          context,
          WebTabKind.library,
          _context(tab, WebTabKind.library),
        );
      case AppTab.transit:
      case AppTab.meal:
        final ShellData? data = _data;
        if (data == null) {
          return ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Center(
              child: _loadError == null
                  ? const CircularProgressIndicator()
                  : const Text('데이터를 읽지 못했어요'),
            ),
          );
        }
        return tab == AppTab.meal
            ? MealTab(
                data: data.data.meals,
                school: data.data.school,
                setting: data.setting,
                openPage: _openPage,
                clock: widget.clock,
              )
            : TransitTab(
                data: data.data.transit,
                school: data.data.school,
                setting: data.setting,
                openPage: _openPage,
                clock: widget.clock,
              );
    }
  }

  static const List<NavigationDestination> _destinations =
      <NavigationDestination>[
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: '홈',
        ),
        NavigationDestination(
          icon: Icon(Icons.how_to_reg_outlined),
          selectedIcon: Icon(Icons.how_to_reg),
          label: '출결',
        ),
        NavigationDestination(
          icon: Icon(Icons.local_library_outlined),
          selectedIcon: Icon(Icons.local_library),
          label: '도서관',
        ),
        NavigationDestination(
          icon: Icon(Icons.directions_bus_outlined),
          selectedIcon: Icon(Icons.directions_bus),
          label: '교통',
        ),
        NavigationDestination(
          icon: Icon(Icons.restaurant_outlined),
          selectedIcon: Icon(Icons.restaurant),
          label: '학식',
        ),
      ];

  /// 탭 막대 글자 배율 상한. 탭 다섯 개가 한 줄에 들어가도록 둔다(글자 크기 2배에서 `도서관`이 칸을
  /// 넘지 않음, `test/shell_test.dart`).
  static const double navMaxTextScale = 1.5;

  @override
  Widget build(BuildContext context) {
    final ThemeData legacy = Theme.of(context);
    return ValueListenableBuilder<AppTab>(
      valueListenable: _current,
      builder: (BuildContext context, AppTab current, Widget? _) {
        final bool fullscreen = _fullscreen.contains(current);
        return PopScope<Object?>(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, Object? _) {
            if (!didPop) handleBack();
          },
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.transparent,
            ),
            child: Theme(
              data: AppTheme.material3,
              child: Builder(
                builder: (BuildContext context) => Column(
                  children: <Widget>[
                    Expanded(
                      child: MediaQuery.removePadding(
                        context: context,
                        removeBottom: !fullscreen,
                        child: IndexedStack(
                          index: current.index,
                          sizing: StackFit.expand,
                          children: <Widget>[
                            for (final AppTab tab in AppTab.values)
                              KeyedSubtree(
                                key: ValueKey<AppTab>(tab),
                                child: _tabChild(context, tab, legacy),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (!fullscreen)
                      MediaQuery.withClampedTextScaling(
                        maxScaleFactor: navMaxTextScale,
                        child: NavigationBar(
                          selectedIndex: current.index,
                          onDestinationSelected: (int index) =>
                              select(AppTab.values[index]),
                          destinations: _destinations,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
