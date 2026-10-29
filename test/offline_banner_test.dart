import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knut_smartmobile/src/offline_banner.dart';

/// 앱을 쓰는 동안 연결이 끊겼을 때의 안내 띠(개선판). 잠깐 끊겼다 돌아오는 것은 거른다.
void main() {
  testWidgets('끊긴 채로 기다리는 시간이 지나야 띠를 보이고, 돌아오면 바로 걷는다', (
    WidgetTester tester,
  ) async {
    final List<bool> changes = <bool>[];
    final OfflineTracker tracker = OfflineTracker(
      onChanged: changes.add,
      delay: const Duration(seconds: 2),
    );
    addTearDown(tracker.dispose);

    tracker.update(online: false);
    await tester.pump(const Duration(milliseconds: 1900));
    expect(tracker.offline, isFalse);
    expect(changes, isEmpty);

    await tester.pump(const Duration(milliseconds: 200));
    expect(tracker.offline, isTrue);
    expect(changes, <bool>[true]);

    tracker.update(online: true);
    expect(tracker.offline, isFalse);
    expect(changes, <bool>[true, false]);
  });

  testWidgets('잠깐 끊겼다 돌아오면 띠가 한 번도 보이지 않는다(와이파이 → 모바일 데이터)', (
    WidgetTester tester,
  ) async {
    final List<bool> changes = <bool>[];
    final OfflineTracker tracker = OfflineTracker(
      onChanged: changes.add,
      delay: const Duration(seconds: 2),
    );
    addTearDown(tracker.dispose);

    tracker.update(online: false);
    await tester.pump(const Duration(seconds: 1));
    tracker.update(online: true);
    await tester.pump(const Duration(seconds: 5));

    expect(tracker.offline, isFalse);
    expect(changes, isEmpty);
  });

  testWidgets('끊긴 알림이 거듭 와도 기다리는 시간을 다시 재지 않고, 띠도 한 번만 알린다', (
    WidgetTester tester,
  ) async {
    final List<bool> changes = <bool>[];
    final OfflineTracker tracker = OfflineTracker(
      onChanged: changes.add,
      delay: const Duration(seconds: 2),
    );
    addTearDown(tracker.dispose);

    tracker.update(online: false);
    await tester.pump(const Duration(milliseconds: 1500));
    tracker.update(online: false);
    await tester.pump(const Duration(milliseconds: 600));
    expect(changes, <bool>[true]);

    tracker.update(online: false);
    await tester.pump(const Duration(seconds: 5));
    expect(changes, <bool>[true]);
  });

  testWidgets('이미 연결된 상태의 알림은 아무 일도 하지 않는다', (WidgetTester tester) async {
    final List<bool> changes = <bool>[];
    final OfflineTracker tracker = OfflineTracker(onChanged: changes.add);
    addTearDown(tracker.dispose);

    tracker.update(online: true);
    tracker.update(online: true);
    await tester.pump(const Duration(seconds: 5));
    expect(changes, isEmpty);
  });

  testWidgets('화면이 사라지면 기다리던 알림은 취소된다', (WidgetTester tester) async {
    final List<bool> changes = <bool>[];
    final OfflineTracker tracker = OfflineTracker(onChanged: changes.add);

    tracker.update(online: false);
    tracker.dispose();
    await tester.pump(const Duration(seconds: 5));
    expect(changes, isEmpty);
  });

  testWidgets('안내 띠는 한글 문구와 아이콘을 보이고 글자가 커져도 깨지지 않는다', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(360, 640),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(body: Column(children: <Widget>[OfflineBanner()])),
        ),
      ),
    );

    expect(find.text('인터넷에 연결되어 있지 않습니다'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
