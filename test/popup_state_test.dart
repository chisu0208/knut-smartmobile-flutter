import 'package:flutter_test/flutter_test.dart';
import 'package:knut_smartmobile/src/popup_animation.dart';
import 'package:knut_smartmobile/src/popup_state.dart';

/// 팝업 보임 상태와 뒤로 키 주인(HANDOFF 5.7·5.12·5.13, PR #7 리뷰).
void main() {
  late PopupState popup;
  late bool webviewIsMain;
  Duration now = Duration.zero;

  setUp(() {
    webviewIsMain = false;
    now = Duration.zero;
    popup = PopupState(
      onAnimationStart: () {},
      webviewIsMain: () => webviewIsMain,
    );
  });

  /// 그려지는 프레임을 [time]만큼 흘린다(첫 프레임에서 애니메이션 시작 시각이 정해진다).
  void frames(Duration time) {
    popup.tick(now);
    const Duration step = Duration(milliseconds: 16);
    for (Duration t = Duration.zero; t < time; t += step) {
      now += step;
      popup.tick(now);
    }
  }

  /// 팝업 구성(webview/popup)과 A0 앞의 `webview` 값 저장을 흉내 낸다.
  void open(String align) {
    webviewIsMain = false;
    popup.beginOpen();
    popup.enter(align);
  }

  void close() {
    webviewIsMain = true; // A0는 webview="main"을 먼저 저장한다
    popup.close();
  }

  group('팝업을 닫으면 뒤로 키는 메인으로(✕·배경 탭·browser·뒤로 키·연결 안내 모두 A0)', () {
    for (final String align in <String>[
      'right',
      'bottom',
      'top',
      'left',
      'center',
      'full',
    ]) {
      test(align, () {
        open(align);
        frames(AnimTrack.duration * 2);
        expect(popup.shown, isTrue);
        expect(popup.mainOwner, isFalse); // 열려 있는 동안 뒤로 키는 팝업 쪽
        close();
        expect(popup.mainOwner, isTrue); // 닫자마자 첫 뒤로 키부터 메인이 받는다
        frames(AnimTrack.duration * 2);
        expect(popup.shown, isFalse);
        expect(popup.drawn, isFalse);
        expect(popup.animating, isFalse);
      });
    }
  });

  group('나오는 중(0.25초 안)에 닫아도 "열림"으로 남지 않는다', () {
    for (final String align in <String>['right', 'bottom', 'top', 'left']) {
      test(align, () {
        open(align);
        frames(AnimTrack.duration ~/ 2);
        expect(popup.shown, isFalse);
        close();
        expect(popup.mainOwner, isTrue);
        frames(AnimTrack.duration * 2);
        expect(popup.shown, isFalse);
        expect(popup.drawn, isFalse);
        expect(popup.body.attached, isFalse);
        expect(popup.bg.attached, isFalse);
      });
    }

    test('나오다 만 애니메이션이 다음 center 팝업을 닫지 않는다', () {
      // 예전에는 본체 애니메이션이 멈춘 채 남아 있다가, 다음 center 팝업이 배경을 보이면 다시
      // 흘러 끝 알림이 "닫힘"으로 처리해 새 팝업이 사라졌다.
      open('bottom');
      frames(AnimTrack.duration ~/ 2);
      close();
      open('center');
      frames(AnimTrack.duration * 2);
      expect(popup.shown, isTrue);
      expect(popup.drawn, isTrue);
      expect(popup.mainOwner, isFalse);
    });

    test('그려지기 전(첫 프레임 전)에 닫아도 같다', () {
      open('bottom');
      close();
      frames(AnimTrack.duration * 2);
      expect(popup.shown, isFalse);
      expect(popup.drawn, isFalse);
    });
  });

  test('left 팝업을 닫은 뒤 배경이 남지 않는다(fillAfter, HANDOFF 5.12)', () {
    open('left');
    frames(AnimTrack.duration * 2);
    expect(popup.bg.attached, isTrue); // 등장 애니메이션이 배경에 붙어 있다
    close();
    frames(AnimTrack.duration * 2);
    expect(popup.bg.attached, isFalse);
    expect(popup.drawn, isFalse);
  });

  test('left 다음 right 팝업을 닫아도 배경이 남지 않는다', () {
    open('left');
    frames(AnimTrack.duration * 2);
    open('right');
    frames(AnimTrack.duration * 2);
    close();
    frames(AnimTrack.duration * 2);
    expect(popup.drawn, isFalse);
  });

  test('메인 구성은 뒤로 키를 메인으로 하고 배경 애니메이션을 뗀다', () {
    open('left');
    frames(AnimTrack.duration * 2);
    close();
    popup.mainOwner = true; // _configureMain
    popup.cancelAnimation();
    expect(popup.bg.attached, isFalse);
  });
}
