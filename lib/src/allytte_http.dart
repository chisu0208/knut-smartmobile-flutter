import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:path_provider/path_provider.dart';

import 'legacy_json.dart';

/// `i2.a.a(url, versionName, deviceToken)` — 본문 없는 POST(HANDOFF 5.3).
///
/// 200이면 본문, 아니면 오류 본문을 JSON으로 읽어 `urlConnResult`를 덧붙인 문자열을 돌려준다.
/// 어떤 실패든 null.
///
/// 원본은 연결 제한(3초)만 있고 응답은 끝없이 기다린다. 개선판은 [timeout]을 주면 연결부터
/// 응답을 다 읽을 때까지 그 시간 안에 끝나지 않을 때 null을 돌려준다(통합본 1-10).
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

Future<String> _post(
  HttpClient client,
  String url,
  String versionName,
  String deviceToken,
) async {
  final HttpClientRequest request = await client.postUrl(Uri.parse(url));
  request.headers
    ..set(HttpHeaders.userAgentHeader, 'allytte $versionName')
    ..set('allytte-device-token', deviceToken)
    ..set('allytte-device-platform', 'android')
    // Android HttpURLConnection(OkHttp)이 POST에 붙이는 기본값.
    ..set(HttpHeaders.contentTypeHeader, 'application/x-www-form-urlencoded');
  request.contentLength = 0;
  final HttpClientResponse response = await request.close();
  final String text = await response.transform(utf8.decoder).join();
  // BufferedReader.readLine()으로 이어 붙이므로 줄바꿈 문자가 모두 빠진다.
  final String body = text.replaceAll('\r', '').replaceAll('\n', '');
  final JObj json = JObj.parse(body);
  json.map['urlConnResult'] = response.statusCode;
  return json.toString();
}

/// 메뉴 아이콘·헤더 배경을 내려받는 스레드(`d`/`e`)의 결과.
sealed class BitmapFetch {
  const BitmapFetch();
}

/// 내려받아 이미지로 읽힘.
class BitmapLoaded extends BitmapFetch {
  const BitmapLoaded(this.bytes, this.image);
  final Uint8List bytes;
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

Future<BitmapFetch> fetchBitmap(String url) async {
  final HttpClient client = HttpClient();
  try {
    final HttpClientRequest request = await client.getUrl(Uri.parse(url));
    final HttpClientResponse response = await request.close();
    if (response.statusCode >= 400) return const BitmapFailed();
    final BytesBuilder builder = BytesBuilder(copy: false);
    await for (final List<int> chunk in response) {
      builder.add(chunk);
    }
    final Uint8List bytes = builder.takeBytes();
    try {
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      return BitmapLoaded(bytes, frame.image);
    } catch (_) {
      return const BitmapUndecodable();
    }
  } catch (_) {
    return const BitmapFailed();
  } finally {
    client.close(force: true);
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
