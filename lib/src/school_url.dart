/// 기기 토큰(`allytte-device-token`)을 보내도 되는 학교 주소인지: http·https이고 호스트가
/// `ut.ac.kr`이나 그 하위 주소.
///
/// 원본은 명령이 준 주소라면 학교 밖이라도 웹뷰 공통 헤더와 POST로 토큰을 보냈고, POST 응답은
/// 명령으로 실행했다. 개선판은 이 주소에만 보낸다. 규칙은 웹 페이지 통로를 여는
/// `WebViewBridge.kt` `isSchoolPage`와 같다(IDF가 `http://idf.ut.ac.kr`이라 http도 받는다).
///
/// 다만 `isSchoolPage`는 웹뷰가 정리한 페이지 주소를 보고, 이 함수는 명령에 든 문자열을 그대로
/// 본다. 웹뷰(Chromium)는 탭·줄바꿈을 지우고 전각 문자를 바꾸는 등 Dart `Uri`와 다르게 읽는 곳이
/// 있어서, 그런 글자가 낀 주소는 학교 주소로 보지 않는다. 사용자 정보(`@` 앞)가 있거나 호스트에
/// 영문 소문자·숫자·`.`·`-` 밖의 글자(Dart가 `%XX`로 남긴 글자나 `_`·`!` 같은 기호)가 있으면
/// false다. 학교 주소에는 둘 다 없다.
bool isSchoolUrl(String url) {
  final Uri? uri = Uri.tryParse(url);
  return uri != null && isSchoolUri(uri);
}

/// 이미 읽은 [Uri]로 보는 [isSchoolUrl]. 리디렉트처럼 그 [Uri]로 바로 연결할 때 쓴다.
bool isSchoolUri(Uri uri) {
  if (uri.scheme != 'http' && uri.scheme != 'https') return false;
  final String host = uri.host;
  if (uri.userInfo.isNotEmpty || !_plainHost.hasMatch(host)) return false;
  return host == 'ut.ac.kr' || host.endsWith('.ut.ac.kr');
}

/// 손댈 것 없는 호스트. Dart `Uri`는 호스트를 소문자로 바꾸고, 탭·전각 문자 같은 글자는 `%XX`로
/// 남기며 `_`·`!` 같은 기호는 그대로 둔다.
final RegExp _plainHost = RegExp(r'^[a-z0-9.-]+$');
