import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knut_smartmobile/src/app_data.dart';
import 'package:knut_smartmobile/src/app_shell.dart';
import 'package:knut_smartmobile/src/campus_setting.dart';
import 'package:knut_smartmobile/src/shell_link.dart';
import 'package:knut_smartmobile/src/tab_route.dart';

import 'support.dart';

/// 하단 탭 막대(개선판 2차, `app_shell.dart`). 홈 탭(`MainScreen`)과 출결·도서관 탭(`WebTab`)은
/// 플랫폼 웹뷰가 있어 가짜로 바꾸고, 학식·교통 탭은 실제 화면과 저장소 데이터를 쓴다.
void main() {
  final AppData data = loadTestData();

  late MemoryStore store;
  late List<String> webTabsBuilt;
  late Map<WebTabKind, _FakeWebState> webTabs;
  late int homeBacks;

  setUp(() {
    store = MemoryStore();
    webTabsBuilt = <String>[];
    webTabs = <WebTabKind, _FakeWebState>{};
    homeBacks = 0;
  });

  Future<AppShellState> pumpShell(
    WidgetTester tester, {
    double textScale = 1,
    Size size = const Size(412, 915),
  }) async {
    await pumpScreen(
      tester,
      AppShell(
        home: (BuildContext context, TabContext tab) =>
            _FakeHome(tab: tab, onBack: () => homeBacks++),
        webTab: (BuildContext context, WebTabKind kind, TabContext tab) =>
            _FakeWeb(
              kind: kind,
              tab: tab,
              states: webTabs,
              created: webTabsBuilt,
            ),
        load: () async => ShellData(data, CampusSetting(store)),
        openPage: OpenedPages().call,
        clock: mockNow,
      ),
      textScale: textScale,
      size: size,
      material3: false, // 탭 막대가 스스로 M3 테마를 입힌다
    );
    await tester.pump();
    return tester.state<AppShellState>(find.byType(AppShell));
  }

  Future<void> tapTab(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      ),
    );
    await tester.pump();
  }

  testWidgets('탭 막대: 이름이 있는 탭 5개, 홈이 처음', (WidgetTester tester) async {
    final AppShellState shell = await pumpShell(tester);
    for (final String label in <String>['홈', '출결', '도서관', '교통', '학식']) {
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }
    for (final IconData icon in <IconData>[
      Icons.home,
      Icons.how_to_reg_outlined,
      Icons.local_library_outlined,
      Icons.directions_bus_outlined,
      Icons.restaurant_outlined,
    ]) {
      expect(find.byIcon(icon), findsOneWidget);
    }
    expect(shell.currentTab.value, AppTab.home);
    // 홈 탭은 1차의 원본 모양(M2 테마), 탭 막대는 M3
    final BuildContext home = tester.element(find.byType(_FakeHome));
    expect(Theme.of(home).useMaterial3, isFalse);
    expect(
      Theme.of(tester.element(find.byType(NavigationBar))).useMaterial3,
      isTrue,
    );
  });

  testWidgets('탭을 바꿔도 각 탭 상태가 남는다(홈 상태, 학식 식당·스크롤)', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester, size: const Size(412, 640));
    await tester.tap(find.text('홈 +1'));
    await tester.pump();
    expect(find.text('홈 1'), findsOneWidget);

    await tapTab(tester, '학식');
    await tester.tap(find.text('교직원식당'));
    await tester.pump();
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pump();
    final double offset = tester
        .state<ScrollableState>(find.byType(Scrollable).last)
        .position
        .pixels;
    expect(offset, greaterThan(0));

    await tapTab(tester, '교통');
    expect(find.text('15분'), findsOneWidget);
    await tapTab(tester, '홈');
    expect(find.text('홈 1'), findsOneWidget);
    await tapTab(tester, '학식');
    expect(find.text('백반정식'), findsOneWidget);
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable).last)
          .position
          .pixels,
      offset,
    );
  });

  testWidgets('출결·도서관 탭은 처음 열 때 만든다', (WidgetTester tester) async {
    await pumpShell(tester);
    expect(webTabsBuilt, isEmpty);
    await tapTab(tester, '출결');
    expect(webTabsBuilt, <String>['attend']);
    await tapTab(tester, '홈');
    await tapTab(tester, '출결');
    expect(webTabsBuilt, <String>['attend']); // 다시 만들지 않음
  });

  testWidgets('뒤로 키: 다른 탭에서는 홈 탭으로, 홈 탭은 원래 규칙', (WidgetTester tester) async {
    final AppShellState shell = await pumpShell(tester);
    await tapTab(tester, '교통');
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(shell.currentTab.value, AppTab.home);
    expect(homeBacks, 0);

    // 홈 탭에서는 홈(MainScreen의 y0)이 받는다.
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(shell.currentTab.value, AppTab.home);
    expect(homeBacks, 1);

    // 웹 탭: 웹 페이지가 뒤로 갈 수 있으면 먼저 뒤로, 그다음 홈으로
    await tapTab(tester, '도서관');
    webTabs[WebTabKind.library]!.canGoBack = true;
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(shell.currentTab.value, AppTab.library);
    expect(webTabs[WebTabKind.library]!.wentBack, 1);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(shell.currentTab.value, AppTab.home);
  });

  testWidgets('홈 쪽 명령이 오면 홈 탭으로, 출결·도서관 주소는 그 탭으로', (
    WidgetTester tester,
  ) async {
    final AppShellState shell = await pumpShell(tester);
    await tapTab(tester, '학식');
    shell.showHome(); // 팝업·alert 등
    await tester.pump();
    expect(shell.currentTab.value, AppTab.home);

    // 홈의 전자출결 타일: 출결 탭이 만들어지면서 주소를 받는다
    shell.openTabRoute(
      const TabRoute(WebTabKind.attend, 'https://attend.ut.ac.kr/a'),
    );
    await tester.pump();
    expect(shell.currentTab.value, AppTab.attend);
    expect(find.text('attend https://attend.ut.ac.kr/a'), findsOneWidget);

    // 이미 있는 탭에도 넘긴다
    await tapTab(tester, '홈');
    shell.openTabRoute(
      const TabRoute(WebTabKind.attend, 'https://attend.ut.ac.kr/b'),
    );
    await tester.pump();
    expect(find.text('attend https://attend.ut.ac.kr/b'), findsOneWidget);
  });

  testWidgets('동영상 전체 화면인 동안 탭 막대를 숨긴다', (WidgetTester tester) async {
    final AppShellState shell = await pumpShell(tester);
    shell.setFullscreen(AppTab.home, true);
    await tester.pump();
    expect(find.byType(NavigationBar), findsNothing);
    expect(
      MediaQuery.sizeOf(tester.element(find.byType(_FakeHome))),
      const Size(412, 915),
    );
    shell.setFullscreen(AppTab.home, false);
    await tester.pump();
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('홈 탭의 화면 크기는 홈 탭 영역(팝업 80% 규칙·대화상자 폭의 기준)', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester);
    final double bar = tester.getSize(find.byType(NavigationBar)).height;
    final Size home = MediaQuery.sizeOf(tester.element(find.byType(_FakeHome)));
    expect(home, Size(412, 915 - bar));
    expect(tester.getSize(find.byType(_FakeHome)), home);
  });

  testWidgets('캠퍼스 설정은 학식·교통이 함께 쓰고 저장된다', (WidgetTester tester) async {
    await pumpShell(tester);
    await tapTab(tester, '학식');
    await tester.tap(find.byTooltip('캠퍼스 고르기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('증평캠퍼스').last);
    await tester.pumpAndSettle();
    expect(find.text('생활관식당'), findsOneWidget);

    await tapTab(tester, '교통');
    final Text label = tester.widget<Text>(
      find
          .descendant(
            of: find.byType(IndexedStack),
            matching: find.byKey(const ValueKey<String>('campus-button-label')),
          )
          .last,
    );
    expect(label.data, '증평');
    expect(store.values[CampusSetting.campusKey], 'jeungpyeong');
    expect(CampusSetting(store).campus, 'jeungpyeong'); // 다시 열어도 남음
  });

  testWidgets('글자 크기 2배, 좁은 폰(360dp): 탭 막대와 새 화면이 깨지지 않는다', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester, textScale: 2, size: const Size(360, 780));
    expect(tester.takeException(), isNull);
    for (final String label in <String>['학식', '교통', '출결', '홈']) {
      await tapTab(tester, label);
      expect(tester.takeException(), isNull, reason: label);
    }
  });
}

class _FakeHome extends StatefulWidget {
  const _FakeHome({required this.tab, required this.onBack});

  final TabContext tab;
  final VoidCallback onBack;

  @override
  State<_FakeHome> createState() => _FakeHomeState();
}

class _FakeHomeState extends State<_FakeHome> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    widget.tab.back.onBack = () async {
      widget.onBack();
      return true; // MainScreen처럼 홈은 항상 처리한다
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text('홈 $_count'),
        TextButton(
          onPressed: () => setState(() => _count++),
          child: const Text('홈 +1'),
        ),
      ],
    );
  }
}

class _FakeWeb extends StatefulWidget {
  const _FakeWeb({
    required this.kind,
    required this.tab,
    required this.states,
    required this.created,
  });

  final WebTabKind kind;
  final TabContext tab;
  final Map<WebTabKind, _FakeWebState> states;

  /// 탭 상태(웹뷰)가 만들어진 기록.
  final List<String> created;

  @override
  State<_FakeWeb> createState() => _FakeWebState();
}

class _FakeWebState extends State<_FakeWeb> {
  String? url;
  bool canGoBack = false;
  int wentBack = 0;

  @override
  void initState() {
    super.initState();
    widget.created.add(widget.kind.name);
    widget.states[widget.kind] = this;
    url = widget.tab.link?.takeUrl();
    widget.tab.link?.addListener(_onLink);
    widget.tab.back.onBack = () async {
      if (!canGoBack) return false;
      canGoBack = false;
      wentBack++;
      return true;
    };
  }

  void _onLink() => setState(() => url = widget.tab.link?.takeUrl() ?? url);

  @override
  void dispose() {
    widget.tab.link?.removeListener(_onLink);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Text('${widget.kind.name} ${url ?? '-'}');
}
