import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:path_provider/path_provider.dart';

import 'legacy_json.dart';
import 'school_url.dart';

/// `i2.a.a(url, versionName, deviceToken)` — 본문 없는 POST(HANDOFF 5.3).
///
/// 200이면 본문, 아니면 오류 본문을 JSON으로 읽어 `urlConnResult`를 덧붙인 문자열을 돌려준다.
/// 어떤 실패든 null.
///
/// 원본은 연결 제한(3초)만 있고 응답은 끝없이 기다린다. 개선판은 [timeout]을 주면 연결부터
/// 응답을 다 읽을 때까지 그 시간 안에 끝나지 않을 때 null을 돌려준다(통합본 1-10).
///
/// 리디렉트는 학교 주소로 갈 때만 따라간다([nextRedirect]). Dart `HttpClient`에 맡기면 POST에
/// 303이 왔을 때 학교 밖 호스트로도 기기 토큰 헤더를 붙인 채 따라가고, 그 응답이 명령으로
/// 실행된다.
Future<String?> allyttePost(
  String url,
  String versionName,
  String deviceToken, {
  Duration? timeout,
}) async {
  final HttpClient client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 3);
  try {
    final Future<String> result = _post(client, url, versionName, deviceToken);
    return await (timeout == null ? result : result.timeout(timeout));
  } catch (_) {
    return null;
  } finally {
    client.close(force: true);
  }
}

/// 원본이 학교 서버에 보내는 공통 헤더(HANDOFF 5.3·5.10). 기기 토큰이 들어 있다.
Map<String, String> _allytteHeaders(String versionName, String deviceToken) =>
    <String, String>{
      'User-Agent': 'allytte $versionName',
      'allytte-device-token': deviceToken,
      'allytte-device-platform': 'android',
    };

/// 웹뷰 `loadUrl`에 붙이는 공통 헤더(원본 `B0`·`c1`, HANDOFF 5.10). 기기 토큰이 들어 있어서
/// 학교 주소([isSchoolUrl])에만 붙이고, 다른 주소는 빈 맵이다(페이지는 헤더 없이 열린다).
/// 원본은 명령이 준 주소라면 어디든 붙였다.
Map<String, String> commonHeaders(
  String url,
  String versionName,
  String deviceToken,
) => isSchoolUrl(url)
    ? _allytteHeaders(versionName, deviceToken)
    : const <String, String>{};

/// 명령이 준 주소로 보내는 결과 POST(원본 `O0`: `url`·QR·위치·NFC·비콘). 기기 토큰을 붙여
/// 보내고 응답을 명령으로 실행하므로, 학교 주소([isSchoolUrl])가 아니면 보내지 않고 null.
/// 원본은 명령이 준 주소라면 어디든 보냈다.
Future<String?> schoolPost(
  String url,
  String versionName,
  String deviceToken,
) async {
  if (!isSchoolUrl(url)) return null;
  return allyttePost(url, versionName, deviceToken);
}

/// 리디렉트를 따라가는 최대 횟수(Dart `HttpClient` 기본값).
const int _maxRedirects = 5;

Future<String> _post(
  HttpClient client,
  String url,
  String versionName,
  String deviceToken,
) async {
  String method = 'POST';
  Uri uri = Uri.parse(url);
  final Set<Uri> redirectedTo = <Uri>{};
  while (true) {
    final HttpClientRequest request = await client.openUrl(method, uri);
    request.followRedirects = false;
    _allytteHeaders(versionName, deviceToken).forEach(request.headers.set);
    if (method == 'POST') {
      // Android HttpURLConnection(OkHttp)이 POST에 붙이는 기본값.
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'application/x-www-form-urlencoded',
      );
      request.contentLength = 0;
    }
    final HttpClientResponse response = await request.close();
    // 리디렉트가 아니면 Location을 읽지 않는다(값이 둘이면 value()가 예외를 던진다).
    final Uri? next = response.isRedirect
        ? nextRedirect(
            method,
            uri,
            response.statusCode,
            response.headers.value(HttpHeaders.locationHeader),
          )
        : null;
    if (next == null) {
      final String text = await response.transform(utf8.decoder).join();
      // BufferedReader.readLine()으로 이어 붙이므로 줄바꿈 문자가 모두 빠진다.
      final String body = text.replaceAll('\r', '').replaceAll('\n', '');
      final JObj json = JObj.parse(body);
      json.map['urlConnResult'] = response.statusCode;
      return json.toString();
    }
    await response.drain<void>();
    // Dart처럼 5번을 넘거나, 앞서 넘겨 준 주소가 다시 오면 멈춘다. 다만 Dart는 `Location` 값을
    // 풀기 전 그대로 비교하고, 여기서는 푼 주소를 비교한다.
    if (redirectedTo.length == _maxRedirects || !redirectedTo.add(next)) {
      throw HttpException('redirect limit or loop', uri: next);
    }
    method = 'GET';
    uri = next;
  }
}

/// [method] 요청([from])의 응답이 리디렉트면 다음에 GET으로 부를 주소, 아니면 null.
///
/// 리디렉트로 보는 응답은 Dart `HttpClient`와 같다: POST는 303(GET으로 바꿔 따라감), GET은
/// 301·302·303·307·308. 다음 요청에도 기기 토큰이 붙으므로 아래 경우에는 [HttpException]을
/// 던진다(그러면 [allyttePost]는 null).
/// - `Location`이 없다.
/// - 넘겨 준 주소가 학교 주소([isSchoolUri])가 아니다.
/// - https에서 http로 내려간다. 토큰이 평문으로 가고 응답을 중간에서 바꿔 끼울 수 있다. 원본
///   (Android `HttpURLConnection`)은 http·https를 바꾸는 리디렉트를 아예 따라가지 않는다.
Uri? nextRedirect(String method, Uri from, int statusCode, String? location) {
  final bool redirect = method == 'POST'
      ? statusCode == HttpStatus.seeOther
      : const <int>{
          HttpStatus.movedPermanently,
          HttpStatus.found,
          HttpStatus.seeOther,
          HttpStatus.temporaryRedirect,
          HttpStatus.permanentRedirect,
        }.contains(statusCode);
  if (!redirect) return null;
  if (location == null) {
    throw HttpException('redirect without Location', uri: from);
  }
  final Uri target = from.resolve(location);
  if (!isSchoolUri(target)) {
    throw HttpException('redirect outside the school', uri: target);
  }
  if (from.scheme == 'https' && target.scheme != 'https') {
    throw HttpException('redirect from https to http', uri: target);
  }
  return target;
}

/// 메뉴 아이콘·헤더 배경을 내려받는 스레드(`d`/`e`)의 결과.
sealed class BitmapFetch {
  const BitmapFetch();

  /// 받은 그림. 받지 못했거나 그림이 아니면 null(개선판은 이때 그림 없이 둔다).
  ui.Image? get image => null;
}

/// 내려받아 이미지로 읽힘.
class BitmapLoaded extends BitmapFetch {
  const BitmapLoaded(this.bytes, this.image);
  final Uint8List bytes;
  @override
  final ui.Image image;
}

/// 내려받았지만 이미지가 아님(`decodeStream`이 null).
class BitmapUndecodable extends BitmapFetch {
  const BitmapUndecodable();
}

/// 연결·응답 오류. 원본은 이때 공용 비트맵 필드를 바꾸지 않는다.
class BitmapFailed extends BitmapFetch {
  const BitmapFailed();
}

/// 메뉴 아이콘·헤더 배경 하나를 받는 데 기다리는 시간.
const Duration bitmapTimeout = Duration(seconds: 10);

/// 그림 하나를 내려받아 읽는다.
///
/// 원본은 시간 제한 없이 기다렸고, 그동안 명령 처리기 줄 전체(뒤로 키·팝업 닫기 포함)가 멈췄다.
/// 개선판은 연결 3초, 다 받을 때까지 [timeout] 안에 끝나지 않으면 받지 못한 것으로 본다.
Future<BitmapFetch> fetchBitmap(
  String url, {
  Duration timeout = bitmapTimeout,
}) async {
  final HttpClient client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 3);
  try {
    return await _fetchBitmap(client, url).timeout(timeout);
  } catch (_) {
    return const BitmapFailed();
  } finally {
    client.close(force: true);
  }
}

Future<BitmapFetch> _fetchBitmap(HttpClient client, String url) async {
  final HttpClientRequest request = await client.getUrl(Uri.parse(url));
  final HttpClientResponse response = await request.close();
  if (response.statusCode >= 400) return const BitmapFailed();
  final BytesBuilder builder = BytesBuilder(copy: false);
  await for (final List<int> chunk in response) {
    builder.add(chunk);
  }
  final Uint8List bytes = builder.takeBytes();
  ui.Codec? codec;
  try {
    codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    return BitmapLoaded(bytes, frame.image);
  } catch (_) {
    return const BitmapUndecodable();
  } finally {
    codec?.dispose();
  }
}

/// 시작 이미지 내려받기(IntroActivity `c`, MainActivity `C`): `files/allytte/intro.png`에 저장.
///
/// 화면에는 쓰이지 않지만(HANDOFF 5.2) 원본처럼 내려받고, 끝난 뒤 다음 단계로 넘어간다.
Future<void> downloadSplash(String url) async {
  final HttpClient client = HttpClient();
  try {
    final Directory files = await getApplicationSupportDirectory();
    final Directory dir = Directory('${files.path}/allytte');
    if (!dir.existsSync()) dir.createSync();
    final HttpClientRequest request = await client.getUrl(Uri.parse(url));
    final HttpClientResponse response = await request.close();
    if (response.statusCode >= 400) return;
    // 원본은 Content-Length 크기의 버퍼를 만들어서, 길이를 모르면(-1) 여기서 실패한다.
    if (response.contentLength < 0) return;
    final IOSink sink = File('${dir.path}/intro.png').openWrite();
    await response.pipe(sink);
  } catch (_) {
    // 원본도 예외를 기록만 하고 넘어간다.
  } finally {
    client.close(force: true);
  }
}
