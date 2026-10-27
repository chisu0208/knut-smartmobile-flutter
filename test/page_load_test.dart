import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knut_smartmobile/src/page_load.dart';

/// PR #6 리뷰에서 나온 웹뷰 규칙: 첨부 내려받기 창 닫기, 방문 기록 지우기 시점.
void main() {
  const Map<String, String> headers = <String, String>{
    'allytte-device-platform': 'android',
  };

  group('내려받기만 한 창 닫기(첨부파일)', () {
    const String download =
        'https://www.ut.ac.kr/cmm/fms/FileDown.do;jsessionid=X?atchFileId=1';

    test('공지 첨부: 자식 창이 내려받기 주소를 바로 열면(그린 페이지 없음) 닫는다', () {
      final PageLoad load = PageLoad(() {});
      // 내려받기는 페이지가 아니라서 시작·기록 알림 없이 바로 download가 온다.
      load.navigate(download);
      load.settle(); // download
      expect(load.hasPage, isFalse);
      expect(closeWindowAfterDownload('child', load), isTrue);
      expect(closeWindowAfterDownload('grandchild', load), isTrue);
    });

    test('about:blank만 있는 창도 그린 페이지가 없는 것으로 본다', () {
      final PageLoad load = PageLoad(() {});
      load.pageStarted('about:blank');
      load.committed('about:blank');
      load.visible('about:blank');
      load.pageFinished('about:blank');
      expect(closeWindowAfterDownload('child', load), isTrue);
    });

    test('페이지를 보여 준 창은 그 안에서 내려받아도 닫지 않는다', () {
      final PageLoad load = PageLoad(() {});
      load.pageStarted('https://www.ut.ac.kr/viewer.do');
      load.pageFinished('https://www.ut.ac.kr/viewer.do');
      load.navigate(download, byUser: true);
      load.settle(); // download
      expect(load.hasPage, isTrue);
      expect(closeWindowAfterDownload('child', load), isFalse);
    });

    test('첫 화면(visible)이나 기록(committed) 알림만 와도 페이지가 있는 것으로 본다', () {
      final PageLoad visible = PageLoad(() {})
        ..visible('https://www.ut.ac.kr/a');
      final PageLoad committed = PageLoad(() {})
        ..committed('https://www.ut.ac.kr/a');
      expect(closeWindowAfterDownload('child', visible), isFalse);
      expect(closeWindowAfterDownload('child', committed), isFalse);
    });

    test('팝업·메인 웹뷰는 닫지 않는다', () {
      final PageLoad load = PageLoad(() {});
      expect(closeWindowAfterDownload('popup', load), isFalse);
      expect(closeWindowAfterDownload('main', load), isFalse);
    });
  });

  group('방문 기록 지우기(webview/main 명령)', () {
    const String main = 'https://mobile.ut.ac.kr/page/main';
    late int clears;
    late PageLoad load;

    setUp(() {
      clears = 0;
      load = PageLoad(() {}, onClearHistory: () => clears++);
    });

    test('앱이 불러온 페이지가 시작될 때와 끝날 때 지운다. 그 뒤 링크로 간 페이지에서는 지우지 않는다', () {
      load.ownLoad(main, headers, clearHistory: true);
      load.pageStarted(main);
      expect(clears, 1);
      load.pageFinished(main);
      expect(clears, 2);
      load.navigate('https://mobile.ut.ac.kr/page/sub', byUser: true);
      load.pageStarted('https://mobile.ut.ac.kr/page/sub');
      load.pageFinished('https://mobile.ut.ac.kr/page/sub');
      expect(clears, 2);
    });

    test('다 뜨기 전에 링크를 누르면: 시작될 때 이미 지웠고, 링크 페이지에서는 지우지 않는다', () {
      // 원본 404 문제(권한 안내 페이지가 기록에 남음)가 이 경우에도 생기지 않는다.
      load.ownLoad(main, headers, clearHistory: true);
      load.pageStarted(main);
      expect(clears, 1);
      const String link = 'https://mobile.ut.ac.kr/page/sub';
      load.navigate(link, byUser: true);
      load.pageStarted(link);
      load.pageFinished(link);
      expect(clears, 1);
    });

    test('지우라고 하지 않은 불러오기(팝업, webview/change)는 지우지 않는다', () {
      load.ownLoad(main, headers);
      load.pageStarted(main);
      load.pageFinished(main);
      expect(clears, 0);
    });

    test('서버 리디렉션·스크립트 이동은 같은 불러오기로 보고, 넘어간 페이지에서도 지운다', () {
      load.ownLoad('https://mobile.ut.ac.kr/', headers, clearHistory: true);
      load.navigate(main); // 서버 리디렉션(byUser 아님)
      load.pageStarted(main);
      load.pageFinished(main);
      expect(clears, 2);

      // 시작된 페이지의 스크립트가 끝나기 전에 다른 페이지로 넘긴 경우
      clears = 0;
      const String next = 'https://mobile.ut.ac.kr/page/next';
      load.ownLoad(main, headers, clearHistory: true);
      load.pageStarted(main);
      load.navigate(next);
      load.pageStarted(next);
      load.pageFinished(next);
      expect(clears, 3);
    });

    test('시작되기 전에 사용자가 링크를 누르면 버린다. 다시 시도는 그 링크 주소', () {
      fakeAsync((FakeAsync async) {
        load.ownLoad(main, headers, clearHistory: true);
        const String link = 'https://www.ut.ac.kr/notice';
        load.navigate(link, byUser: true);
        load.mainFrameError(link, connectionError: true);
        final RetryAction action = load.retry();
        expect(action, isA<RetryUrl>());
        expect((action as RetryUrl).url, link);
        load.pageStarted(link);
        load.pageFinished(link);
        expect(clears, 0);
      });
    });

    test('실패한 뒤 뒤로 키로 이전 페이지로 가면 버린다', () {
      load.ownLoad(main, headers, clearHistory: true);
      load.mainFrameError(main, connectionError: true);
      load.goBack();
      const String previous = 'https://mobile.ut.ac.kr/page/authority#1';
      load.pageStarted(previous);
      load.pageFinished(previous);
      expect(clears, 0);
      expect(load.problem, isNull);
    });

    test('끝나기 전에 앱이 다른 주소를 불러오면 그 불러오기의 설정을 따른다', () {
      load.ownLoad(main, headers, clearHistory: true);
      const String other = 'https://mobile.ut.ac.kr/page/other';
      load.ownLoad(other, headers);
      load.pageStarted(other);
      load.pageFinished(other);
      expect(clears, 0);

      load.ownLoad(other, headers);
      load.ownLoad(main, headers, clearHistory: true);
      load.pageStarted(main);
      load.pageFinished(main);
      expect(clears, 2);
    });

    test('네트워크가 없어 불러오지 않은 팝업을 다시 시도해도 지우지 않는다', () {
      load.offline('https://mobile.ut.ac.kr/popup', headers);
      expect(load.retry(), isA<RetryOwnLoad>());
      load.pageStarted('https://mobile.ut.ac.kr/popup');
      load.pageFinished('https://mobile.ut.ac.kr/popup');
      expect(clears, 0);
    });
  });
}
