import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knut_smartmobile/src/tab_route.dart';

/// 출결·도서관 명령 가로채기(개선판 2차). 서버 응답의 정확한 모양은 클라우드에서 확인하지 못해,
/// 로컬 세션이 확인한 동작(전자출결 `browser`, 도서관 full 팝업)을 본뜬 가짜 명령 JSON으로 시험한다.
void main() {
  String commands(List<Map<String, Object?>> actions) =>
      jsonEncode(<String, Object?>{'action': actions});

  final String attendBrowser = commands(<Map<String, Object?>>[
    <String, Object?>{
      'command': 'browser',
      'config': <String, Object?>{
        'url': 'https://attend.ut.ac.kr/mobile/sso?token=abc',
      },
    },
  ]);
  final String libraryPopup = commands(<Map<String, Object?>>[
    <String, Object?>{
      'command': 'webview',
      'config': <String, Object?>{
        'show': 'popup',
        'align': 'full',
        'url': 'https://mchains.ut.ac.kr/index.ax',
        'header': <String, Object?>{'bgColor': 'null'},
      },
    },
  ]);
  final String loginAlert = commands(<Map<String, Object?>>[
    <String, Object?>{
      'command': 'alert',
      'config': <String, Object?>{'message': '로그인 후 이용해 주세요.'},
    },
  ]);

  group('tabRouteOf', () {
    test('전자출결 browser 명령 → 출결 탭, 서버가 준 주소 그대로', () {
      expect(
        tabRouteOf(attendBrowser),
        const TabRoute(
          WebTabKind.attend,
          'https://attend.ut.ac.kr/mobile/sso?token=abc',
        ),
      );
    });

    test('전자출결의 실제 주소(학교 SSO, RelayState가 출결) → 출결 탭, SSO 주소 그대로', () {
      const String sso =
          'https://sso.ut.ac.kr/svc/tk/AuthFederate.eps?id=abc&targetId=attend'
          '&t=TOKEN&RelayState=https://attend.ut.ac.kr/exsignon/sso/sso_index.jsp';
      final String json = commands(<Map<String, Object?>>[
        <String, Object?>{
          'command': 'browser',
          'config': <String, Object?>{'preCondition': null, 'url': sso},
        },
      ]);
      expect(tabRouteOf(json), const TabRoute(WebTabKind.attend, sso));
    });

    test('SSO 주소라도 RelayState가 탭 주소가 아니면 null', () {
      expect(
        tabForUrl(
          'https://sso.ut.ac.kr/svc/tk/AuthFederate.eps?targetId=portal'
          '&RelayState=https://portal.ut.ac.kr/',
        ),
        isNull,
      );
      expect(tabForUrl('https://sso.ut.ac.kr/svc/tk/AuthFederate.eps'), isNull);
      expect(
        tabForUrl('https://sso.ut.ac.kr/a?RelayState=https://sso.ut.ac.kr/b'),
        isNull,
      );
    });

    test('도서관 full 팝업 → 도서관 탭', () {
      expect(
        tabRouteOf(libraryPopup),
        const TabRoute(WebTabKind.library, 'https://mchains.ut.ac.kr/index.ax'),
      );
    });

    test('Android JSONObject 직렬화(\\/)도 읽는다', () {
      expect(
        tabRouteOf(
          r'{"action":[{"command":"browser","config":{"url":"https:\/\/attend.ut.ac.kr\/m"}}]}',
        ),
        const TabRoute(WebTabKind.attend, 'https://attend.ut.ac.kr/m'),
      );
    });

    test('팝업 닫기와 함께 온 주소 명령도 가로챈다', () {
      final String json = commands(<Map<String, Object?>>[
        <String, Object?>{
          'command': 'function',
          'config': <String, Object?>{'function': 'close'},
        },
        <String, Object?>{
          'command': 'browser',
          'config': <String, Object?>{'url': 'https://attend.ut.ac.kr/'},
        },
      ]);
      expect(tabRouteOf(json)?.tab, WebTabKind.attend);
    });

    test('다른 주소·다른 명령·모양이 다르면 null(홈에서 원래대로)', () {
      // 포탈은 지금처럼 외부 브라우저
      expect(
        tabRouteOf(
          commands(<Map<String, Object?>>[
            <String, Object?>{
              'command': 'browser',
              'config': <String, Object?>{'url': 'https://portal.ut.ac.kr/'},
            },
          ]),
        ),
        isNull,
      );
      expect(tabRouteOf(loginAlert), isNull);
      // 같은 호스트라도 메인 구성·페이지 바꾸기는 탭 주소가 아니다
      expect(
        tabRouteOf(
          commands(<Map<String, Object?>>[
            <String, Object?>{
              'command': 'webview',
              'config': <String, Object?>{
                'show': 'change',
                'url': 'https://attend.ut.ac.kr/',
              },
            },
          ]),
        ),
        isNull,
      );
      // 주소 명령 + 다른 명령(알림)
      expect(
        tabRouteOf(
          commands(<Map<String, Object?>>[
            <String, Object?>{
              'command': 'browser',
              'config': <String, Object?>{'url': 'https://attend.ut.ac.kr/'},
            },
            <String, Object?>{
              'command': 'alert',
              'config': <String, Object?>{'message': '안내'},
            },
          ]),
        ),
        isNull,
      );
      expect(tabRouteOf('not json'), isNull);
      expect(tabRouteOf('{"command":"browser"}'), isNull);
      expect(tabRouteOf(null), isNull);
      expect(tabForUrl('intent://attend.ut.ac.kr#Intent;end'), isNull);
      expect(tabForUrl('https://attend.ut.ac.kr.evil.example/'), isNull);
    });
  });

  test('로그인 버튼 찾기: 로그아웃 버튼은 고르지 않는다', () {
    expect(
      isLoginButton(
        '{"icon":"https://mobile.ut.ac.kr/img/ico_login.png","action":[]}',
      ),
      isTrue,
    );
    expect(
      isLoginButton(
        '{"action":[{"command":"webview","config":{"header":{"menu":{"center":[{"name":"로그인"}]}}}}]}',
      ),
      isTrue,
    );
    expect(
      isLoginButton(
        '{"icon":"https://mobile.ut.ac.kr/img/ico_login.png","action":[{"command":"function","config":{"url":"/logout"}}]}',
      ),
      isFalse,
    );
    expect(
      isLoginButton('{"icon":"https://mobile.ut.ac.kr/img/ico_home.png"}'),
      isFalse,
    );
  });

  group('ServiceRequests: 시작 표시 → 응답 → 끝 표시', () {
    String begin(int id) => '{"knutTabRequest":"begin","id":$id}';
    String end(int id, {bool called = true}) =>
        '{"knutTabRequest":"end","id":$id,"called":$called}';

    test('주소 명령이 오면 가로채고(처리기에 넣지 않음) 탭 주소로 끝난다', () async {
      final ServiceRequests requests = ServiceRequests();
      final ({int id, Future<ServiceResult> result}) r = requests.start();
      expect(requests.handle(begin(r.id)), isTrue);
      expect(requests.handle(attendBrowser), isTrue);
      expect(requests.handle(end(r.id)), isTrue);
      final ServiceResult result = await r.result;
      expect((result as ServiceRouted).route.tab, WebTabKind.attend);
    });

    test('로그인 필요 알림은 가로채지 않고(홈에서 처리) 로그인 필요로 끝난다', () async {
      final ServiceRequests requests = ServiceRequests();
      final ({int id, Future<ServiceResult> result}) r = requests.start();
      requests.handle(begin(r.id));
      expect(requests.handle(loginAlert), isFalse);
      requests.handle(end(r.id));
      expect(await r.result, isA<ServiceNotRouted>());
    });

    test('응답이 없으면: 부르지 못함(메인 페이지가 아님)과 답 없음', () async {
      final ServiceRequests requests = ServiceRequests();
      final ({int id, Future<ServiceResult> result}) r = requests.start();
      requests.handle(begin(r.id));
      requests.handle(end(r.id, called: false));
      expect(((await r.result) as ServiceNoResponse).called, isFalse);

      final ({int id, Future<ServiceResult> result}) r2 = requests.start();
      requests.handle(begin(r2.id));
      requests.handle(end(r2.id));
      expect(((await r2.result) as ServiceNoResponse).called, isTrue);
    });

    test('요청 밖의 명령은 건드리지 않는다(홈 타일은 처리기에서 탭으로)', () {
      final ServiceRequests requests = ServiceRequests();
      expect(requests.handle(attendBrowser), isFalse);
      expect(requests.handle(loginAlert), isFalse);
      final ({int id, Future<ServiceResult> result}) r = requests.start();
      requests.handle(begin(r.id));
      requests.handle(end(r.id));
      expect(requests.handle(libraryPopup), isFalse);
    });

    test('끝 표시가 오지 않으면 15초 뒤 답 없음', () {
      fakeAsync((FakeAsync async) {
        final ServiceRequests requests = ServiceRequests();
        ServiceResult? result;
        requests.start().result.then((ServiceResult r) => result = r);
        async.elapse(const Duration(seconds: 14));
        expect(result, isNull);
        async.elapse(const Duration(seconds: 2));
        expect(result, isA<ServiceNoResponse>());
      });
    });

    test('스크립트는 표시 사이에서 callService("SERVICE", id)를 부른다', () {
      final String script = ServiceRequests.script(7, '9');
      final int begin = script.indexOf('"begin","id":7');
      final int call = script.indexOf(
        'AllytteCommand.callService("SERVICE", "9")',
      );
      final int end = script.indexOf('"end","id":7');
      expect(begin, greaterThan(0));
      expect(call, greaterThan(begin));
      expect(end, greaterThan(call));
    });
  });
}
