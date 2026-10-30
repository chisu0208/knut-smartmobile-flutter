import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:knut_smartmobile/src/allytte_http.dart';
import 'package:knut_smartmobile/src/intro_screen.dart';
import 'package:knut_smartmobile/src/school_url.dart';

/// 모든 요청을 로컬 서버([port])에 프록시로 보내는 실제 HttpClient. 로컬 서버가 주소 전체를
/// 받으므로 학교 주소(http)로 가는 요청과 리디렉트를 흉내 낼 수 있다.
class _ViaLocalProxy extends HttpOverrides {
  _ViaLocalProxy(this.port);
  final int port;

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      super.createHttpClient(context)
        ..findProxy = (Uri uri) => 'PROXY 127.0.0.1:$port';
}

/// 기기 토큰을 보내는 주소 제한. 웹뷰가 학교 밖 호스트로 여는 주소는 모두 false여야 한다.
/// 웹뷰 쪽 해석은 에뮬레이터 WebView 155의 `new URL()`로 확인했다.
void main() {
  group('학교 주소에는 보낸다', () {
    for (final String url in <String>[
      'https://mobile.ut.ac.kr/service/mobile/page/main',
      'https://mobile.ut.ac.kr//service/api/device/nfc?value=1',
      'http://idf.ut.ac.kr/',
      'https://ut.ac.kr',
      'HTTPS://MOBILE.UT.AC.KR/x',
      'https://mobile.ut.ac.kr:8443/x',
    ]) {
      test(url, () => expect(isSchoolUrl(url), isTrue));
    }
  });

  group('학교 밖 주소에는 보내지 않는다', () {
    for (final (String why, String url) in <(String, String)>[
      ('학교 도메인으로 시작하는 다른 도메인', 'https://ut.ac.kr.evil.com/'),
      ('점 없이 이어 붙인 도메인', 'https://evilut.ac.kr/'),
      ('학교 주소가 쿼리에만 있음', 'https://evil.com/?a=.ut.ac.kr'),
      ('학교 주소가 # 뒤에만 있음', 'https://evil.com#.ut.ac.kr'),
      ('학교 주소가 사용자 정보에만 있음', 'https://mobile.ut.ac.kr@evil.com/'),
      // Dart Uri도 웹뷰처럼 \를 /로 읽어 호스트를 evil.com으로 본다.
      (r'\ 뒤의 학교 주소', r'https://evil.com\@mobile.ut.ac.kr/'),
      ('http·https가 아님', 'ftp://mobile.ut.ac.kr/'),
      ('javascript 주소', 'javascript:alert(1)//.ut.ac.kr'),
      ('// 없는 https', 'https:evil.com'),
      ('빈 문자열', ''),
      ('주소가 아님', 'not a url'),
    ]) {
      test(why, () => expect(isSchoolUrl(url), isFalse));
    }
  });

  group('웹뷰가 Dart와 다르게 읽을 수 있는 주소는 보내지 않는다', () {
    for (final (String why, String url) in <(String, String)>[
      ('호스트 속 탭', 'https://evil.com\t.ut.ac.kr/'),
      ('호스트 속 줄바꿈', 'https://mobile.ut.ac.kr\n.evil.com/'),
      ('호스트 속 전각 마침표', 'https://evil.com。ut.ac.kr/'),
      ('호스트 속 전각 문자', 'https://ｍobile.ut.ac.kr/'),
      ('호스트 속 %5C', 'https://evil.com%5C.ut.ac.kr/'),
      ('사용자 정보 속 탭', 'https://evil.com\t@mobile.ut.ac.kr/'),
      // 웹뷰도 mobile.ut.ac.kr을 열지만 학교 주소에는 사용자 정보가 없다.
      ('사용자 정보가 있음', 'https://evil.com@mobile.ut.ac.kr/'),
    ]) {
      test(why, () => expect(isSchoolUrl(url), isFalse));
    }
  });

  group('POST 리디렉트는 학교 주소로만 따라간다', () {
    final Uri from = Uri.parse('https://mobile.ut.ac.kr/service/api/x');
    final Matcher refused = throwsA(isA<HttpException>());

    test('POST의 303은 학교 주소일 때만 다음 주소를 준다', () {
      expect(
        nextRedirect('POST', from, 303, 'https://idf.ut.ac.kr/next'),
        Uri.parse('https://idf.ut.ac.kr/next'),
      );
      expect(
        nextRedirect('POST', from, 303, '/next?x=1'),
        Uri.parse('https://mobile.ut.ac.kr/next?x=1'),
      );
      expect(
        () => nextRedirect('POST', from, 303, 'https://evil.com/'),
        refused,
      );
      expect(() => nextRedirect('POST', from, 303, '//evil.com/x'), refused);
      expect(
        () => nextRedirect('POST', from, 303, r'https://evil.com\@ut.ac.kr/'),
        refused,
      );
      expect(() => nextRedirect('POST', from, 303, null), refused);
    });

    test('https에서 http로 내려가는 리디렉트는 학교 주소라도 따라가지 않는다', () {
      expect(
        () => nextRedirect('POST', from, 303, 'http://idf.ut.ac.kr/next'),
        refused,
      );
      expect(() => nextRedirect('GET', from, 302, 'http://ut.ac.kr/'), refused);
      // http에서 https로 올라가는 것은 따라간다.
      expect(
        nextRedirect(
          'POST',
          Uri.parse('http://idf.ut.ac.kr/x'),
          303,
          'https://idf.ut.ac.kr/y',
        ),
        Uri.parse('https://idf.ut.ac.kr/y'),
      );
    });

    test('POST의 다른 응답은 Dart처럼 리디렉트로 보지 않는다', () {
      for (final int code in <int>[200, 301, 302, 307, 308, 404, 500]) {
        expect(
          nextRedirect('POST', from, code, 'https://evil.com/'),
          isNull,
          reason: '$code',
        );
      }
    });

    test('303 뒤의 GET은 301·302·303·307·308을 학교 주소로만 따라간다', () {
      for (final int code in <int>[301, 302, 303, 307, 308]) {
        expect(
          nextRedirect('GET', from, code, '/b'),
          Uri.parse('https://mobile.ut.ac.kr/b'),
          reason: '$code',
        );
        expect(
          () => nextRedirect('GET', from, code, 'https://evil.com/'),
          refused,
        );
      }
      expect(nextRedirect('GET', from, 200, null), isNull);
    });
  });

  group('POST 리디렉트(로컬 서버)', () {
    /// POST에는 [postTo]로 303을 주고, GET에는 [getTo]가 몇 번째 GET인지를 받아 준 주소로 302,
    /// 없으면(null) 빈 명령 목록을 주는 서버. 받은 요청을 `방식 주소 토큰`으로 적는다.
    Future<(HttpServer, List<String>)> serve(
      String postTo, {
      String? Function(int gets)? getTo,
    }) async {
      final HttpServer server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      addTearDown(() => server.close(force: true));
      final List<String> seen = <String>[];
      int gets = 0;
      server.listen((HttpRequest request) async {
        seen.add(
          '${request.method} ${request.uri} '
          '${request.headers.value('allytte-device-token')}',
        );
        final String? location = request.method == 'POST'
            ? postTo
            : getTo?.call(++gets);
        if (location != null) {
          request.response
            ..statusCode = request.method == 'POST'
                ? HttpStatus.seeOther
                : HttpStatus.found
            ..headers.set(HttpHeaders.locationHeader, location);
        } else {
          request.response.write('{"action":[]}');
        }
        await request.response.close();
      });
      return (server, seen);
    }

    Future<String?> post(HttpServer server) =>
        HttpOverrides.runWithHttpOverrides(
          () => allyttePost(
            'http://mobile.ut.ac.kr/service/api/x',
            '1.1.3',
            'TOKEN',
          ),
          _ViaLocalProxy(server.port),
        );

    const String posted = 'POST http://mobile.ut.ac.kr/service/api/x TOKEN';

    // 토큰이 어디로 갔는지가 핵심이라 받은 요청을 결과보다 먼저 본다.
    test('학교 주소로 넘기면 토큰을 붙인 GET으로 따라가 그 응답을 돌려준다', () async {
      final (HttpServer server, List<String> seen) = await serve(
        'http://idf.ut.ac.kr/next',
      );
      final String? result = await post(server);
      expect(seen, <String>[posted, 'GET http://idf.ut.ac.kr/next TOKEN']);
      expect(result, '{"action":[],"urlConnResult":200}');
    });

    test('학교 밖으로 넘기면 요청하지 않고 null', () async {
      final (HttpServer server, List<String> seen) = await serve(
        'http://evil.example/collect',
      );
      final String? result = await post(server);
      expect(seen, <String>[posted]);
      expect(result, isNull);
    });

    test('303 뒤의 GET이 다시 학교 밖으로 넘겨도 따라가지 않고 null', () async {
      final (HttpServer server, List<String> seen) = await serve(
        'http://idf.ut.ac.kr/next',
        getTo: (_) => 'http://evil.example/collect',
      );
      final String? result = await post(server);
      expect(seen, <String>[posted, 'GET http://idf.ut.ac.kr/next TOKEN']);
      expect(result, isNull);
    });

    test('리디렉트는 5번까지만 따라가고 넘으면 null', () async {
      final (HttpServer server, List<String> seen) = await serve(
        'http://idf.ut.ac.kr/0',
        getTo: (int gets) => 'http://idf.ut.ac.kr/$gets',
      );
      final String? result = await post(server);
      expect(seen, hasLength(6)); // POST 1번, GET 5번
      expect(result, isNull);
    });

    test('앞서 넘겨 준 주소가 다시 오면 Dart처럼 바로 멈춘다', () async {
      final (HttpServer server, List<String> seen) = await serve(
        'http://idf.ut.ac.kr/next',
        getTo: (_) => 'http://idf.ut.ac.kr/next',
      );
      final String? result = await post(server);
      expect(seen, <String>[posted, 'GET http://idf.ut.ac.kr/next TOKEN']);
      expect(result, isNull);
    });

    test('리디렉트가 아닌 응답은 Location 값이 둘이어도 따라가지 않고 본문을 돌려준다', () async {
      final HttpServer server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      addTearDown(() => server.close(force: true));
      final List<String> seen = <String>[];
      server.listen((HttpRequest request) async {
        seen.add(
          '${request.method} ${request.uri} '
          '${request.headers.value('allytte-device-token')}',
        );
        // 한 줄로 합쳐 보내면 받는 쪽에서도 값이 하나라서 두 줄로 나눠 보낸다.
        request.response.headers
          ..noFolding(HttpHeaders.locationHeader)
          ..add(HttpHeaders.locationHeader, 'http://idf.ut.ac.kr/a')
          ..add(HttpHeaders.locationHeader, 'http://idf.ut.ac.kr/b');
        request.response.write('{"action":[]}');
        await request.response.close();
      });
      final String? result = await post(server);
      expect(seen, <String>[posted]);
      expect(result, '{"action":[],"urlConnResult":200}');
    });
  });

  group('명령이 준 주소와 기기 등록 주소', () {
    test('공통 헤더는 학교 주소에만 붙는다', () {
      expect(
        commonHeaders('https://mobile.ut.ac.kr/x', '1.1.3', 'TOKEN'),
        <String, String>{
          'User-Agent': 'allytte 1.1.3',
          'allytte-device-token': 'TOKEN',
          'allytte-device-platform': 'android',
        },
      );
      expect(commonHeaders('https://evil.com/', '1.1.3', 'TOKEN'), isEmpty);
    });

    test('결과 POST는 학교 주소가 아니면 요청하지 않고 null', () async {
      final HttpServer server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      addTearDown(() => server.close(force: true));
      final List<String> seen = <String>[];
      server.listen((HttpRequest request) async {
        seen.add('${request.method} ${request.uri}');
        request.response.write('{"action":[]}');
        await request.response.close();
      });
      Future<String?> post(String url) => HttpOverrides.runWithHttpOverrides(
        () => schoolPost(url, '1.1.3', 'TOKEN'),
        _ViaLocalProxy(server.port),
      );

      expect(await post('http://evil.example/x'), isNull);
      expect(seen, isEmpty);
      expect(
        await post('http://mobile.ut.ac.kr/x'),
        '{"action":[],"urlConnResult":200}',
      );
      expect(seen, <String>['POST http://mobile.ut.ac.kr/x']);
    });

    test('기기 등록의 push_url도 Dart로 다시 보고, 학교 주소가 아니면 기본 주소', () {
      const String fallback =
          'https://mobile.ut.ac.kr//service/api/device/save?q';
      expect(IntroScreen.registerUrl(null, '?q'), fallback);
      expect(
        IntroScreen.registerUrl('https://mobile.ut.ac.kr/push', '?q'),
        'https://mobile.ut.ac.kr/push',
      );
      // Android Uri가 \를 다르게 읽어 통과시켜도, 연결하는 Dart는 evil.com으로 읽는다.
      expect(
        IntroScreen.registerUrl(r'https://evil.com\@mobile.ut.ac.kr/', '?q'),
        fallback,
      );
    });
  });
}
