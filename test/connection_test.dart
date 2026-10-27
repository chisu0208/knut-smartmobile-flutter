import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knut_smartmobile/src/allytte_http.dart';
import 'package:knut_smartmobile/src/connection_notice.dart';
import 'package:knut_smartmobile/src/intro_screen.dart';
import 'package:knut_smartmobile/src/page_load.dart';

/// flutter_test는 모든 HTTP 요청에 400을 돌려주는 가짜 클라이언트를 쓴다. 이 테스트는 진짜
/// 소켓으로 로컬 서버에 연결해야 하므로 기본 HttpClient로 되돌린다.
class _RealHttp extends HttpOverrides {}

Future<String?> _post(String url, Duration timeout) =>
    HttpOverrides.runWithHttpOverrides(
      () => allyttePost(url, '1.1.3', 'TOKEN', timeout: timeout),
      _RealHttp(),
    );

/// 연결 실패·지연 안내(통합본 1-9, 1-10, 6-10).
void main() {
  group('기기 등록 POST의 시간 제한', () {
    test('서버가 답하지 않으면 제한 시간이 지나고 null', () async {
      // 연결은 받아 주지만 응답을 보내지 않는 서버
      final HttpServer server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      final List<HttpRequest> held = <HttpRequest>[];
      server.listen(held.add);
      final Stopwatch watch = Stopwatch()..start();
      final String? result = await _post(
        'http://127.0.0.1:${server.port}/service/api/device/save',
        const Duration(milliseconds: 300),
      );
      watch.stop();
      expect(result, isNull);
      expect(held, hasLength(1)); // 요청은 서버에 닿았다
      expect(
        watch.elapsed,
        greaterThanOrEqualTo(const Duration(milliseconds: 300)),
      );
      expect(watch.elapsed, lessThan(const Duration(seconds: 3)));
      await server.close(force: true);
    });

    test('제한 시간 안에 답하면 원본처럼 urlConnResult를 덧붙인 문자열', () async {
      final HttpServer server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      server.listen((HttpRequest request) {
        request.response
          ..write('{"action":[{"command":"alert","config":{"message":"ok"}}]}')
          ..close();
      });
      final String? result = await _post(
        'http://127.0.0.1:${server.port}/',
        IntroScreen.registerTimeout,
      );
      expect(
        result,
        '{"action":[{"command":"alert","config":{"message":"ok"}}],'
        '"urlConnResult":200}',
      );
      expect(IntroScreen.isScreenInfo(result), isTrue);
      await server.close(force: true);
    });

    test('등록 요청 제한은 10초', () {
      expect(IntroScreen.registerTimeout, const Duration(seconds: 10));
    });
  });

  group('기기 등록 응답 확인', () {
    test('명령 목록이 없으면 메인으로 넘어가지 않는다', () {
      expect(IntroScreen.isScreenInfo(null), isFalse);
      expect(IntroScreen.isScreenInfo(''), isFalse);
      expect(IntroScreen.isScreenInfo('<html>'), isFalse);
      expect(
        IntroScreen.isScreenInfo('{"message":"x","urlConnResult":500}'),
        isFalse,
      );
      expect(
        IntroScreen.isScreenInfo('{"action":[],"urlConnResult":200}'),
        isTrue,
      );
    });
  });

  group('연결 안내 화면', () {
    Future<void> pump(WidgetTester tester, Widget notice) =>
        tester.pumpWidget(MaterialApp(home: Scaffold(body: notice)));

    testWidgets('연결 실패: 한글 안내와 다시 시도', (WidgetTester tester) async {
      int retries = 0;
      await pump(
        tester,
        ConnectionNotice(
          problem: ConnectionProblem.failed,
          onRetry: () => retries++,
        ),
      );
      expect(find.text('연결할 수 없습니다'), findsOneWidget);
      expect(find.textContaining('학교 서버에 연결하지 못했습니다'), findsOneWidget);
      expect(find.text('닫기'), findsNothing);
      await tester.tap(find.text('다시 시도'));
      expect(retries, 1);
      // 누르기 쉬운 크기(48dp 이상)
      expect(
        tester.getSize(find.widgetWithText(ElevatedButton, '다시 시도')).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('10초가 지나면: 늦어지고 있다는 안내', (WidgetTester tester) async {
      await pump(
        tester,
        ConnectionNotice(problem: ConnectionProblem.slow, onRetry: () {}),
      );
      expect(find.text('연결이 늦어지고 있습니다'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
    });

    testWidgets('팝업에서는 닫기도 있다', (WidgetTester tester) async {
      int closes = 0;
      await pump(
        tester,
        ConnectionNotice(
          problem: ConnectionProblem.offline,
          onRetry: () {},
          onClose: () => closes++,
        ),
      );
      expect(find.text('인터넷에 연결되어 있지 않습니다'), findsOneWidget);
      await tester.tap(find.text('닫기'));
      expect(closes, 1);
    });
  });

  group('웹뷰 불러오기 상태(로딩 표시·연결 안내)', () {
    const Map<String, String> headers = <String, String>{
      'allytte-device-platform': 'android',
    };

    test('10초 넘게 응답이 없으면 늦어지고 있다는 안내, 응답이 오면 걷힘', () {
      fakeAsync((FakeAsync async) {
        final PageLoad load = PageLoad(() {});
        load.ownLoad('https://www.ut.ac.kr/', headers);
        expect(load.busy, isTrue);
        async.elapse(const Duration(seconds: 9));
        expect(load.problem, isNull);
        async.elapse(const Duration(seconds: 1));
        expect(load.problem, ConnectionProblem.slow);
        // 서버가 답해서 페이지가 시작되면 안내를 걷고, 첫 화면이 그려지면 로딩 표시도 끈다.
        load.pageStarted('https://www.ut.ac.kr/');
        expect(load.problem, isNull);
        expect(load.busy, isTrue);
        load.settle();
        expect(load.busy, isFalse);
      });
    });

    test('첫 화면 알림이 없어도 페이지가 시작되고 5초 뒤 로딩 표시를 걷는다', () {
      fakeAsync((FakeAsync async) {
        final PageLoad load = PageLoad(() {});
        load.navigate('https://www.ut.ac.kr/a');
        load.committed();
        async.elapse(PageLoad.settleAfterCommit);
        expect(load.busy, isFalse);
        async.elapse(PageLoad.slowAfter);
        expect(load.problem, isNull);
      });
    });

    test('앱이 불러온 주소가 연결 오류로 실패하면 안내, 다시 시도는 헤더까지 같게', () {
      fakeAsync((FakeAsync async) {
        int clears = 0;
        final PageLoad load = PageLoad(() {}, onClearHistory: () => clears++);
        const String url = 'https://mobile.ut.ac.kr/page/main';
        load.ownLoad(url, headers, clearHistory: true);
        load.mainFrameError(url, connectionError: true);
        // 오류 페이지의 시작·끝 알림은 성공으로 치지 않는다(방문 기록도 지우지 않음).
        load.pageStarted(url);
        load.pageFinished(url);
        expect(clears, 0);
        expect(load.problem, ConnectionProblem.failed);
        expect(load.busy, isFalse);
        load.markOffline();
        expect(load.problem, ConnectionProblem.offline);

        final RetryAction action = load.retry();
        expect(action, isA<RetryOwnLoad>());
        expect((action as RetryOwnLoad).url, url);
        expect(action.headers, headers);
        expect(load.problem, isNull);
        expect(load.busy, isTrue);

        // 다시 시도가 성공하면 그때 방문 기록을 지운다.
        load.pageStarted(url);
        load.pageFinished(url);
        expect(clears, greaterThan(0));
        expect(load.busy, isFalse);
        async.elapse(PageLoad.slowAfter);
        expect(load.problem, isNull);
      });
    });

    test('링크로 간 페이지가 실패하면 그 주소를 다시 부른다', () {
      fakeAsync((FakeAsync async) {
        final PageLoad load = PageLoad(() {});
        load.ownLoad('https://mobile.ut.ac.kr/', headers);
        load.pageStarted('https://mobile.ut.ac.kr/');
        load.pageFinished('https://mobile.ut.ac.kr/');
        load.navigate('https://www.ut.ac.kr/notice');
        load.mainFrameError(
          'https://www.ut.ac.kr/notice',
          connectionError: true,
        );
        final RetryAction action = load.retry();
        expect(action, isA<RetryUrl>());
        expect((action as RetryUrl).url, 'https://www.ut.ac.kr/notice');
      });
    });

    test('연결 오류가 아닌 실패(앱 링크 등)는 안내 없이 로딩 표시만 끈다', () {
      fakeAsync((FakeAsync async) {
        final PageLoad load = PageLoad(() {});
        load.navigate('intent://x');
        load.mainFrameError('intent://x', connectionError: false);
        expect(load.busy, isFalse);
        expect(load.problem, isNull);
        async.elapse(PageLoad.slowAfter);
        expect(load.problem, isNull);
      });
    });

    test('내려받기로 끝난 이동이나 진행률 100이면 로딩 표시를 끈다', () {
      fakeAsync((FakeAsync async) {
        final PageLoad load = PageLoad(() {});
        load.navigate('https://www.ut.ac.kr/cmm/fms/FileDown.do');
        load.settle(); // download
        expect(load.busy, isFalse);
        load.navigate('https://www.ut.ac.kr/x');
        load.progress(10);
        expect(load.busy, isTrue);
        load.progress(100);
        expect(load.busy, isFalse);
        async.elapse(PageLoad.slowAfter);
        expect(load.problem, isNull);
      });
    });

    test('네트워크가 없어 불러오지 않은 팝업은 다시 시도 때 불러온다', () {
      final PageLoad load = PageLoad(() {});
      load.offline('https://mobile.ut.ac.kr/popup', headers);
      expect(load.problem, ConnectionProblem.offline);
      expect(load.busy, isFalse);
      final RetryAction action = load.retry();
      expect(action, isA<RetryOwnLoad>());
    });
  });
}
