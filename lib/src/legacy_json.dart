import 'dart:convert';

/// Android `org.json` 동작을 흉내 낸 얇은 래퍼.
///
/// 원본은 `getString`/`getJSONObject` 같은 메서드가 값이 없거나 형이 다르면
/// 예외를 던지고, 그 예외로 이후 처리가 통째로 중단된다(HANDOFF 5.5).
/// 같은 지점에서 같은 이유로 멈추도록 같은 규칙을 따른다.
class JsonFormatError implements Exception {
  JsonFormatError(this.message);
  final String message;
  @override
  String toString() => 'JsonFormatError: $message';
}

class JObj {
  JObj(this.map);

  /// `new JSONObject(String)`.
  factory JObj.parse(String source) {
    final Object? value = jsonDecode(source);
    if (value is Map<String, dynamic>) return JObj(value);
    throw JsonFormatError('not a JSONObject');
  }

  final Map<String, dynamic> map;

  Object get(String name) {
    if (!map.containsKey(name)) throw JsonFormatError('No value for $name');
    return map[name] ?? jsonNull;
  }

  /// 키가 없거나 JSON null이면 true.
  bool isNull(String name) => !map.containsKey(name) || map[name] == null;

  String getString(String name) => _coerceString(get(name));

  bool getBoolean(String name) {
    final Object value = get(name);
    if (value is bool) return value;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
    }
    throw JsonFormatError('$name is not a boolean');
  }

  JObj getJSONObject(String name) {
    final Object value = get(name);
    if (value is Map<String, dynamic>) return JObj(value);
    throw JsonFormatError('$name is not a JSONObject');
  }

  JArr getJSONArray(String name) {
    final Object value = get(name);
    if (value is List<dynamic>) return JArr(value);
    throw JsonFormatError('$name is not a JSONArray');
  }

  /// 개선판 도우미(org.json에는 없음): 값이 객체 하나면 그 객체, 배열이면 그 안의 객체들.
  /// 그 밖의 형이면 [getJSONObject]처럼 예외.
  List<JObj> getJSONObjects(String name) {
    if (get(name) is List<dynamic>) {
      final JArr array = getJSONArray(name);
      return <JObj>[
        for (int i = 0; i < array.length; i++) array.getJSONObject(i),
      ];
    }
    return <JObj>[getJSONObject(name)];
  }

  /// Android `JSONObject.toString()`과 같은 모양으로 직렬화한다.
  @override
  String toString() => androidJsonEncode(map);
}

class JArr {
  JArr(this.list);
  final List<dynamic> list;

  int get length => list.length;

  Object _get(int index) {
    if (index < 0 || index >= list.length) {
      throw JsonFormatError('Index $index out of range');
    }
    return list[index] ?? jsonNull;
  }

  String getString(int index) => _coerceString(_get(index));

  JObj getJSONObject(int index) {
    final Object value = _get(index);
    if (value is Map<String, dynamic>) return JObj(value);
    throw JsonFormatError('Value at $index is not a JSONObject');
  }
}

/// `JSONObject.NULL` 자리표시.
const Object jsonNull = _JsonNull();

class _JsonNull {
  const _JsonNull();
  @override
  String toString() => 'null';
}

String _coerceString(Object value) {
  if (value is String) return value;
  // getString은 String.valueOf(Number)라서 1.0은 "1.0"으로 남는다.
  if (value is int) return value.toString();
  if (value is double) return javaDoubleToString(value);
  if (value is Map || value is List) return androidJsonEncode(value);
  return value.toString();
}

/// Android `JSONStringer`와 같은 규칙: `/`도 `\/`로 바꾸고, 정수로 떨어지는 실수는
/// 소수점 없이 쓴다.
String androidJsonEncode(Object? value) {
  final StringBuffer out = StringBuffer();
  _write(out, value);
  return out.toString();
}

void _write(StringBuffer out, Object? value) {
  if (value == null || value == jsonNull) {
    out.write('null');
  } else if (value is String) {
    _writeString(out, value);
  } else if (value is bool) {
    out.write(value ? 'true' : 'false');
  } else if (value is num) {
    out.write(_numberToString(value));
  } else if (value is Map) {
    out.write('{');
    bool first = true;
    value.forEach((Object? key, Object? v) {
      if (!first) out.write(',');
      first = false;
      _writeString(out, key.toString());
      out.write(':');
      _write(out, v);
    });
    out.write('}');
  } else if (value is List) {
    out.write('[');
    for (int i = 0; i < value.length; i++) {
      if (i > 0) out.write(',');
      _write(out, value[i]);
    }
    out.write(']');
  } else {
    _writeString(out, value.toString());
  }
}

void _writeString(StringBuffer out, String value) {
  out.write('"');
  for (final int c in value.codeUnits) {
    switch (c) {
      case 0x22: // "
      case 0x5C: // \
      case 0x2F: // /
        out.writeCharCode(0x5C);
        out.writeCharCode(c);
      case 0x09:
        out.write(r'\t');
      case 0x08:
        out.write(r'\b');
      case 0x0A:
        out.write(r'\n');
      case 0x0D:
        out.write(r'\r');
      case 0x0C:
        out.write(r'\f');
      default:
        if (c <= 0x1F || c == 0x2028 || c == 0x2029) {
          out.write('\\u${c.toRadixString(16).padLeft(4, '0')}');
        } else {
          out.writeCharCode(c);
        }
    }
  }
  out.write('"');
}

String _numberToString(num value) {
  if (value is int) return value.toString();
  final double d = value.toDouble();
  if (d == 0 && d.isNegative) return '-0';
  if (d.isFinite && d == d.truncateToDouble() && d.abs() < 9.2e18) {
    return d.toInt().toString();
  }
  return javaDoubleToString(d);
}

/// Java `Double.toString`과 같은 표기(1e-3 미만, 1e7 이상은 지수 표기).
String javaDoubleToString(double d) {
  if (d.isNaN) return 'NaN';
  if (d.isInfinite) return d > 0 ? 'Infinity' : '-Infinity';
  final double a = d.abs();
  if (a == 0) return d.isNegative ? '-0.0' : '0.0';
  if (a >= 1e-3 && a < 1e7) {
    final String s = d.toString();
    return s.contains('.') ? s : '$s.0';
  }
  final String exp = d.toStringAsExponential();
  final int e = exp.indexOf('e');
  String mantissa = exp.substring(0, e);
  if (!mantissa.contains('.')) mantissa = '$mantissa.0';
  final int power = int.parse(exp.substring(e + 1));
  return '${mantissa}E$power';
}

/// Java `Integer.parseInt`. 앞뒤 공백을 허용하지 않는다.
int javaParseInt(String s) {
  if (!RegExp(r'^[+-]?[0-9]+$').hasMatch(s)) {
    throw FormatException('For input string: "$s"');
  }
  final int v = int.parse(s);
  if (v < -2147483648 || v > 2147483647) {
    throw FormatException('For input string: "$s"');
  }
  return v;
}
